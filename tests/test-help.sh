#!/bin/bash
# Test help output
set -e

echo "❓ Running Help Output Test..."

OUTPUT=$(./run-ci.sh --help 2>&1)

echo "   Checking for banner..."
if echo "$OUTPUT" | grep -q "Universal CI Verifier"; then
    echo "   Found 'Universal CI Verifier' banner"
else
    echo "❌ Banner not found"
    exit 1
fi

echo "   Checking for usage info..."
if echo "$OUTPUT" | grep -q "Usage"; then
    echo "   Found usage information"
else
    echo "❌ Usage info not found"
    exit 1
fi

echo "   Checking for options..."
if echo "$OUTPUT" | grep -q "\-\-config"; then
    echo "   Found --config option"
else
    echo "❌ --config option not documented"
    exit 1
fi

echo "✅ HELP_OUTPUT_PASSED"
