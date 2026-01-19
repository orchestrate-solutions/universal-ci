# Integration Guide: Adding Git Hooks Blocking Tests to CI

This guide shows how to integrate the git hooks blocking tests into your Universal CI pipeline.

## Quick Start

### Add to universal-ci.config.json

```json
{
  "tasks": [
    {
      "name": "Test Git Hooks Blocking",
      "working_directory": "universal-ci-testing-env/tests",
      "command": "python3 run_git_hooks_tests.py",
      "stage": "test",
      "description": "Verify that failed scripts properly block git operations"
    }
  ]
}
```

### Add to GitHub Actions

```yaml
name: Verify Git Hooks Blocking

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      
      - name: Test Git Hooks Blocking
        run: python3 universal-ci-testing-env/tests/run_git_hooks_tests.py
```

## Running Tests Locally

### Before Committing
```bash
# Test that git hooks block failed scripts
./universal-ci-testing-env/tests/test-git-hooks.sh

# Expected output:
# ✅ Pre-commit hook creation
# ✅ Pre-push hook creation
# ✅ Hook called on commit attempt
# ✅ Passing task allows commit
# ✅ Failing task blocks commit
# ✅ Multiple failing tasks block
# 
# Results: 6/6 tests passed
```

### Via Universal CI
```bash
./verify.sh
```

## Implementation Examples

### Example 1: Minimal Setup

If you just want to run the blocking test:

```bash
python3 universal-ci-testing-env/tests/run_git_hooks_tests.py
```

Exit code:
- `0` = All tests passed (blocking works correctly)
- `1` = Tests failed (blocking mechanism broken)

### Example 2: Integration with Act (Local GitHub Actions Testing)

```bash
# Test locally using act
act -j test
```

### Example 3: Manual Verification

```bash
# Create a test repo
mkdir test_project
cd test_project
git init

# Create config with failing task
cat > universal-ci.config.json << 'EOF'
{
  "tasks": [
    {
      "name": "Test",
      "working_directory": ".",
      "command": "exit 1",
      "stage": "test"
    }
  ]
}
EOF

# Create hook
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
./verify.sh
exit $?
EOF
chmod +x .git/hooks/pre-commit

# Copy verify.sh here
cp ../verify.sh .

# Try to commit
echo "test" > file.txt
git add file.txt
git commit -m "test"  # Should fail/be blocked
```

## Troubleshooting

### Test Fails with "git not found"

**Solution**: Ensure git is installed and in PATH
```bash
which git
git --version
```

### Test Fails with Python error

**Solution**: Use Python 3.6+
```bash
python3 --version
```

### Test Fails: "Hook called on commit attempt"

**Solution**: This test requires git to be properly configured
```bash
git config user.name "Test User"
git config user.email "test@example.com"
```

## Understanding Test Output

### ✅ Success Output
```
============================================================
🚀 Universal CI - Git Hooks Blocking Test Suite
============================================================

Testing that failed scripts block git operations...

🧪 Test: Pre-commit hook creation
   ✅ Pre-commit hook created and executable

...

Results: 6/6 tests passed
🎉 ALL TESTS PASSED!
```

### ❌ Failure Output
```
❌ Failed test name
   Error: Assertion failed - commit should be blocked

Results: 5/6 tests passed
💥 1 test(s) failed
```

## Monitoring and Maintenance

### Track Test Results

Add to your dashboards:
```
✓ Git hooks blocking test passes
✓ Failed scripts block commits  
✓ Failed scripts block pushes
✓ Passing scripts allow commits
```

### Regular Verification

Run these tests:
- After modifying verify.sh
- After updating hooks installation
- In every CI pipeline run
- Manually before major releases

### Continuous Integration

**Recommended CI Schedule**:
```yaml
# Run on every commit
on: [push, pull_request]

# Run daily to catch environment issues
schedule:
  - cron: '0 2 * * *'  # Daily at 2 AM UTC
```

## Performance Considerations

- **Test Duration**: ~2-3 seconds per test
- **Disk Usage**: Minimal (temporary directories cleaned up)
- **Resource Usage**: Low (single core, ~50MB RAM)
- **Network**: None (all local)

**Total Test Suite Time**: ~15-20 seconds

## Advanced Configuration

### Skip Specific Tests

Modify `run_git_hooks_tests.py`:

```python
# In run_all_tests(), comment out tests you want to skip:
tests = [
    # ("Hook called on commit attempt", test_hook_called_on_commit),  # Skip this
    ("Pre-commit hook creation", test_pre_commit_hook_creation),
    # ... others
]
```

### Run with Debugging

```bash
python3 -u universal-ci-testing-env/tests/run_git_hooks_tests.py 2>&1 | tee test_output.log
```

### Run Individual Tests

```bash
# Use pytest for individual tests
python3 -m pytest test_git_hooks_blocking.py::TestGitHooksSetup::test_pre_commit_hook_creation -v
```

## Success Criteria

Test suite passes when:

✅ All 6 tests return `PASSED`
✅ No error messages displayed
✅ Exit code is 0
✅ Test output contains "🎉 ALL TESTS PASSED!"

If any of these fail, the blocking mechanism may not be working correctly.

## Next Steps

1. **Add to CI**: Include in your GitHub Actions or CI system
2. **Monitor**: Track test results in your CI dashboard
3. **Document**: Share with team that blocking mechanism is tested
4. **Alert**: Set up alerts if tests fail
5. **Review**: Periodically review test logs for patterns

## Questions?

Refer to:
- [GIT_HOOKS_BLOCKING_TESTS.md](./universal-ci-testing-env/tests/GIT_HOOKS_BLOCKING_TESTS.md) - Detailed test documentation
- [GIT_HOOKS_BLOCKING_TEST_SUMMARY.md](./GIT_HOOKS_BLOCKING_TEST_SUMMARY.md) - Complete overview
- `run_git_hooks_tests.py` - Test implementation

---

**Recommendation**: Add this test to your CI pipeline immediately to ensure the blocking mechanism is working correctly and prevent regressions.
