#!/usr/bin/env bash
set -euo pipefail

# check-re-conformance.sh
# Verifies full 12-case conformance synchronization between:
# 1. Lean 4 Formal RE Specification (SCRFormal/SCR/REConformance.lean)
# 2. Mojo Reference Executor (runtime/Reference_Executor/.../test_formal_conformance_probe.mojo)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== [1/2] Verifying Lean 4 Formal RE Model & Proofs ==="
cd "${ROOT}/SCRFormal"
lake build SCR.REConformance
echo "✓ Lean formal model & 12 ground-truth theorems verified."

echo ""
echo "=== [2/2] Running Mojo Reference Executor Live Conformance Probe ==="
cd "${ROOT}/runtime/Reference_Executor/v0.0.1-0A-Reference_Executor_Mojo"
uv run mojo run -I src tests/test_formal_conformance_probe.mojo
echo "✓ Mojo Reference Executor matches formal model across all 12 cases."

echo ""
echo "=== RE SEMANTIC CONFORMANCE VERIFIED (12/12 CASES SYNCHRONIZED) ==="
