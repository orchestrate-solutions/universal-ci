# Universal CI Verifier - PowerShell Implementation
# Works on Windows (PowerShell 5.1+), macOS, and Linux (PowerShell Core)
# Zero dependencies beyond PowerShell itself

param(
    [string]$Config = "universal-ci.config.json",
    [ValidateSet("test", "release")]
    [string]$Stage = "test",
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
    Write-Host "Usage: .\verify.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Config <path>    Path to config file (default: universal-ci.config.json)"
    Write-Host "  -Stage <stage>    Stage to run: test or release (default: test)"
    Write-Host "  -Help             Show this help message"
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

function Invoke-Task {
    param(
        [string]$Name,
        [string]$WorkingDirectory,
        [string]$Command
    )
    
    Write-Host "---------------------------------------------------"
    Write-Host "${Blue}🔍 Checking ${Name}...${Reset}"
    Write-Host "   📂 Path: ${WorkingDirectory}"
    Write-Host "   🚀 Command: ${Command}"
    
    # Check if directory exists
    if (-not (Test-Path $WorkingDirectory -PathType Container)) {
        Write-Host "   ${Yellow}⚠️  Skipped (Directory not found)${Reset}"
        return $true
    }
    
    # Run command
    try {
        Push-Location $WorkingDirectory
        
        # Execute command based on platform
        if ($IsWindows -or $env:OS -match "Windows") {
            $result = cmd /c $Command 2>&1
        } else {
            $result = sh -c $Command 2>&1
        }
        
        $exitCode = $LASTEXITCODE
        
        # Output result
        $result | ForEach-Object { Write-Host $_ }
        
        if ($exitCode -eq 0) {
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
                    }
                }
            } else {
                # No versions, add task as-is
                $expandedTasks += @{
                    name = $task.name
                    working_directory = $task.working_directory
                    command = $task.command
                    stage = $taskStage
                }
            }
        }
    }
    
    if ($expandedTasks.Count -eq 0) {
        Write-Host "   ${Yellow}No tasks found for stage: ${Stage}${Reset}"
        exit 0
    }
    
    # Run tasks
    $failures = @()
    foreach ($task in $expandedTasks) {
        $success = Invoke-Task -Name $task.name -WorkingDirectory $task.working_directory -Command $task.command
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