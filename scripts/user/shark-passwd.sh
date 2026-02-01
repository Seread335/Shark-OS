#!/usr/bin/env bash
# shark-passwd.sh - Đặt lại mật khẩu cho user trên Shark OS (an toàn, log)
# Usage: shark-passwd.sh <username>

set -euo pipefail
LOG_FILE="/var/log/shark/user_mgmt.log"

usage() {
  echo "Usage: $0 <username>"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  usage
fi

USERNAME="$1"

# Validate username
if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
  echo "Invalid username: $USERNAME" >&2
  exit 2
fi

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME does not exist" >&2
  exit 3
fi

passwd "$USERNAME"

mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] Password changed for $USERNAME" >> "$LOG_FILE"

echo "Password updated for $USERNAME."
