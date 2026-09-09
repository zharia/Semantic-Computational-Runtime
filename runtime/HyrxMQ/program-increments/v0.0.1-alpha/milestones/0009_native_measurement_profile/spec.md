# HyrxMQ — 0009 · Native Measurement Profile

**Status:** Complete
**Milestone:** 0009_native_measurement_profile
**Depends on:** 0008_baseline_transport_guard (baseline guarded and reproducible; broker cycles now unattributed post-0007)
**Date:** 2026-09-09
**Owner:** scr-architect

---

## 0. Problem

Every gate number to date (0004..0008) is measured through the **pika client**,
which burns ~450 µs CPU/msg at 128 KB. The harness is client-bound: the gate
ratio is a floor created by the measuring instrument, not by either broker, so
HyrxMQ headroom is invisible and 0010 copy-elimination work cannot be sized
honestly.

Separately, post-0007 the broker still spends ~230 µs/msg user-CPU at 128 KB
whose location is **unattributed**: 0007 removed the transport per-element loops
(`recv_bytes` fell out of the profile) but nothing has re-ranked the remaining
hot spots, so the 0010 target list would be guesswork.

## 1. Method

One measurement shape for **both** brokers: a native Mojo closed-loop
publish→basic_get client (1 message in flight), `benchmarks/native_cycle_bench.mojo`,
composed only from patterns already proven in
`tests/integration/broker_tcp_e2e.mojo`. Same client, same shape, both brokers
⇒ the client wall cancels and the broker-only ceiling becomes visible.
Then `perf record` on the HEAD broker binary under 128 KB load to attribute the
residual cycles.

## 2. Change (BENCH ONLY — zero production code)

| # | item | operation |
|---|---|---|
| 1 | `benchmarks/native_cycle_bench.mojo` | NEW closed-loop native bench client (sizes 64..131072, `--count`, `--no-echo` for brokers that do not echo the 8-octet header) |
| 2 | profiling pass | `perf record -F 1997` on `build/hyrxmq-listen` under 128 KB load; attribution table → ranked 0010 target list |
| 3 | production code | **NONE.** No transformation, no flag, no refactor |

## 3. Safety invariants — no semantic change

- **Zero production diff** — the broker binary profiled is the 0008-HEAD
  binary; the bench client is additive under `benchmarks/`.
- **Gate authority unchanged:** native numbers are **ceiling evidence**, not a
  replacement for the pika fair-pair gate (different client = different
  absolute numbers; the gate stays the pika matrix).
- **Interop strictness is evidence, not a defect:** where RabbitMQ's stricter
  parser rejected the bench payload, the *bench* was fixed; the broker was not.

## 4. Measured, not speculative

All numbers come from the T1 sweep and T2 profile on this host
(AMD Ryzen 5 3600, kernel 7.1.8); see
`reports/native_ceiling_and_profile.md`. No perf-improvement claim is made —
this increment measures only.

## 5. Acceptance criteria

1. Native closed-loop client runs green against **both** brokers on the same
   binary (HyrxMQ default path; RabbitMQ via `--no-echo`)
2. Ceiling table recorded at 7 sizes with hyrx/rabbit ratios
3. 128 KB broker profile attributed; `recv_bytes` absence from the hot list
   confirmed (cross-checks 0007)
4. 0010 target list ranked by measured share — not by speculation
5. Zero production-code diff; pika fair pair untouched

## 6. Definition of done

1. `benchmarks/native_cycle_bench.mojo` landed (bench-only)
2. Ceiling + profile recorded in `reports/native_ceiling_and_profile.md`
3. `docs/MEMORY_MODEL.md` carries the 0009 note (after the 0008 note)
4. 0010 inherits an evidence-ranked target list

## 7. Verdict

**Broker-only ceiling is now visible.** Same-client closed-loop: HyrxMQ is
**6.4x** RabbitMQ at 64 B falling to **1.21x** at 128 KB — the pika ~450 µs/msg
client wall that made the gate numbers ratio-flat is removed from the
measurement. Residual broker work is attributed: response assembly
(`emit_message_frames` 23.6% + `resp.copy()`) > List realloc/extend churn
(~27%) > payload extract (`read_payload` 5.9%); `recv_bytes` is **gone** from
the top (was 78.02% pre-0007 — confirms the 0007 fix). 0010 targets ranked in
that order. Zero production change; rabbit gate stands.
