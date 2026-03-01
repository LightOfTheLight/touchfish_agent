#!/bin/bash
# Validation tests for agent folder structure
# Checks that all required agent files exist and have required sections

set -e

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

AGENTS=("PO" "DEV" "TESTER")

echo "=== TouchFish Agent Structure Validation Tests ==="
echo ""

# Test 1: Agent folders exist
echo "[1] Agent folder structure"
for agent in "${AGENTS[@]}"; do
    if [[ -d "agents/$agent" ]]; then
        pass "agents/$agent/ directory exists"
    else
        fail "agents/$agent/ directory missing"
    fi
done

# Test 2: Agent definition files exist
echo ""
echo "[2] Agent definition files"
for agent in "${AGENTS[@]}"; do
    if [[ -f "agents/$agent/$agent.md" ]]; then
        pass "agents/$agent/$agent.md exists"
    else
        fail "agents/$agent/$agent.md missing"
    fi
done

# Test 3: Agent history files exist
echo ""
echo "[3] Agent history files"
for agent in "${AGENTS[@]}"; do
    if [[ -f "agents/$agent/history.md" ]]; then
        pass "agents/$agent/history.md exists"
    else
        fail "agents/$agent/history.md missing"
    fi
done

# Test 4: Agent definition files have required sections
echo ""
echo "[4] Required sections in agent definitions"
REQUIRED_SECTIONS=("Role Definition" "Responsibilities" "Workflow" "Constraints")

for agent in "${AGENTS[@]}"; do
    def_file="agents/$agent/$agent.md"
    if [[ -f "$def_file" ]]; then
        for section in "${REQUIRED_SECTIONS[@]}"; do
            if grep -q "$section" "$def_file"; then
                pass "$agent: has '$section' section"
            else
                fail "$agent: missing '$section' section"
            fi
        done
    fi
done

# Test 5: History files have session entries
echo ""
echo "[5] History file content"
for agent in "${AGENTS[@]}"; do
    history_file="agents/$agent/history.md"
    if [[ -f "$history_file" ]]; then
        if grep -q "Session" "$history_file"; then
            pass "$agent: history.md has session entries"
        else
            fail "$agent: history.md has no session entries"
        fi
    fi
done

# Test 6: Core infrastructure files exist
echo ""
echo "[6] Core infrastructure"
INFRA_FILES=(
    "Dockerfile"
    "scripts/entrypoint.sh"
    ".github/workflows/agent-trigger.yml"
    "REQUIREMENT.md"
    "README.md"
    "docs/SETUP.md"
)

for file in "${INFRA_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        pass "$file exists"
    else
        fail "$file missing"
    fi
done

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
