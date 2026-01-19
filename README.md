# Universal CI

> **Configuration-Driven CI/CD That Works Everywhere**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## ⚡ One-Command Setup

```bash
# macOS / Linux / WSL - Fully automated setup
curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install-ci.sh | sh

# Windows PowerShell
irm https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install-ci.ps1 | iex
```

**That's it.** The installer will:
1. ✅ Download the CI runner script
2. ✅ Auto-detect your project type (Node, Python, Go, Rust, .NET, Java, Kotlin, Scala, Swift, C++, Dart, Ruby, PHP)
3. ✅ Generate `universal-ci.config.json` with smart defaults
4. ✅ Set up Git pre-push hooks
5. ✅ Run initial CI verification

### Advanced Install Options

```bash
# Skip prompts (fully automatic)
curl -sL .../install-ci.sh | sh -s -- -y

# Include GitHub Actions workflow
curl -sL .../install-ci.sh | sh -s -- --github-actions

# Include Docker setup for isolated runs
curl -sL .../install-ci.sh | sh -s -- --docker

# Force a specific project type
curl -sL .../install-ci.sh | sh -s -- --type nodejs

# Full setup (everything)
curl -sL .../install-ci.sh | sh -s -- -y --github-actions --docker
```

---

## 🚀 Getting Started

### What is Universal CI?

Universal CI is a lightweight, configuration-driven CI/CD tool that runs the same way locally and in the cloud. Define your build, test, and deployment tasks in simple JSON configuration files, then execute them consistently across environments.

**Zero dependencies.** Works on any system with a shell (macOS, Linux) or PowerShell (Windows).

### Why Universal CI?

- **🪶 Zero Dependencies**: Pure shell script - no Python, Node, or runtime required
- **🔧 Config-Driven**: Define tasks in `universal-ci.config.json` - no complex YAML
- **🏠 Local First**: Test your CI locally before pushing
- **📦 Multi-Stage**: Separate `test` and `release` stage configurations
- **🌍 Cross-Platform**: Shell script for macOS/Linux, PowerShell for Windows
- **🎯 Task-Based**: Each task specifies its working directory and command
- **🔍 Smart Detection**: Auto-detects 16+ programming languages (Node, Python, Go, Rust, .NET, Java, Kotlin, Scala, Swift, C++, Dart, Ruby, PHP, and more)

### Supported Project Types

The installer automatically detects and configures:

| Language | Files Detected | Package Manager | Tasks Generated |
|----------|----------------|-----------------|-----------------|
| **Node.js** | `package.json` | npm, pnpm, yarn, bun | install, test, lint, build |
| **Python** | `pyproject.toml`, `requirements.txt` | pip, poetry, pipenv, uv | install, lint, test |
| **Go** | `go.mod` | go modules | download, vet, test, build |
| **Rust** | `Cargo.toml` | cargo | check, clippy, test, build |
| **.NET** | `*.csproj`, `*.fsproj` | dotnet | restore, build, test |
| **Java (Maven)** | `pom.xml` | maven | compile, test, package |
| **Java (Gradle)** | `build.gradle*` | gradle | compile, test, build |
| **Kotlin** | `build.gradle.kts`, `src/main/kotlin` | gradle | build, test, assemble |
| **Scala** | `build.sbt`, `src/main/scala` | sbt/gradle | compile, test, package |
| **Swift** | `Package.swift`, `Sources/` | swiftpm | build, test, release |
| **C++** | `CMakeLists.txt`, `*.cpp` | cmake/make | configure, build, test |
| **Dart** | `pubspec.yaml`, `*.dart` | pub | get, analyze, test, build |
| **Ruby** | `Gemfile` | bundler | install, rubocop, test |
| **PHP** | `composer.json` | composer | install, phpstan, test |
| **Makefile** | `Makefile` | make | build, test |
| **Generic** | - | - | Hello World example |

### Quick Example

After running the installer, you'll have a `universal-ci.config.json` like this:

```json
{
  "tasks": [
    {
      "name": "Install Dependencies",
      "working_directory": ".",
      "command": "npm ci",
      "stage": "test"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "npm test",
      "stage": "test"
    },
    {
      "name": "Lint",
      "working_directory": ".",
      "command": "npm run lint",
      "stage": "test"
    },
    {
      "name": "Build",
      "working_directory": ".",
      "command": "npm run build",
      "stage": "release"
    }
  ]
}
```

Run it locally:
```bash
./run-ci.sh
```

---

## 📦 Installation Methods

### npm (Recommended for Node Projects)
```bash
# Install as dev dependency
npm install --save-dev @orchestrate-solutions/universal-ci

# Initialize config with auto-detection
npx @orchestrate-solutions/universal-ci init

# Run CI
npx @orchestrate-solutions/universal-ci
# or use npm script
npm run ci
```

### One-Command Bootstrap (Shell/curl)
```bash
# macOS / Linux / WSL
curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install-ci.sh | sh

# Windows PowerShell
irm https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install-ci.ps1 | iex
```

### Manual Download
```bash
# macOS / Linux
curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/run-ci.sh -o run-ci.sh && chmod +x run-ci.sh

# Windows (PowerShell)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/run-ci.ps1" -OutFile "run-ci.ps1"
```

### Clone Repository
```bash
git clone https://github.com/orchestrate-solutions/universal-ci.git
cd universal-ci
./run-ci.sh  # or .\run-ci.ps1 on Windows
```

### Already have the script? Just init:
```bash
./run-ci.sh --init          # Creates config for current project
./run-ci.sh --init --type go  # Force specific project type
```

## 🚀 Quick Start

### 1. Run the Installer
The one-liner above handles everything automatically. Or if you want to start manually:

### 2. Run Locally
```bash
# macOS / Linux
./run-ci.sh

# Windows
.\run-ci.ps1
```

### 3. GitHub Actions Integration
```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Universal CI
        run: |
          curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/run-ci.sh -o run-ci.sh
          chmod +x run-ci.sh
          ./run-ci.sh
```

### 4. Customize Configuration
Edit `universal-ci.config.json` to add your own tasks:

```json
{
  "tasks": [
    {
      "name": "Install Dependencies",
      "working_directory": ".",
      "command": "npm install"
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "npm test"
    },
    {
      "name": "Build",
      "working_directory": ".",
      "command": "npm run build"
    }
  ]
}
```

---

## 📋 Configuration Schema

### Basic Task
```json
{
  "name": "Task Name",
  "working_directory": ".",
  "command": "echo 'Hello World'"
}
```

### Multi-Stage Tasks
```json
{
  "tasks": [
    {
      "name": "Unit Tests",
      "working_directory": ".",
      "command": "npm test",
      "stage": "test"
    },
    {
      "name": "Deploy to Production",
      "working_directory": ".",
      "command": "npm run deploy",
      "stage": "release"
    }
  ]
}
```

### Version Testing (Matrix Strategy)
Test across multiple versions without duplicating tasks:

```json
{
  "tasks": [
    {
      "name": "Test on Python {version}",
      "working_directory": ".",
      "command": "python{version} -m pytest",
      "stage": "test",
      "versions": ["3.9", "3.10", "3.11", "3.12", "3.13"]
    },
    {
      "name": "Test on Node {version}",
      "working_directory": ".",
      "command": "node{version} --version && npm test",
      "stage": "test",
      "versions": ["16", "18", "20", "22"]
    }
  ]
}
```

When `versions` is specified, Universal CI automatically creates separate tasks for each version, replacing `{version}` with the actual value. This is equivalent to GitHub Actions' matrix strategy but in your config file.

### Task Properties
| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| `name` | ✅ | - | Human-readable task identifier (can include `{version}` placeholder) |
| `working_directory` | ✅ | - | Directory to execute command from |
| `command` | ✅ | - | Shell command to run (can include `{version}` placeholder) |
| `stage` | ❌ | `"test"` | `"test"` or `"release"` |
| `versions` | ❌ | - | Array of versions to test (e.g., `["3.9", "3.10", "3.11"]`) |
| `cache` | ❌ | - | Cache configuration with `key` and `paths` |
| `if` | ❌ | - | Conditional expression (skip if false) |
| `requires_approval` | ❌ | `false` | Require explicit approval to run task |

---

## 🚀 Advanced Features

### Caching (Performance Optimization)

Skip expensive tasks using hash-based caching:

```json
{
  "tasks": [
    {
      "name": "Install Dependencies",
      "working_directory": ".",
      "command": "npm install",
      "cache": {
        "key": "npm-${{ hashFiles('package-lock.json') }}",
        "paths": ["node_modules"]
      }
    },
    {
      "name": "Run Tests",
      "working_directory": ".",
      "command": "npm test"
    }
  ]
}
```

**How it works:**
- `${{ hashFiles('file1', 'file2') }}` computes MD5/SHA256 hash of files
- Cache key is used to create `.universal-ci-cache/{key}/` directory
- If cache exists, task is skipped (files already installed/built)
- After successful task, cache is written for next run
- Hash changes automatically invalidate old cache

### Conditional Task Execution

Run tasks only when specific conditions are met:

```json
{
  "tasks": [
    {
      "name": "Test Locally",
      "working_directory": ".",
      "command": "npm test",
      "if": "env.CI == '' || env.CI == 'false'"
    },
    {
      "name": "Build Release",
      "working_directory": ".",
      "command": "npm run build --production",
      "stage": "release",
      "if": "${{ github.ref }} == 'refs/heads/main' && env.PRODUCTION == 'true'"
    },
    {
      "name": "Deploy if Flag Exists",
      "working_directory": ".",
      "command": "npm run deploy",
      "if": "file(.deploy-flag)"
    },
    {
      "name": "Mac-Only Task",
      "working_directory": ".",
      "command": "xcode-select --install",
      "if": "os(macos)"
    }
  ]
}
```

**Condition Syntax:**
- **Environment variables:** `env.VAR_NAME` (e.g., `env.CI`, `env.DEPLOY`)
- **File existence:** `file(path)` (e.g., `file(.deploy-flag)`)
- **Operating system:** `os(linux)`, `os(macos)`, `os(windows)`
- **Git branch:** `branch(main)` (e.g., `branch(main)`)
- **GitHub context:** `${{ github.ref }}` (when running in GitHub Actions)
- **Boolean logic:** `&&` (and), `||` (or), parentheses for grouping
- **String comparison:** `==`, `!=` operators

Tasks with unmet conditions are skipped with transparency logging.

### Interactive Mode (AI-First Automation)

List tasks as JSON and run only selected ones - perfect for AI automation:

```bash
# List all tasks as JSON (AI reads and decides which to run)
./run-ci.sh --list-tasks

# Output:
# {"tasks":[{"name":"Build","directory":".","command":"npm run build"},{"name":"Test","directory":".","command":"npm test"},...]}

# Run only specific tasks (AI selects via JSON array)
./run-ci.sh --select-tasks '["Build","Test"]'

# Approve tasks requiring approval
./run-ci.sh --stage release --approve-task "Deploy to Production"

# Skip tasks without running them
./run-ci.sh --skip-task "Slow Integration Tests"
```

**Interactive CLI Commands:**
- `--interactive` - Enable interactive mode
- `--list-tasks` - Output all parsed tasks as JSON (for AI to read)
- `--select-tasks '["task1","task2"]'` - Run only named tasks
- `--approve-task "name"` - Approve task requiring approval (repeatable)
- `--skip-task "name"` - Skip task by name (repeatable)

**Example: AI-Driven Workflow**
```bash
# AI gets list of available tasks
tasks=$(./run-ci.sh --list-tasks | jq .tasks)

# AI analyzes and decides which tasks to run
# AI constructs JSON selection based on logic

# AI executes only the selected tasks
./run-ci.sh --select-tasks '["Lint","Test","Build"]'

# If deploy task requires approval, AI requests it
if ./run-ci.sh --stage release --list-tasks | jq '.tasks[] | select(.requires_approval == true)'; then
  ./run-ci.sh --stage release --approve-task "Deploy" --approve-task "Notify"
fi
```

---

## 🔧 CLI Options

```bash
# macOS / Linux
./run-ci.sh [OPTIONS]

# Windows  
.\run-ci.ps1 [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--init` | Initialize config for current project (auto-detect type) |
| `--config <path>` | Path to config file (default: `universal-ci.config.json`) |
| `--stage <stage>` | Stage to run: `test` or `release` (default: `test`) |
| `--type <type>` | Force project type for `--init` |
| `--interactive` | Interactive mode (for AI automation) |
| `--list-tasks` | Output all tasks as JSON (use with --interactive) |
| `--select-tasks <json>` | Run only specified tasks (e.g., `'["task1","task2"]'`) |
| `--approve-task <name>` | Approve task requiring approval (repeatable) |
| `--skip-task <name>` | Skip task by name (repeatable) |
| `--help` | Show help message |

### Examples
```bash
# Initialize a new project
./run-ci.sh --init

# Run with default config
./run-ci.sh

# Run specific config
./run-ci.sh --config my-project.json

# Run release tasks
./run-ci.sh --stage release

# Windows equivalent
.\run-ci.ps1 -Config my-project.json -Stage release
```

---

## 📁 Available Scripts

| Script | Platform | Dependencies |
|--------|----------|--------------|
| `install-ci.sh` | macOS, Linux, WSL | POSIX shell + curl |
| `install-ci.ps1` | Windows | PowerShell 5.1+ |
| `run-ci.sh` | macOS, Linux, WSL | POSIX shell (sh/bash) |
| `run-ci.ps1` | Windows, macOS*, Linux* | PowerShell 5.1+ |
| `universal-ci-testing-env/verify.py` | Any | Python 3.8+ |

*PowerShell Core required on macOS/Linux

---

## 🎬 Local Testing with Git Hooks

The installer sets this up automatically, but you can also do it manually:

```bash
# Create hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/sh
echo "🔍 Running Universal CI verification..."
./run-ci.sh || exit 1
EOF

chmod +x .git/hooks/pre-push
```

---

## 🐳 Docker Support

Run verification in an isolated container:

```bash
# Use the installer to set up Docker
curl -sL .../install-ci.sh | sh -s -- --docker

# Then run with Docker Compose
docker-compose -f docker-compose.ci.yml run ci
```

The Docker setup creates:
- `Dockerfile.ci`: Alpine-based container with basic tools
- `docker-compose.ci.yml`: Compose file for easy execution

---

## 🎯 Semantic Versioning (Auto Version Bumping)

Universal CI automatically analyzes your git history and determines version bumps - **no manual version management needed.**

### How It Works

1. **Before each push**, git pre-push hook runs semantic analyzer
2. **Analyzes commits** using conventional commit format (feat:, fix:, BREAKING:)
3. **Detects version bump type:**
   - `feat:` → **minor** version bump (new features)
   - `fix:` → **patch** version bump (bug fixes)
   - `BREAKING CHANGE:` → **major** version bump (breaking changes)
4. **Prompts for breaking changes** if needed (forces user/AI response)
5. **Auto-updates VERSION, CHANGELOG.md, package.json**
6. **Stages files** for push
7. **Push proceeds** with versioning already done

### Conventional Commits Format

Write commit messages following this pattern. [See full Commit Standard documentation](docs/COMMIT_STANDARD.md).

```bash
# New feature (triggers minor bump)
git commit -m "feat: Add user authentication system"

# Bug fix (triggers patch bump)
git commit -m "fix: Resolve infinite loop in data processor"

# Breaking change (triggers major bump)
git commit -m "feat!: Redesign API response format

This is a breaking change - all clients must update their parsers.

BREAKING CHANGE: Response format changed from array to object"

# Or simplified breaking change
git commit -m "BREAKING CHANGE: Removed deprecated login endpoint"
```

### Interactive Breaking Change Prompt

When commits suggest version bumps, you'll be prompted:

```
ℹ Analyzing commits for semantic versioning...

✓ Found: 2 features, 1 fixes, 0 breaking changes
✓ Suggested version bump: minor

🔍 Detecting breaking changes...

Has any breaking change been made to the API, CLI, or configuration?
  • API changes that aren't backward compatible
  • CLI flag/argument removal or significant changes
  • Configuration format changes
  • Database schema changes

Has breaking change? [yes/no]:
```

**The push won't proceed** until you respond. This ensures you never forget to document breaking changes.

### Configuration

Control semantic versioning in `universal-ci.config.json`:

```json
{
  "tasks": [...],
  "semver": {
    "enabled": true,
    "auto_update_version": true,
    "require_breaking_change_confirmation": true
  }
}
```

- **`enabled`** - Enable/disable semantic versioning (default: `true`)
- **`auto_update_version`** - Automatically update VERSION file (default: `true`)
- **`require_breaking_change_confirmation`** - Force breaking change prompt (default: `true`)

### Disable Semantic Versioning

To disable automatic version bumping:

```json
{
  "semver": {
    "enabled": false
  }
}
```

The pre-push hook will skip semantic versioning but still run verification.

### AI-Friendly JSON Output

For agents/CI systems, get JSON output:

```bash
./.github/scripts/semantic-version.sh --analyze
```

Output:
```json
{
  "bump_type": "minor",
  "changes": {
    "breaking": 0,
    "features": 2,
    "fixes": 1
  },
  "commits": [
    "feat: Add user authentication",
    "feat: Add two-factor auth",
    "fix: Resolve login timeout"
  ],
  "requires_input": false,
  "breaking_change_response": ""
}
```

### What Gets Updated Automatically

When semantic versioning runs, it updates:

1. **VERSION** file - Contains current version (e.g., `1.0.0`)
2. **CHANGELOG.md** - Adds new dated release section with commit list
3. **package.json** - `version` field synced automatically
4. **Git staging area** - All updated files staged for push

Nothing needs manual editing - the system decides everything.

### Example: Complete Release Flow

```bash
# 1. Make changes and commits (using conventional format)
git add .
git commit -m "feat: Add dark mode theme"
git commit -m "fix: Resolve color contrast issues"

# 2. Push triggers semantic versioning
git push origin main

# 3. Pre-push hook runs:
# ✓ Analyzes commits → Detects minor version bump
# ✓ Updates VERSION: 1.0.0 → 1.1.0
# ✓ Updates CHANGELOG.md with new section
# ✓ Updates package.json version field
# ✓ Stages VERSION, CHANGELOG.md, package.json
# ✓ Runs full CI verification
# ✓ Push completes

# 4. GitHub Actions publishes to npm automatically
# ✓ Detects VERSION change
# ✓ Publishes to npm as v1.1.0
# ✓ Creates GitHub release with changelog
# ✓ Tags commit as v1.1.0
```

### Works for Monorepos

In monorepos, place semantic versioning at your workspace root or per package:

```
monorepo/
├── VERSION              # Workspace version (optional)
├── CHANGELOG.md         # Shared changelog
├── package-a/
│   ├── VERSION          # Package-specific version
│   ├── CHANGELOG.md
│   └── package.json
└── package-b/
    ├── VERSION
    ├── CHANGELOG.md
    └── package.json
```

Each VERSION file is independent - changes to one don't affect others.

---

## 📦 Publishing to npm

### Version Files

- **VERSION** - Single source of truth (e.g., `1.0.1`)
- **CHANGELOG.md** - Dated release notes
- **package.json** - Automatically synced with VERSION

### Release Workflow

```bash
# 1. Bump version (auto-updates package.json and CHANGELOG.md)
.github/scripts/bump-version.sh patch    # or minor, major

# 2. Edit CHANGELOG.md to describe changes
vim CHANGELOG.md
# Add details under the new version section

# 3. Commit and push
git add VERSION CHANGELOG.md package.json
git commit -m "release: v1.0.1"
git push origin main
```

### Automatic Publishing

When you push to main with VERSION file change:

1. **Workflow detects** VERSION file update
2. **Publishes to npm** with new version
3. **Creates GitHub release** with changelog
4. **Tags commit** with version number
5. **Updates package.json** automatically

### Setup (One-time)

1. Generate npm access token at https://npmjs.com/settings/tokens
2. Add to GitHub: Settings → Secrets and variables → `NPM_TOKEN`
3. That's it!

### Works for Any Project

Whether you have:
- **Single repo:** VERSION is the app version
- **Monorepo:** Keep VERSION at workspace root (or create per-package)
- **Multiple projects:** Each can have its own VERSION file

### Example Release

```bash
$ .github/scripts/bump-version.sh minor
Current version: 1.0.0
New version: 1.1.0

✅ Version bumped: 1.0.0 → 1.1.0

Next steps:
  1. Edit CHANGELOG.md to describe changes
  2. git add VERSION CHANGELOG.md package.json
  3. git commit -m "release: v1.1.0"
  4. git push origin main

# After push:
# ✅ npm publishes v1.1.0
# ✅ GitHub creates release
# ✅ Commit tagged as v1.1.0
```

---

## 📦 Publishing to npm (Legacy)

Universal CI automatically publishes to npm when changes are pushed to main.

### Setup (One-time)

1. Create an npm account at https://npmjs.com
2. Generate an access token (with publish permission)
3. Add it to GitHub: Repository Settings → Secrets and variables → New repository secret
   - **Name:** `NPM_TOKEN`
   - **Value:** Your npm access token

### Publishing Flow

Every push to `main` that modifies `package.json` triggers automatic publishing:

1. **Manual version bump** in `package.json`:
   ```bash
   npm version patch  # or minor, major
   git push origin main
   ```

2. **Automatic workflow:**
   - Detects version change in package.json
   - Publishes to npm with provenance
   - Creates GitHub release
   - Tags commit with version

### Version Strategy

Edit `package.json` to increment the version:
```json
{
  "version": "1.0.1"  // Change this, push to main
}
```

The workflow automatically publishes and creates GitHub releases at:
- https://www.npmjs.com/package/@orchestrate-solutions/universal-ci
- https://github.com/orchestrate-solutions/universal-ci/releases

---

## 🌟 Philosophy

**Simple, Predictable, Everywhere**

- **No Magic**: Tasks are just shell commands with working directories
- **No Dependencies**: Works with any language, framework, or tooling
- **No Lock-in**: Use it locally, in GitHub Actions, or anywhere else
- **No Complexity**: JSON configuration that anyone can understand

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `./run-ci.sh`
5. Submit a pull request

## 📄 License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

---

**Universal CI: Because CI/CD should be as simple as writing a config file.** 🚀
