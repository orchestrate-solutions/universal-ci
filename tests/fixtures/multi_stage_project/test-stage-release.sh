#!/bin/bash
# Test multi-stage release phase
set -e

echo "🚀 Running Multi-Stage Release Phase..."
echo "   Directory: $(pwd)"

# Run the nested run-ci.sh with release stage
OUTPUT=$(../../../run-ci.sh --stage release 2>&1)

echo "   Checking for success message..."
if echo "$OUTPUT" | grep -q "ALL SYSTEMS GO"; then
    echo "   Found success message for release stage"
    echo "✅ MULTI_STAGE_RELEASE_PASSED"
else
    echo "❌ Multi-stage release phase did not pass"
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi
