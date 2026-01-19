# Universal CI

> **Configuration-Driven CI/CD That Works Everywhere**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## ⚡ One-Command Setup

```bash
# macOS / Linux / WSL - Fully automated setup
curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install.sh | sh

# Windows PowerShell
irm https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install.ps1 | iex
```

**That's it.** The installer will:
1. ✅ Download the verification script
2. ✅ Auto-detect your project type (Node, Python, Go, Rust, .NET, Java, Kotlin, Scala, Swift, C++, Dart, Ruby, PHP)
3. ✅ Generate `universal-ci.config.json` with smart defaults
4. ✅ Set up Git pre-push hooks
5. ✅ Run initial verification

### Advanced Install Options

```bash
# Skip prompts (fully automatic)
curl -sL .../install.sh | sh -s -- -y

# Include GitHub Actions workflow
curl -sL .../install.sh | sh -s -- --github-actions

# Include Docker setup for isolated runs
curl -sL .../install.sh | sh -s -- --docker

# Force a specific project type
curl -sL .../install.sh | sh -s -- --type nodejs

# Full setup (everything)
curl -sL .../install.sh | sh -s -- -y --github-actions --docker
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
./verify.sh
```

---

## 📦 Installation Methods

### One-Command Bootstrap (Recommended)
```bash
# macOS / Linux / WSL
curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install.sh | sh

# Windows PowerShell
irm https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/install.ps1 | iex
```

### Manual Download
```bash
# macOS / Linux
curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/verify.sh -o verify.sh && chmod +x verify.sh

# Windows (PowerShell)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/verify.ps1" -OutFile "verify.ps1"
```

### Clone Repository
```bash
git clone https://github.com/orchestrate-solutions/universal-ci.git
cd universal-ci
./verify.sh  # or .\verify.ps1 on Windows
```

### Already have the script? Just init:
```bash
./verify.sh --init          # Creates config for current project
./verify.sh --init --type go  # Force specific project type
```

## 🚀 Quick Start

### 1. Run the Installer
The one-liner above handles everything automatically. Or if you want to start manually:

### 2. Run Locally
```bash
# macOS / Linux
./verify.sh

# Windows
.\verify.ps1
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
          curl -sL https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/verify.sh -o verify.sh
          chmod +x verify.sh
          ./verify.sh
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

### Task Properties
| Property | Required | Default | Description |
|----------|----------|---------|-------------|
| `name` | ✅ | - | Human-readable task identifier |
| `working_directory` | ✅ | - | Directory to execute command from |
| `command` | ✅ | - | Shell command to run |
| `stage` | ❌ | `"test"` | `"test"` or `"release"` |

---

## 🔧 CLI Options

```bash
# macOS / Linux
./verify.sh [OPTIONS]

# Windows  
.\verify.ps1 [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--init` | Initialize config for current project (auto-detect type) |
| `--config <path>` | Path to config file (default: `universal-ci.config.json`) |
| `--stage <stage>` | Stage to run: `test` or `release` (default: `test`) |
| `--type <type>` | Force project type for `--init` |
| `--help` | Show help message |

### Examples
```bash
# Initialize a new project
./verify.sh --init

# Run with default config
./verify.sh

# Run specific config
./verify.sh --config my-project.json

# Run release tasks
./verify.sh --stage release

# Windows equivalent
.\verify.ps1 -Config my-project.json -Stage release
```

---

## 📁 Available Scripts

| Script | Platform | Dependencies |
|--------|----------|--------------|
| `install.sh` | macOS, Linux, WSL | POSIX shell + curl |
| `install.ps1` | Windows | PowerShell 5.1+ |
| `verify.sh` | macOS, Linux, WSL | POSIX shell (sh/bash) |
| `verify.ps1` | Windows, macOS*, Linux* | PowerShell 5.1+ |
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
./verify.sh || exit 1
EOF

chmod +x .git/hooks/pre-push
```

---

## 🐳 Docker Support

Run verification in an isolated container:

```bash
# Use the installer to set up Docker
curl -sL .../install.sh | sh -s -- --docker

# Then run with Docker Compose
docker-compose -f docker-compose.ci.yml run ci
```

The Docker setup creates:
- `Dockerfile.ci`: Alpine-based container with basic tools
- `docker-compose.ci.yml`: Compose file for easy execution

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
4. Ensure all tests pass: `./verify.sh`
5. Submit a pull request

## 📄 License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

---

**Universal CI: Because CI/CD should be as simple as writing a config file.** 🚀
