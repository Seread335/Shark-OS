#!/usr/bin/env bash
# shark-config.sh - Quản lý cấu hình hệ thống Shark OS (init, edit, validate, backup/restore)
# Usage: shark-config.sh <init|edit|validate|backup|restore> [options]

set -euo pipefail
CONFIG_FILE="/etc/shark/config.yml"
BACKUP_DIR="/var/backups/shark-config"
LOG_FILE="/var/log/shark/config_mgmt.log"

usage() {
  echo "Usage: $0 <init|edit|validate|backup|restore> [options]"
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
  init)
    if [[ -f "$CONFIG_FILE" ]]; then
      echo "Config file already exists: $CONFIG_FILE" >&2
      exit 2
    fi
    mkdir -p "$(dirname $CONFIG_FILE)"
    cat > "$CONFIG_FILE" <<EOF
# Shark OS config (YAML)
network:
  hostname: "shark-01"
  interfaces:
    eth0:
      address: 192.168.1.10
      netmask: 255.255.255.0
      gateway: 192.168.1.1
      dns:
        - 8.8.8.8
        - 8.8.4.4
EOF
    echo "Config initialized at $CONFIG_FILE"
    ;;
  edit)
    ${EDITOR:-vi} "$CONFIG_FILE"
    ;;
  validate)
    if ! command -v yq &>/dev/null; then
      echo "yq is required for validation. Please install yq." >&2
      exit 3
    fi
    yq e . "$CONFIG_FILE" >/dev/null || { echo "YAML syntax error in $CONFIG_FILE" >&2; exit 4; }
    echo "Config $CONFIG_FILE is valid."
    ;;
  backup)
    mkdir -p "$BACKUP_DIR"
    cp "$CONFIG_FILE" "$BACKUP_DIR/config.yml.$(date +%Y%m%d%H%M%S)"
    echo "Config backed up to $BACKUP_DIR"
    ;;
  restore)
    LATEST=$(ls -1t $BACKUP_DIR/config.yml.* 2>/dev/null | head -n1)
    if [[ -z "$LATEST" ]]; then
      echo "No backup found in $BACKUP_DIR" >&2
      exit 5
    fi
    cp "$LATEST" "$CONFIG_FILE"
    echo "Config restored from $LATEST"
    ;;
  *)
    usage
    ;;
esac

mkdir -p "$(dirname $LOG_FILE)"
echo "[$(date)] $ACTION config" >> "$LOG_FILE"
