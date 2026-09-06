#!/usr/bin/env bash
# check-ir-terminology.sh
# Scans normative docs for prohibited IR terminology per AGENTS.md §19.
# Exit 0 = clean, 1 = violations found.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Skip list: these basenames are always excluded
declare -A SKIP_FILES=(
  ["103_ir-clarification.md"]=1
  ["102_normalisation.md"]=1
)

VIOLATIONS=0
declare -A FILE_COUNT

scan_file() {
  local file="$1"
  local base
  base="$(basename "$file")"
  [[ -n "${SKIP_FILES[$base]:-}" ]] && return

  local hits
  hits=$(grep -n 'SCR IR\|Semantic IR\|Domain IR\|Custom IR' "$file" 2>/dev/null || true)
  [[ -z "$hits" ]] && return

  while IFS= read -r hitline; do
    local lineno="${hitline%%:*}"
    local content="${hitline#*:}"

    local is_violation=0

    # Each prohibited term checked independently.
    # "SCR Semantic MLIR" and "Semantic MLIR" are CORRECT → only suppress
    # the specific "SCR IR" / "Semantic IR" matches, not other terms.

    if echo "$content" | grep -q 'SCR Semantic MLIR'; then
      :  # "SCR Semantic MLIR" correct — do NOT flag "SCR IR" from this match
    elif echo "$content" | grep -q 'SCR IR'; then
      is_violation=1
    fi

    if echo "$content" | grep -q 'Semantic MLIR'; then
      :  # "Semantic MLIR" correct — do NOT flag "Semantic IR" from this match
    elif echo "$content" | grep -q 'Semantic IR'; then
      is_violation=1
    fi

    echo "$content" | grep -q 'Domain IR' && is_violation=1
    echo "$content" | grep -q 'Custom IR'  && is_violation=1

    if [[ "$is_violation" -eq 1 ]]; then
      echo "$file:$hitline"
      VIOLATIONS=$((VIOLATIONS + 1))
      FILE_COUNT["$file"]=$(( ${FILE_COUNT["$file"]:-0} + 1 ))
    fi
  done <<< "$hits"
}

# --- Collect .md files to scan ---
FILES=()

# Root-level .md files
while IFS= read -r f; do
  FILES+=("$f")
done < <(find "$REPO_ROOT" -maxdepth 1 -name '*.md' 2>/dev/null)

# lib/, docs/, public-documentation/ subtrees
for subdir in lib docs public-documentation; do
  if [ -d "$REPO_ROOT/$subdir" ]; then
    while IFS= read -r f; do
      FILES+=("$f")
    done < <(find "$REPO_ROOT/$subdir" -type f -name '*.md' 2>/dev/null)
  fi
done

# --- Scan ---
for file in "${FILES[@]}"; do
  scan_file "$file"
done

# --- Report ---
if [ "$VIOLATIONS" -gt 0 ]; then
  echo ""
  echo "=== SUMMARY ==="
  echo "Total violations: $VIOLATIONS"
  for f in "${!FILE_COUNT[@]}"; do
    relpath="${f#$REPO_ROOT/}"
    echo "  $relpath: ${FILE_COUNT[$f]}"
  done
  exit 1
else
  echo "No prohibited IR terminology found."
  exit 0
fi
