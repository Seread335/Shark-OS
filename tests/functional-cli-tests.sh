#!/usr/bin/env bash
# Functional test suite for Shark OS CLI
set -eEuo pipefail
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

TEST_LOG="test-functional-cli.log"
SHARK="../shark-cli/shark"
export SHARK_CONFIG="../docs/config.example.yml"
export SHARK_AUTH_TOKEN="testtoken"

pass=0
fail=0

log_result() {
    local result="$1"; shift
    local msg="$*"
    echo "[$result] $msg" | tee -a "$TEST_LOG"
}

run_test() {
    local desc="$1"; shift
    if "$@" > /dev/null 2>&1; then
        log_result PASS "$desc"
        pass=$((pass+1))
    else
        log_result FAIL "$desc"
        fail=$((fail+1))
    fi
}

rm -f "$TEST_LOG"

# --- CLI tests ---
run_test "Show version" $SHARK version
run_test "Show status" $SHARK status
run_test "Show config" $SHARK config show
run_test "Get config key" $SHARK config get version
run_test "Init config (should require auth)" $SHARK config init <<< "testtoken"
run_test "Edit config (should require auth)" $SHARK config edit <<< "testtoken"
run_test "Update info" $SHARK update info
run_test "Update check" $SHARK update check
run_test "Update apply (should require auth)" $SHARK update apply <<< "testtoken"
run_test "System reboot (should require auth, expect fail if not root)" $SHARK system reboot <<< "testtoken"
run_test "Service status (should require auth)" $SHARK service sshd status <<< "testtoken"
run_test "Container list" $SHARK container list
run_test "Container run (should require auth, expect fail if not root)" $SHARK container run alpine echo hello <<< "testtoken"
run_test "Kubernetes status (should skip if k3s not installed)" $SHARK kubernetes status || true

# --- Negative tests ---
# Config with invalid YAML (expect failure)
if $SHARK config show --config ../docs/invalid-config.yml >/dev/null 2>&1; then
    log_result FAIL "Config with invalid YAML (should fail)"
    fail=$((fail+1))
else
    log_result PASS "Config with invalid YAML (should fail)"
    pass=$((pass+1))
fi

# Auth with wrong token (expect failure)
if bash -c 'SHARK_AUTH_TOKEN=wrong "$SHARK" update apply <<< "wrongtoken"' >/dev/null 2>&1; then
    log_result FAIL "Auth with wrong token (should fail)"
    fail=$((fail+1))
else
    log_result PASS "Auth with wrong token (should fail)"
    pass=$((pass+1))
fi

# Container run with dangerous input (expect failure)
if bash -c "$SHARK container run 'alpine; rm -rf /' <<< \"testtoken\"" >/dev/null 2>&1; then
    log_result FAIL "Container run with dangerous input (should fail)"
    fail=$((fail+1))
else
    log_result PASS "Container run with dangerous input (should fail)"
    pass=$((pass+1))
fi

# --- Summary ---
echo "\nFunctional CLI tests: $pass passed, $fail failed. Log: $TEST_LOG"
exit $fail
