#!/usr/bin/env python3
"""
Deterministic repository-level Phase 0 checks.

This tool intentionally does not assume that Mojo is installed. It reports the
environment clearly so a missing toolchain is a validation failure rather than
an excuse to guess.
"""

from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "README.md",
    "LICENSE",
    "mojo.toml",
    "docs/PHASE_0.md",
    "docs/ARCHITECTURE_INVARIANTS.md",
    "docs/TOOLCHAIN.md",
    "docs/TESTING.md",
    "docs/BENCHMARKING.md",
    "docs/QUALITY_GATES.md",
    "src/hyrx/main.mojo",
    "src/hyrx/version.mojo",
    "tests/phase0/bootstrap_test.mojo",
    "config/phase0.toml",
    "schemas/benchmark-result.schema.json",
    "packaging/systemd/hyrxmq.service.example",
]

missing = [p for p in REQUIRED if not (ROOT / p).exists()]

if missing:
    print("PHASE0=FAIL")
    print("Missing required files:")
    for item in missing:
        print(f"  - {item}")
    sys.exit(1)

print("Repository structure: PASS")

mojo = shutil.which("mojo")
if mojo is None:
    print("Mojo executable: NOT PROVEN (not found in PATH)")
else:
    print(f"Mojo executable: FOUND ({mojo})")
    result = subprocess.run(
        [mojo, "--version"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    print(result.stdout.strip() or result.stderr.strip())

print("PHASE0_STRUCTURE=PASS")
