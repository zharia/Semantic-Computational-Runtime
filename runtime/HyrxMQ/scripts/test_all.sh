#!/usr/bin/env bash
# Full Mojo test suite: every *.mojo under tests/phase* and tests/integration.
# Success = a line ending in `=PASS` or `_PASS` (e.g. PHASE0_TEST_BOOTSTRAP=PASS,
# FLARE_SMOKE_PASS) appears in the test's stdout.
# Run inside the pixi env: `pixi run test` or `pixi run bash scripts/test_all.sh`.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

INCLUDES=(-I src -I vendor/flare)

# Resolve a Mojo invocation that works both inside an activated pixi shell
# (`mojo` on PATH) and when run directly (`bash scripts/test_all.sh`), by
# preferring `pixi run mojo` when pixi is available.
if command -v mojo >/dev/null 2>&1; then
    MOJO=(mojo)
elif command -v pixi >/dev/null 2>&1; then
    MOJO=(pixi run mojo)
else
    echo "error: neither 'mojo' nor 'pixi' found on PATH" >&2
    exit 127
fi

pass=0
fail=0
failed_files=()

run_test() {
    local f="$1"
    local out err rc
    out="$(mktemp)"
    err="$(mktemp)"
    "${MOJO[@]}" run "${INCLUDES[@]}" "$f" >"$out" 2>"$err"
    rc=$?
    if [ "$rc" -eq 0 ] && grep -Eq '(=|_)PASS$' "$out"; then
        printf 'PASS  %s\n' "$f"
        pass=$((pass + 1))
    else
        printf 'FAIL  %s (exit=%s)\n' "$f" "$rc"
        tail -5 "$out" | sed 's/^/   out| /'
        tail -5 "$err" | sed 's/^/  err| /'
        fail=$((fail + 1))
        failed_files+=("$f")
    fi
    rm -f "$out" "$err"
}

while IFS= read -r f; do
    run_test "$f"
done < <(find tests/phase0 tests/phase1 tests/phase2 tests/phase3 \
              tests/phase4 tests/phase5 tests/phase6 tests/phase7 \
              -name '*.mojo' -type f | sort)

for f in tests/integration/*.mojo; do
    [ -e "$f" ] || continue
    run_test "$f"
done

echo
echo "TOTAL pass=$pass fail=$fail"
if [ "$fail" -ne 0 ]; then
    printf 'failed: %s\n' "${failed_files[@]}"
    exit 1
fi
