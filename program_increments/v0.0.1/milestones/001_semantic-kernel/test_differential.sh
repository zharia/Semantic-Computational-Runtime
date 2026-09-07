#!/bin/bash
# Differential Execution Test — SCR Canonical Programs
#
# Tests that canonical MLIR programs produce expected results through:
#   1. MLIR parsing
#   2. MLIR lowering to LLVM dialect
#   3. Translation to LLVM IR
#   4. Compilation to native object
#   5. Execution and result verification
#
# Single entity: 0 + 5 + 3 + 2 = 10
# Multi entity:  c1=5+3=8, c2=10-2=8
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MLIR_SINGLE="$SCRIPT_DIR/canonical_counter.mlir"
MLIR_MULTI="$SCRIPT_DIR/canonical_multi_entity.mlir"
TMP_DIR="/tmp/scr_differential_$$"
mkdir -p "$TMP_DIR"

PASS=0
FAIL=0

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "=== SCR Differential Execution Test ==="
echo ""

# ---- Test 1: Single entity canonical_counter ----
echo "--- Test 1: Single Entity (canonical_counter) ---"
echo "Expected: 10"

echo "[1/5] Parsing MLIR..."
mlir-opt "$MLIR_SINGLE" --allow-unregistered-dialect > "$TMP_DIR/single_parsed.mlir" 2>"$TMP_DIR/parse_err.txt" || {
  echo "FAIL: MLIR parse error"
  cat "$TMP_DIR/parse_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 1: FAIL"
  echo ""
  echo "--- Test 2: Multi Entity (canonical_multi_entity) ---"
  echo "SKIPPED: parse failed"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Parse: PASS"

echo "[2/5] Lowering to LLVM..."
mlir-opt "$MLIR_SINGLE" --allow-unregistered-dialect \
  --convert-scf-to-cf --convert-to-llvm > "$TMP_DIR/single_lowered.mlir" 2>"$TMP_DIR/lower_err.txt" || {
  echo "FAIL: Lowering error"
  cat "$TMP_DIR/lower_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 1: FAIL"
  echo ""
  echo "--- Test 2: Multi Entity ---"
  echo "SKIPPED"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Lower: PASS"

echo "[3/5] Translating to LLVM IR..."
mlir-translate --allow-unregistered-dialect "$TMP_DIR/single_lowered.mlir" \
  --mlir-to-llvmir > "$TMP_DIR/single.ll" 2>"$TMP_DIR/translate_err.txt" || {
  echo "FAIL: Translation error"
  cat "$TMP_DIR/translate_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 1: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Translate: PASS"

echo "[4/5] Compiling to object..."
llc -filetype=obj "$TMP_DIR/single.ll" -o "$TMP_DIR/single.o" 2>"$TMP_DIR/llc_err.txt" || {
  echo "FAIL: llc error"
  cat "$TMP_DIR/llc_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 1: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Compile: PASS"

echo "[5/5] Executing and verifying..."

# C wrapper: canonical_counter returns i32, straightforward ABI
cat > "$TMP_DIR/single_wrapper.c" << 'CEOF'
#include <stdio.h>
#include <stdlib.h>

extern long long canonical_counter(void);

int main(void) {
    long long result = canonical_counter();
    printf("%lld\n", result);
    return 0;
}
CEOF

gcc "$TMP_DIR/single_wrapper.c" "$TMP_DIR/single.o" \
  -o "$TMP_DIR/single_test" 2>"$TMP_DIR/gcc_err.txt" || {
  echo "FAIL: gcc link error"
  cat "$TMP_DIR/gcc_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 1: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}

OUTPUT=$("$TMP_DIR/single_test" 2>&1)
EXPECTED=10

if [ "$OUTPUT" = "$EXPECTED" ]; then
  echo "  Execute: PASS (got $OUTPUT)"
  PASS=$((PASS+1))
else
  echo "  Execute: FAIL (expected $EXPECTED, got $OUTPUT)"
  FAIL=$((FAIL+1))
fi

echo ""
echo "--- Test 1 complete ---"
echo ""

# ---- Test 2: Multi entity canonical_multi_entity ----
echo "--- Test 2: Multi Entity (canonical_multi_entity) ---"
echo "Expected: c1=8, c2=8"

echo "[1/5] Parsing MLIR..."
mlir-opt "$MLIR_MULTI" --allow-unregistered-dialect > "$TMP_DIR/multi_parsed.mlir" 2>"$TMP_DIR/parse_err.txt" || {
  echo "FAIL: MLIR parse error"
  cat "$TMP_DIR/parse_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 2: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Parse: PASS"

echo "[2/5] Lowering to LLVM..."
mlir-opt "$MLIR_MULTI" --allow-unregistered-dialect \
  --convert-scf-to-cf --convert-to-llvm > "$TMP_DIR/multi_lowered.mlir" 2>"$TMP_DIR/lower_err.txt" || {
  echo "FAIL: Lowering error"
  cat "$TMP_DIR/lower_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 2: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Lower: PASS"

echo "[3/5] Translating to LLVM IR..."
mlir-translate --allow-unregistered-dialect "$TMP_DIR/multi_lowered.mlir" \
  --mlir-to-llvmir > "$TMP_DIR/multi.ll" 2>"$TMP_DIR/translate_err.txt" || {
  echo "FAIL: Translation error"
  cat "$TMP_DIR/translate_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 2: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Translate: PASS"

echo "[4/5] Compiling to object..."
llc -filetype=obj "$TMP_DIR/multi.ll" -o "$TMP_DIR/multi.o" 2>"$TMP_DIR/llc_err.txt" || {
  echo "FAIL: llc error"
  cat "$TMP_DIR/llc_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 2: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}
echo "  Compile: PASS"

echo "[5/5] Executing and verifying..."

# C wrapper: canonical_multi_entity returns (i32, i32)
# In x86-64 SysV ABI, this is returned in rax and rdx.
# We use a struct to capture both values properly.
cat > "$TMP_DIR/multi_wrapper.c" << 'CEOF'
#include <stdio.h>
#include <stdlib.h>

typedef struct { long long v1; long long v2; } Pair;

extern Pair canonical_multi_entity(void);

int main(void) {
    Pair p = canonical_multi_entity();
    printf("c1=%lld\n", p.v1);
    printf("c2=%lld\n", p.v2);
    return 0;
}
CEOF

gcc "$TMP_DIR/multi_wrapper.c" "$TMP_DIR/multi.o" \
  -o "$TMP_DIR/multi_test" 2>"$TMP_DIR/gcc_err.txt" || {
  echo "FAIL: gcc link error"
  cat "$TMP_DIR/gcc_err.txt"
  FAIL=$((FAIL+1))
  echo "Test 2: FAIL"
  echo ""
  echo "=== Results: $PASS passed, $FAIL failed ==="
  exit 1
}

OUTPUT=$("$TMP_DIR/multi_test" 2>&1)
C1_VAL=$(echo "$OUTPUT" | grep "^c1=" | cut -d= -f2)
C2_VAL=$(echo "$OUTPUT" | grep "^c2=" | cut -d= -f2)

EXPECTED_C1=8
EXPECTED_C2=8

if [ "$C1_VAL" = "$EXPECTED_C1" ] && [ "$C2_VAL" = "$EXPECTED_C2" ]; then
  echo "  Execute: PASS (c1=$C1_VAL, c2=$C2_VAL)"
  PASS=$((PASS+1))
else
  echo "  Execute: FAIL (expected c1=$EXPECTED_C1 c2=$EXPECTED_C2, got c1=$C1_VAL c2=$C2_VAL)"
  FAIL=$((FAIL+1))
fi

echo ""
echo "--- Test 2 complete ---"
echo ""

# ---- Summary ----
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ $FAIL -gt 0 ]; then
  exit 1
fi

echo ""
echo "Differential execution: PASS"
exit 0
