#!/usr/bin/env bash
# shark-log-forward.sh - Forward log hệ thống Shark OS tới server tập trung (demo, server-oriented)
# Usage: shark-log-forward.sh <server:port>

set -euo pipefail
LOG_FILE="/var/log/shark/log_mgmt.log"

usage() {
  echo "Usage: $0 <server:port>"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

if [[ $# -ne 1 ]]; then
  usage
fi

SERVER="$1"

# Forward log (demo: tail và netcat, thực tế nên dùng syslog-ng/rsyslog/loki)
tail -F /var/log/messages | nc "$SERVER"

mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] log forwarded to $SERVER" >> "$LOG_FILE"
