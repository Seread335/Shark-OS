#!/usr/bin/env bash
# Functional test suite for Shark OS CLI
set -eEuo pipefail
rc=0
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

TEST_LOG="test-functional-cli.log"
# Resolve paths relative to test script location so tests work anywhere
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARK="$SCRIPT_DIR/../shark-cli/shark"
export SHARK_CONFIG="$SCRIPT_DIR/../docs/config.example.yml"
export SHARK_AUTH_TOKEN="testtoken"
export SHARK_AUDIT_LOG="$SCRIPT_DIR/test-audit.log"
rm -f "$SHARK_AUDIT_LOG"

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
run_test "Show version" "$SHARK" version
run_test "Show status" "$SHARK" status
run_test "Show config" "$SHARK" config show
run_test "Get config key" "$SHARK" config get version
# Init config requires root; in non-root test environment expect failure
if "$SHARK" config init <<< "testtoken" >/dev/null 2>&1; then
    log_result FAIL "Init config (unexpected success without root)"
    fail=$((fail+1))
else
    log_result PASS "Init config (requires root) - failed as expected"
    pass=$((pass+1))
fi
# Edit config requires root; in non-root test environment expect failure
if "$SHARK" config edit <<< "testtoken" >/dev/null 2>&1; then
    log_result FAIL "Edit config (unexpected success without root)"
    fail=$((fail+1))
else
    log_result PASS "Edit config (requires root) - failed as expected"
    pass=$((pass+1))
fi
run_test "Update info" "$SHARK" update info
run_test "Update check" "$SHARK" update check
# Update apply requires root; in non-root env expect failure but should still be audited
if "$SHARK" update apply >/dev/null 2>&1; then
    log_result FAIL "Update apply (unexpected success without root)"
    fail=$((fail+1))
else
    log_result PASS "Update apply (requires root) - failed as expected"
    pass=$((pass+1))
fi
# Verify audit log contains update.apply
if grep -q "update.apply" "$SHARK_AUDIT_LOG" 2>/dev/null; then
    log_result PASS "Audit logged for update.apply"
    pass=$((pass+1))
else
    log_result FAIL "Audit logged for update.apply"
    fail=$((fail+1))
fi
# System reboot requires root; expect failure in non-root test env
if "$SHARK" system reboot <<< "testtoken" >/dev/null 2>&1; then
    log_result FAIL "System reboot (unexpected success without root)"
    fail=$((fail+1))
else
    log_result PASS "System reboot (requires root) - failed as expected"
    pass=$((pass+1))
fi
# Service management requires root; expect failure in non-root test env
if "$SHARK" service sshd status <<< "testtoken" >/dev/null 2>&1; then
    log_result FAIL "Service status (unexpected success without root)"
    fail=$((fail+1))
else
    log_result PASS "Service status (requires root) - failed as expected"
    pass=$((pass+1))
fi
run_test "Container list" "$SHARK" container list
# Container run requires root; expect failure in non-root test env
if "$SHARK" container run alpine echo hello <<< "testtoken" >/dev/null 2>&1; then
    log_result FAIL "Container run (unexpected success without root)"
    fail=$((fail+1))
else
    log_result PASS "Container run (requires root) - failed as expected"
    pass=$((pass+1))
fi
run_test "Kubernetes status (should skip if k3s not installed)" "$SHARK" kubernetes status || true

# --- Negative tests ---
# Config with invalid YAML (expect failure)
if "$SHARK" config show --config "$SCRIPT_DIR/../docs/invalid-config.yml" >/dev/null 2>&1; then
    log_result FAIL "Config with invalid YAML (should fail)"
    fail=$((fail+1))
else
    log_result PASS "Config with invalid YAML (should fail)"
    pass=$((pass+1))
fi

# Auth with wrong token (expect failure)
if SHARK_AUTH_TOKEN=wrong "$SHARK" update apply <<< "wrongtoken" >/dev/null 2>&1; then
    log_result FAIL "Auth with wrong token (should fail)"
    fail=$((fail+1))
else
    log_result PASS "Auth with wrong token (should fail)"
    pass=$((pass+1))
fi

# Container run with dangerous input (expect failure)
if "$SHARK" container run 'alpine; rm -rf /' <<< "testtoken" >/dev/null 2>&1; then
    log_result FAIL "Container run with dangerous input (should fail)"
    fail=$((fail+1))
else
    log_result PASS "Container run with dangerous input (should fail)"
    pass=$((pass+1))
fi

# --- Summary ---
printf '\nFunctional CLI tests: %d passed, %d failed. Log: %s\n' "$pass" "$fail" "$TEST_LOG"
exit $fail
