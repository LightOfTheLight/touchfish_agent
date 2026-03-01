#!/bin/bash
# Validation tests for GitHub Actions workflow
# Checks that the workflow YAML is well-formed and contains required fields

set -e

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

WORKFLOW_FILE=".github/workflows/agent-trigger.yml"

echo "=== TouchFish Workflow Validation Tests ==="
echo ""

# Test 1: Workflow file exists
echo "[1] Workflow file checks"
if [[ -f "$WORKFLOW_FILE" ]]; then
    pass "agent-trigger.yml exists"
else
    fail "agent-trigger.yml not found at $WORKFLOW_FILE"
    exit 1
fi

# Test 2: YAML syntax (basic check using Python if available)
echo ""
echo "[2] YAML syntax"
if command -v python3 &>/dev/null; then
    if python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" 2>/dev/null; then
        pass "YAML syntax is valid"
    else
        fail "YAML syntax is invalid"
    fi
else
    echo "  SKIP: python3 not available for YAML validation"
fi

# Test 3: Required jobs exist
echo ""
echo "[3] Required jobs"
for job in "parse-trigger" "run-agent" "create-pr"; do
    if grep -q "$job:" "$WORKFLOW_FILE"; then
        pass "Job '$job' exists"
    else
        fail "Job '$job' missing"
    fi
done

# Test 4: Required secrets are referenced
echo ""
echo "[4] Secret references"
if grep -q "GITHUB_TOKEN" "$WORKFLOW_FILE"; then
    pass "GITHUB_TOKEN referenced"
else
    fail "GITHUB_TOKEN not referenced"
fi

if grep -q "CLAUDE_CODE_OAUTH_TOKEN" "$WORKFLOW_FILE"; then
    pass "CLAUDE_CODE_OAUTH_TOKEN referenced"
else
    fail "CLAUDE_CODE_OAUTH_TOKEN not referenced"
fi

# Test 5: Trigger excludes master/main
echo ""
echo "[5] Branch protection"
if grep -q "branches-ignore" "$WORKFLOW_FILE"; then
    pass "branches-ignore is configured"
else
    fail "branches-ignore not found (master/main not protected)"
fi

if grep -E "master|main" "$WORKFLOW_FILE" | grep -q "branches-ignore" 2>/dev/null || \
   awk '/branches-ignore/,/^[^ ]/' "$WORKFLOW_FILE" | grep -q "master"; then
    pass "master branch is excluded from trigger"
else
    fail "master branch may not be excluded"
fi

# Test 6: Agent name parsing covers all agents
echo ""
echo "[6] Agent name parsing"
for agent in PO DEV TESTER; do
    if grep -q "$agent" "$WORKFLOW_FILE"; then
        pass "Agent '$agent' is handled"
    else
        fail "Agent '$agent' not found in workflow"
    fi
done

# Test 7: Docker run uses --user flag (security check)
echo ""
echo "[7] Security checks"
if grep -q "\-\-user" "$WORKFLOW_FILE"; then
    pass "Docker runs with --user flag (non-root execution)"
else
    fail "--user flag missing from docker run (container may run as root)"
fi

# Summary
echo ""
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo "FAILED: $FAIL test(s) failed"
    exit 1
else
    echo "SUCCESS: All $PASS tests passed"
fi
