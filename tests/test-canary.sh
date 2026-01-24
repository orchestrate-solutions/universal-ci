#!/bin/bash
# Canary test - verifies basic execution works
set -e

echo "🐦 Running Canary Test..."
echo "   Checking run-ci.sh exists..."
test -f run-ci.sh || { echo "❌ run-ci.sh not found"; exit 1; }

echo "   Checking run-ci.sh is executable..."
test -x run-ci.sh || { echo "❌ run-ci.sh not executable"; exit 1; }

echo "   Verifying shell environment..."
echo "   Shell: $SHELL"
echo "   PWD: $PWD"

echo "✅ CANARY_TEST_PASSED"
