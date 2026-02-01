#!/usr/bin/env bash
# scripts/ci/auto-fix-shellcheck.sh - heuristic auto-fixes for trivial ShellCheck issues
# WARNING: This is best-effort and only handles very safe transformations (quoting, shebang normalization, replace echo -e with printf)

set -eEuo pipefail
rc=0
trap 'rc=$?; echo "ERROR: ${BASH_SOURCE[0]} failed at line ${LINENO} with status ${rc}" >&2; exit ${rc}' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "Running heuristic auto-fixes (dry-run by default). Use --apply to write changes."
APPLY=0
if [ "${1:-}" = "--apply" ]; then
  APPLY=1
fi

# 1) Normalize shebangs to /usr/bin/env bash if missing or wrong
for f in $(find . -name '*.sh' -type f); do
  head -n1 "$f" | grep -q '#!' || continue
  if head -n1 "$f" | grep -q 'bash$' && ! head -n1 "$f" | grep -q '/usr/bin/env'; then
    echo "Normalize shebang in $f"
    if [ $APPLY -eq 1 ]; then
      sed -i '1s|^#!.*bash$|#!/usr/bin/env bash|' "$f"
    fi
  fi
done

# 2) Replace echo -e with printf where escape sequences are used
# Very conservative: only if "echo -e" present and not complex
while IFS= read -r -d '' f; do
  if grep -q "echo -e" "$f"; then
    echo "Found echo -e in $f"
    if [ $APPLY -eq 1 ]; then
      # naive replacement; still review changes
      sed -E -i "s/echo -e \\\"(.*)\\\"/printf '%b\\n' '\\\1'/g" "$f" || true
    fi
  fi
done < <(find . -name '*.sh' -type f -print0)

# 3) Add quotes to [ -z $VAR ] patterns (only simple cases)
while IFS= read -r -d '' f; do
  if grep -Eq "\[\s*-z\s+\$[A-Za-z0-9_]+\s*\]" "$f"; then
    echo "Found unquoted -z pattern in $f"
    if [ $APPLY -eq 1 ]; then
      # Replace patterns like: [ -z $VAR ] -> [ -z "$VAR" ] (simple cases)
      sed -E -i "s/\[\s*-z\s+\$([A-Za-z0-9_]+)\s*\]/[ -z \"\\$\1\" ]/g" "$f" || true
    fi
  fi
done < <(find . -name '*.sh' -type f -print0)
# 4) Quote simple unquoted variable tokens in argument lists (VERY conservative)
# Matches: space + $VAR + space or end-of-line. Avoid touching complex expressions, arrays, or parameter expansions.
while IFS= read -r -d '' f; do
  if grep -Eq "(^|[[:space:]])\$[A-Za-z0-9_]+($|[[:space:]])" "$f"; then
    echo "Found simple unquoted var tokens in $f"
    if [ $APPLY -eq 1 ]; then
      # Add spaces around line to ensure pattern match; replace ' $VAR ' -> ' "$VAR" '
      sed -E -i "s/([[:space:]])\$([A-Za-z0-9_]+)([[:space:]])/ \"\\$\\2\" /g" "$f" || true
      # Also handle EOL case: ' $VAR$' -> ' "$VAR"'
      sed -E -i "s/([[:space:]])\$([A-Za-z0-9_]+)\$/ \"\\$\\2\"/g" "$f" || true
    fi
  fi
done < <(find . -name '*.sh' -type f -print0)
# Warn user to run shellcheck and review diffs
if [ $APPLY -eq 1 ]; then
  echo "Applied heuristic fixes. Please run 'git diff' and 'bash scripts/ci/run-shellcheck.sh' to confirm fixes." 
else
  echo "Dry-run complete. Re-run with --apply to write changes (review outputs first)."
fi
