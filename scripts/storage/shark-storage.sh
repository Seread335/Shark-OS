#!/usr/bin/env bash
# shark-storage.sh - Quản lý phân vùng & storage cho Shark OS (server-oriented)
# Usage: shark-storage.sh <list|add|remove|resize|snapshot|restore> [options]

set -euo pipefail
LOG_FILE="/var/log/shark/storage_mgmt.log"

usage() {
  echo "Usage: $0 <list|add|remove|resize|snapshot|restore> [options]"
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
    lsblk
    df -h
    ;;
  add)
    DEV="$1"; MOUNT="$2"
    mkfs.ext4 "$DEV"
    mkdir -p "$MOUNT"
    mount "$DEV" "$MOUNT"
    echo "$DEV $MOUNT ext4 defaults 0 2" >> /etc/fstab
    echo "[$(date)] add $DEV to $MOUNT" >> "$LOG_FILE"
    ;;
  remove)
    MOUNT="$1"
    umount "$MOUNT"
    sed -i "\| $MOUNT |d" /etc/fstab
    echo "[$(date)] remove $MOUNT" >> "$LOG_FILE"
    ;;
  resize)
    DEV="$1"; SIZE="$2"
    resize2fs "$DEV" "$SIZE"
    echo "[$(date)] resize $DEV to $SIZE" >> "$LOG_FILE"
    ;;
  snapshot)
    DEV="$1"; SNAP="/var/backups/shark-storage/$(basename $DEV).$(date +%Y%m%d%H%M%S).img"
    mkdir -p /var/backups/shark-storage
    dd if="$DEV" of="$SNAP" bs=1M status=progress
    echo "[$(date)] snapshot $DEV to $SNAP" >> "$LOG_FILE"
    ;;
  restore)
    DEV="$1"; SNAP="$2"
    dd if="$SNAP" of="$DEV" bs=1M status=progress
    echo "[$(date)] restore $DEV from $SNAP" >> "$LOG_FILE"
    ;;
  *)
    usage
    ;;
esac
