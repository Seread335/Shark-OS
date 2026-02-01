#!/usr/bin/env bash
# scripts/security/collect-apparmor-denials.sh
# Run workloads (k3s/podman) on a runner with AppArmor enabled, collect denials and run aa-logprof suggestions

set -eEuo pipefail
rc=0
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${OUT_DIR:-$HERE/../../reports/apparmor}"; mkdir -p "$OUT_DIR"

echo "Collecting AppArmor denials and logs into $OUT_DIR"

# Put profiles into complain mode to collect denials safely
if command -v aa-complain >/dev/null 2>&1; then
  echo "Putting managed profiles into complain mode (k3s, podman, shark-cli)"
  sudo aa-complain /etc/apparmor.d/*k3s* || true
  sudo aa-complain /etc/apparmor.d/*podman* || true
  sudo aa-complain /etc/apparmor.d/*shark-cli* || true
else
  echo "aa-complain missing; ensure apparmor-utils installed." >&2
fi

# Exercise workloads
# 1) Start k3s (if available)
if command -v k3s >/dev/null 2>&1; then
  echo "Starting k3s (short run)..."
  sudo systemctl start k3s || sudo service k3s start || true
  sleep 5
  # perform a simple k3s check
  kubectl get nodes --no-headers -o wide >/dev/null 2>&1 || true
  # collect logs
  sudo journalctl -u k3s --no-pager -n 200 | sudo tee "$OUT_DIR/k3s-journal.log" > /dev/null || true
fi

# 2) Run a podman container that exercises common behavior
if command -v podman >/dev/null 2>&1; then
  echo "Running podman test container..."
  podman run --rm --name shark-apparmor-test alpine:3.18 /bin/sh -c "echo hello && sleep 1" || true
fi

# Gather dmesg and audit logs for AppArmor denials
sudo dmesg | grep -i apparmor | sudo tee "$OUT_DIR/dmesg-apparmor.log" > /dev/null || true
if command -v ausearch >/dev/null 2>&1; then
  sudo ausearch -m apparmor -ts recent | sudo tee "$OUT_DIR/ausearch-apparmor.log" > /dev/null || true
fi

# Run aa-logprof to suggest profile tweaks
if command -v aa-logprof >/dev/null 2>&1; then
  echo "Running aa-logprof in non-interactive mode to collect suggestions..."
  sudo aa-logprof -r >/dev/null 2>&1 || true
  sudo aa-logprof -q | sudo tee "$OUT_DIR/aa-logprof-out.txt" > /dev/null || true
else
  echo "aa-logprof not available on runner. Install apparmor-utils to use aa-logprof." >&2
fi

echo "Collected logs at: $OUT_DIR"
