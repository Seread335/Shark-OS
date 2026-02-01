#!/usr/bin/env bash
# scripts/maintenance/clean-build.sh - Clean build artifacts and temp dirs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -f "$ROOT_DIR/scripts/lib/common.sh" ]; then
    # shellcheck disable=SC1090
    source "$ROOT_DIR/scripts/lib/common.sh"
else
    set -eEuo pipefail
    trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR
    log_info() { echo "[*] $*"; }
fi

log_info "Cleaning dist, build and temporary directories..."
rm -rf dist/ || true
rm -rf /tmp/shark-build || true
rm -rf build/ || true
log_info "Cleaning complete. (Note: does not remove source files)"