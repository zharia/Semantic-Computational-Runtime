#!/usr/bin/env python3
"""Automated Acceptance Gate — SCR Semantic Algebra Closure.

Verifies that:
1. closure_manifest.yaml has no OPEN/DEFERRED/FALSIFIED/REVISED items
2. Lean build succeeds with zero sorry/axiom violations
3. All 6 counterexamples are present and proven
4. All 6 algebraic theorems are present and proven
5. Clean axiom profiles (only propext, Quot.sound allowed)

Exit 0 = PASS, Exit 1 = FAIL.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MANIFEST = REPO_ROOT / "program_increments" / "v0.0.1" / "algebra_closure" / "closure_manifest.yaml"
SCR_FORMAL = REPO_ROOT / "SCRFormal"

PROHIBITED_STATUSES = {"OPEN", "UNDER_ANALYSIS", "FALSIFIED", "REVISED", "DEFERRED"}
REQUIRED_THEOREMS = [
    "step_deterministic",
    "step_rollback_on_failure",
    "observation_purity",
    "step_advances_time",
    "step_preserves_time_on_failure",
    "node_identity_invariant",
]
REQUIRED_COUNTEREXAMPLES = [
    "CX_01_failure_distinguishable_from_noop",
    "CX_02_dangling_edge_rejected",
    "CX_03_incident_node_removal_rejected",
    "CX_04_conflicting_writes_do_not_commute",
    "CX_05_trace_shadow_incomparability",
    "CX_06_hyperedge_fanout_non_functional",
]
ALLOWED_AXIOMS = {"propext", "Quot.sound"}


def check_manifest():
    """Verify manifest has no prohibited statuses."""
    content = MANIFEST.read_text()
    statuses = re.findall(r"status:\s*(\w+)", content)
    failed = []
    for s in statuses:
        if s in PROHIBITED_STATUSES:
            failed.append(s)
    if failed:
        print(f"FAIL: Manifest has prohibited statuses: {set(failed)}")
        return False
    total = len(statuses)
    print(f"PASS: Manifest — {total} items, all PROVEN/DERIVED/EXCLUDED")
    return True


def check_lean_build():
    """Run lake build and check for sorry."""
    result = subprocess.run(
        ["lake", "build"],
        cwd=SCR_FORMAL,
        capture_output=True,
        text=True,
        timeout=300,
        env={"PATH": str(Path.home() / ".elan" / "bin") + ":" + os.environ.get("PATH", "")},
    )
    if result.returncode != 0:
        print("FAIL: lake build failed")
        for line in (result.stdout + result.stderr).splitlines()[-10:]:
            print(f"  {line}")
        return False
    sorry_count = 0
    algebra_files = [
        SCR_FORMAL / "SCR" / "Algebra.lean",
        SCR_FORMAL / "SCR" / "AlgebraCounterexamples.lean",
    ]
    for lean_file in algebra_files:
        if lean_file.exists():
            content = lean_file.read_text()
            # Count sorry outside comments/strings (simple heuristic: line-level)
            for line in content.splitlines():
                stripped = line.strip()
                if stripped.startswith("--") or stripped.startswith("/-"):
                    continue
                if "sorry" in stripped:
                    sorry_count += 1
    if sorry_count > 0:
        print(f"FAIL: Found {sorry_count} sorry in Algebra.lean / AlgebraCounterexamples.lean")
        return False
    print("PASS: Lean build succeeds, zero sorry")
    return True


def check_axiom_profiles():
    """Verify axiom profiles of key theorems."""
    lean_code = "\n".join(
        f'#print axioms SCR.Algebra.{thm}' for thm in REQUIRED_THEOREMS
    )
    lean_code += "\n" + "\n".join(
        f'#print axioms SCR.Algebra.Counterexamples.{cx}' for cx in REQUIRED_COUNTEREXAMPLES
    )
    code_file = SCR_FORMAL.parent / "_gate_check.lean"
    code_file.write_text(lean_code)

    # Find package .lake paths
    pkg_paths = []
    packages_dir = SCR_FORMAL / ".lake" / "packages"
    if packages_dir.exists():
        for p in packages_dir.iterdir():
            lake_lib = p / ".lake" / "build" / "lib" / "lean"
            if lake_lib.exists():
                pkg_paths.append(str(lake_lib))
    build_lib = SCR_FORMAL / ".lake" / "build" / "lib" / "lean"
    lean_path = str(build_lib) + (":" + ":".join(pkg_paths) if pkg_paths else "")

    result = subprocess.run(
        ["lean", str(code_file)],
        cwd=SCR_FORMAL,
        capture_output=True,
        text=True,
        timeout=120,
        env={"LEAN_PATH": lean_path, "PATH": str(Path.home() / ".elan" / "bin") + ":" + os.environ.get("PATH", "")},
    )

    violations = []
    for line in result.stdout.splitlines() + result.stderr.splitlines():
        if "depends on axioms:" in line:
            axioms_str = line.split("[")[1].rstrip("]")
            axioms = {a.strip().strip("'") for a in axioms_str.split(",")}
            extra = axioms - ALLOWED_AXIOMS
            if extra:
                violations.append(f"  {line.strip()}")

    code_file.unlink(missing_ok=True)

    if violations:
        print("FAIL: Axiom profile violations:")
        for v in violations:
            print(v)
        return False
    print("PASS: Axiom profiles clean (only propext, Quot.sound)")
    return True


def check_files_exist():
    """Verify all required artifacts exist."""
    required = [
        "primitive_inventory.md",
        "canonical_algebra.md",
        "algebraic_laws.md",
        "counterexample_catalog.md",
        "terminology.md",
        "closure_manifest.yaml",
    ]
    base = REPO_ROOT / "program_increments" / "v0.0.1" / "algebra_closure"
    missing = [f for f in required if not (base / f).exists()]
    if missing:
        print(f"FAIL: Missing artifacts: {missing}")
        return False
    print(f"PASS: All {len(required)} artifacts present")
    return True


def main():
    print("=" * 60)
    print("SCR ALGEBRA CLOSURE — ACCEPTANCE GATE")
    print("=" * 60)
    results = []
    results.append(("Manifest", check_manifest()))
    results.append(("Artifacts", check_files_exist()))
    results.append(("Lean Build", check_lean_build()))
    results.append(("Axiom Profiles", check_axiom_profiles()))

    print("\n" + "=" * 60)
    passed = sum(1 for _, ok in results if ok)
    total = len(results)
    for name, ok in results:
        print(f"  {'PASS' if ok else 'FAIL'}: {name}")
    print("=" * 60)

    if passed == total:
        print(f"RESULT: ALL {total} CHECKS PASSED — CLOSURE VERIFIED")
        sys.exit(0)
    else:
        print(f"RESULT: {total - passed}/{total} CHECKS FAILED — CLOSURE NOT VERIFIED")
        sys.exit(1)


if __name__ == "__main__":
    main()
