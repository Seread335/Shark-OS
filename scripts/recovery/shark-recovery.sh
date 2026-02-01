#!/usr/bin/env bash
# shark-recovery.sh - Công cụ khôi phục hệ thống Shark OS (reset root, rescue, backup/restore)
# Usage: shark-recovery.sh <reset-root|rescue|backup|restore> [options]

set -euo pipefail
LOG_FILE="/var/log/shark/recovery_mgmt.log"
BACKUP_DIR="/var/backups/shark-system"

usage() {
  echo "Usage: $0 <reset-root|rescue|backup|restore> [options]"
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
  reset-root)
    echo "[INFO] Resetting root password..."
    passwd root
    echo "[$(date)] root password reset" >> "$LOG_FILE"
    ;;
  rescue)
    echo "[INFO] Entering rescue shell..."
    /bin/sh
    echo "[$(date)] rescue shell entered" >> "$LOG_FILE"
    ;;
  backup)
    mkdir -p "$BACKUP_DIR"
    tar czf "$BACKUP_DIR/system.$(date +%Y%m%d%H%M%S).tar.gz" /etc /var /home
    echo "[$(date)] system backup created" >> "$LOG_FILE"
    ;;
  restore)
    LATEST=$(ls -1t $BACKUP_DIR/system.*.tar.gz 2>/dev/null | head -n1)
    if [[ -z "$LATEST" ]]; then
      echo "No backup found in $BACKUP_DIR" >&2
      exit 2
    fi
    tar xzf "$LATEST" -C /
    echo "[$(date)] system restored from $LATEST" >> "$LOG_FILE"
    ;;
  *)
    usage
    ;;
esac
