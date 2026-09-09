# 0009 — Native Ceiling & Broker Profile Report

**Date:** 2026-09-09
**Milestone:** 0009_native_measurement_profile
**Depends on:** 0008_baseline_transport_guard

---

## Summary

0009 removes the measuring instrument from the measurement: a native Mojo
closed-loop client (`benchmarks/native_cycle_bench.mojo`) run against **both**
brokers in the same publish→basic_get shape, plus a `perf` attribution pass on
the HEAD broker. The ~450 µs/msg pika client wall that bound every gate number
to date is gone from the picture; the broker-only ceiling is visible and the
post-0007 residual cycles are attributed and ranked for 0010. **Zero production
code change.**

### Environment

- **Host:** AMD Ryzen 5 3600, kernel 7.1.8 (single host; same caveat class as 0008)
- **HyrxMQ build:** HEAD at 0008 (post-0007 transport byte path)
- **Reference broker:** RabbitMQ 4.3.5 (docker), `127.0.0.1:5673`
- **Client:** `benchmarks/native_cycle_bench.mojo` — closed-loop, **1 message in
  flight**, both brokers, same binary and same code path
- **Pattern:** publish (persistent-exempt default bench queue) → basic_get →
  byte-compare ack loop; no batching, no prefetch
- **Counts (msgs/run):** 20000 / 20000 / 20000 / 20000 / 8000 / 4000 / 2000 at
  64 / 256 / 1024 / 4096 / 16384 / 65536 / 131072 B; default 20000 for ≤ 4096

---

## Table 1 — native closed-loop ceiling (us_per_msg / msgs per second)

| size | hyrx µs/msg | hyrx msg/s | rabbit µs/msg | rabbit msg/s | hyrx/rabbit |
|---:|---:|---:|---:|---:|---:|
| 64 | 17.25 | 57,966 | 110.7 | 9,032 | **6.4x** |
| 256 | 18.74 | 53,374 | 113.6 | 8,800 | **6.1x** |
| 1,024 | 22.98 | 43,513 | 117.8 | 8,487 | **5.1x** |
| 4,096 | 37.48 | 26,677 | 137.9 | 7,251 | **3.7x** |
| 16,384 | 95.06 | 10,519 | 208.5 | 4,796 | **2.2x** |
| 65,536 | 333.0 | 3,002 | 481.2 | 2,077 | **1.45x** |
| 131,072 | 669.1 | 1,494 | 809.5 | 1,235 | **1.21x** |

Key points:

1. **Same-client comparison removes the pika ~450 µs/msg client wall** that
   binds the pika gate: both columns pay the identical native client cost, so
   the broker-only ceiling — 6.4x at small messages — is visible for the first
   time.
2. **These numbers are absolute closed-loop 1-in-flight values and are NOT
   comparable to the batched pika harness baseline numbers** in
   `benchmarks/perf/baseline.json` — different measurement shape (no client
   batching, one round-trip serialized per message).
3. **At 64 B, broker per-message work is ~17 µs total.** The whole 0010
   optimization headroom therefore lives at **≥ 16 KB where per-byte costs
   dominate**; small-message cost is already near the floor.

---

## Profile (T2) — HEAD binary, 128 KB pika load, `perf record -F 1997`, 8 s

| share | symbol | note |
|---:|---|---|
| 23.6% | `emit_message_frames` | response assembly (basic_get reply wire build) |
| 15.6% | `List::_realloc` | buffer growth |
| 11.2% | `List::extend` | buffer copying |
| 6.0% | `handle_frame` | dispatch |
| 5.9% | `Router::read_payload` | payload extract into get-response |
| 5.8% | `try_parse_frame` | inbound frame parse |
| 4.8% | `_publish_pending` | publish path |
| 4.0% | `feed_bytes` | inbound compaction |
| — | `recv_bytes` | **GONE from top** — was **78.02%** pre-0007; confirms the 0007 fix |

### Interpretation — ranked targets for 0010

1. **(i) Response assembly copies** — `emit_message_frames` (23.6%) plus the
   `resp.copy()` on the emit path. Target: zero-copy outbound.
2. **(ii) List realloc/extend churn** — `_realloc` + `extend` ≈ **27%**:
   per-message buffer allocation/resizing in the feed and emit paths. Target:
   reuse persistent per-connection buffers.
3. **(iii) Payload extract copies** — `Router::read_payload` (5.9%). Target:
   direct-into-codec ingest.

Ranking is by measured share, not speculation; 0010 inherits this order.

---

## Client interop note

The native client was validated against **both brokers on the same binary**:

- HyrxMQ echoes the 8-octet header on the get-response — the client consumes
  and asserts it (default path).
- RabbitMQ does not echo — the client's `--no-echo` flag skips that assertion;
  the measurement shape is otherwise identical.
- Rabbit's stricter frame parser rejected the bench's initial `queue.bind`
  payload (missing `nowait` + arguments table). **Fixed in the bench client
  only** — protocol-conformance evidence; no production change.

---

## Regression cross-check

Full pika fair-pair gate **not re-run this increment** — production code is
unchanged, so the 0008 gate result (R 1.364, PASS) still describes the shipped
binary. The next gate run happens at 0010.

---

## Files changed (0009)

| File | Change |
|---|---|
| `benchmarks/native_cycle_bench.mojo` | NEW native closed-loop bench client (both brokers, `--no-echo`) |
| `queue.bind` payload in bench client | fixed for Rabbit strictness (bench-only) |
| production code | **none** |
