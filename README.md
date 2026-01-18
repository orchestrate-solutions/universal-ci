# Universal CI

> **Configuration-Driven CI/CD That Works Everywhere**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Universal CI is a lightweight, configuration-driven CI/CD tool that runs the same way locally and in the cloud. Define your build, test, and deployment tasks in simple JSON configuration files, then execute them consistently across environments.

## ✨ Features

- **🔧 Config-Driven**: Define tasks in `universal-ci.config.json` - no complex YAML or scripting required
- **🏠 Local First**: Test your CI locally before pushing (works with `act` for GitHub Actions simulation)
- **📦 Multi-Stage**: Separate `test` and `release` stage configurations
- **🔄 Environment Agnostic**: Runs identically in local shell, GitHub Actions, or any CI platform
- **🚀 Zero Dependencies**: Pure Python with minimal external requirements
- **🎯 Task-Based**: Each task specifies its working directory and command independently

## 📦 Installation

### Option 1: Clone and Run
```bash
git clone https://github.com/orchestrate-solutions/universal-ci.git
cd universal-ci/universal-ci-testing-env
python3 verify.py
```

### Option 2: Direct Download
```bash
# Download verify.py and run it directly
curl -O https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/universal-ci-testing-env/verify.py
python3 verify.py
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
# From your project root
python3 /path/to/verify.py

# Or if verify.py is in your project
python3 verify.py
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
          curl -O https://raw.githubusercontent.com/orchestrate-solutions/universal-ci/main/universal-ci-testing-env/verify.py
          python3 verify.py
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
- **`name`** (required): Human-readable task identifier
- **`working_directory`** (required): Directory to execute command from (relative to config file)
- **`command`** (required): Shell command to run
- **`stage`** (optional): `"test"` or `"release"` (defaults to `"test"`)

## 🎬 Local Testing with `act`

Test your GitHub Actions workflows locally using `act`:

```bash
# Install act (macOS)
brew install act

# Run from project root
./universal-ci-testing-env/run-local-ci.sh
```

This ensures your local tests match exactly what runs in GitHub Actions.

## 📁 Project Structure

```
your-project/
├── universal-ci.config.json    # Your CI configuration
├── verify.py                   # (Optional) Local copy of verifier
└── ...your code...
```

## 🧪 Testing Universal CI

The tool comes with its own comprehensive test suite:

```bash
cd universal-ci-testing-env
pip3 install -r tests/requirements.txt
python3 -m pytest tests/ -v
```

## 🔧 Advanced Usage

### Custom Config Path
```bash
python3 verify.py --config path/to/my-config.json
```

### Run Specific Stage
```bash
# Run only test tasks
python3 verify.py --stage test

# Run only release tasks
python3 verify.py --stage release
```

### Config Resolution
Universal CI automatically finds your config file by checking:
1. Specified path (`--config` flag)
2. Current directory
3. Parent directories (up to 3 levels)
4. Git repository root

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
4. Ensure all tests pass: `python3 -m pytest tests/ -v`
5. Submit a pull request

## 📄 License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

---

**Universal CI: Because CI/CD should be as simple as writing a config file.** 🚀
