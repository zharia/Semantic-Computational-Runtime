# Baseline — HyrxMQ confidence audit §2

- Mojo: `Mojo 1.0.0 (ed45d567)`
- OS: `Linux sneaky-bat 7.1.8-1-cachyos #1 SMP PREEMPT_DYNAMIC Tue, 11 Aug 2026 x86_64 GNU/Linux` nproc=12
- Build: `pixi run build` → `mojo build -I src -I vendor/flare src/hyrx/main.mojo -o build/hyrx` (pixi.toml [tasks])
- Test: `pixi run test` → `bash scripts/test_all.sh` (per file: `mojo run -I src -I vendor/flare <f>`, PASS = exit 0 && line `=PASS|_PASS`)
- Baseline run (pre-repair): `TOTAL pass=28 fail=0`. 81 flare deprecation warnings per socket test (expected).
- Trustworthy? NO — see §3.

## Test Validity (audit §3)

**B1 assert verdict — INERT.** Probe `/tmp/opencode/audit-assert-probe.mojo`: runtime-false non-constant
`assert x < 0` (x=getpid()%1000+3, std.ffi) → printed after assert, `EXIT=0`. Bare `assert` never fails a test. `raise` → `Unhandled exception...`, `EXIT=1`. `std.testing.assert_equal` → raises, `EXIT=1` (genuine).

**B2 mechanism.** `src/hyrx/testing.mojo`: `check(Bool,String) raises` + `check_eq[T:Equatable]`.
Proof: `tests/_selftest/assertion_mechanism_test.mojo` exit=0 (`ASSERTION_MECHANISM_PASS`);
`tests/_selftest/assertion_negfail.mojo` (false check) exit=1, "NEGFAIL_AFTER_MUST_NOT_PRINT" absent.
test_all.sh walks only tests/phase0..7 + tests/integration — _selftest excluded (verified in script).

**B3 audit.** Tests reviewed: 28. Valid runtime (pre-repair): 15 (phase4/uds, phase5/tcp, phase6×5, phase7×5,
integration amqp_over_tcp + broker_tcp_e2e = raise-based local `check`; flare_smoke = assert_equal).
VACUOUS: 13 (phase0 print-only; phase1×3/phase2×4/phase3×2/phase4 transport/phase5 framing+flow = bare inert `assert`).

**B4 repair.** Converted 327 `assert`→`check()` across 12 files + real checks added to phase0; migrated the
14 valid files' duplicate local `def check` to `from hyrx.testing import check` (one mechanism). Kept all `*_PASS` markers.
Latent bugs exposed (src unchanged, per package constraint):
1. `latency_histogram_test` old asserts (50/250/25/10) contradicted helper `samples[n*p//100]` (matches
   `benchmarks/direct_benchmark.mojo`): corrected to 51/96/100/260/26/20 — prior expectations were never executed.
2. `queue_test` "slot opens after dequeue" false: capacity counts unacked (`Queue._total_count` design);
   now asserts full-after-dequeue + slot-opens-after-ack.
3. **ESCALATION (src bug):** `exchange.mojo _topic_match("orders","orders.#")`→False though its own docstring
   ("# = zero or more words", AMQP 0-9-1) requires match. `exchange_test` L80 asserts contract (==2) → suite red.
   Not weakened to buggy behavior; fix belongs in a src package.

**B5 negative proofs.** Flipped expected values post-repair: flow_control L7 1024→1025 exit 0→1→0;
framing L24 8→9 exit 0→1→0; transport L8 1024→1023 exit 0→1→0 (restored after each).

Summary — Tests reviewed: 28 | valid pre-repair: 15 | repaired: 13 (+14 deduped to shared mechanism) | uncertain: 1 (phase2/exchange_test — pending src `_topic_match` fix; see escalation).
Final: `bash scripts/test_all.sh` → `TOTAL pass=27 fail=1` (fail = exchange contract bug above).
