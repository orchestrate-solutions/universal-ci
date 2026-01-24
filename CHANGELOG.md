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

## [1.4.1] - 2026-01-24

### Added
- Auto-populate CHANGELOG from git commits and enable CI on releases
- Enhance CI summary output and fix test visibility
- Implement auto-push capability in pre-push hook to handle automated version bumps gracefully
- Add automatic semantic versioning with breaking change detection
- Add unified versioning and changelog system
- Add automatic npm publishing workflow
- Add npm package support with npx initialization
- Add caching, conditional tasks, and interactive mode
- Add versions field support for matrix-style testing
- Add comprehensive git hooks blocking test suite
- add initial CI agents documentation and Visual Studio solution file
- complete comprehensive testing support for all 16 languages
- add Dart language support with pub package manager
- add C++ language support with CMake/Make integration
- add Swift language support with Swift Package Manager
- add Scala language support with sbt/Gradle integration
- add Kotlin language support with Gradle integration
- one-command bootstrap for any platform
- Add lightweight shell/PowerShell scripts - zero dependencies
- Add comprehensive CI setup with pre-push hooks
- Add comprehensive test suite
- Add Release Stage support
- Add reusable workflow for remote consumption
- Establish I-prefixed types as recommended pattern (#26)
- Implement clean URL routing for docs site (#22)
- Add clean URL router for docs site (#21)
- Add comprehensive README with architecture, core concepts, and language implementations
- Enhance pseudocode documentation with conceptual storytelling (#18)
- Complete Rust typing implementation and v1.0.0 release (#17)
- update Go release README and add publish workflow
- standardize cheat sheets and add ASCII diagrams
- Complete v1.0.0 release with all package versions and documentation updates
- Add Go workspace file for proper submodule handling
- Update Go module path for cleaner publishing
- Bump Python package to v1.0.0 with type hints support
- Bump JavaScript package to v1.0.0 with TypeScript support
- type saftey for go lang #7
- Enhance pseudocode documentation with conceptual storytelling (#6)
- Implement comprehensive JavaScript typed features
- Complete Python typed features implementation
- Complete C# typed features implementation with 100% test coverage

### Changed
- Clarify dual verification behavior in AGENTS.md
- release: v1.2.4 - Fix shell pipe parsing in run-ci.sh
- Add COMMIT_STANDARD.md to explain semantic versioning rules
- Add semantic versioning guide for agents
- Enable semantic versioning dogfooding in config
- rename scripts from verify/install to run-ci/install-ci
- update README with all 5 new languages (Kotlin, Scala, Swift, C++, Dart)
- add Apache 2.0 license for Orchestrate LLC 2026
- comprehensive README update
- Update README to reflect Universal CI branding and features
- Improve verify.py config path resolution and add integration tests
- Add Complete COBOL Implementation (#1)
- Remove 'agape' references from implementation codebases (#29)
- Release v1.1.1: Package cleanup and release assets (#27)
- Add comprehensive JSDoc documentation to TypeScript definition files (#24)
- Fix Context types: Use Record<string, any> as default for better key-value structure (#25)
- Clean URL Router Implementation (#23)
- Site + buf-json demo (#20)
- Update README with website link, add CNAME for custom domain, and clean up files
- Create CNAME
- Delete CNAME
- Create CNAME
- Merge remote-tracking branch 'origin/main'
- Merge pull request #16 from codeuchain/chore/github-config
- Merge branch 'main' into chore/github-config
- add issue/PR templates and labels.yml
- preserve release scripts and C++ README (#15)
- remove unpacked release directories, keep compressed archives
- add script to upload assets to per-language tags
- add helper and workflow to upload release assets to GitHub Releases
- Remove redundant cpp-package directory and update workflow to use releases/ (#13)
- recreate per-language minimal release archives and harden packaging script (exclude build artifacts) (#14)
- recreate per-language minimal release archives and harden packaging script (exclude build artifacts)
- Add release-only C++ package (v1.0.0) and prebuilt archives
- Add generated C++ standalone package artifacts for testing (ignored in final release)
- Add C++ standalone package workflow and documentation
- Add C++ Implementation (#2)
- Merge pull request #11 from codeuchain/publish/csharp-v1.0.0
- Publish C# CodeUChain v1.0.0 to NuGet
- Update all READMEs with proper installation instructions near the top
- Merge pull request #10 from codeuchain/feat/stylish-github-pages
- Merge main into feat/stylish-github-pages - resolve documentation conflicts
- revert: Revert Go module path to original for submodule publishing
- ✨ Redesign GitHub Pages with Tailwind CSS (#9)
- ✨ Redesign GitHub Pages with Tailwind CSS
- Add llm.txt and llm-full.txt files for all language packages
- Remove npm package config from pseudocode - it's documentation only
- Add GitHub Pages documentation for pseudocode v1.0.0
- Merge pull request #8 from codeuchain/feat/update-typed-features-docs
- Update Typed Features Implementation documentation with current status and achievements
- Merge pull request #5 from codeuchain/feature/javascript-typed-features
- Enhance JavaScript docstrings to SOLID standards
- Merge pull request #4 from codeuchain/feature/python-typed-features
- Merge pull request #3 from codeuchain/feature/typed-features-implementation
- Fix C# test-runner compilation and validation
- Update README.md
- Update README.md
- Update license to Apache 2.0 and add copyright
- Initial commit: CodeUChain multi-language implementation

### Fixed
- Correct regex syntax in bump script for bash compatibility
- Update CI workflow and changelog for v1.3.0
- update installers to download latest hooks and improve documentation
- Use release commits as version boundary to prevent double-counting features
- Fix function ordering in pre-push hook verification
- Update pre-push hook to commit version bumps and request re-push
- reorder language detection to prioritize Kotlin and Scala before Java Gradle
- Purge codeuchain files from repository
- Restore content of reusable workflow


## [1.4.0] - 2026-01-24

### Added
- Auto-populate CHANGELOG from git commits and enable CI on releases
- Enhance CI summary output and fix test visibility
- Implement auto-push capability in pre-push hook to handle automated version bumps gracefully
- Add automatic semantic versioning with breaking change detection
- Add unified versioning and changelog system
- Add automatic npm publishing workflow
- Add npm package support with npx initialization
- Add caching, conditional tasks, and interactive mode
- Add versions field support for matrix-style testing
- Add comprehensive git hooks blocking test suite
- add initial CI agents documentation and Visual Studio solution file
- complete comprehensive testing support for all 16 languages
- add Dart language support with pub package manager
- add C++ language support with CMake/Make integration
- add Swift language support with Swift Package Manager
- add Scala language support with sbt/Gradle integration
- add Kotlin language support with Gradle integration
- one-command bootstrap for any platform
- Add lightweight shell/PowerShell scripts - zero dependencies
- Add comprehensive CI setup with pre-push hooks
- Add comprehensive test suite
- Add Release Stage support
- Add reusable workflow for remote consumption
- Establish I-prefixed types as recommended pattern (#26)
- Implement clean URL routing for docs site (#22)
- Add clean URL router for docs site (#21)
- Add comprehensive README with architecture, core concepts, and language implementations
- Enhance pseudocode documentation with conceptual storytelling (#18)
- Complete Rust typing implementation and v1.0.0 release (#17)
- update Go release README and add publish workflow
- standardize cheat sheets and add ASCII diagrams
- Complete v1.0.0 release with all package versions and documentation updates
- Add Go workspace file for proper submodule handling
- Update Go module path for cleaner publishing
- Bump Python package to v1.0.0 with type hints support
- Bump JavaScript package to v1.0.0 with TypeScript support
- type saftey for go lang #7
- Enhance pseudocode documentation with conceptual storytelling (#6)
- Implement comprehensive JavaScript typed features
- Complete Python typed features implementation
- Complete C# typed features implementation with 100% test coverage

### Changed
- release: v1.2.4 - Fix shell pipe parsing in run-ci.sh
- Add COMMIT_STANDARD.md to explain semantic versioning rules
- Add semantic versioning guide for agents
- Enable semantic versioning dogfooding in config
- rename scripts from verify/install to run-ci/install-ci
- update README with all 5 new languages (Kotlin, Scala, Swift, C++, Dart)
- add Apache 2.0 license for Orchestrate LLC 2026
- comprehensive README update
- Update README to reflect Universal CI branding and features
- Improve verify.py config path resolution and add integration tests
- Add Complete COBOL Implementation (#1)
- Remove 'agape' references from implementation codebases (#29)
- Release v1.1.1: Package cleanup and release assets (#27)
- Add comprehensive JSDoc documentation to TypeScript definition files (#24)
- Fix Context types: Use Record<string, any> as default for better key-value structure (#25)
- Clean URL Router Implementation (#23)
- Site + buf-json demo (#20)
- Update README with website link, add CNAME for custom domain, and clean up files
- Create CNAME
- Delete CNAME
- Create CNAME
- Merge remote-tracking branch 'origin/main'
- Merge pull request #16 from codeuchain/chore/github-config
- Merge branch 'main' into chore/github-config
- add issue/PR templates and labels.yml
- preserve release scripts and C++ README (#15)
- remove unpacked release directories, keep compressed archives
- add script to upload assets to per-language tags
- add helper and workflow to upload release assets to GitHub Releases
- Remove redundant cpp-package directory and update workflow to use releases/ (#13)
- recreate per-language minimal release archives and harden packaging script (exclude build artifacts) (#14)
- recreate per-language minimal release archives and harden packaging script (exclude build artifacts)
- Add release-only C++ package (v1.0.0) and prebuilt archives
- Add generated C++ standalone package artifacts for testing (ignored in final release)
- Add C++ standalone package workflow and documentation
- Add C++ Implementation (#2)
- Merge pull request #11 from codeuchain/publish/csharp-v1.0.0
- Publish C# CodeUChain v1.0.0 to NuGet
- Update all READMEs with proper installation instructions near the top
- Merge pull request #10 from codeuchain/feat/stylish-github-pages
- Merge main into feat/stylish-github-pages - resolve documentation conflicts
- revert: Revert Go module path to original for submodule publishing
- ✨ Redesign GitHub Pages with Tailwind CSS (#9)
- ✨ Redesign GitHub Pages with Tailwind CSS
- Add llm.txt and llm-full.txt files for all language packages
- Remove npm package config from pseudocode - it's documentation only
- Add GitHub Pages documentation for pseudocode v1.0.0
- Merge pull request #8 from codeuchain/feat/update-typed-features-docs
- Update Typed Features Implementation documentation with current status and achievements
- Merge pull request #5 from codeuchain/feature/javascript-typed-features
- Enhance JavaScript docstrings to SOLID standards
- Merge pull request #4 from codeuchain/feature/python-typed-features
- Merge pull request #3 from codeuchain/feature/typed-features-implementation
- Fix C# test-runner compilation and validation
- Update README.md
- Update README.md
- Update license to Apache 2.0 and add copyright
- Initial commit: CodeUChain multi-language implementation

### Fixed
- Correct regex syntax in bump script for bash compatibility
- Update CI workflow and changelog for v1.3.0
- update installers to download latest hooks and improve documentation
- Use release commits as version boundary to prevent double-counting features
- Fix function ordering in pre-push hook verification
- Update pre-push hook to commit version bumps and request re-push
- reorder language detection to prioritize Kotlin and Scala before Java Gradle
- Purge codeuchain files from repository
- Restore content of reusable workflow


## [1.3.1] - 2026-01-24

### Fixed
- **GitHub Actions CI:** Fixed reusable workflow to fetch correct script (`run-ci.sh` instead of non-existent `verify.sh`), resolving CI execution failures in GitHub Actions.
- **Documentation:** Properly documented v1.3.0 changes in CHANGELOG that were missing from previous release. 


## [1.3.0] - 2026-01-24

### Added
- **Enhanced CI Summary Output:** Added detailed task-by-task summary at the end of CI runs, showing all passed tasks with checkmarks for better visibility.
- **Improved Test Visibility:** Removed quiet flags from test commands to show actual output, making it easier to verify what was tested.

### Changed
- **CI Workflow Fix:** Updated GitHub Actions reusable workflow to fetch `run-ci.sh` instead of non-existent `verify.sh`.


## [1.2.5] - 2026-01-24

### Added
- 

### Changed
- 

### Fixed
- 


## [1.2.4] - 2026-01-24

### Fixed
- **Critical:** Fixed JSON parsing in `run-ci.sh` to correctly handle commands containing pipe characters (`|`).
- Updated task splitter to use ASCII Record Separator (`\036`) instead of string splitting, preventing command fragmentation.
- Fixed "Directory not found" errors in CI when using piped commands. 


## [1.2.3] - 2026-01-19

### Added
- 

### Changed
- 

### Fixed
- 


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
