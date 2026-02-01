#!/usr/bin/env bash
# shark-userdel.sh - Xóa user khỏi Shark OS (an toàn, log, xác nhận)
# Usage: shark-userdel.sh <username>

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

read -p "Are you sure you want to delete user $USERNAME? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

userdel -r "$USERNAME"

mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] Deleted user $USERNAME" >> "$LOG_FILE"

echo "User $USERNAME deleted."
