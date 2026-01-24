#!/bin/bash
# Test JS fixture execution
set -e

echo "📦 Running JS Fixture Test..."
echo "   Directory: $(pwd)"

# Run the nested run-ci.sh
OUTPUT=$(../../../run-ci.sh 2>&1)

echo "   Checking for success message..."
if echo "$OUTPUT" | grep -q "ALL SYSTEMS GO"; then
    echo "   Found success message"
    echo "✅ JS_FIXTURE_PASSED"
else
    echo "❌ JS fixture did not pass"
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi
