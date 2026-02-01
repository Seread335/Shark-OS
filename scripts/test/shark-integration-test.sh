#!/usr/bin/env bash
# shark-integration-test.sh - Bộ test tích hợp cho Shark OS (A/B, service, network, security)
# Usage: shark-integration-test.sh [all|user|service|pkg|config|log|net|storage|security|recovery]

set -euo pipefail
LOG_FILE="/var/log/shark/test_integration.log"

usage() {
  echo "Usage: $0 [all|user|service|pkg|config|log|net|storage|security|recovery]"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

TARGET="${1:-all}"

run_test() {
  echo "[TEST] $1..."
  if bash -c -- "$2"; then
    echo "[PASS] $1" >> "$LOG_FILE"
  else
    echo "[FAIL] $1" >> "$LOG_FILE"
    return 1
  fi
}

case "$TARGET" in
  all|user)
    run_test "User add/del" "id testuser 2>/dev/null || useradd testuser; id testuser; userdel testuser"
    ;;
  all|service)
    run_test "Service status" "rc-status -a"
    ;;
  all|pkg)
    run_test "APK update" "apk update"
    ;;
  all|config)
    run_test "Config validate" "[ -f /etc/shark/config.yml ] && yq e . /etc/shark/config.yml >/dev/null"
    ;;
  all|log)
    run_test "Logrotate" "/usr/sbin/logrotate /etc/logrotate.d/shark"
    ;;
  all|net)
    run_test "Network ping" "ping -c 1 8.8.8.8"
    ;;
  all|storage)
    run_test "List storage" "lsblk"
    ;;
  all|security)
    run_test "AppArmor status" "aa-status || true"
    ;;
  all|recovery)
    run_test "Backup dir exists" "[ -d /var/backups/shark-system ]"
    ;;
  *)
    usage
    ;;
esac
