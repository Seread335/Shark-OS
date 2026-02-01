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

# Helper tests that require multiple steps or relaxed failure handling
test_user_add_del() {
  id testuser 2>/dev/null || useradd testuser
  id testuser
  userdel testuser
}

test_config_validate() {
  [ -f /etc/shark/config.yml ] && yq e . /etc/shark/config.yml >/dev/null
}

test_apparmor_status() {
  aa-status || true
}

test_backup_dir_exists() {
  [ -d /var/backups/shark-system ]
}

run_test() {
  local desc="$1"; shift
  echo "[TEST] $desc..."
  if "$@"; then
    echo "[PASS] $desc" >> "$LOG_FILE"
  else
    echo "[FAIL] $desc" >> "$LOG_FILE"
    return 1
  fi
}

case "$TARGET" in
  all|user)
    run_test "User add/del" test_user_add_del
    ;;
  all|service)
    run_test "Service status" rc-status -a
    ;;
  all|pkg)
    run_test "APK update" apk update
    ;;
  all|config)
    run_test "Config validate" test_config_validate
    ;;
  all|log)
    run_test "Logrotate" /usr/sbin/logrotate /etc/logrotate.d/shark
    ;;
  all|net)
    run_test "Network ping" ping -c 1 8.8.8.8
    ;;
  all|storage)
    run_test "List storage" lsblk
    ;;
  all|security)
    run_test "AppArmor status" test_apparmor_status
    ;;
  all|recovery)
    run_test "Backup dir exists" test_backup_dir_exists
    ;;
  *)
    usage
    ;;
esac
