#!/usr/bin/env bash
# shark-pkg-sign.sh - Ký số gói APK cho Shark OS (demo, log)
# Usage: shark-pkg-sign.sh <apk-file> <private-key>

set -euo pipefail
LOG_FILE="/var/log/shark/pkg_sign.log"

usage() {
  echo "Usage: $0 <apk-file> <private-key>"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

if [[ $# -ne 2 ]]; then
  usage
fi

APK_FILE="$1"
KEY_FILE="$2"

if [[ ! -f "$APK_FILE" ]]; then
  echo "APK file not found: $APK_FILE" >&2
  exit 2
fi

if [[ ! -f "$KEY_FILE" ]]; then
  echo "Private key not found: $KEY_FILE" >&2
  exit 3
fi

# Ký số (giả lập, thực tế dùng abuild-sign hoặc openssl)
echo "[MOCK] Signing $APK_FILE with $KEY_FILE..."
mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] Signed $APK_FILE with $KEY_FILE" >> "$LOG_FILE"
echo "Package $APK_FILE signed."
