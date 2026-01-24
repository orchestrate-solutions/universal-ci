#!/bin/bash
# Test error handling for missing config
set -e

echo "⚠️  Running Error Handling Test..."

# This should fail with a "not found" message
OUTPUT=$(./run-ci.sh --config nonexistent-config-12345.json 2>&1) || true

echo "   Checking for error message..."
if echo "$OUTPUT" | grep -q "not found"; then
    echo "   Found 'not found' error message"
    echo "✅ ERROR_HANDLING_PASSED"
else
    echo "❌ Expected error message not found"
    echo "Output was:"
    echo "$OUTPUT"
    exit 1
fi
