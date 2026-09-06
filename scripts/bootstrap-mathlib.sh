#!/usr/bin/env bash
set -Eeuo pipefail

###############################################################################
# SCR — Mathlib / Lean Formal Substrate Bootstrap
#
# Purpose:
#   Integrate Lean 4 + Mathlib into the Semantic Computational Runtime
#   without contaminating the executable SCR runtime.
#
# Architectural boundary:
#
#   seed/       Semantic vocabulary / canonical definitions
#   formal/     Lean + Mathlib formal semantics and proofs
#   lib/        Executable SCR semantic libraries
#   compiler/   MLIR / lowering infrastructure
#   runtime/    Mojo / native runtime
#
# Mathlib is a BUILD-TIME / FORMAL dependency.
# It is NOT a runtime dependency.
###############################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

echo
echo "============================================================"
echo " SCR — Mathlib Integration"
echo "============================================================"
echo
echo "Repository: ${REPO_ROOT}"
echo

###############################################################################
# Configuration
###############################################################################

MATHLIB_URL="https://github.com/leanprover-community/mathlib4"

# We deliberately use the current Mathlib branch here.
#
# IMPORTANT:
#   lake update resolves the exact commit into lake-manifest.json.
#   The manifest MUST be committed to git.
#
# Future production releases may replace this with an explicit
# Mathlib tag once SCR establishes a compatibility baseline.
MATHLIB_REF="master"

FORMAL_DIR="formal"
FORMAL_SRC="${FORMAL_DIR}/SCR"

###############################################################################
# Preconditions
###############################################################################

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "ERROR: This script must be executed inside the SCR git repository."
    exit 1
fi

if [[ "$(git rev-parse --show-toplevel)" != "${REPO_ROOT}" ]]; then
    echo "ERROR: Repository root mismatch."
    exit 1
fi

###############################################################################
# Required tools
###############################################################################

for command in git curl; do
    if ! command -v "${command}" >/dev/null 2>&1; then
        echo "ERROR: Required command '${command}' is not installed."
        exit 1
    fi
done

###############################################################################
# Lean / Lake
###############################################################################

if ! command -v lake >/dev/null 2>&1; then
    echo
    echo "ERROR: 'lake' is not installed or not on PATH."
    echo
    echo "Install Lean 4 via elan, then restart your shell:"
    echo
    echo "  curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \\"
    echo "    -sSf | sh"
    echo
    exit 1
fi

if ! command -v lean >/dev/null 2>&1; then
    echo "ERROR: 'lean' is not installed or not on PATH."
    exit 1
fi

echo "Lean:"
lean --version
echo

echo "Lake:"
lake --version
echo

###############################################################################
# Repository structure
###############################################################################

echo "Creating SCR formalisation boundary..."

mkdir -p \
    "${FORMAL_SRC}/Field" \
    "${FORMAL_SRC}/Entity" \
    "${FORMAL_SRC}/Relation" \
    "${FORMAL_SRC}/Transformation" \
    "${FORMAL_SRC}/Context" \
    "${FORMAL_SRC}/Runtime" \
    "${FORMAL_SRC}/Laws" \
    "${FORMAL_SRC}/Proofs" \
    "${FORMAL_DIR}/Tests"

###############################################################################
# Prevent accidental mixing of formal and executable layers
###############################################################################

if [[ -d "formal/lib" ]]; then
    echo
    echo "ERROR: formal/lib exists."
    echo "The SCR formal layer must not duplicate executable lib/."
    exit 1
fi

###############################################################################
# Lake configuration
###############################################################################

LAKEFILE="lakefile.lean"

if [[ -f "${LAKEFILE}" ]]; then
    echo
    echo "Found existing ${LAKEFILE}."
    echo
    echo "The script will NOT overwrite it."
    echo
    echo "You must add the following dependency manually if it is not already"
    echo "present:"
    echo
    cat <<'EOF'
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"
EOF
    echo
    echo "Then rerun this script."
    exit 1
fi

if [[ -f "lakefile.toml" ]]; then
    echo
    echo "Found existing lakefile.toml."
    echo
    echo "SCR is being given a Lean formalisation boundary."
    echo "Converting the repository build configuration automatically would"
    echo "risk destroying existing Lake configuration."
    echo
    echo "Create/merge a lakefile.lean explicitly before rerunning."
    exit 1
fi

###############################################################################
# Create dedicated Lake project configuration
#
# The formal library is deliberately named SCRFormal.
# It does NOT represent the executable SCR library.
###############################################################################

echo "Creating ${LAKEFILE}..."

cat > "${LAKEFILE}" <<'EOF'
import Lake

open Lake DSL

package «SemanticComputationalRuntime» where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`maxRecDepth, 100000⟩
  ]

/-
  Mathlib is the formal mathematical substrate of SCR.

  It is intentionally a build-time dependency and MUST NOT become
  a runtime dependency of the executable SCR implementation.
-/
require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

@[default_target]
lean_lib SCRFormal where
  srcDir := "formal"
  roots := #[`SCR]

lean_lib SCRTests where
  srcDir := "formal/Tests"
EOF

###############################################################################
# Lean toolchain
###############################################################################

echo
echo "Synchronising Lean toolchain with Mathlib..."

TMP_TOOLCHAIN="$(mktemp)"

cleanup() {
    rm -f "${TMP_TOOLCHAIN}"
}
trap cleanup EXIT

if ! curl -fsSL \
    "https://raw.githubusercontent.com/leanprover-community/mathlib4/${MATHLIB_REF}/lean-toolchain" \
    -o "${TMP_TOOLCHAIN}"; then

    echo "ERROR: Unable to retrieve Mathlib's lean-toolchain."
    exit 1
fi

if [[ ! -s "${TMP_TOOLCHAIN}" ]]; then
    echo "ERROR: Retrieved lean-toolchain is empty."
    exit 1
fi

cp "${TMP_TOOLCHAIN}" lean-toolchain

echo
echo "SCR Lean toolchain:"
cat lean-toolchain
echo

###############################################################################
# Bootstrap Lake dependency graph
###############################################################################

echo "Resolving Lake dependencies..."

lake update

###############################################################################
# Fetch precompiled Mathlib artifacts
#
# This is strongly preferred over compiling all of Mathlib locally.
###############################################################################

echo
echo "Fetching precompiled Mathlib artifacts..."

lake exe cache get

###############################################################################
# Formal SCR root
###############################################################################

ROOT_FILE="${FORMAL_SRC}/Basic.lean"

if [[ ! -f "${ROOT_FILE}" ]]; then
    echo "Creating SCR formal root..."

    cat > "${ROOT_FILE}" <<'EOF'
/-
  Semantic Computational Runtime
  Formal Semantic Substrate

  This module is intentionally small.

  The formal SCR hierarchy grows outward from the Semantic Field.
  Concrete semantic structures should be introduced only when they
  are justified by the canonical SCR semantic model.
-/

import Mathlib

namespace SCR

/--
The formal namespace of the Semantic Computational Runtime.

This namespace is deliberately independent of the executable SCR
implementation.
-/
def version : String := "0.1.0"

end SCR
EOF
fi

###############################################################################
# Formal smoke test
###############################################################################

SMOKE_FILE="${FORMAL_DIR}/Tests/MathlibSmoke.lean"

cat > "${SMOKE_FILE}" <<'EOF'
import Mathlib

namespace SCR.Tests

/--
Basic theorem proving that the SCR formal layer can consume Mathlib.
-/
example : (1 : Nat) + 1 = 2 := by
  norm_num

/--
Basic algebraic theorem.
-/
example {α : Type} [AddMonoid α] (x : α) : 0 + x = x := by
  exact zero_add x

end SCR.Tests
EOF

###############################################################################
# Build
###############################################################################

echo
echo "============================================================"
echo " Building SCR formal substrate"
echo "============================================================"
echo

lake build

###############################################################################
# Explicit smoke-test build
###############################################################################

echo
echo "Building Mathlib smoke test..."

lake env lean "${SMOKE_FILE}"

###############################################################################
# Repository hygiene
###############################################################################

echo
echo "Checking generated files..."

if [[ -d ".lake" ]]; then
    echo "  .lake/ present — OK"
fi

if [[ -f "lake-manifest.json" ]]; then
    echo "  lake-manifest.json present — OK"
else
    echo
    echo "ERROR: lake-manifest.json was not generated."
    exit 1
fi

if [[ -f "lean-toolchain" ]]; then
    echo "  lean-toolchain present — OK"
else
    echo
    echo "ERROR: lean-toolchain missing."
    exit 1
fi

###############################################################################
# Git status
###############################################################################

echo
echo "============================================================"
echo " Integration complete"
echo "============================================================"
echo

echo "Files/directories established:"
echo
echo "  ${LAKEFILE}"
echo "  lean-toolchain"
echo "  lake-manifest.json"
echo "  ${FORMAL_SRC}/"
echo "  ${FORMAL_DIR}/Tests/MathlibSmoke.lean"
echo

echo "IMPORTANT:"
echo
echo "  Commit lake-manifest.json and lean-toolchain."
echo "  Do NOT commit .lake/."
echo
echo "Recommended verification:"
echo
echo "  lake build"
echo "  lake env lean formal/Tests/MathlibSmoke.lean"
echo
echo "Git status:"
echo

git status --short

echo
echo "Mathlib integration successful."
