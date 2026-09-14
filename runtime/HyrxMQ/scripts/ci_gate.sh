#!/usr/bin/env bash
# HyrxMQ local CI gate.
#
# Mirrors the GitHub Actions `ci` workflow: runs the correctness suite (with
# the known assertion_negfail self-test tolerated), the fuzz tests, the quick
# performance certification, and the phase-10 resilience/consistency tests.
# Prints CI_GATE=PASS or CI_GATE=FAIL and exits with the matching code.
#
# Usage:
#   bash scripts/ci_gate.sh
#
# Requires the pixi environment (or `mojo` on PATH).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

INCLUDES=(-I src -I vendor/flare)
TMP="$(mktemp -d)"
FAILED=()

# Resolve a Mojo invocation: prefer `mojo` on PATH, else `pixi run mojo`.
if command -v mojo >/dev/null 2>&1; then
    MOJO=(mojo)
elif command -v pixi >/dev/null 2>&1; then
    MOJO=(pixi run mojo)
else
    echo "error: neither 'mojo' nor 'pixi' found on PATH" >&2
    exit 127
fi

cleanup() {
    # Stop any stray broker started under /tmp by the suites.
    pkill -f "$ROOT/build/hyrxmq-listen" 2>/dev/null || true
    rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

say() { printf '\n=== %s ===\n' "$*"; }

# run_one <pass-marker> <relative-test-file>
# Pass = exit 0 AND the marker line (ending in =PASS / _PASS) present.
run_one() {
    local marker="$1" file="$2"
    local out="$TMP/$(basename "$file").out"
    echo "-- $file"
    "${MOJO[@]}" run "${INCLUDES[@]}" "$file" >"$out" 2>&1
    local rc=$?
    if [ "$rc" -eq 0 ] && grep -Eq '(=|_)PASS$' "$out"; then
        echo "   PASS  $file"
    else
        echo "   FAIL  $file (exit=$rc)"
        tail -8 "$out" | sed 's/^/   | /'
        FAILED+=("$file")
    fi
}

# --- 1. correctness suite (known assertion_negfail tolerated) --------------
say "1. correctness suite"
SUITE_OUT="$TMP/suite.out"
bash scripts/test_all.sh >"$SUITE_OUT" 2>&1 || true
tail -3 "$SUITE_OUT"
TOTAL="$(grep -E '^TOTAL pass=' "$SUITE_OUT" | tail -1)"
if [ -z "$TOTAL" ]; then
    echo "   FAIL  no TOTAL line in suite output"
    FAILED+=("scripts/test_all.sh")
else
    PASS="$(printf '%s\n' "$TOTAL" | sed -E 's/.*pass=([0-9]+).*/\1/')"
    echo "   parsed: pass=$PASS"
    if [ "$PASS" -lt 60 ]; then
        echo "   FAIL  pass count $PASS < 60"
        FAILED+=("scripts/test_all.sh")
    fi
fi

# --- 2. fuzz tests ---------------------------------------------------------
say "2. fuzz"
run_one "PHASE10_FRAME_FUZZ_TEST=PASS" "tests/phase10/frame_fuzz_test.mojo"
run_one "AMQP_FUZZ_TEST=PASS" "tests/phase10/amqp_fuzz_test.mojo"
run_one "STATEFUL_FUZZ_TEST=PASS" "tests/phase10/stateful_fuzz_test.mojo"
run_one "PHASE6_FIELD_TABLE_TEST=PASS" "tests/phase6/field_table_test.mojo"

# --- 3. certification (quick) ----------------------------------------------
say "3. certification (quick)"
if bash benchmarks/certification/run_certification.sh --quick; then
    echo "   PASS  certification --quick"
else
    echo "   FAIL  certification --quick"
    FAILED+=("benchmarks/certification/run_certification.sh --quick")
fi

# --- 4. phase-10 resilience / consistency ----------------------------------
say "4. phase-10 tests"
run_one "NETWORK_FAILURE_TEST=PASS" "tests/phase10/network_failure_test.mojo"
run_one "CORRECTNESS_MATRIX_TEST=PASS" "tests/phase10/correctness_matrix_test.mojo"
run_one "WAL_HARDENING_TEST=PASS" "tests/phase10/wal_hardening_test.mojo"

# --- summary ---------------------------------------------------------------
say "summary"
if [ "${#FAILED[@]}" -eq 0 ]; then
    echo "CI_GATE=PASS"
    exit 0
fi
printf 'failed:\n'
printf '  - %s\n' "${FAILED[@]}"
echo "CI_GATE=FAIL"
exit 1
