# Changelog

All notable changes to Universal CI are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-19

### Added
- Initial release of Universal CI
- Configuration-driven CI/CD tool with zero dependencies
- Support for 16+ programming languages
- Caching with hash-based keys

## [1.2.2] - 2026-01-19

### Added
- 

### Changed
- 

### Fixed
- 


## [1.2.1] - 2026-01-19

### Added
- 

### Changed
- 

### Fixed
- 


## [1.2.0] - 2026-01-19

### Added
- 

### Changed
- 

### Fixed
- 


## [1.1.0] - 2026-01-19

### Added
- 

### Changed
- 

### Fixed
- 

- Conditional task execution with boolean logic
- Interactive mode for AI-first automation
- Multi-stage task execution (test/release)
- Version testing with matrix strategy
- GitHub Actions, shell, and PowerShell implementations
- npm package distribution
- Automatic npm publishing workflow
- Git pre-push hook integration
- Docker support

### Features
- Pure shell script implementation (macOS, Linux, WSL)
- PowerShell implementation (Windows)
- JSON-based configuration
- No external dependencies
- Cross-platform compatibility
- Task approval workflow
- Cache invalidation on file changes

---

## Release Guide

To release a new version:

```bash
# 1. Update VERSION file
echo "1.0.1" > VERSION

# 2. Run version bump script (auto-updates CHANGELOG)
.github/scripts/bump-version.sh

# 3. Review changes
git diff

# 4. Commit and push
git add VERSION CHANGELOG.md package.json
git commit -m "release: v1.0.1"
git push origin main
```

The GitHub Actions workflow will automatically:
- Read VERSION file
- Publish to npm
- Create GitHub release with changelog entry
- Tag the commit
