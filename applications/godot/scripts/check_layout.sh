#!/usr/bin/env bash
# check_layout.sh — verify applications/godot workspace layout per
# program_increments/v0.0.1/milestone_0001_project-initiation/spec.md §2.3.
#
# Exit 0: all required directories and files present.
# Exit 1: one or more missing (clear message per missing path).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"   # applications/godot/

REQUIRED_PATHS=(
  "README.md"
  "docs"
  "docs/README.md"
  "docs/01_architecture.md"
  "docs/02_development_environment.md"
  "docs/03_coding_standards.md"
  "docs/04_simulation_engine.md"
  "docs/05_provider_boundary.md"
  "docs/06_roadmap.md"
  "src/mojo"
  "src/mojo/main.mojo"
  "godot"
  "godot/project.godot"
  "godot/main.tscn"
  "tests"
  "tests/mojo"
  "tests/godot"
  "scripts"
  "scripts/check_layout.sh"
  "program_increments/v0.0.1/milestone_0001_project-initiation/spec.md"
  ".gitignore"
  "LICENSE"
)

missing=0
for rel in "${REQUIRED_PATHS[@]}"; do
  if [[ ! -e "${ROOT}/${rel}" ]]; then
    echo "MISSING: ${rel}" >&2
    missing=$((missing + 1))
  fi
done

# Empty directories must carry a marker (.gitkeep or README.md)
for empty_ok in "src/mojo" "tests/mojo" "tests/godot" "scripts"; do
  dir="${ROOT}/${empty_ok}"
  if [[ -d "${dir}" ]]; then
    if [[ -z "$(ls -A "${dir}" 2>/dev/null | grep -v -e '^\.\.\?$' || true)" ]]; then
      echo "EMPTY (needs .gitkeep or README): ${empty_ok}" >&2
      missing=$((missing + 1))
    fi
  fi
done

if [[ "${missing}" -gt 0 ]]; then
  echo "FAIL — ${missing} required path(s) missing under applications/godot/." >&2
  exit 1
fi

echo "PASS — all required paths present under applications/godot/."
exit 0
