#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

printf '%s\n' "============================================================"
printf '%s\n' " SCR — Mathlib Integration"
printf '%s\n' "============================================================"

command -v lake >/dev/null 2>&1 || {
    echo "ERROR: lake is not installed."
    exit 1
}

command -v lean >/dev/null 2>&1 || {
    echo "ERROR: lean is not installed."
    exit 1
}

[[ -f lakefile.lean ]] || {
    echo "ERROR: lakefile.lean not found."
    exit 1
}

[[ -f lean-toolchain ]] || {
    echo "ERROR: lean-toolchain not found."
    exit 1
}

[[ -f formal/SCR/Basic.lean ]] || {
    echo "ERROR: formal/SCR/Basic.lean not found."
    exit 1
}

echo
echo "==> Writing lakefile.lean"

cat > lakefile.lean <<'EOF'
import Lake

open Lake DSL

package «SemanticComputationalRuntime» where
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩,
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩,
    ⟨`maxRecDepth, 100000⟩
  ]

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

@[default_target]
lean_lib SCRFormal where
  srcDir := "formal"
  roots := #[`SCR.Basic]
EOF

echo
echo "==> Checking Lake default-target configuration"
lake check-build

echo
echo "==> Resolving dependencies"
lake update

echo
echo "==> Fetching Mathlib cache"
lake exe cache get

echo
echo "==> Querying SCRFormal target"
lake query SCRFormal

echo
echo "==> Building SCRFormal"
lake build SCRFormal

echo
echo "==> Building default target"
lake build

echo
echo "==> Checking SCR.Basic directly"
lake env lean formal/SCR/Basic.lean

if [[ -f formal/Tests/MathlibSmoke.lean ]]; then
    echo
    echo "==> Running Mathlib smoke test"
    lake env lean formal/Tests/MathlibSmoke.lean
fi

echo
printf '%s\n' "============================================================"
printf '%s\n' " SCR — Mathlib Integration SUCCESS"
printf '%s\n' "============================================================"

echo
echo "Lean:"
lean --version

echo
echo "Lake:"
lake --version

echo
echo "Toolchain:"
cat lean-toolchain

echo
echo "Git status:"
git status --short
