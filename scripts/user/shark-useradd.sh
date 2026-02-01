#!/usr/bin/env bash
# shark-useradd.sh - Thêm user mới cho Shark OS (an toàn, kiểm tra input, log)
# Usage: shark-useradd.sh <username> [--group <group>] [--shell <shell>] [--home <dir>]

set -euo pipefail
LOG_FILE="/var/log/shark/user_mgmt.log"

usage() {
  echo "Usage: $0 <username> [--group <group>] [--shell <shell>] [--home <dir>]"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  usage
fi

USERNAME=""
GROUP=""
SHELL="/bin/sh"
HOME_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --group)
      GROUP="$2"; shift 2;;
    --shell)
      SHELL="$2"; shift 2;;
    --home)
      HOME_DIR="$2"; shift 2;;
    -h|--help)
      usage;;
    *)
      if [[ -z "$USERNAME" ]]; then
        USERNAME="$1"; shift
      else
        usage
      fi
      ;;
  esac
done

# Validate username
if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
  echo "Invalid username: $USERNAME" >&2
  exit 2
fi

# Check if user exists
if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists" >&2
  exit 3
fi

# Create group if specified and not exists
if [[ -n "$GROUP" ]]; then
  if ! getent group "$GROUP" >/dev/null; then
    groupadd "$GROUP"
    echo "[$(date)] Created group $GROUP" >> "$LOG_FILE"
  fi
  GROUP_OPT="-g $GROUP"
else
  GROUP_OPT=""
fi

# Set home dir
if [[ -n "$HOME_DIR" ]]; then
  HOME_OPT="-d $HOME_DIR"
else
  HOME_OPT=""
fi

# Add user
useradd $GROUP_OPT $HOME_OPT -s "$SHELL" "$USERNAME"
passwd -d "$USERNAME"  # Xóa password mặc định, yêu cầu đặt mới

# Log
mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] Created user $USERNAME (group: $GROUP, shell: $SHELL, home: $HOME_DIR)" >> "$LOG_FILE"

echo "User $USERNAME created. Please set password with: passwd $USERNAME"
