#!/bin/bash
# Test JSON parsing functionality
set -e

echo "📋 Running JSON Parsing Test..."

# Test that --list-tasks returns valid JSON
echo "   Testing --list-tasks output..."
OUTPUT=$(./run-ci.sh --list-tasks 2>/dev/null)

if echo "$OUTPUT" | grep -q '"tasks"'; then
    echo "   Found 'tasks' key in output"
else
    echo "❌ No 'tasks' key found in JSON output"
    exit 1
fi

if echo "$OUTPUT" | grep -q '"name"'; then
    echo "   Found 'name' field in tasks"
else
    echo "❌ No 'name' field found in tasks"
    exit 1
fi

# Count tasks
TASK_COUNT=$(echo "$OUTPUT" | grep -o '"name"' | wc -l | tr -d ' ')
echo "   Detected $TASK_COUNT tasks in config"

if [ "$TASK_COUNT" -gt 0 ]; then
    echo "✅ JSON_PARSING_PASSED"
else
    echo "❌ No tasks detected"
    exit 1
fi
