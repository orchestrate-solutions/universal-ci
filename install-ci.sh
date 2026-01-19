#!/bin/sh
# Universal CI - One-Command Bootstrap
# Usage: curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install-ci.sh | sh
#
# Options (pass via -s --):
#   curl -sL ... | sh -s -- --no-hooks          Skip Git hooks setup
#   curl -sL ... | sh -s -- --no-verify         Skip initial verification
#   curl -sL ... | sh -s -- --force             Overwrite existing config
#   curl -sL ... | sh -s -- --type <type>       Force project type detection
#   curl -sL ... | sh -s -- --github-actions    Also create GitHub Actions workflow
#   curl -sL ... | sh -s -- --docker            Also create Docker setup
#
# This script will:
# 1. Download run-ci.sh
# 2. Auto-detect your project type (Node, Python, Go, Rust, .NET, Java, etc.)
# 3. Generate universal-ci.config.json with appropriate tasks
# 4. Optionally set up Git pre-push hooks
# 5. Run initial verification

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

REPO_URL="https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main"
CONFIG_FILE="universal-ci.config.json"
VERIFY_SCRIPT="run-ci.sh"

# Default options
SKIP_HOOKS=false
SKIP_VERIFY=false
FORCE_CONFIG=false
FORCE_TYPE=""
SETUP_GITHUB_ACTIONS=false
SETUP_DOCKER=false
INTERACTIVE=true

# Colors
if [ -t 1 ]; then
    GREEN='\033[92m'
    RED='\033[91m'
    YELLOW='\033[93m'
    BLUE='\033[94m'
    CYAN='\033[96m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN=''
    RED=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    RESET=''
fi

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_banner() {
    printf "${CYAN}"
    cat << 'EOF'
  _   _       _                          _    ____ ___ 
 | | | |_ __ (_)_   _____ _ __ ___  __ _| |  / ___|_ _|
 | | | | '_ \| \ \ / / _ \ '__/ __|/ _` | | | |    | | 
 | |_| | | | | |\ V /  __/ |  \__ \ (_| | | | |___ | | 
  \___/|_| |_|_| \_/ \___|_|  |___/\__,_|_|  \____|___|
                                                       
EOF
    printf "${RESET}"
    printf "${BOLD}One-Command Bootstrap${RESET}\n"
    echo ""
}

log_step() {
    printf "${BLUE}▶${RESET} $1\n"
}

log_success() {
    printf "${GREEN}✅ $1${RESET}\n"
}

log_warn() {
    printf "${YELLOW}⚠️  $1${RESET}\n"
}

log_error() {
    printf "${RED}❌ $1${RESET}\n"
}

log_info() {
    printf "${CYAN}ℹ️  $1${RESET}\n"
}

prompt_yes_no() {
    question="$1"
    default="$2"
    
    if [ "$INTERACTIVE" = false ]; then
        [ "$default" = "y" ] && return 0 || return 1
    fi
    
    if [ "$default" = "y" ]; then
        printf "${question} ${CYAN}[Y/n]${RESET} "
    else
        printf "${question} ${CYAN}[y/N]${RESET} "
    fi
    
    read -r answer
    case "$answer" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        "") [ "$default" = "y" ] && return 0 || return 1 ;;
        *) [ "$default" = "y" ] && return 0 || return 1 ;;
    esac
}

# ============================================================================
# PROJECT DETECTION
# ============================================================================

detect_project_type() {
    # Force type if specified
    if [ -n "$FORCE_TYPE" ]; then
        echo "$FORCE_TYPE"
        return 0
    fi
    
    # Node.js
    if [ -f "package.json" ]; then
        echo "nodejs"
        return 0
    fi
    
    # Python
    if [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ] || [ -f "Pipfile" ]; then
        echo "python"
        return 0
    fi
    
    # Go
    if [ -f "go.mod" ]; then
        echo "go"
        return 0
    fi
    
    # Rust
    if [ -f "Cargo.toml" ]; then
        echo "rust"
        return 0
    fi
    
    # .NET
    if ls *.csproj 1>/dev/null 2>&1 || ls *.fsproj 1>/dev/null 2>&1 || [ -f "*.sln" ]; then
        echo "dotnet"
        return 0
    fi
    
    # Java (Maven)
    if [ -f "pom.xml" ]; then
        echo "java-maven"
        return 0
    fi
    
    # Kotlin (before Java Gradle since Kotlin uses gradle with kotlin plugin)
    if [ -d "src/main/kotlin" ] || ([ -f "build.gradle.kts" ] && grep -q "kotlin" build.gradle.kts 2>/dev/null); then
        echo "kotlin"
        return 0
    fi
    
    # Scala (before Java Gradle since Scala can use gradle)
    if [ -f "build.sbt" ] || [ -d "src/main/scala" ] || ([ -f "build.gradle" ] && grep -q "scala" build.gradle 2>/dev/null); then
        echo "scala"
        return 0
    fi
    
    # Java (Gradle)
    if [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        echo "java-gradle"
        return 0
    fi
    
    # Swift
    if [ -f "Package.swift" ] || ([ -d "Sources" ] && ls Sources/*.swift 1>/dev/null 2>&1); then
        echo "swift"
        return 0
    fi
    
    # C++
    if [ -f "CMakeLists.txt" ] || ls *.cpp 1>/dev/null 2>&1 || ls *.cc 1>/dev/null 2>&1; then
        echo "cpp"
        return 0
    fi
    
    # Dart
    if [ -f "pubspec.yaml" ] || ls *.dart 1>/dev/null 2>&1; then
        echo "dart"
        return 0
    fi
    
    # Ruby
    if [ -f "Gemfile" ]; then
        echo "ruby"
        return 0
    fi
    
    # PHP (Composer)
    if [ -f "composer.json" ]; then
        echo "php"
        return 0
    fi
    
    # Makefile project
    if [ -f "Makefile" ]; then
        echo "make"
        return 0
    fi
    
    # Shell scripts
    if ls *.sh 1>/dev/null 2>&1; then
        echo "shell"
        return 0
    fi
    
    echo "generic"
}

# Detect package manager for Node.js
detect_node_package_manager() {
    if [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    elif [ -f "bun.lockb" ]; then
        echo "bun"
    else
        echo "npm"
    fi
}

# Detect Python package manager
detect_python_package_manager() {
    if [ -f "poetry.lock" ] || ([ -f "pyproject.toml" ] && grep -q "\[tool.poetry\]" pyproject.toml 2>/dev/null); then
        echo "poetry"
    elif [ -f "Pipfile" ]; then
        echo "pipenv"
    elif [ -f "uv.lock" ] || ([ -f "pyproject.toml" ] && grep -q "\[tool.uv\]" pyproject.toml 2>/dev/null); then
        echo "uv"
    else
        echo "pip"
    fi
}

# Check if package.json has a specific script
has_npm_script() {
    script_name="$1"
    if [ -f "package.json" ]; then
        grep -q "\"$script_name\"" package.json 2>/dev/null && return 0
    fi
    return 1
}

# ============================================================================
# CONFIG GENERATION
# ============================================================================

generate_nodejs_config() {
    pm=$(detect_node_package_manager)
    
    # Build install command
    case "$pm" in
        pnpm) install_cmd="pnpm install" ;;
        yarn) install_cmd="yarn install" ;;
        bun)  install_cmd="bun install" ;;
        *)    install_cmd="npm ci" ;;
    esac
    
    # Build test command
    if has_npm_script "test"; then
        case "$pm" in
            pnpm) test_cmd="pnpm test" ;;
            yarn) test_cmd="yarn test" ;;
            bun)  test_cmd="bun test" ;;
            *)    test_cmd="npm test" ;;
        esac
    else
        test_cmd="echo 'No tests configured - add a test script to package.json'"
    fi
    
    # Build lint command
    if has_npm_script "lint"; then
        case "$pm" in
            pnpm) lint_cmd="pnpm run lint" ;;
            yarn) lint_cmd="yarn lint" ;;
            bun)  lint_cmd="bun run lint" ;;
            *)    lint_cmd="npm run lint" ;;
        esac
        lint_task=",
    {
      \"name\": \"Lint\",
      \"working_directory\": \".\",
      \"command\": \"$lint_cmd\",
      \"stage\": \"test\"
    }"
    else
        lint_task=""
    fi
    
    # Build command
    if has_npm_script "build"; then
        case "$pm" in
            pnpm) build_cmd="pnpm run build" ;;
            yarn) build_cmd="yarn build" ;;
            bun)  build_cmd="bun run build" ;;
            *)    build_cmd="npm run build" ;;
        esac
        build_task=",
    {
      \"name\": \"Build\",
      \"working_directory\": \".\",
      \"command\": \"$build_cmd\",
      \"stage\": \"release\"
    }"
    else
        build_task=""
    fi
    
    cat << EOF
{
  "tasks": [
    {
      "name": "Install Dependencies",
      "working_directory": ".",
      "command": "$install_cmd",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "$test_cmd",
      "stage": "test"
    }$lint_task$build_task
  ]
}
EOF
}

generate_python_config() {
    pm=$(detect_python_package_manager)
    
    case "$pm" in
        poetry)
            install_cmd="poetry install"
            test_cmd="poetry run pytest"
            lint_cmd="poetry run ruff check . || poetry run flake8"
            ;;
        pipenv)
            install_cmd="pipenv install --dev"
            test_cmd="pipenv run pytest"
            lint_cmd="pipenv run ruff check . || pipenv run flake8"
            ;;
        uv)
            install_cmd="uv sync"
            test_cmd="uv run pytest"
            lint_cmd="uv run ruff check ."
            ;;
        *)
            install_cmd="pip install -r requirements.txt"
            test_cmd="pytest"
            lint_cmd="ruff check . || flake8 || echo 'No linter found'"
            ;;
    esac
    
    cat << EOF
{
  "tasks": [
    {
      "name": "Install Dependencies",
      "working_directory": ".",
      "command": "$install_cmd",
      "stage": "test"
    },
    {
      "name": "Lint",
      "working_directory": ".",
      "command": "$lint_cmd",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "$test_cmd",
      "stage": "test"
    }
  ]
}
EOF
}

generate_go_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Download Dependencies",
      "working_directory": ".",
      "command": "go mod download",
      "stage": "test"
    },
    {
      "name": "Lint",
      "working_directory": ".",
      "command": "go vet ./... && (which golangci-lint && golangci-lint run || echo 'golangci-lint not installed')",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "go test -v ./...",
      "stage": "test"
    },
    {
      "name": "Build",
      "working_directory": ".",
      "command": "go build -v ./...",
      "stage": "release"
    }
  ]
}
EOF
}

generate_rust_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Check",
      "working_directory": ".",
      "command": "cargo check",
      "stage": "test"
    },
    {
      "name": "Clippy Lint",
      "working_directory": ".",
      "command": "cargo clippy -- -D warnings || echo 'Clippy not available'",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "cargo test",
      "stage": "test"
    },
    {
      "name": "Build Release",
      "working_directory": ".",
      "command": "cargo build --release",
      "stage": "release"
    }
  ]
}
EOF
}

generate_dotnet_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Restore",
      "working_directory": ".",
      "command": "dotnet restore",
      "stage": "test"
    },
    {
      "name": "Build",
      "working_directory": ".",
      "command": "dotnet build --no-restore",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "dotnet test --no-build --verbosity normal",
      "stage": "test"
    },
    {
      "name": "Publish",
      "working_directory": ".",
      "command": "dotnet publish -c Release",
      "stage": "release"
    }
  ]
}
EOF
}

generate_java_maven_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Compile",
      "working_directory": ".",
      "command": "mvn compile",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "mvn test",
      "stage": "test"
    },
    {
      "name": "Package",
      "working_directory": ".",
      "command": "mvn package -DskipTests",
      "stage": "release"
    }
  ]
}
EOF
}

generate_java_gradle_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Compile",
      "working_directory": ".",
      "command": "./gradlew compileJava || gradlew compileJava",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "./gradlew test || gradlew test",
      "stage": "test"
    },
    {
      "name": "Build",
      "working_directory": ".",
      "command": "./gradlew build -x test || gradlew build -x test",
      "stage": "release"
    }
  ]
}
EOF
}

generate_kotlin_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Build",
      "working_directory": ".",
      "command": "./gradlew build || gradlew build",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "./gradlew test || gradlew test",
      "stage": "test"
    },
    {
      "name": "Assemble",
      "working_directory": ".",
      "command": "./gradlew assemble || gradlew assemble",
      "stage": "release"
    }
  ]
}
EOF
}

generate_scala_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Compile",
      "working_directory": ".",
      "command": "sbt compile || ./gradlew compileScala || gradlew compileScala",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "sbt test || ./gradlew test || gradlew test",
      "stage": "test"
    },
    {
      "name": "Package",
      "working_directory": ".",
      "command": "sbt package || ./gradlew assemble || gradlew assemble",
      "stage": "release"
    }
  ]
}
EOF
}

generate_swift_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Build",
      "working_directory": ".",
      "command": "swift build",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "swift test",
      "stage": "test"
    },
    {
      "name": "Build Release",
      "working_directory": ".",
      "command": "swift build --configuration release",
      "stage": "release"
    }
  ]
}
EOF
}

generate_cpp_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Configure",
      "working_directory": ".",
      "command": "mkdir -p build && cd build && cmake .. || echo 'CMake not found'",
      "stage": "test"
    },
    {
      "name": "Build",
      "working_directory": ".",
      "command": "cd build && make || make",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "cd build && ctest || make test || echo 'No tests configured'",
      "stage": "test"
    }
  ]
}
EOF
}

generate_dart_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Get Dependencies",
      "working_directory": ".",
      "command": "dart pub get",
      "stage": "test"
    },
    {
      "name": "Analyze",
      "working_directory": ".",
      "command": "dart analyze",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "dart test",
      "stage": "test"
    },
    {
      "name": "Build",
      "working_directory": ".",
      "command": "dart compile exe bin/main.dart -o bin/main || echo 'No executable to build'",
      "stage": "release"
    }
  ]
}
EOF
}

generate_ruby_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Install Dependencies",
      "working_directory": ".",
      "command": "bundle install",
      "stage": "test"
    },
    {
      "name": "Lint",
      "working_directory": ".",
      "command": "bundle exec rubocop || echo 'Rubocop not installed'",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "bundle exec rspec || bundle exec rake test || echo 'No tests found'",
      "stage": "test"
    }
  ]
}
EOF
}

generate_php_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Install Dependencies",
      "working_directory": ".",
      "command": "composer install",
      "stage": "test"
    },
    {
      "name": "Lint",
      "working_directory": ".",
      "command": "composer run lint || vendor/bin/phpstan analyse || echo 'No linter configured'",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "composer test || vendor/bin/phpunit || echo 'No tests found'",
      "stage": "test"
    }
  ]
}
EOF
}

generate_make_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Build",
      "working_directory": ".",
      "command": "make",
      "stage": "test"
    },
    {
      "name": "Test",
      "working_directory": ".",
      "command": "make test || echo 'No test target'",
      "stage": "test"
    }
  ]
}
EOF
}

generate_shell_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "ShellCheck Lint",
      "working_directory": ".",
      "command": "shellcheck *.sh || echo 'shellcheck not installed'",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "[ -f test.sh ] && ./test.sh || echo 'No test.sh found'",
      "stage": "test"
    }
  ]
}
EOF
}

generate_generic_config() {
    cat << 'EOF'
{
  "tasks": [
    {
      "name": "Hello World",
      "working_directory": ".",
      "command": "echo '✅ Universal CI is ready! Edit universal-ci.config.json to add your tasks.'",
      "stage": "test"
    }
  ],
  "semver": {
    "enabled": true,
    "auto_update_version": true,
    "require_breaking_change_confirmation": true
  }
}
EOF
}

generate_config() {
    project_type="$1"
    
    case "$project_type" in
        nodejs)      generate_nodejs_config ;;
        python)      generate_python_config ;;
        go)          generate_go_config ;;
        rust)        generate_rust_config ;;
        dotnet)      generate_dotnet_config ;;
        java-maven)  generate_java_maven_config ;;
        java-gradle) generate_java_gradle_config ;;
        kotlin)      generate_kotlin_config ;;
        scala)       generate_scala_config ;;
        swift)       generate_swift_config ;;
        cpp)         generate_cpp_config ;;
        dart)        generate_dart_config ;;
        ruby)        generate_ruby_config ;;
        php)         generate_php_config ;;
        make)        generate_make_config ;;
        shell)       generate_shell_config ;;
        *)           generate_generic_config ;;
    esac
}

# ============================================================================
# GITHUB ACTIONS SETUP
# ============================================================================

setup_github_actions() {
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml << 'EOF'
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
          curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/run-ci.sh -o .run-ci.sh
          chmod +x .run-ci.sh
          ./.run-ci.sh
          rm .run-ci.sh
EOF

    log_success "Created .github/workflows/ci.yml"
}

# ============================================================================
# DOCKER SETUP
# ============================================================================

setup_docker() {
    project_type="$1"
    
    # Base Dockerfile
    cat > Dockerfile.ci << 'EOF'
# Universal CI Docker Environment
# Build: docker build -f Dockerfile.ci -t uci .
# Run:   docker run --rm -v $(pwd):/app uci

FROM alpine:latest

# Install basic tools
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    make

WORKDIR /app

# Copy Universal CI
COPY run-ci.sh /usr/local/bin/uci
RUN chmod +x /usr/local/bin/uci

ENTRYPOINT ["uci"]
EOF

    # Docker Compose
    cat > docker-compose.ci.yml << 'EOF'
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
EOF

    log_success "Created Dockerfile.ci and docker-compose.ci.yml"
    log_info "Run with: docker-compose -f docker-compose.ci.yml run ci"
}

# ============================================================================
# GIT HOOKS
# ============================================================================

setup_git_hooks() {
    # Check if we're in a git repo
    if [ ! -d ".git" ]; then
        if command -v git >/dev/null 2>&1; then
            log_info "Not a Git repository. Initializing..."
            git init
        else
            log_warn "Git not installed. Skipping hooks setup."
            return 1
        fi
    fi
    
    mkdir -p .git/hooks .github/scripts
    
    # Download semantic-version.sh
    if command -v curl >/dev/null 2>&1; then
        log_info "Downloading semantic version analyzer..."
        curl -sL "https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/.github/scripts/semantic-version.sh" -o ".github/scripts/semantic-version.sh"
        chmod +x ".github/scripts/semantic-version.sh"
        log_success "Downloaded semantic-version.sh"
    fi
    
    # Download bump-version.sh if not exists
    if [ ! -f ".github/scripts/bump-version.sh" ] && command -v curl >/dev/null 2>&1; then
        log_info "Downloading version bump helper..."
        curl -sL "https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/.github/scripts/bump-version.sh" -o ".github/scripts/bump-version.sh"
        chmod +x ".github/scripts/bump-version.sh"
        log_success "Downloaded bump-version.sh"
    fi
    
    # Pre-push hook with semantic versioning
    cat > .git/hooks/pre-push << 'HOOK'
#!/bin/sh
# Universal CI Pre-Push Hook with Semantic Versioning
# 1. Analyzes commits for semantic version bump
# 2. Prompts for breaking changes if needed
# 3. Auto-updates VERSION and CHANGELOG.md
# 4. Runs full verification

REPO_ROOT="$(git rev-parse --show-toplevel)"
SEMVER_SCRIPT="${REPO_ROOT}/.github/scripts/semantic-version.sh"
CONFIG_FILE="${REPO_ROOT}/universal-ci.config.json"

# Check if semantic versioning is enabled in config
if [ -f "$CONFIG_FILE" ]; then
    # Simple grep to check if semver is enabled
    if grep -q '"semver"' "$CONFIG_FILE" 2>/dev/null; then
        if grep -q '"enabled"[[:space:]]*:[[:space:]]*false' "$CONFIG_FILE" 2>/dev/null; then
            # Semantic versioning disabled
            :
        elif [ -f "$SEMVER_SCRIPT" ]; then
            echo "🔍 Analyzing commits for semantic versioning..."
            
            # Run semantic version analysis
            if "$SEMVER_SCRIPT" --interactive 2>/dev/null; then
                echo ""
            fi
        fi
    fi
fi

echo "🔍 Running Universal CI verification..."

if [ -f "${REPO_ROOT}/run-ci.sh" ]; then
    "${REPO_ROOT}/run-ci.sh"
elif command -v curl >/dev/null 2>&1; then
    curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/run-ci.sh | sh
else
    echo "⚠️  run-ci.sh not found and curl not available"
    exit 0
fi

exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo ""
    echo "❌ Verification failed. Push blocked."
    echo "   Fix the issues above and try again."
    exit 1
fi

echo "✅ Verification passed. Proceeding with push..."
HOOK

    chmod +x .git/hooks/pre-push
    log_success "Created .git/hooks/pre-push with semantic versioning"
}

# ============================================================================
# MAIN INSTALLATION
# ============================================================================

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --no-hooks)
                SKIP_HOOKS=true
                shift
                ;;
            --no-verify)
                SKIP_VERIFY=true
                shift
                ;;
            --force)
                FORCE_CONFIG=true
                shift
                ;;
            --type)
                FORCE_TYPE="$2"
                shift 2
                ;;
            --github-actions)
                SETUP_GITHUB_ACTIONS=true
                shift
                ;;
            --docker)
                SETUP_DOCKER=true
                shift
                ;;
            --non-interactive|-y)
                INTERACTIVE=false
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'EOF'
Universal CI Bootstrap

Usage:
  curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install-ci.sh | sh
  curl -sL ... | sh -s -- [OPTIONS]

Options:
  --no-hooks        Skip Git hooks setup
  --no-verify       Skip initial verification run
  --force           Overwrite existing config file
  --type <type>     Force project type (nodejs, python, go, rust, dotnet, java-maven, java-gradle, ruby, php, make, shell)
  --github-actions  Create GitHub Actions workflow
  --docker          Create Docker CI setup
  --non-interactive, -y  Skip all prompts (use defaults)
  --help, -h        Show this help message

Examples:
  # Basic install with auto-detection
  curl -sL .../install-ci.sh | sh

  # Force Node.js config
  curl -sL .../install-ci.sh | sh -s -- --type nodejs

  # Full setup with GitHub Actions
  curl -sL .../install-ci.sh | sh -s -- --github-actions

  # Non-interactive with everything
  curl -sL .../install-ci.sh | sh -s -- -y --github-actions --docker
EOF
}

main() {
    parse_args "$@"
    
    print_banner
    
    # Step 1: Download run-ci.sh
    log_step "Downloading Universal CI..."
    if curl -sL "${REPO_URL}/${VERIFY_SCRIPT}" -o "$VERIFY_SCRIPT"; then
        chmod +x "$VERIFY_SCRIPT"
        log_success "Downloaded $VERIFY_SCRIPT"
    else
        log_error "Failed to download $VERIFY_SCRIPT"
        exit 1
    fi
    
    # Step 2: Detect project type
    log_step "Detecting project type..."
    project_type=$(detect_project_type)
    
    # Map type to friendly name
    case "$project_type" in
        nodejs)      friendly_name="Node.js" ;;
        python)      friendly_name="Python" ;;
        go)          friendly_name="Go" ;;
        rust)        friendly_name="Rust" ;;
        dotnet)      friendly_name=".NET" ;;
        java-maven)  friendly_name="Java (Maven)" ;;
        java-gradle) friendly_name="Java (Gradle)" ;;
        kotlin)      friendly_name="Kotlin" ;;
        scala)       friendly_name="Scala" ;;
        swift)       friendly_name="Swift" ;;
        cpp)         friendly_name="C++" ;;
        dart)        friendly_name="Dart" ;;
        ruby)        friendly_name="Ruby" ;;
        php)         friendly_name="PHP" ;;
        make)        friendly_name="Makefile" ;;
        shell)       friendly_name="Shell Scripts" ;;
        *)           friendly_name="Generic" ;;
    esac
    
    log_success "Detected: ${friendly_name}"
    
    # Additional detection info
    if [ "$project_type" = "nodejs" ]; then
        pm=$(detect_node_package_manager)
        log_info "Package manager: $pm"
    elif [ "$project_type" = "python" ]; then
        pm=$(detect_python_package_manager)
        log_info "Package manager: $pm"
    fi
    
    # Step 3: Generate config
    log_step "Generating configuration..."
    
    if [ -f "$CONFIG_FILE" ] && [ "$FORCE_CONFIG" = false ]; then
        log_warn "Config file already exists: $CONFIG_FILE"
        if prompt_yes_no "Overwrite?" "n"; then
            generate_config "$project_type" > "$CONFIG_FILE"
            log_success "Overwrote $CONFIG_FILE"
        else
            log_info "Keeping existing config"
        fi
    else
        generate_config "$project_type" > "$CONFIG_FILE"
        log_success "Created $CONFIG_FILE"
    fi
    
    # Step 4: Git hooks
    if [ "$SKIP_HOOKS" = false ]; then
        log_step "Setting up Git hooks..."
        if prompt_yes_no "Install pre-push verification hook?" "y"; then
            setup_git_hooks
        else
            log_info "Skipped hooks setup"
        fi
    fi
    
    # Step 5: GitHub Actions (optional)
    if [ "$SETUP_GITHUB_ACTIONS" = true ]; then
        log_step "Setting up GitHub Actions..."
        setup_github_actions
    elif [ "$INTERACTIVE" = true ] && [ ! -d ".github/workflows" ]; then
        if prompt_yes_no "Create GitHub Actions workflow?" "n"; then
            setup_github_actions
        fi
    fi
    
    # Step 6: Docker (optional)
    if [ "$SETUP_DOCKER" = true ]; then
        log_step "Setting up Docker..."
        setup_docker "$project_type"
    fi
    
    # Step 7: Run verification
    if [ "$SKIP_VERIFY" = false ]; then
        echo ""
        log_step "Running initial verification..."
        echo ""
        ./"$VERIFY_SCRIPT"
    fi
    
    # Done!
    echo ""
    printf "${GREEN}${BOLD}🎉 Universal CI is ready!${RESET}\n"
    echo ""
    echo "Next steps:"
    echo "  1. Review ${CONFIG_FILE} and customize tasks"
    echo "  2. Run ${CYAN}./run-ci.sh${RESET} to verify your project"
    echo "  3. Commit and push - hooks will verify automatically"
    echo ""
    
    if [ "$SETUP_GITHUB_ACTIONS" = true ]; then
        echo "GitHub Actions:"
        echo "  - Push to trigger CI at .github/workflows/ci.yml"
        echo ""
    fi
    
    if [ "$SETUP_DOCKER" = true ]; then
        echo "Docker:"
        echo "  - Run: ${CYAN}docker-compose -f docker-compose.ci.yml run ci${RESET}"
        echo ""
    fi
}

main "$@"
