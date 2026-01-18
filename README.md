# Universal CI

> **Configuration-Driven CI/CD That Works Everywhere**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Universal CI is a lightweight, configuration-driven CI/CD tool that runs the same way locally and in the cloud. Define your build, test, and deployment tasks in simple JSON configuration files, then execute them consistently across environments.

**Zero dependencies.** Works on any system with a shell (macOS, Linux) or PowerShell (Windows).

## ✨ Features

- **🪶 Zero Dependencies**: Pure shell script - no Python, Node, or runtime required
- **🔧 Config-Driven**: Define tasks in `universal-ci.config.json` - no complex YAML
- **🏠 Local First**: Test your CI locally before pushing
- **📦 Multi-Stage**: Separate `test` and `release` stage configurations
- **🌍 Cross-Platform**: Shell script for macOS/Linux, PowerShell for Windows
- **🎯 Task-Based**: Each task specifies its working directory and command

## 📦 Installation

### Quick Start (One-liner)
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

## 🚀 Quick Start

### 1. Create Configuration
Create `universal-ci.config.json` in your project root:

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

## 🔧 CLI Options

```bash
# macOS / Linux
./verify.sh [OPTIONS]

# Windows  
.\verify.ps1 [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--config <path>` | Path to config file (default: `universal-ci.config.json`) |
| `--stage <stage>` | Stage to run: `test` or `release` (default: `test`) |
| `--help` | Show help message |

### Examples
```bash
# Run with default config
./verify.sh

# Run specific config
./verify.sh --config my-project.json

# Run release tasks
./verify.sh --stage release

# Windows equivalent
.\verify.ps1 -Config my-project.json -Stage release
```

## 📁 Available Scripts

| Script | Platform | Dependencies |
|--------|----------|--------------|
| `verify.sh` | macOS, Linux, WSL | POSIX shell (sh/bash) |
| `verify.ps1` | Windows, macOS*, Linux* | PowerShell 5.1+ |
| `universal-ci-testing-env/verify.py` | Any | Python 3.8+ |

*PowerShell Core required on macOS/Linux

## 🎬 Local Testing with Git Hooks

Add a pre-push hook to verify before every push:

```bash
# Create hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/sh
echo "🔍 Running Universal CI verification..."
./verify.sh || exit 1
EOF

chmod +x .git/hooks/pre-push
```

## 🌟 Philosophy

**Simple, Predictable, Everywhere**

- **No Magic**: Tasks are just shell commands with working directories
- **No Dependencies**: Works with any language, framework, or tooling
- **No Lock-in**: Use it locally, in GitHub Actions, or anywhere else
- **No Complexity**: JSON configuration that anyone can understand

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
