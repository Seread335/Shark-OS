#!/usr/bin/env bash
# shark-net.sh - Quản lý mạng cho Shark OS (server-oriented)
# Usage: shark-net.sh <list|set|test|reload> [options]

set -euo pipefail
LOG_FILE="/var/log/shark/net_mgmt.log"

usage() {
  echo "Usage: $0 <list|set|test|reload> [options]"
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

case "$ACTION" in
  list)
    ip addr show
    ip route show
    ;;
  set)
    IFACE="$1"; ADDR="$2"; MASK="$3"; GW="$4"
    ip addr flush dev "$IFACE"
    ip addr add "$ADDR/$MASK" dev "$IFACE"
    ip route add default via "$GW" dev "$IFACE"
    echo "[$(date)] set $IFACE $ADDR/$MASK gw $GW" >> "$LOG_FILE"
    ;;
  test)
    TARGET="${1:-8.8.8.8}"
    ping -c 4 "$TARGET"
    ;;
  reload)
    if command -v rc-service &>/dev/null; then
      rc-service networking restart
    else
      /etc/init.d/networking restart
    fi
    echo "[$(date)] reload networking" >> "$LOG_FILE"
    ;;
  *)
    usage
    ;;
esac
