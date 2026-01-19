#!/bin/bash
# Integration test: Verify that failed scripts block git operations
# This test should be run as part of CI to ensure the blocking behavior works

set -e

echo "🧪 Running Git Hooks Blocking Integration Test..."
echo "=================================================="

# Get the repo root
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Run the git hooks blocking tests
echo ""
echo "📍 Running test suite..."
python3 universal-ci-testing-env/tests/run_git_hooks_tests.py

TEST_EXIT=$?

echo ""
echo "=================================================="

if [ $TEST_EXIT -eq 0 ]; then
    echo "✅ Git Hooks Blocking Tests PASSED"
    echo ""
    echo "Verified:"
    echo "  ✓ Pre-commit and pre-push hooks are created correctly"
    echo "  ✓ Failing scripts block git operations"
    echo "  ✓ Passing scripts allow git operations"
    echo "  ✓ Multiple task failures are handled properly"
    exit 0
else
    echo "❌ Git Hooks Blocking Tests FAILED"
    echo "The blocking mechanism is not working properly."
    exit 1
fi
