#!/usr/bin/env bash
# shark-harden.sh - Kiểm tra & hardening bảo mật cho Shark OS (server-oriented)
# Usage: shark-harden.sh <check|enforce|apparmor|kernel>

set -euo pipefail
LOG_FILE="/var/log/shark/security_mgmt.log"

usage() {
  echo "Usage: $0 <check|enforce|apparmor|kernel>"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  usage
fi

ACTION="$1"

case "$ACTION" in
  check)
    echo "[INFO] Checking security status..."
    aa-status || echo "AppArmor not installed"
    sysctl kernel.kptr_restrict
    sysctl kernel.dmesg_restrict
    sysctl kernel.randomize_va_space
    sysctl kernel.yama.ptrace_scope
    echo "[$(date)] security check run" >> "$LOG_FILE"
    ;;
  enforce)
    echo "[INFO] Enforcing security settings..."
    sysctl -w kernel.kptr_restrict=1
    sysctl -w kernel.dmesg_restrict=1
    sysctl -w kernel.randomize_va_space=2
    sysctl -w kernel.yama.ptrace_scope=1
    echo "[$(date)] security enforce run" >> "$LOG_FILE"
    ;;
  apparmor)
    echo "[INFO] Reloading all AppArmor profiles..."
    if command -v apparmor_parser &>/dev/null; then
      for f in /etc/apparmor.d/*; do
        apparmor_parser -r "$f"
      done
      echo "[$(date)] apparmor reload run" >> "$LOG_FILE"
    else
      echo "AppArmor not installed" >&2
      exit 2
    fi
    ;;
  kernel)
    echo "[INFO] Checking kernel hardening options..."
    grep CONFIG_FORTIFY_SOURCE /proc/config.gz || echo "No /proc/config.gz, check kernel config manually."
    grep CONFIG_SECURITY_APPARMOR /proc/config.gz || echo "No /proc/config.gz, check kernel config manually."
    echo "[$(date)] kernel hardening check run" >> "$LOG_FILE"
    ;;
  *)
    usage
    ;;
esac
