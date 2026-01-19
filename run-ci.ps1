# Universal CI Verifier - PowerShell Implementation
# Works on Windows (PowerShell 5.1+), macOS, and Linux (PowerShell Core)
# Zero dependencies beyond PowerShell itself

param(
    [string]$Config = "universal-ci.config.json",
    [ValidateSet("test", "release")]
    [string]$Stage = "test",
    [switch]$Interactive,
    [switch]$ListTasks,
    [string]$SelectTasks = "",
    [string[]]$ApproveTasks = @(),
    [string[]]$SkipTasks = @(),
    [switch]$Help
)

# Colors
$Green = "`e[92m"
$Red = "`e[91m"
$Yellow = "`e[93m"
$Blue = "`e[94m"
$Reset = "`e[0m"

# Fallback for older PowerShell without ANSI support
if ($PSVersionTable.PSVersion.Major -lt 6 -and $Host.Name -notmatch "ISE") {
    $Green = ""; $Red = ""; $Yellow = ""; $Blue = ""; $Reset = ""
}

function Show-Help {
    Write-Host "Universal CI Verifier - PowerShell Edition"
    Write-Host ""
    Write-Host "Usage: .\run-ci.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Config <path>       Path to config file (default: universal-ci.config.json)"
    Write-Host "  -Stage <stage>       Stage to run: test or release (default: test)"
    Write-Host "  -Interactive         Interactive mode (requires -ListTasks or task selection)"
    Write-Host "  -ListTasks           Output all tasks as JSON (use with -Interactive)"
    Write-Host "  -SelectTasks <json>  JSON array of task names to run"
    Write-Host "  -ApproveTasks <names> Approve tasks requiring approval (array)"
    Write-Host "  -SkipTasks <names>   Skip tasks by name (array)"
    Write-Host "  -Help                Show this help message"
    exit 0
}

function Find-ConfigFile {
    param([string]$ConfigPath)
    
    # Check provided/default path
    if (Test-Path $ConfigPath) {
        return $ConfigPath
    }
    
    # Check parent directories
    $currentPath = Get-Location
    for ($i = 1; $i -le 3; $i++) {
        $parentPath = Join-Path (Split-Path $currentPath -Parent) $ConfigPath
        if (Test-Path $parentPath) {
            return $parentPath
        }
        $currentPath = Split-Path $currentPath -Parent
    }
    
    # Check git root
    try {
        $gitRoot = git rev-parse --show-toplevel 2>$null
        if ($gitRoot) {
            $gitConfigPath = Join-Path $gitRoot $ConfigPath
            if (Test-Path $gitConfigPath) {
                return $gitConfigPath
            }
        }
    } catch {}
    
    return $null
}

function Get-FileHash256 {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return ""
    }
    
    try {
        $hash = (Get-FileHash -Path $FilePath -Algorithm SHA256 -ErrorAction Stop).Hash
        return $hash.Substring(0, [Math]::Min(16, $hash.Length))
    }
    catch {
        # Fallback to MD5
        try {
            $hash = (Get-FileHash -Path $FilePath -Algorithm MD5 -ErrorAction Stop).Hash
            return $hash.Substring(0, [Math]::Min(16, $hash.Length))
        }
        catch {
            return ""
        }
    }
}

function Resolve-HashKey {
    param(
        [string]$Key,
        [string]$BaseDir = "."
    )
    
    $result = $Key
    
    # Find all ${{ hashFiles(...) }} patterns
    if ($result -match 'hashFiles') {
        # Extract file paths - simplified for single files
        $pattern = '\{\{\s*hashFiles\([''"]([^''")]+)[''"]\)\s*\}\}'
        
        if ($result -match $pattern) {
            $filePath = $matches[1]
            
            # Try to find the file
            $fullPath = Join-Path $BaseDir $filePath
            if (-not (Test-Path $fullPath)) {
                $fullPath = $filePath
            }
            
            if (Test-Path $fullPath) {
                $hash = Get-FileHash256 -FilePath $fullPath
                if ($hash) {
                    $result = $result -replace '\{\{\s*hashFiles\([^)]+\)\s*\}\}', $hash
                }
            }
        }
    }
    
    return $result
}

function Evaluate-Condition {
    param([string]$Condition)
    
    if ([string]::IsNullOrEmpty($Condition)) {
        return $true
    }
    
    $expr = $Condition
    
    # Replace env.VAR_NAME with environment variable values
    $expr = [regex]::Replace($expr, 'env\.([A-Za-z_][A-Za-z0-9_]*)', {
        param($match)
        $varName = $match.Groups[1].Value
        $value = [Environment]::GetEnvironmentVariable($varName)
        if ($null -eq $value) { "null" } else { "`"$value`"" }
    })
    
    # Replace os(type) function
    if ($expr -match 'os\(') {
        $osType = if ($IsWindows) { "windows" } elseif ($IsMacOS) { "macos" } elseif ($IsLinux) { "linux" } else { "unknown" }
        $expr = $expr -replace 'os\(windows\)', ($osType -eq "windows" ? "true" : "false")
        $expr = $expr -replace 'os\(macos\)', ($osType -eq "macos" ? "true" : "false")
        $expr = $expr -replace 'os\(linux\)', ($osType -eq "linux" ? "true" : "false")
    }
    
    # Replace file(path) function
    if ($expr -match 'file\(') {
        $pattern = 'file\([''"]?([^''")]+)[''"]?\)'
        $expr = [regex]::Replace($expr, $pattern, {
            param($match)
            $path = $match.Groups[1].Value
            (Test-Path $path) ? "true" : "false"
        })
    }
    
    # Replace branch(name) function
    if ($expr -match 'branch\(') {
        try {
            $currentBranch = git rev-parse --abbrev-ref HEAD 2>$null
            if ($null -eq $currentBranch) { $currentBranch = "unknown" }
        } catch {
            $currentBranch = "unknown"
        }
        
        $pattern = 'branch\([''"]?([^''")]+)[''"]?\)'
        $expr = [regex]::Replace($expr, $pattern, {
            param($match)
            $branch = $match.Groups[1].Value
            ($currentBranch -eq $branch) ? "true" : "false"
        })
    }
    
    # Handle github context variables
    $expr = $expr -replace '\$\{\{\s*github\.ref\s*\}\}', $env:GITHUB_REF
    
    # Simple evaluation: if contains "false", return false
    if ($expr -match '\bfalse\b') {
        return $false
    }
    
    return $true
}

function Convert-TasksToJson {
    param([array]$Tasks)
    
    $jsonTasks = @()
    foreach ($task in $Tasks) {
        $jsonTask = @{
            name = $task.name
            directory = $task.working_directory
            command = $task.command
        }
        
        if ($task.cache_key) {
            $jsonTask.cache_key = $task.cache_key
        }
        if ($task.condition) {
            $jsonTask.condition = $task.condition
        }
        if ($task.requires_approval -eq $true) {
            $jsonTask.requires_approval = $true
        }
        
        $jsonTasks += $jsonTask
    }
    
    return $jsonTasks | ConvertTo-Json -Compress
}

function Invoke-Task {
    param(
        [string]$Name,
        [string]$WorkingDirectory,
        [string]$Command,
        [string]$CacheKey = "",
        [string]$Condition = "",
        [bool]$RequiresApproval = $false,
        [string[]]$ApprovedTasks = @(),
        [string[]]$SkippedTasks = @()
    )
    
    Write-Host "---------------------------------------------------"
    Write-Host "${Blue}🔍 Checking ${Name}...${Reset}"
    Write-Host "   📂 Path: ${WorkingDirectory}"
    Write-Host "   🚀 Command: ${Command}"
    
    # Check condition
    if ($Condition -and -not (Evaluate-Condition $Condition)) {
        Write-Host "   ${Yellow}⊘ Skipped (condition not met)${Reset}"
        return $true
    }
    
    # Check approval
    if ($RequiresApproval -and $Name -notin $ApprovedTasks) {
        Write-Host "   ${Yellow}⊘ Skipped (requires approval, use -ApproveTasks)${Reset}"
        return $true
    }
    
    # Check if skipped
    if ($Name -in $SkippedTasks) {
        Write-Host "   ${Yellow}⊘ Skipped (explicitly skipped)${Reset}"
        return $true
    }
    
    # Check directory exists
    if (-not (Test-Path $WorkingDirectory -PathType Container)) {
        Write-Host "   ${Yellow}⚠️  Skipped (Directory not found)${Reset}"
        return $true
    }
    
    # Handle caching
    if ($CacheKey) {
        $resolvedCacheKey = Resolve-HashKey -Key $CacheKey -BaseDir $WorkingDirectory
        $cachePath = Join-Path ".universal-ci-cache" $resolvedCacheKey
        
        if (Test-Path $cachePath) {
            Write-Host "   ${Green}⚡ Cache hit! (${resolvedCacheKey})${Reset}"
            return $true
        }
    }
    
    # Run command
    try {
        Push-Location $WorkingDirectory
        
        # Execute command
        if ($IsWindows -or $env:OS -match "Windows") {
            $result = cmd /c $Command 2>&1
        } else {
            $result = sh -c $Command 2>&1
        }
        
        $exitCode = $LASTEXITCODE
        
        # Output result
        $result | ForEach-Object { Write-Host $_ }
        
        if ($exitCode -eq 0) {
            # Save to cache if configured
            if ($CacheKey) {
                $resolvedCacheKey = Resolve-HashKey -Key $CacheKey -BaseDir $WorkingDirectory
                $cachePath = Join-Path ".universal-ci-cache" $resolvedCacheKey
                if (-not (Test-Path $cachePath)) {
                    New-Item -ItemType Directory -Path $cachePath -Force | Out-Null
                    New-Item -Path (Join-Path $cachePath ".cache-valid") -ItemType File -Force | Out-Null
                }
            }
            
            Write-Host "   ${Green}✅ ${Name} Passed${Reset}"
            return $true
        } else {
            Write-Host "   ${Red}❌ ${Name} FAILED${Reset}"
            return $false
        }
    }
    catch {
        Write-Host "   ${Red}❌ Execution Error: $_${Reset}"
        return $false
    }
    finally {
        Pop-Location
    }
}

function Main {
    if ($Help) {
        Show-Help
    }
    
    Write-Host "${Blue}🌐 Starting Universal CI Verification (PowerShell Edition)...${Reset}"
    
    # Detect environment
    if ($env:GITHUB_ACTIONS) {
        Write-Host "   📍 Environment: GitHub Actions"
    } elseif ($env:CI) {
        Write-Host "   📍 Environment: CI Server"
    } else {
        Write-Host "   📍 Environment: Local Shell"
    }
    
    # Find config file
    $configPath = Find-ConfigFile -ConfigPath $Config
    if (-not $configPath) {
        Write-Host "${Red}Error: Config file '${Config}' not found.${Reset}"
        Write-Host "Searched in: current directory, parent directories, and git root."
        exit 1
    }
    
    Write-Host "   📄 Config: ${configPath}"
    
    # Load config
    try {
        $configData = Get-Content $configPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "${Red}Error: Failed to parse config file: $_${Reset}"
        exit 1
    }
    
    Write-Host "---------------------------------------------------"
    Write-Host "${Blue}🛠  $($Stage.ToUpper()) PHASE${Reset}"
    
    # Filter tasks by stage and expand versions
    $expandedTasks = @()
    foreach ($task in $configData.tasks) {
        $taskStage = if ($task.stage) { $task.stage } else { "test" }
        
        if ($taskStage -eq $Stage) {
            # Check if task has versions array
            if ($task.versions -and $task.versions.Count -gt 0) {
                # Expand task for each version
                foreach ($version in $task.versions) {
                    $expandedName = $task.name -replace "{version}", $version
                    $expandedCommand = $task.command -replace "{version}", $version
                    
                    $expandedTasks += @{
                        name = $expandedName
                        working_directory = $task.working_directory
                        command = $expandedCommand
                        stage = $taskStage
                        cache_key = if ($task.cache_key) { $task.cache_key } else { "" }
                        condition = if ($task.condition) { $task.condition } else { "" }
                        requires_approval = if ($task.requires_approval) { $task.requires_approval } else { $false }
                    }
                }
            } else {
                # No versions, add task as-is
                $expandedTasks += @{
                    name = $task.name
                    working_directory = $task.working_directory
                    command = $task.command
                    stage = $taskStage
                    cache_key = if ($task.cache_key) { $task.cache_key } else { "" }
                    condition = if ($task.condition) { $task.condition } else { "" }
                    requires_approval = if ($task.requires_approval) { $task.requires_approval } else { $false }
                }
            }
        }
    }
    
    if ($expandedTasks.Count -eq 0) {
        Write-Host "   ${Yellow}No tasks found for stage: ${Stage}${Reset}"
        exit 0
    }
    
    # Interactive mode: list tasks and exit
    if ($ListTasks) {
        Convert-TasksToJson -Tasks $expandedTasks
        exit 0
    }
    
    # Interactive mode: filter tasks by selection
    if ($SelectTasks) {
        $selectedArray = $SelectTasks | ConvertFrom-Json
        $expandedTasks = $expandedTasks | Where-Object { $_.name -in $selectedArray }
        
        if ($expandedTasks.Count -eq 0) {
            Write-Host "   ${Yellow}No tasks selected${Reset}"
            exit 0
        }
    }
    
    # Run tasks
    $failures = @()
    foreach ($task in $expandedTasks) {
        $success = Invoke-Task `
            -Name $task.name `
            -WorkingDirectory $task.working_directory `
            -Command $task.command `
            -CacheKey $task.cache_key `
            -Condition $task.condition `
            -RequiresApproval $task.requires_approval `
            -ApprovedTasks $ApproveTasks `
            -SkippedTasks $SkipTasks
            
        if (-not $success) {
            $failures += $task.name
        }
    }
    
    # Summary
    Write-Host "---------------------------------------------------"
    Write-Host "${Blue}📊 SUMMARY${Reset}"
    
    if ($failures.Count -eq 0) {
        Write-Host "${Green}🎉 ALL SYSTEMS GO! Universal CI Passed.${Reset}"
        exit 0
    } else {
        Write-Host "${Red}🚨 FAILURES DETECTED:${Reset}"
        foreach ($fail in $failures) {
            Write-Host "   - ${fail}"
        }
        exit 1
    }
}

# Run main
Main