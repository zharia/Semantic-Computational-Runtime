#!/usr/bin/env bash
# check_layout.sh — verify applications/godot workspace layout per
# program_increments/v0.0.1/milestone_0001_project-initiation/spec.md §2.3,
# plus the milestone_0002 layout amendment (provider tree) and the Sprint-03
# gates (AP-1 engine isolation, AP-4 absolute-path ban) plus the
# milestone_0004 AP-15 wall-clock gate on the weather/atmosphere sim sources.
#
# Exit 0: all required paths present and all gates clean.
# Exit 1: one or more violations (clear message per violation).

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
  # --- milestone_0002 layout amendment: provider tree (spec §5) -------------
  "providers/render/graphics/godot/101_definition.md"
  "providers/render/graphics/godot/102_status.yaml"
  "providers/render/graphics/godot/103_provider.graph.json"
  "providers/render/graphics/godot/104_contract.md"
  "providers/render/graphics/godot/adapter/scr_godot_abi.h"
  "providers/render/graphics/godot/adapter/scr_sim_loader.h"
  "providers/render/graphics/godot/adapter/scr_godot_adapter.cpp"
  "providers/render/graphics/godot/adapter/SConstruct"
  # --- Sprint 03 deliverables ----------------------------------------------
  "godot/addons/scr_godot/scr_godot.gdextension"
  "godot/addons/scr_godot/plugin.cfg"
  "scripts/build_godot_provider.sh"
  "tests/test_schema_mismatch.sh"
  "tests/schema_mismatch_test.c"
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

# ---------------------------------------------------------------------------
# Gate 1 (AP-1 / spec §6 invariant 4): no engine types in the semantic layer.
# Strip Mojo '#' comments, then grep remaining CODE for engine tokens.
# Allowed (unavoidable CLI strings): src/mojo/main.mojo only — reported, not
# failed. Everything else must be zero.
# ---------------------------------------------------------------------------
gate1_fail=0
while IFS= read -r mojo_file; do
  rel="${mojo_file#"${ROOT}"/}"
  hits="$(sed 's/#.*$//' "${mojo_file}" \
          | grep -inE 'godot|gdscript|@onready' || true)"
  if [[ -z "${hits}" ]]; then
    continue
  fi
  if [[ "${rel}" == "src/mojo/main.mojo" ]]; then
    count="$(printf '%s\n' "${hits}" | wc -l)"
    echo "AP-1 gate: ${count} allowed main.mojo CLI-help string match(es):"
    printf '%s\n' "${hits}" | sed 's/^/    /'
    continue
  fi
  echo "AP-1 gate VIOLATION: engine token in ${rel} code (comments stripped):" >&2
  printf '%s\n' "${hits}" >&2
  gate1_fail=1
done < <(grep -rl --include='*.mojo' '' "${ROOT}/src/mojo" 2>/dev/null || true)

if [[ "${gate1_fail}" -ne 0 ]]; then
  echo "FAIL — AP-1: engine types found in src/mojo/ (semantic layer must be engine-free)." >&2
  exit 1
fi
echo "PASS — AP-1 gate: zero engine-type code matches in src/mojo/ (comments stripped)."

# ---------------------------------------------------------------------------
# Gate 2 (AP-4 / spec §6 invariant 6): no absolute filesystem paths in
# sources: src/, godot/, providers/ (build outputs and engine caches skipped).
# ---------------------------------------------------------------------------
abs_hits="$(grep -rnI '/home/' \
    "${ROOT}/src" "${ROOT}/godot" "${ROOT}/providers" \
    --exclude-dir=.deps --exclude-dir=.godot --exclude-dir=bin \
    --exclude='*.so' --exclude='*.bin' 2>/dev/null || true)"
if [[ -n "${abs_hits}" ]]; then
  echo "AP-4 gate VIOLATION: absolute /home/ path(s) in sources:" >&2
  printf '%s\n' "${abs_hits}" >&2
  echo "FAIL — AP-4: zero absolute paths required (spec §6 invariant 6)." >&2
  exit 1
fi
echo "PASS — AP-4 gate: no /home/ absolute paths under src/, godot/, providers/."

# ---------------------------------------------------------------------------
# Gate 3 (AP-15 / milestone_0004 §1.1): simulation determinism — sim sources
# must not consume wall-clock/engine-time. Scope: the weather machine and the
# atmosphere/world/parameters units it feeds (all sim inputs are seed + tick
# + fixed dt). Strip '#' comments first, then grep CODE for clock tokens.
# ---------------------------------------------------------------------------
ap15_scope=(
  "${ROOT}/src/mojo/weather"
  "${ROOT}/src/mojo/sim/subjects.mojo"
  "${ROOT}/src/mojo/sim/world.mojo"
  "${ROOT}/src/mojo/sim/parameters.mojo"
)
ap15_fail=0
for target in "${ap15_scope[@]}"; do
  [[ -e "${target}" ]] || continue
  if [[ -d "${target}" ]]; then
    mapfile -t ap15_files < <(grep -rl --include='*.mojo' '' "${target}" 2>/dev/null || true)
  else
    ap15_files=("${target}")
  fi
  for mojo_file in "${ap15_files[@]}"; do
    [[ -f "${mojo_file}" ]] || continue
    rel="${mojo_file#"${ROOT}"/}"
    hits="$(sed 's/#.*$//' "${mojo_file}" \
            | grep -inE 'wall_clock|unix_time|Time\.get_|OS\.get_|get_ticks|datetime|Date\.' || true)"
    if [[ -n "${hits}" ]]; then
      echo "AP-15 gate VIOLATION: wall-clock token in ${rel} code (comments stripped):" >&2
      printf '%s\n' "${hits}" >&2
      ap15_fail=1
    fi
  done
done

if [[ "${ap15_fail}" -ne 0 ]]; then
  echo "FAIL — AP-15: wall-clock/engine-time tokens found in sim sources (seed+tick+dt only)." >&2
  exit 1
fi
echo "PASS — AP-15 gate: zero wall-clock tokens in weather/atmosphere/world sim sources (comments stripped)."

echo "PASS — layout + Sprint-03 gates."
exit 0
