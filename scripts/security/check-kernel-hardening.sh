#!/usr/bin/env bash
# scripts/security/check-kernel-hardening.sh - Basic kernel hardening checks

set -eEuo pipefail
rc=0
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

check_sysctl() {
  local name="$1" expected="$2"
  local value
  if sysctl -n "$name" >/dev/null 2>&1; then
    value=$(sysctl -n "$name")
    if [ "$value" = "$expected" ]; then
      echo "OK: $name=$value"
    else
      echo "WARN: $name=$value (expected $expected)"
    fi
  else
    echo "MISSING: $name (sysctl not available)"
  fi
}

if ! command -v sysctl >/dev/null 2>&1; then
  echo "sysctl not available on this system; skipping kernel hardening checks" >&2
  exit 0
fi

echo "Checking kernel hardening settings (informational)..."
check_sysctl kernel.randomize_va_space 2
check_sysctl kernel.kptr_restrict 1
check_sysctl kernel.dmesg_restrict 1
check_sysctl fs.protected_regular 1
check_sysctl fs.protected_fifos 1
check_sysctl kernel.unprivileged_bpf_disabled 1 || true
check_sysctl kernel.yama.ptrace_scope 1 || true

# AppArmor/enabled
if command -v aa-status >/dev/null 2>&1; then
  aa-status --quiet && echo "AppArmor: enabled" || echo "AppArmor: present but not fully enabled"
else
  echo "AppArmor: not installed or aa-status missing"
fi

# SELinux
if command -v getenforce >/dev/null 2>&1; then
  getenforce && echo "SELinux: active" || echo "SELinux: not active"
else
  echo "SELinux: not present (getenforce missing)"
fi

echo "Kernel hardening checks complete (informational)."