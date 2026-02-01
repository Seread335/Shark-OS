#!/usr/bin/env bash
# scripts/ci/run-shellcheck.sh - Run ShellCheck locally or via Docker fallback

# Source common helper if available for consistent logging
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    # shellcheck disable=SC1090
    source "$SCRIPT_DIR/../lib/common.sh"
else
    set -eEuo pipefail
    rc=0
    trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR
    log_info() { echo "[*] $*"; }
    log_error() { echo "[!] $*"; }
fi

run_shellcheck() {
  if command -v shellcheck >/dev/null 2>&1; then
    echo "Using local shellcheck"
    find . -name '*.sh' -type f -print0 | xargs -0 shellcheck -x --external-sources --format=gcc
  elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo "Using Docker shellcheck image"
    docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck:stable sh -c "find /mnt -name '*.sh' -type f -print0 | xargs -0 shellcheck --external-sources --format=gcc"
  else
    echo "ShellCheck not installed and Docker daemon not available." >&2
    echo "To install ShellCheck locally, try:" >&2
    echo "  - Debian/Ubuntu: sudo apt-get update && sudo apt-get install -y shellcheck" >&2
    echo "  - macOS: brew install shellcheck" >&2
    echo "  - Windows: scoop install shellcheck  (or use Docker)" >&2
    echo "Or run via Docker (if daemon available):" >&2
    echo "  docker run --rm -v \"${PWD}:/mnt\" koalaman/shellcheck:stable sh -c \"find /mnt -name '*.sh' -type f -print0 | xargs -0 shellcheck --external-sources --format=gcc\"" >&2
    exit 2
  fi
}

echo "Running shellcheck (with fallback)..."
run_shellcheck
