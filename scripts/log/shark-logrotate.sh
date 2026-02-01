#!/usr/bin/env bash
# shark-logrotate.sh - Quản lý logrotate cho Shark OS (server-oriented)
# Usage: shark-logrotate.sh [--force]

set -euo pipefail
LOG_DIR="/var/log"
CONF_FILE="/etc/logrotate.d/shark"
LOG_FILE="/var/log/shark/log_mgmt.log"

usage() {
  echo "Usage: $0 [--force]"
  exit 1
}

FORCE=false
if [[ $# -gt 0 ]]; then
  [[ "$1" == "--force" ]] && FORCE=true || usage
fi

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

# Tạo file cấu hình logrotate nếu chưa có
if [[ ! -f "$CONF_FILE" ]]; then
  mkdir -p "$(dirname $CONF_FILE)"
  cat > "$CONF_FILE" <<EOF
/var/log/shark/*.log {
  daily
  rotate 14
  compress
  missingok
  notifempty
  create 0640 root root
}
EOF
fi

if $FORCE; then
  logrotate -f "$CONF_FILE"
else
  logrotate "$CONF_FILE"
fi

mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] logrotate run (force=$FORCE)" >> "$LOG_FILE"
