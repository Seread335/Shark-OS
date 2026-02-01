#!/usr/bin/env bash
# scripts/lib/common.sh - Common helpers for Shark OS scripts
# Usage: source this file near script top to import logging, strict-mode and helpers

set -eEuo pipefail
rc=0
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

# Logging helpers
log_info() { printf "\e[32m[*]\e[0m %s\n" "$*"; }
log_warn() { printf "\e[33m[!]\e[0m %s\n" "$*"; }
log_error() { printf "\e[31m[×]\e[0m %s\n" "$*"; }

# Run a command with logging; returns non-zero on failure
run_cmd() {
  log_info "Running: $*"
  "$@"
}

# Ensure directory exists
ensure_dir() {
  local d="$1"
  if [ -z "$d" ]; then return 0; fi
  mkdir -p -- "$d"
}

# Safe check for root
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log_error "This operation requires root privileges"
    return 1
  fi
  return 0
}

# Safe find all shell scripts in repo
find_scripts() {
  find . -name '*.sh' -type f -print0
}
