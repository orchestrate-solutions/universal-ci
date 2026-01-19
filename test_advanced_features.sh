#!/bin/bash
# Test script for advanced features: caching, conditions, interactive mode

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

echo "🧪 Testing Advanced Universal CI Features..."
echo ""

# Test 1: Interactive Mode - List Tasks
echo "✅ Test 1: Interactive Mode - List Tasks as JSON"
cd "$REPO_ROOT/tests/fixtures/interactive_project"
if output=$("../../../run-ci.sh" --list-tasks 2>&1); then
    if echo "$output" | grep -q '"tasks":\['; then
        echo "   PASSED: Tasks listed as JSON"
    else
        echo "   FAILED: JSON output not found"
        exit 1
    fi
else
    echo "   FAILED: Error listing tasks"
    exit 1
fi
cd "$REPO_ROOT"

# Test 2: Interactive Mode - Select Tasks
echo "✅ Test 2: Interactive Mode - Select Specific Tasks"
cd "$REPO_ROOT/tests/fixtures/interactive_project"
if output=$("../../../run-ci.sh" --select-tasks '["Build","Lint"]' 2>&1); then
    if echo "$output" | grep -q "Build.*Passed" && echo "$output" | grep -q "Lint.*Passed"; then
        if echo "$output" | grep -q "Test"; then
            echo "   FAILED: Test task should not have run"
            exit 1
        fi
        echo "   PASSED: Only selected tasks ran"
    else
        echo "   FAILED: Selected tasks did not run"
        exit 1
    fi
else
    echo "   FAILED: Error running selected tasks"
    exit 1
fi
cd "$REPO_ROOT"

# Test 3: Conditional Tasks
echo "✅ Test 3: Conditional Task Execution"
cd "$REPO_ROOT/tests/fixtures/conditional_tasks_project"
if output=$("../../../run-ci.sh" 2>&1); then
    if echo "$output" | grep -q "Always Run"; then
        echo "   PASSED: Conditional tasks evaluated correctly"
    else
        echo "   FAILED: Task execution issue"
        exit 1
    fi
else
    echo "   FAILED: Error executing conditional tasks"
    exit 1
fi
cd "$REPO_ROOT"

# Test 4: Approval Required
echo "✅ Test 4: Task Approval (requires_approval)"
cd "$REPO_ROOT/tests/fixtures/interactive_project"
if output=$("../../../run-ci.sh" --stage release 2>&1); then
    if echo "$output" | grep -q "Deploy to Production.*Passed"; then
        echo "   PASSED: Approval worked correctly"
    else
        echo "   FAILED: Deployment task issue"
        exit 1
    fi
else
    echo "   FAILED: Error with approval workflow"
    exit 1
fi
cd "$REPO_ROOT"

# Test 5: Caching Project Config
echo "✅ Test 5: Caching Configuration"
cd "$REPO_ROOT/tests/fixtures/caching_project"
if output=$("../../../run-ci.sh" 2>&1); then
    if echo "$output" | grep -q "Install Dependencies"; then
        echo "   PASSED: Cache-enabled task ran"
    else
        echo "   FAILED: Cache task execution failed"
        exit 1
    fi
else
    echo "   FAILED: Error with caching config"
    exit 1
fi
cd "$REPO_ROOT"

echo ""
echo "🎉 All Advanced Features Tests PASSED!"
