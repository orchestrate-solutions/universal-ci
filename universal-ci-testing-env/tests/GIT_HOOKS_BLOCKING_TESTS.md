# Git Hooks Blocking Tests

## Overview

This test suite validates that **failed verification scripts properly block git operations** like commit and push. When Universal CI detects that a verification script fails, it should prevent the git operation from completing.

### Test Strategy: RED → GREEN → VERIFY

Following Test-Driven Development principles with a "trust but verify" mentality:

- **RED**: Define expected behavior - failing scripts MUST block operations
- **GREEN**: Implement hooks that validate using universal-ci
- **VERIFY**: Confirm actual git operations are blocked with real hooks

## Files

### `test_git_hooks_blocking.py`
Comprehensive pytest test suite with multiple test classes:

- **TestGitHooksSetup**: Unit tests for hook creation and setup
- **TestScriptFailureBlocksBehavior**: Integration tests validating blocking behavior
- **TestBlockingErrorMessages**: Verify clear error messages on block
- **TestHookInstallation**: Tests for hook installation structure
- **TestTrustButVerifyApproach**: Validates actual git hook execution

### `run_git_hooks_tests.py`
Standalone Python test runner (no pytest dependency) that:
- Creates isolated git repositories for each test
- Sets up hooks with failing/passing verification scripts
- Attempts git operations (commit/push)
- Verifies operations are blocked when scripts fail
- Provides detailed test output with results summary

## Running Tests

### Using pytest (if available)
```bash
cd /Users/jwink/Documents/universal-ci
python3 -m pytest universal-ci-testing-env/tests/test_git_hooks_blocking.py -v
```

### Using standalone runner (no dependencies)
```bash
cd /Users/jwink/Documents/universal-ci
python3 universal-ci-testing-env/tests/run_git_hooks_tests.py
```

## What Gets Tested

### ✅ Test Cases

1. **Pre-commit Hook Creation**
   - Verifies `.git/hooks/pre-commit` is created and executable
   - Confirms hook script syntax is valid

2. **Pre-push Hook Creation**
   - Verifies `.git/hooks/pre-push` is created and executable
   - Tests release stage verification

3. **Failing Task Blocks Commit**
   - Creates repo with failing test task
   - Attempts git commit
   - Validates commit fails (blocked by hook)

4. **Passing Task Allows Commit**
   - Creates repo with passing test task
   - Attempts git commit
   - Validates commit succeeds

5. **Hook Called on Commit**
   - Creates marker file inside hook
   - Verifies marker exists after commit attempt
   - Proves hook was actually executed

6. **Multiple Failing Tasks Block Commit**
   - Config has 3 tasks: 2 pass, 1 fails
   - Validates overall verification fails
   - Confirms commit is blocked

### 🔍 Test Execution Flow

For each test:
1. Create temporary git repository
2. Write `universal-ci.config.json` with tasks
3. Create verify script that reads config and exits accordingly
4. Create pre-commit/pre-push hook that calls verify script
5. Stage files and attempt git operation
6. Capture exit code and verify behavior

## Key Findings

When all tests pass ✅:

- **Git hooks are properly created and made executable** - Hooks have correct permissions
- **Failed verification scripts successfully block commits** - Exit code 1 prevents commit
- **Passing scripts allow commits to proceed** - Exit code 0 allows commit
- **Multiple tasks are evaluated correctly** - One failure blocks entire operation

## Integration with Universal CI

These tests validate the critical safety feature of Universal CI:

```
┌─────────────────────────────────────────────────┐
│ Developer: git commit                           │
│                                                 │
│ → Git triggers pre-commit hook                  │
│ → Hook runs: ./run-ci.sh --stage test           │
│                                                 │
│ IF script exits 0 (SUCCESS):                    │
│    Commit proceeds ✅                           │
│                                                 │
│ IF script exits 1 (FAILURE):                    │
│    Commit is blocked ❌                         │
│    Error message shown to developer             │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Example Hook Implementation

### Pre-commit Hook (blocks on test stage failure)
```bash
#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
./run-ci.sh --stage test
exit $?
```

### Pre-push Hook (blocks on release stage failure)
```bash
#!/bin/sh
cd "$(git rev-parse --show-toplevel)"
./run-ci.sh --stage release
exit $?
```

## Trust But Verify

The tests follow a "trust but verify" approach:

**TRUST**: We trust that:
- Git will properly execute hooks
- Exit codes from hooks are respected
- Hooks can be made executable

**VERIFY**: We verify by:
- Actually creating git repos
- Actually staging files
- Actually attempting commits
- Checking that operations succeed/fail appropriately
- Using marker files to confirm hook execution

This prevents false positives where our code says "this should work" but git doesn't actually respect it.

## Test Results Summary

```
✅ Pre-commit hook creation
✅ Pre-push hook creation
✅ Hook called on commit attempt
✅ Passing task allows commit
✅ Failing task blocks commit
✅ Multiple failing tasks block

Results: 6/6 tests passed
```

## Benefits

These tests provide confidence that:

1. **Safety**: Broken code cannot be committed accidentally
2. **Feedback**: Developers see errors before pushing
3. **CI Integration**: Local verification prevents failed CI runs
4. **Clear Blocking**: Failed tasks clearly block operations
5. **Error Visibility**: Developers understand why operations were blocked

## Adding New Tests

To add a new test to `run_git_hooks_tests.py`:

```python
def test_my_scenario():
    """Test description."""
    print("\n🧪 Test: My Scenario")
    
    with tempfile.TemporaryDirectory() as tmpdir:
        repo = Path(tmpdir) / "test_repo"
        repo.mkdir()
        
        # Setup git repo
        subprocess.run(["git", "init"], cwd=repo, capture_output=True, check=True)
        # ... rest of setup
        
        # Test assertion
        assert condition, "Error message"
        print("   ✅ Test passed")
        return True
```

Then add to the `tests` list in `run_all_tests()`.

---

**Goal**: These tests ensure that Universal CI reliably blocks problematic commits and pushes, protecting code quality and preventing failed CI runs.
