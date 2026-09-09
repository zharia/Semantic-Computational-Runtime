# HyrxMQ — 0012 · Persistent Codec Buffers + Direct-Into-Codec Ingest (rejected by gate — measurement-only)

**Status:** Rejected by gate (P2 skipped) — measurement-only increment
**Milestone:** 0012_persistent_codec_buffers
**Depends on:** 0011_fs_free_local_ipc (0010 post-mortem rank: remaining `List::realloc`/`extend` ~28% user-CPU @128 KB, now attributed inside the ingest path)
**Date:** 2026-09-09
**Owner:** scr-architect

---

## 0. Problem

The 0010 post-mortem re-attributed the post-emit residual: **~28% user-CPU**
(`List::realloc` + `extend`) at the 128 KB cell, no longer from response
assembly but from **per-message allocation churn concentrated in ingest** —
every ~64 KB socket read allocates a fresh List (plus shrink), `feed_bytes`
grows the codec buffer (a `_compact` downsize kills capacity, so the regrow
pays alloc+copy), and `try_parse_frame` allocates a fresh payload List per
frame. For fresh buffers, downsize does NOT retain capacity (regrow 3.46 µs
@128 KB; one-shot reserve beats cascade growth ~10x — established 0009
probe).

## 1. Hypothesis

A persistent per-connection codec buffer (cursor-bookkept, resize-UP only)
plus direct-into-codec ingest (`recv_bytes_into` would read the socket
straight into the codec tail) recovers a **measurable** share of the
closed-loop wall at the 128 KB shape.

## 2. Method (measure first — P1 with an explicit reject gate)

Before any implementation: a codec-level probe quantifying what is actually
left to recover in the ingest path.

- **Probe shape** (same codec file reuse as all prior probes): a FRESH
  `AMQPFrameCodec(131072)` per rep; 2 × 65544-byte frames fed + parsed +
  payload-copied per message (mirrors the real 128 KB ingest shape — method
  frame + body frames ride the same buffer); `feed_bytes` calls are
  parse-drained between feeds per the codec backlog contract. 500 reps, 3
  runs.
- **Floor:** memcpy pair (two copies of 65536 + 65544 bytes) — the pure
  copy cost that can never be recovered.
- **Reject threshold (pre-committed):** the implementation tier (P2) is
  built only if the **recoverable** ingest cost
  (measured `us/msg` − memcpy floor) is **>= 10 us/msg**. Below that, P2 is
  speculative churn for < 1.5% of the wall and is rejected on measurement,
  per rule 17 (optimization follows correctness and measurement).

## 3. Result — GATE FAILS

| quantity | value |
|---|---:|
| probe, current ingest path (3 runs) | 9.9 – 11.1 µs/msg |
| memcpy floor pair | 2.2 µs |
| recoverable (current − floor) | **8.6 µs/msg** |
| closed-loop wall @128 KB (0010 native) | 644 µs/msg |
| recoverable share of wall | **1.3%** |
| threshold | 10 µs/msg — **NOT met** |

Even a **perfect** rewrite (every byte of non-memcpy ingest work recovered)
saves ~8.6 µs off a ~644 µs closed-loop message — ~1.3%. The hypothesis is
rejected by measurement: the per-message alloc churn in ingest is NOT where
the wall lives.

## 4. Decision

**No production change.** P2 (`_used` bookkeeping + `admit_tail` +
`recv_bytes_into`) and its gates are skipped; the increment closes as a
measurement-only record. The suite is unchanged at 44/0.

**Revisit condition:** only if the architecture changes so that the
per-message ingest share grows — e.g. batched consume pipelines where many
messages amortize against the same alloc churn, making the recovered µs/msg
add up to a measurable wall fraction. At the current 1-in-flight serial
shape it does not.

## 5. Verdict

**Measured, then refused.** The 28% realloc/extend attribution decomposes
under the probe: ~2.2 µs is irreducible memcpy and the full recoverable
fraction is ~8.6 µs — 1.3% of the 644 µs 128 KB closed-loop wall, below the
pre-committed 10 µs/msg implement threshold. Persistent codec buffers and
direct-into-codec ingest would have been speculative churn per rule 17.
Where the remaining user-CPU actually lives (no single candidate > 16%) and
the honest close-out are recorded in
`reports/measurement_probe.md`.
