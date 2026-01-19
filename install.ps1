# Universal CI - One-Command Bootstrap for Windows
# Usage: irm https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install.ps1 | iex
#
# Or with options:
#   $env:UCI_NO_HOOKS = "1"; irm ... | iex
#   $env:UCI_TYPE = "nodejs"; irm ... | iex

param(
    [switch]$NoHooks,
    [switch]$NoVerify,
    [switch]$Force,
    [string]$Type = "",
    [switch]$GitHubActions,
    [switch]$Docker,
    [switch]$NonInteractive,
    [Alias("h")]
    [switch]$Help
)

# ============================================================================
# CONFIGURATION
# ============================================================================

$RepoUrl = "https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main"
$ConfigFile = "universal-ci.config.json"
$VerifyScript = "verify.ps1"

# Support environment variables for piped execution
if ($env:UCI_NO_HOOKS -eq "1") { $NoHooks = $true }
if ($env:UCI_NO_VERIFY -eq "1") { $NoVerify = $true }
if ($env:UCI_FORCE -eq "1") { $Force = $true }
if ($env:UCI_TYPE) { $Type = $env:UCI_TYPE }
if ($env:UCI_GITHUB_ACTIONS -eq "1") { $GitHubActions = $true }
if ($env:UCI_DOCKER -eq "1") { $Docker = $true }
if ($env:UCI_NON_INTERACTIVE -eq "1") { $NonInteractive = $true }

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Banner {
    Write-Host @"
  _   _       _                          _    ____ ___ 
 | | | |_ __ (_)_   _____ _ __ ___  __ _| |  / ___|_ _|
 | | | | '_ \| \ \ / / _ \ '__/ __|/ _` | | | |    | | 
 | |_| | | | | |\ V /  __/ |  \__ \ (_| | | | |___ | | 
  \___/|_| |_|_| \_/ \___|_|  |___/\__,_|_|  \____|___|
                                                       
"@ -ForegroundColor Cyan
    Write-Host "One-Command Bootstrap" -ForegroundColor White
    Write-Host ""
}

function Write-Step { param($Message) Write-Host "▶ $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

function Prompt-YesNo {
    param(
        [string]$Question,
        [string]$Default = "y"
    )
    
    if ($NonInteractive) {
        return $Default -eq "y"
    }
    
    $prompt = if ($Default -eq "y") { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Question $prompt"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $Default -eq "y"
    }
    
    return $response.ToLower().StartsWith("y")
}

# ============================================================================
# PROJECT DETECTION
# ============================================================================

function Get-ProjectType {
    if ($Type) { return $Type }
    
    # Node.js
    if (Test-Path "package.json") { return "nodejs" }
    
    # Python
    if ((Test-Path "pyproject.toml") -or (Test-Path "setup.py") -or 
        (Test-Path "requirements.txt") -or (Test-Path "Pipfile")) {
        return "python"
    }
    
    # Go
    if (Test-Path "go.mod") { return "go" }
    
    # Rust
    if (Test-Path "Cargo.toml") { return "rust" }
    
    # .NET
    if ((Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue) -or
        (Get-ChildItem -Filter "*.fsproj" -ErrorAction SilentlyContinue) -or
        (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue)) {
        return "dotnet"
    }
    
    # Java (Maven)
    if (Test-Path "pom.xml") { return "java-maven" }
    
    # Java (Gradle)
    if ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
        return "java-gradle"
    }
    
    # Ruby
    if (Test-Path "Gemfile") { return "ruby" }
    
    # PHP
    if (Test-Path "composer.json") { return "php" }
    
    # Makefile
    if (Test-Path "Makefile") { return "make" }
    
    return "generic"
}

function Get-NodePackageManager {
    if (Test-Path "pnpm-lock.yaml") { return "pnpm" }
    if (Test-Path "yarn.lock") { return "yarn" }
    if (Test-Path "bun.lockb") { return "bun" }
    return "npm"
}

function Get-PythonPackageManager {
    if (Test-Path "poetry.lock") { return "poetry" }
    if ((Test-Path "pyproject.toml") -and (Select-String -Path "pyproject.toml" -Pattern "\[tool\.poetry\]" -Quiet)) {
        return "poetry"
    }
    if (Test-Path "Pipfile") { return "pipenv" }
    if (Test-Path "uv.lock") { return "uv" }
    return "pip"
}

function Test-NpmScript {
    param([string]$ScriptName)
    if (Test-Path "package.json") {
        $pkg = Get-Content "package.json" | ConvertFrom-Json
        return $null -ne $pkg.scripts.$ScriptName
    }
    return $false
}

# ============================================================================
# CONFIG GENERATION
# ============================================================================

function Get-NodejsConfig {
    $pm = Get-NodePackageManager
    
    $installCmd = switch ($pm) {
        "pnpm" { "pnpm install" }
        "yarn" { "yarn install" }
        "bun" { "bun install" }
        default { "npm ci" }
    }
    
    $testCmd = if (Test-NpmScript "test") {
        switch ($pm) {
            "pnpm" { "pnpm test" }
            "yarn" { "yarn test" }
            "bun" { "bun test" }
            default { "npm test" }
        }
    } else {
        "echo 'No tests configured - add a test script to package.json'"
    }
    
    $tasks = @(
        @{ name = "Install Dependencies"; working_directory = "."; command = $installCmd; stage = "test" }
        @{ name = "Run Tests"; working_directory = "."; command = $testCmd; stage = "test" }
    )
    
    if (Test-NpmScript "lint") {
        $lintCmd = switch ($pm) {
            "pnpm" { "pnpm run lint" }
            "yarn" { "yarn lint" }
            "bun" { "bun run lint" }
            default { "npm run lint" }
        }
        $tasks += @{ name = "Lint"; working_directory = "."; command = $lintCmd; stage = "test" }
    }
    
    if (Test-NpmScript "build") {
        $buildCmd = switch ($pm) {
            "pnpm" { "pnpm run build" }
            "yarn" { "yarn build" }
            "bun" { "bun run build" }
            default { "npm run build" }
        }
        $tasks += @{ name = "Build"; working_directory = "."; command = $buildCmd; stage = "release" }
    }
    
    return @{ tasks = $tasks }
}

function Get-PythonConfig {
    $pm = Get-PythonPackageManager
    
    switch ($pm) {
        "poetry" {
            $installCmd = "poetry install"
            $testCmd = "poetry run pytest"
            $lintCmd = "poetry run ruff check . || poetry run flake8"
        }
        "pipenv" {
            $installCmd = "pipenv install --dev"
            $testCmd = "pipenv run pytest"
            $lintCmd = "pipenv run ruff check . || pipenv run flake8"
        }
        "uv" {
            $installCmd = "uv sync"
            $testCmd = "uv run pytest"
            $lintCmd = "uv run ruff check ."
        }
        default {
            $installCmd = "pip install -r requirements.txt"
            $testCmd = "pytest"
            $lintCmd = "ruff check . || flake8 || echo 'No linter found'"
        }
    }
    
    return @{
        tasks = @(
            @{ name = "Install Dependencies"; working_directory = "."; command = $installCmd; stage = "test" }
            @{ name = "Lint"; working_directory = "."; command = $lintCmd; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = $testCmd; stage = "test" }
        )
    }
}

function Get-GoConfig {
    return @{
        tasks = @(
            @{ name = "Download Dependencies"; working_directory = "."; command = "go mod download"; stage = "test" }
            @{ name = "Lint"; working_directory = "."; command = "go vet ./..."; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = "go test -v ./..."; stage = "test" }
            @{ name = "Build"; working_directory = "."; command = "go build -v ./..."; stage = "release" }
        )
    }
}

function Get-RustConfig {
    return @{
        tasks = @(
            @{ name = "Check"; working_directory = "."; command = "cargo check"; stage = "test" }
            @{ name = "Clippy Lint"; working_directory = "."; command = "cargo clippy -- -D warnings"; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = "cargo test"; stage = "test" }
            @{ name = "Build Release"; working_directory = "."; command = "cargo build --release"; stage = "release" }
        )
    }
}

function Get-DotnetConfig {
    return @{
        tasks = @(
            @{ name = "Restore"; working_directory = "."; command = "dotnet restore"; stage = "test" }
            @{ name = "Build"; working_directory = "."; command = "dotnet build --no-restore"; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = "dotnet test --no-build --verbosity normal"; stage = "test" }
            @{ name = "Publish"; working_directory = "."; command = "dotnet publish -c Release"; stage = "release" }
        )
    }
}

function Get-JavaMavenConfig {
    return @{
        tasks = @(
            @{ name = "Compile"; working_directory = "."; command = "mvn compile"; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = "mvn test"; stage = "test" }
            @{ name = "Package"; working_directory = "."; command = "mvn package -DskipTests"; stage = "release" }
        )
    }
}

function Get-JavaGradleConfig {
    return @{
        tasks = @(
            @{ name = "Compile"; working_directory = "."; command = "gradlew compileJava"; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = "gradlew test"; stage = "test" }
            @{ name = "Build"; working_directory = "."; command = "gradlew build -x test"; stage = "release" }
        )
    }
}

function Get-RubyConfig {
    return @{
        tasks = @(
            @{ name = "Install Dependencies"; working_directory = "."; command = "bundle install"; stage = "test" }
            @{ name = "Lint"; working_directory = "."; command = "bundle exec rubocop"; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = "bundle exec rspec || bundle exec rake test"; stage = "test" }
        )
    }
}

function Get-PhpConfig {
    return @{
        tasks = @(
            @{ name = "Install Dependencies"; working_directory = "."; command = "composer install"; stage = "test" }
            @{ name = "Lint"; working_directory = "."; command = "composer run lint || vendor/bin/phpstan analyse"; stage = "test" }
            @{ name = "Run Tests"; working_directory = "."; command = "composer test || vendor/bin/phpunit"; stage = "test" }
        )
    }
}

function Get-MakeConfig {
    return @{
        tasks = @(
            @{ name = "Build"; working_directory = "."; command = "make"; stage = "test" }
            @{ name = "Test"; working_directory = "."; command = "make test"; stage = "test" }
        )
    }
}

function Get-GenericConfig {
    return @{
        tasks = @(
            @{ name = "Hello World"; working_directory = "."; command = "echo 'Universal CI is ready! Edit universal-ci.config.json to add your tasks.'"; stage = "test" }
        )
    }
}

function Get-ProjectConfig {
    param([string]$ProjectType)
    
    switch ($ProjectType) {
        "nodejs" { return Get-NodejsConfig }
        "python" { return Get-PythonConfig }
        "go" { return Get-GoConfig }
        "rust" { return Get-RustConfig }
        "dotnet" { return Get-DotnetConfig }
        "java-maven" { return Get-JavaMavenConfig }
        "java-gradle" { return Get-JavaGradleConfig }
        "ruby" { return Get-RubyConfig }
        "php" { return Get-PhpConfig }
        "make" { return Get-MakeConfig }
        default { return Get-GenericConfig }
    }
}

# ============================================================================
# GITHUB ACTIONS SETUP
# ============================================================================

function Setup-GitHubActions {
    $workflowDir = ".github/workflows"
    if (-not (Test-Path $workflowDir)) {
        New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
    }
    
    $workflow = @'
name: CI

on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Universal CI
        run: |
          curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/verify.sh -o .verify.sh
          chmod +x .verify.sh
          ./.verify.sh
          rm .verify.sh
'@
    
    $workflow | Set-Content "$workflowDir/ci.yml" -Encoding UTF8
    Write-Success "Created .github/workflows/ci.yml"
}

# ============================================================================
# DOCKER SETUP
# ============================================================================

function Setup-Docker {
    $dockerfile = @'
# Universal CI Docker Environment
# Build: docker build -f Dockerfile.ci -t uci .
# Run:   docker run --rm -v ${pwd}:/app uci

FROM alpine:latest

RUN apk add --no-cache bash curl git jq make

WORKDIR /app

COPY verify.sh /usr/local/bin/uci
RUN chmod +x /usr/local/bin/uci

ENTRYPOINT ["uci"]
'@

    $compose = @'
# Universal CI Docker Compose
# Usage: docker-compose -f docker-compose.ci.yml run ci

version: '3.8'
services:
  ci:
    build:
      context: .
      dockerfile: Dockerfile.ci
    volumes:
      - .:/app
    working_dir: /app
'@

    $dockerfile | Set-Content "Dockerfile.ci" -Encoding UTF8
    $compose | Set-Content "docker-compose.ci.yml" -Encoding UTF8
    
    Write-Success "Created Dockerfile.ci and docker-compose.ci.yml"
    Write-Info "Run with: docker-compose -f docker-compose.ci.yml run ci"
}

# ============================================================================
# GIT HOOKS
# ============================================================================

function Setup-GitHooks {
    if (-not (Test-Path ".git")) {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Write-Info "Not a Git repository. Initializing..."
            git init
        } else {
            Write-Warn "Git not installed. Skipping hooks setup."
            return
        }
    }
    
    $hooksDir = ".git/hooks"
    if (-not (Test-Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }
    
    $prePushHook = @'
#!/bin/sh
# Universal CI Pre-Push Hook

echo "🔍 Running Universal CI verification..."

if [ -f "./verify.sh" ]; then
    ./verify.sh
elif [ -f "./verify.ps1" ]; then
    pwsh -File ./verify.ps1
else
    echo "⚠️  verify script not found"
    exit 0
fi

exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo ""
    echo "❌ Verification failed. Push blocked."
    exit 1
fi

echo "✅ Verification passed."
'@
    
    $prePushHook | Set-Content "$hooksDir/pre-push" -Encoding UTF8 -NoNewline
    
    # Make executable on Unix-like systems
    if ($IsLinux -or $IsMacOS) {
        chmod +x "$hooksDir/pre-push"
    }
    
    Write-Success "Created .git/hooks/pre-push"
}

# ============================================================================
# HELP
# ============================================================================

function Show-Help {
    Write-Host @"
Universal CI Bootstrap

Usage:
  irm https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install.ps1 | iex

  # With options (set environment variables first):
  `$env:UCI_TYPE = "nodejs"; irm ... | iex
  `$env:UCI_GITHUB_ACTIONS = "1"; irm ... | iex

Options:
  -NoHooks          Skip Git hooks setup
  -NoVerify         Skip initial verification run
  -Force            Overwrite existing config file
  -Type <type>      Force project type (nodejs, python, go, rust, dotnet, java-maven, java-gradle, ruby, php, make)
  -GitHubActions    Create GitHub Actions workflow
  -Docker           Create Docker CI setup
  -NonInteractive   Skip all prompts (use defaults)
  -Help             Show this help message

Environment Variables (for piped execution):
  UCI_NO_HOOKS=1, UCI_NO_VERIFY=1, UCI_FORCE=1
  UCI_TYPE=<type>, UCI_GITHUB_ACTIONS=1, UCI_DOCKER=1
  UCI_NON_INTERACTIVE=1

Examples:
  # Basic install with auto-detection
  irm .../install.ps1 | iex

  # Force Node.js config
  `$env:UCI_TYPE = "nodejs"; irm .../install.ps1 | iex

  # Full setup with GitHub Actions
  `$env:UCI_GITHUB_ACTIONS = "1"; irm .../install.ps1 | iex
"@
}

# ============================================================================
# MAIN
# ============================================================================

function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Banner
    
    # Step 1: Download verify.ps1
    Write-Step "Downloading Universal CI..."
    try {
        Invoke-WebRequest -Uri "$RepoUrl/$VerifyScript" -OutFile $VerifyScript -UseBasicParsing
        Write-Success "Downloaded $VerifyScript"
    } catch {
        Write-Error "Failed to download $VerifyScript"
        exit 1
    }
    
    # Also download verify.sh for cross-platform hooks
    try {
        Invoke-WebRequest -Uri "$RepoUrl/verify.sh" -OutFile "verify.sh" -UseBasicParsing
        Write-Success "Downloaded verify.sh (for cross-platform hooks)"
    } catch {
        Write-Warn "Could not download verify.sh"
    }
    
    # Step 2: Detect project type
    Write-Step "Detecting project type..."
    $projectType = Get-ProjectType
    
    $friendlyName = switch ($projectType) {
        "nodejs" { "Node.js" }
        "python" { "Python" }
        "go" { "Go" }
        "rust" { "Rust" }
        "dotnet" { ".NET" }
        "java-maven" { "Java (Maven)" }
        "java-gradle" { "Java (Gradle)" }
        "ruby" { "Ruby" }
        "php" { "PHP" }
        "make" { "Makefile" }
        default { "Generic" }
    }
    
    Write-Success "Detected: $friendlyName"
    
    if ($projectType -eq "nodejs") {
        Write-Info "Package manager: $(Get-NodePackageManager)"
    } elseif ($projectType -eq "python") {
        Write-Info "Package manager: $(Get-PythonPackageManager)"
    }
    
    # Step 3: Generate config
    Write-Step "Generating configuration..."
    
    if ((Test-Path $ConfigFile) -and -not $Force) {
        Write-Warn "Config file already exists: $ConfigFile"
        if (Prompt-YesNo "Overwrite?" "n") {
            $config = Get-ProjectConfig -ProjectType $projectType
            $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -Encoding UTF8
            Write-Success "Overwrote $ConfigFile"
        } else {
            Write-Info "Keeping existing config"
        }
    } else {
        $config = Get-ProjectConfig -ProjectType $projectType
        $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -Encoding UTF8
        Write-Success "Created $ConfigFile"
    }
    
    # Step 4: Git hooks
    if (-not $NoHooks) {
        Write-Step "Setting up Git hooks..."
        if (Prompt-YesNo "Install pre-push verification hook?" "y") {
            Setup-GitHooks
        } else {
            Write-Info "Skipped hooks setup"
        }
    }
    
    # Step 5: GitHub Actions
    if ($GitHubActions) {
        Write-Step "Setting up GitHub Actions..."
        Setup-GitHubActions
    } elseif (-not $NonInteractive -and -not (Test-Path ".github/workflows")) {
        if (Prompt-YesNo "Create GitHub Actions workflow?" "n") {
            Setup-GitHubActions
        }
    }
    
    # Step 6: Docker
    if ($Docker) {
        Write-Step "Setting up Docker..."
        Setup-Docker
    }
    
    # Step 7: Run verification
    if (-not $NoVerify) {
        Write-Host ""
        Write-Step "Running initial verification..."
        Write-Host ""
        & ".\$VerifyScript"
    }
    
    # Done!
    Write-Host ""
    Write-Host "🎉 Universal CI is ready!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Review $ConfigFile and customize tasks"
    Write-Host "  2. Run " -NoNewline
    Write-Host ".\verify.ps1" -ForegroundColor Cyan -NoNewline
    Write-Host " to verify your project"
    Write-Host "  3. Commit and push - hooks will verify automatically"
    Write-Host ""
    
    if ($GitHubActions) {
        Write-Host "GitHub Actions:"
        Write-Host "  - Push to trigger CI at .github/workflows/ci.yml"
        Write-Host ""
    }
    
    if ($Docker) {
        Write-Host "Docker:"
        Write-Host "  - Run: " -NoNewline
        Write-Host "docker-compose -f docker-compose.ci.yml run ci" -ForegroundColor Cyan
        Write-Host ""
    }
}

Main
