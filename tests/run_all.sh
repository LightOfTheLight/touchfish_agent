#!/bin/bash
# Run all TouchFish validation tests
# Usage: ./tests/run_all.sh (from repository root)

set -e

cd "$(git rev-parse --show-toplevel)"

TOTAL_PASS=0
TOTAL_FAIL=0
FAILED_SUITES=()

run_suite() {
    local script="$1"
    local name="$2"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if bash "$script"; then
        TOTAL_PASS=$((TOTAL_PASS + 1))
    else
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        FAILED_SUITES+=("$name")
    fi
}

echo "TouchFish Agent Test Runner"
echo "Running from: $(pwd)"

run_suite "tests/validate_agents.sh"     "Agent Structure"
run_suite "tests/validate_workflow.sh"   "Workflow"
run_suite "tests/validate_entrypoint.sh" "Entrypoint"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "=== OVERALL RESULTS ==="
echo "  Suites passed: $TOTAL_PASS"
echo "  Suites failed: $TOTAL_FAIL"

if [[ $TOTAL_FAIL -gt 0 ]]; then
    echo ""
    echo "Failed suites:"
    for suite in "${FAILED_SUITES[@]}"; do
        echo "  - $suite"
    done
    exit 1
else
    echo ""
    echo "All test suites passed!"
fi
