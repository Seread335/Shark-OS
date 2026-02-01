#!/usr/bin/env bash
# shark-service.sh - Quản lý dịch vụ OpenRC cho Shark OS (server-oriented)
# Usage: shark-service.sh <start|stop|restart|status|enable|disable|list> <service>

set -euo pipefail
LOG_FILE="/var/log/shark/service_mgmt.log"

usage() {
  echo "Usage: $0 <start|stop|restart|status|enable|disable|list> <service>"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root" >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  usage
fi

ACTION="$1"; shift || true
SERVICE="${1:-}"

case "$ACTION" in
  list)
    rc-status -a
    exit 0
    ;;
  start|stop|restart|status|enable|disable)
    if [[ -z "$SERVICE" ]]; then usage; fi
    ;;
  *)
    usage
    ;;
esac

case "$ACTION" in
  start)
    rc-service "$SERVICE" start
    ;;
  stop)
    rc-service "$SERVICE" stop
    ;;
  restart)
    rc-service "$SERVICE" restart
    ;;
  status)
    rc-service "$SERVICE" status
    ;;
  enable)
    rc-update add "$SERVICE"
    ;;
  disable)
    rc-update del "$SERVICE"
    ;;
esac

mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] $ACTION $SERVICE" >> "$LOG_FILE"
