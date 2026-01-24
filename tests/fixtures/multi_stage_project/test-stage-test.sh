#!/bin/bash
# Test multi-stage test phase
set -e

echo "🔧 Running Multi-Stage Test Phase..."
echo "   Directory: $(pwd)"

# Run the nested run-ci.sh with test stage
OUTPUT=$(../../../run-ci.sh --stage test 2>&1)

echo "   Checking for success message..."
if echo "$OUTPUT" | grep -q "ALL SYSTEMS GO"; then
    echo "   Found success message for test stage"
    echo "✅ MULTI_STAGE_TEST_PASSED"
else
    echo "❌ Multi-stage test phase did not pass"
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi
