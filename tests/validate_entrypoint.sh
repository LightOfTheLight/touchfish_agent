#!/bin/bash
# Validation tests for entrypoint.sh
# Tests observable behavior and structure without sourcing the script directly

set -e

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SCRIPT="scripts/entrypoint.sh"

echo "=== TouchFish Entrypoint Validation Tests ==="
echo ""

# Test 1: File checks
echo "[1] File checks"
if [[ -f "$SCRIPT" ]]; then
    pass "entrypoint.sh exists"
else
    fail "entrypoint.sh not found"
fi

if [[ -x "$SCRIPT" ]]; then
    pass "entrypoint.sh is executable"
else
    fail "entrypoint.sh is not executable"
fi

# Test 2: Required functions are defined
echo ""
echo "[2] Function definitions"
for fn in validate_env configure_git build_agent_prompt run_agent main; do
    if grep -q "^${fn}()" "$SCRIPT"; then
        pass "Function '$fn' is defined"
    else
        fail "Function '$fn' is missing"
    fi
done

# Test 3: Required env vars are checked in validate_env
echo ""
echo "[3] Environment variable validation logic"
for var in AGENT_NAME GITHUB_TOKEN COMMIT_MESSAGE BRANCH_NAME; do
    if grep -q "\"$var\"" "$SCRIPT"; then
        pass "validate_env checks $var"
    else
        fail "validate_env does not check $var"
    fi
done

# Test 4: Agent name validation covers all agents
echo ""
echo "[4] Agent name regex"
for agent in PO DEV TESTER; do
    if grep -q "$agent" "$SCRIPT"; then
        pass "Agent '$agent' referenced in script"
    else
        fail "Agent '$agent' not found in script"
    fi
done

# Test 5: Security checks - no hardcoded credentials
echo ""
echo "[5] Security checks"
if grep -qE "(password|secret|api_key)\s*=" "$SCRIPT" 2>/dev/null; then
    fail "Potential hardcoded credential found"
else
    pass "No hardcoded credentials detected"
fi

# Test 6: Timeout is configured
echo ""
echo "[6] Safety mechanisms"
if grep -q "timeout" "$SCRIPT"; then
    pass "Timeout is configured"
else
    fail "No timeout found (runaway sessions possible)"
fi

if grep -q "max-turns" "$SCRIPT"; then
    pass "Max turns limit is configured"
else
    fail "No max-turns limit found"
fi

# Test 7: Git configuration
echo ""
echo "[7] Git configuration"
if grep -q "git config" "$SCRIPT"; then
    pass "Git config is set in script"
else
    fail "No git config found"
fi

if grep -q "git-credentials" "$SCRIPT"; then
    pass "Git credentials helper is configured"
else
    fail "Git credentials helper not found"
fi

# Test 8: Prompt includes key context
echo ""
echo "[8] Agent prompt content"
if grep -q 'AGENT_NAME' "$SCRIPT" && grep -q 'COMMIT_MESSAGE' "$SCRIPT"; then
    pass "Prompt uses AGENT_NAME and COMMIT_MESSAGE"
else
    fail "Prompt may be missing key context variables"
fi

if grep -q 'REQUIREMENT.md' "$SCRIPT"; then
    pass "Prompt references REQUIREMENT.md"
else
    fail "Prompt does not reference REQUIREMENT.md"
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
