# HyrxMQ — 0008 · Baseline Transport Guard

**Status:** Complete
**Milestone:** 0008_baseline_transport_guard
**Depends on:** 0007_transport_byte_path (transport byte path fixed but unguarded; 128 KB verdict single-run; baseline stale)
**Date:** 2026-09-09
**Owner:** scr-architect

---

## 0. Problem

0007 fixed the transport byte path but exposed three systemic gaps plus one
residue; four entries, all real:

- **Stale baseline gate reference.** `benchmarks/perf/baseline.json` held
  pre-0005 numbers (e.g. 16 KB hyrx native 1208/s vs ~6013/s actual) — every
  regression gate run through compare.py was scoring current trees against a
  snapshot of the codebase from before the memcpy sweep.
- **Unguarded transport byte path.** No test drove the transport
  `recv_bytes` byte path: the defect class 0007 fixed (per-element loops
  feeding a live byte path) was invisible to the suite — phase8's guard
  covers codec/copy sites only. The same regression could land again and
  pass 40/0.
- **Single-run 128 KB verdict.** 0007's 128 KB parity claim (1.21x) rested
  on one timed run on one host; not reproducible, therefore not closable.
- **`recv_exact` residue.** Plan-time premise: `recv_exact` (tcp/uds) is dead
  code outside the `AMQPConn` trait whose element loop could matter.
  **Premise rebutted by verification**: 17 callers across 7 test files
  (phase4/uds_test, phase5/tcp_test, listener_hostile, amqp_over_tcp,
  broker_tcp_e2e, socket_behavior, broker_uds_e2e); zero callers in `src/`.
  NOT dead — but not on any measured hot path. Deletion would be
  speculative churn justified by nothing.

## 1. Hypothesis

A byte-exact guard test over a real `TCPConnection` makes the transport byte
path regression-visible without touching production code; a canonical 5-rep
sweep refreshed into `baseline.json` makes the regression gate reproducible;
and `recv_exact` is retained unchanged once its callers are counted. The
128 KB verdict then becomes a 5-rep median with a CI, not a single number.

## 2. Change (no production code change)

| # | item | operation |
|---|---|---|
| 1 | `tests/phase8/transport_byte_path_test.mojo` | NEW guard test: socketpair fixture over a real `TCPConnection` (flare loopback), full frame path through live `recv_bytes` at 13 sizes, partial-feeds, EOF contracts, negative proof |
| 2 | `benchmarks/perf/baseline.json` | refreshed from the canonical 5-rep sweep (compare.py --update-baseline, explicit human step) |
| 3 | production code | **NONE.** T2's premise (dead `recv_exact`) was rebutted; the function is retained unchanged. No transformation, no flag, no deletion |

The T2 rebuttal is the recorded outcome: the plan's justification for a code
change evaporated under verification, so the only correct change is the
record saying so.

## 3. Safety invariants — no semantic change

- **No production file touched** — the byte path 0007 landed is exactly what
  ships; the guard test only observes it.
- **Byte-exactness guarded:** suite 41/0 (40 + new transport guard); every
  round-trip byte-compared at 13 sizes through the live `recv_bytes`.
- **Baseline is data, not code:** refreshed values are measurements of the
  0007-state tree; the compare.py host-signature guard still prevents
  accidental cross-host gate use.

## 4. Measured, not speculative

The verdict numbers come only from the T3 canonical sweep (5-rep medians,
env rabbit 127.0.0.1:5673, RabbitMQ 4.3.5 docker, pika 1.4.4, frame_max
131072); no perf number is recorded from the guard-test session. Negative
proof for the guard is executed, not argued: skipping the
`buf.resize(unsafe_uninit_length=got)` shrink makes the test fail.

## 5. Acceptance criteria

1. Transport byte path guarded: `tests/phase8/transport_byte_path_test.mojo`
   green, byte-exact at 0/1/2/3/7/8/127/128/255/4096/16384/65536/131072,
   partial-feed cases assert the 0007 shrink branch executes; negative
   proof demonstrates failure without the shrink
2. Suite 41/0
3. Baseline refreshed from a 5-rep canonical sweep; gate PASS at R 1.364
   (95% CI 1.3511–1.3742), all four cells ≥ parity at every size
4. 128 KB verdict reproducible: 5 independently timed reps per cell, all
   above parity
5. `recv_exact` retention recorded (17 callers / 7 test files / 0 in src/)

## 6. Definition of done

1. Guard test landed and auto-discovered by test_all; suite 41/0
2. `baseline.json` refreshed; sweep + gate table in
   `reports/performance_canonical.md`
3. `docs/MEMORY_MODEL.md` carries the 0008 note (after the 0007 note)
4. 0007 plan cross-ref: single-host caveat hardened by 0008
5. recv_exact residue closed as "retained, premise rebutted" — no deletion,
   no production diff

## 7. Verdict

**Gate:** PERFORMANCE RATING R 1.364 → 1.364 (threshold ±0.10) **PASS**,
95% CI 1.3511–1.3742; every Hyrx cell/size above parity on this run (min
1.13x docker@65K). **128 KB gate:** Hyrx/Rabbit ≥ ~1.0 — PASS (native 1.46x,
docker 1.31x, uds 1.51x, 5 independently timed reps per cell). The 0007
single-run verdict is now reproducible; the single-host caveat stands
(compare.py host-signature guard covers cross-host misuse). Guard test in
place with a negative proof; `recv_exact` retained — premise rebutted, zero
production change. 0008 closes its scope with no code delta.
