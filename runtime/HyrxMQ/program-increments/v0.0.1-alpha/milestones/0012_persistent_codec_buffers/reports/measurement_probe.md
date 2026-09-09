# 0012 — Ingest Persistent-Buffer Gate Probe

**Date:** 2026-09-09
**Milestone:** 0012_persistent_codec_buffers
**Depends on:** 0011_fs_free_local_ipc / 0010_response_copy_elimination (post-0010 profile)
**Scope:** measurement only — zero production, test, or bench-file change

---

## Summary

Measure-first gate for the persistent-buffer + direct-into-codec ingest
hypothesis. A codec-level probe isolates the ingest cost the rewrite could
recover at the 128 KB shape. **Result: 8.6 µs/msg recoverable = 1.3% of the
closed-loop wall — below the pre-committed 10 µs/msg implement threshold.
P2 rejected per rule 17; no production change.**

---

## Method

- **Codec-level probe** (same codec file reuse as all prior probes):
  a fresh `AMQPFrameCodec(131072)` per rep; **2 × 65544-byte frames** fed +
  parsed + `payload_copy`'d per message — mirrors the real 128 KB ingest
  shape (frame + body frames through one codec buffer).
- Feeds are **parse-drained between feeds** per the codec backlog contract
  (feed → try_parse loop → feed), matching how the serving loop actually
  drives the buffer.
- **500 reps per run, 3 independent runs.**
- **Floor probe:** the memcpy pair — two block copies of 65536 + 65544
  bytes — the copy cost no buffering strategy can remove.

---

## Numbers

### Ingest cost, current path (per message = 2 frames; units ns/msg)

> Unit note: the probe's earlier stdout label said `us_per_msg`; the printed
> values are **nanoseconds** per message. Corrected here — all figures below
> are labeled ns/msg.

| run | ns/msg |
|---|---:|
| run 1 | 10,773 |
| run 2 | 9,900 |
| run 3 | 11,056 |
| **range** | **9.9 – 11.1 µs/msg** |

### Floor

| probe | ns |
|---|---:|
| memcpy pair (65536 + 65544 copies) | **2,237** |

---

## Share math at the 128 KB cell

| step | value |
|---|---:|
| closed-loop wall @128 KB (0010 native) | 644 – 669 µs/msg |
| current ingest probe | 9.9 – 11.1 µs/msg |
| memcpy floor pair | 2.2 µs |
| **recoverable** (current − floor) | **8.6 µs/msg** |
| recoverable share of wall | 8.6 / 644 ≈ **1.3%** |
| implement threshold | **10 µs/msg — NOT met** |

Even a perfect rewrite (everything above the memcpy floor recovered) moves
the wall by ~1.3%. **P2 rejected; no production change.**

---

## Where the remaining user-CPU lives after 0010 (horizontal distribution)

The residual realloc/extend ~28% share decomposes into sites spread flat
across the ingest/emit cycle — **no single candidate above 16%**:

| share | site |
|---:|---|
| 4.6% | `feed_bytes` (ingest compaction/grow) |
| 7.2% | `try_parse` (frame parse) |
| 7.5% | `read_payload` (payload extract) |
| 6.4% | `handle_frame` (dispatch) |
| 6.1% | `_publish_pending` (publish path) |
| 14.1% | `emit` (response assembly — post-0010 residual) |
| 15.3% | `realloc` |
| 12.9% | `extend` |

### Interpretation

The earlier measure-first milestones (0009 → 0010) worked because one
candidate held 23–28% and a rewrite could concentrate on it. After 0010 the
cost is **distributed**: the biggest remaining site is 14–16%, and the
recursive realloc/extend shares are the *combined trace* of all the sites
above — not one attackable mechanism.

The 128 KB closed-loop wall itself is dominated by factors **outside broker
control at this shape**: 1-in-flight serial scheduling per message, kernel
network cost, and client-side latency.

### Conclusion

**Broker-side copy-elimination backlog is largely exhausted at the current
shape.** The 0012 gate formalizes it: nothing in the ingest path is worth a
rewrite at 1.3% of wall. The next structural step if squeezing further —
from 0013 backlog items, not this increment:

- **hostnet gate wiring** (make `hyrx-tcp-hostnet` a gated cell after a
  considered index/compare edit + baseline refresh),
- **native client UDS support** (pika cannot speak abstract addresses;
  unlock `hyrx-uds`/abstract harness measurement),
- **multi-connection serving architecture** (change the 1-in-flight serial
  shape itself — the only direction that moves a wall currently bounded
  outside the per-message work).

Revisit the persistent-buffer idea **only** if the architecture changes so
the per-message alloc share grows — e.g. batched consume pipelines where
per-msg alloc churn amortizes across many messages per cycle.

---

## Files changed (0012)

| File | Change |
|---|---|
| production code / tests / benches | **none** |
