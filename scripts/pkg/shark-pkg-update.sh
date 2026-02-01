#!/usr/bin/env bash
# shark-pkg-update.sh - Cập nhật hệ thống Shark OS (A/B, kiểm tra, log, integrity)
# Usage: shark-pkg-update.sh [--check] [--apply]

set -euo pipefail
LOG_FILE="/var/log/shark/pkg_update.log"

usage() {
  echo "Usage: $0 [--check] [--apply]"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

CHECK_ONLY=false
APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=true; shift;;
    --apply) APPLY=true; shift;;
    -h|--help) usage;;
    *) usage;;
  esac
done

# Kiểm tra update
if $CHECK_ONLY; then
  echo "[INFO] Checking for updates..."
  apk update
  apk version -l '<'
  exit 0
fi

# Áp dụng update (A/B logic)
if $APPLY; then
  echo "[INFO] Applying system update (A/B partition)..."
  # Giả lập: mount root B, apk upgrade, kiểm tra integrity, switch boot flag
  # (Cần script thực tế cho A/B, đây là khung mẫu)
  echo "[MOCK] Mounting root B partition..."
  echo "[MOCK] Upgrading packages on root B..."
  echo "[MOCK] Verifying integrity..."
  echo "[MOCK] Switching boot flag to root B..."
  echo "[MOCK] Update complete. Please reboot to apply."
  mkdir -p "$(dirname $LOG_FILE)"
  echo "[$(date)] System update applied (A/B)" >> "$LOG_FILE"
  exit 0
fi

usage
