#!/bin/bash
# Test Python fixture execution
set -e

echo "🐍 Running Python Fixture Test..."
echo "   Directory: $(pwd)"

# Run the nested run-ci.sh
OUTPUT=$(../../../run-ci.sh 2>&1)

echo "   Checking for success message..."
if echo "$OUTPUT" | grep -q "ALL SYSTEMS GO"; then
    echo "   Found success message"
    echo "✅ PYTHON_FIXTURE_PASSED"
else
    echo "❌ Python fixture did not pass"
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi
