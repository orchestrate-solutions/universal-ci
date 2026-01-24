#!/bin/bash
# Test Python script compatibility
set -e

echo "🐍 Running Python Compatibility Test..."
echo "   Directory: $(pwd)"

# Check if verify.py exists
VERIFY_SCRIPT="../../../universal-ci-testing-env/verify.py"
if [ ! -f "$VERIFY_SCRIPT" ]; then
    echo "⚠️  Python verify script not found at $VERIFY_SCRIPT"
    echo "   Skipping Python compatibility test"
    echo "✅ PYTHON_COMPAT_SKIPPED (script not present)"
    exit 0
fi

# Run the Python verify script
OUTPUT=$(python3 "$VERIFY_SCRIPT" 2>&1)

echo "   Checking for success message..."
if echo "$OUTPUT" | grep -q "ALL SYSTEMS GO"; then
    echo "   Found success message from Python script"
    echo "✅ PYTHON_COMPAT_PASSED"
else
    echo "❌ Python compatibility test did not pass"
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi
