#!/usr/bin/env bash
# scripts/security/check-apparmor.sh - Validate AppArmor profiles are syntactically OK and (optionally) loadable

set -eEuo pipefail
rc=0
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
PROFILES=(
  "$REPO_ROOT/overlays/base/etc/apparmor.d/k3s"
  "$REPO_ROOT/overlays/base/etc/apparmor.d/podman"
)

echo "Checking AppArmor profiles..."

if ! command -v apparmor_parser >/dev/null 2>&1; then
  echo "apparmor_parser not found. Skipping load checks. Install 'apparmor'/'apparmor-utils' to run tests." >&2
  for p in "${PROFILES[@]}"; do
    if [ -f "$p" ]; then
      echo " OK: $p exists"
    else
      echo " MISSING: $p" >&2
    fi
  done
  echo "Note: AppArmor not available on this runner; skipping full load checks." >&2
  exit 0
fi

# If apparmor_parser exists, test load each profile in complain mode (safe)
failed=0
for p in "${PROFILES[@]}"; do
  if [ ! -f "$p" ]; then
    echo "MISSING: $p" >&2
    failed=1
    continue
  fi
  echo "Testing profile: $p"
  if sudo apparmor_parser -r --complain "$p"; then
    echo "Loaded (complain mode): $p"
  else
    echo "Initial load failed for $p; attempting --subdomainfs fallbacks..."
    tried=0
    for candidate in /sys/fs/apparmor /sys/kernel/security/apparmor /proc/sys/kernel/security; do
      if [ -d "$candidate" ]; then
        tried=1
        echo "Trying --subdomainfs $candidate"
        if sudo apparmor_parser -r --complain --subdomainfs "$candidate" "$p"; then
          echo "Loaded with --subdomainfs $candidate: $p"
          break
        else
          echo "Failed with --subdomainfs $candidate"
        fi
      fi
    done
    if [ "$tried" -eq 0 ]; then
      echo "No candidate subdomainfs paths found; profile load failed: $p" >&2
      failed=1
    else
      # If the last attempt did not succeed, mark failure
      if ! sudo apparmor_parser -T -r --complain "$p" >/dev/null 2>&1; then
        echo "All attempts failed for $p" >&2
        failed=1
      fi
    fi
  fi

  # Heuristic: find first 'profile' line to extract profile name
  PROFILE_NAME=$(grep -m1 '^profile ' "$p" | awk '{print $2}') || PROFILE_NAME="(unknown)"
  echo "Profile name heuristic: $PROFILE_NAME"
done

if [ "$failed" -ne 0 ]; then
  echo "One or more AppArmor profiles failed to load or were missing." >&2
  echo "Please inspect the profiles and adjust rules; use complain mode until tuned." >&2
  exit 3
fi

echo "Done. If profiles loaded in complain mode, review logs and tune rules; then switch to enforce mode when ready."