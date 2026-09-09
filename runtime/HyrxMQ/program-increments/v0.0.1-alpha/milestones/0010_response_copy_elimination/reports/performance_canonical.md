# 0010 — Response Copy Elimination Performance Report

**Date:** 2026-09-09
**Milestone:** 0010_response_copy_elimination
**Depends on:** 0009_native_measurement_profile

---

## Summary

0010 rewrites the response assembly to a single-contiguous write path
(`AMQPFrameCodec.append_body_frame` onto one `out` buffer — no cascade, no
`part`/`wf` intermediates), shifts codec compaction in place under the
`remaining <= cursor` guard, and computes the listener open-ok pre-send.
Wire format byte-identical (probe-proven). Gate refreshes upward:
**R 1.364 → 1.430, PASS**.

### Environment

- **Deployment:** identical to the 0008/0009 canonical runs —
  - **Host:** single host (single-host caveat stands; compare.py host-signature guard covers cross-host misuse)
  - **Reference broker:** RabbitMQ 4.3.5 (docker), bench rabbit `127.0.0.1:5673` (`RABBIT_PORT=5673`)
  - **Client:** pika 1.4.4, `frame_max` 131072
  - **Protocol:** 5 reps per cell, medians; all four cells status OK
  - **Cells:** rabbit-tcp / hyrx-tcp-native / hyrx-tcp-docker / hyrx-uds
- **Native A/B:** `benchmarks/native_cycle_bench.mojo` (0009 closed-loop client), same binary shape, same host
- **Microbench:** the 0009 plan's costing probe step, executed at protocol start

---

## 1. Microbench costing at protocol start (from 0009 plan step)

Per-response cost of assembling the 3-piece 128 KB basic.get response:

| strategy | cost |
|---|---:|
| cascade growth (one resize per piece — pre-0010 emit) | **81.9 µs** |
| one-shot reserve + in-place writes (0010 emit) | **8.2 µs** |

**10x** on the emit assembly itself.

> **Caveat, stated honestly:** the measured in-wall gain at 128 KB is
> SMALLER than this 82-vs-8 µs microbench delta predicts: +4% native
> closed-loop; +4–10% across the pika gate cells (docker/uds +8.5–19.8%).
> See §5 honest limitation block: the closed-loop wall is now
> bounded by the REMAINING realloc/extend candidates (feed/parse payload
> allocations, not emit) and by 1-in-flight loop serialization.

## 2. Native ceiling A/B (closed-loop native client, msgs/s)

Same client, same host, 0009-state vs 0010-state binary:

| size | 0009 | 0010 | delta |
|---:|---:|---:|---:|
| 64 | 57,966 | 58,191 | **+0.4%** |
| 256 | 53,374 | 55,665 | +4.3% |
| 1,024 | 43,513 | 44,662 | +2.6% |
| 4,096 | 26,677 | 27,119 | **+1.7%** |
| 16,384 | 10,519 | 10,388 | **−1.2%** (run noise — no regression claim either way) |
| 65,536 | 3,002 | 3,042 | **+1.3%** |
| 131,072 | 1,494 | 1,552 | **+3.9%** (669 → 644 µs/msg) |

No size regresses beyond noise; the target size (128 KB) improves.

## 3. pika fair-pair gate sweep (4 cells, 5-rep medians, gate sizes shown)

| cell / size | previous baseline (0008-state) | 0010 | delta |
|---|---:|---:|---:|
| native 16K | 6,334 | 6,296 | **−0.6%** (within run noise) |
| native 65K | 4,133 | 4,428 | **+7.1%** |
| native 128K | 2,567 | 2,680 | **+4.4%** |
| docker 16K | 4,866 | 5,830 | **+19.8%** |
| docker 65K | 3,283 | 3,890 | **+18.5%** |
| docker 128K | 2,299 | 2,494 | **+8.5%** |
| uds 16K | 6,960 | 7,631 | **+9.6%** |
| uds 65K | 4,521 | 4,994 | **+10.5%** |
| uds 128K | 2,656 | 2,919 | **+9.9%** |
| rabbit 131,072 (reference cell) | 1,756 | v. run | variance known (0008 note: rabbit measured 1,756–1,965 across canonical runs) |

No cell is below the previous baseline at any gate size outside run noise;
every Hyrx cell improved or held.

### Gate verdict (verbatim)

```
R 1.364 -> 1.430 (delta +0.066, threshold +-0.10) PASS [95% CI now: 1.4205-1.435]
```

- Every gate cell **PASS**.
- Every hyrx/rabbit ratio is now **≥ 1.29** at the gate sizes (minimum ratio
  moved up from 0008's 1.13x docker@65K); 16K ratios span **1.42–1.86x**
  across cells.
- Ratios above are computed against THIS run's rabbit column (rabbit
  reference cell variance known, per the 0008 hardening note).
- **Baseline updated via `compare.py --update-baseline` (explicit step).**

## 4. Verification

### Byte-identity probe

`encode_body_frame` vs `append_body_frame` compared octet-for-octet at sizes
**0 / 1 / 2 / 3 / 7 / 8 / 255 / 131064** — every boundary class (below,
around and above the header/end octet arithmetic, and the full
frame_max-sized payload). **PASS.** Committed as
`tests/phase8/append_body_frame_identity_test.mojo`.

### Compaction in-place branch (coverage gap closed)

The pre-existing purpose-built compaction test PREDATED the new in-place
branch and had **NO suite coverage** of it (the 0005 cursor work tested the
fresh-alloc path that shipped then). New targeted probe:
`tests/phase8/codec_compaction_test.mojo` — large-frame + pail feed
(90,000-octet frame + 2,000-octet chunk) exercising cursor-past-half
compaction through the in-place left-shift branch. **PASS.**

### Negative proofs (executed, not argued)

| # | mutation | expected & observed |
|---|---|---|
| (i) | `append_body_frame` frame-type byte 3 → 2 | identity probe **CHECK FAILED byte 0 (3 vs 2)**; restored → PASS |
| (ii) | compaction `memcpy` count − 1 | compaction probe **CHECK FAILED frame2 byte 1992 stale 200 vs 213**; restored → PASS |

The append-byte-identity and compaction-miscopy defect classes are now
regression-visible.

### Suite & rollback

- Suite: **43/0** (41 + two new probes), auto-discovered by test_all.
- **flag-OFF rollback check:** `contiguous_batch_enabled` False → suite
  **43/0**, byte-identical — the emit elementwise path and fresh-alloc
  compaction are intact.

---

## 5. Honest limitation block

The in-wall gains at 128 KB (**+4%** native closed-loop; **+4–10%** pika
cells native/docker/uds) are SMALLER than the 82-vs-8 µs microbench delta would predict. **Recorded
reason, not speculation:** the closed-loop wall at 0010-state is bounded by
the REMAINING candidates —

1. **List realloc/extend now attributable to feed/parse payload
   allocations** (not emit): the ~27% share's other half lives in the
   per-message allocation of `feed_bytes`/`try_parse_frame` payload buffers.
2. **Scheduling/latency serialization of the 1-in-flight loop:** a
   publish→get round-trip that cannot overlap client and broker work
   serializes; assembly savings do not stack linearly onto a serialized
   wall.

0011 targets **per-connection persistent buffers** (amortize the
feed/parse payload allocs) and **direct-into-codec ingest**, by numbers.

---

## Files changed (0010)

| File | Change |
|---|---|
| `tests/phase8/append_body_frame_identity_test.mojo` | NEW byte-identity probe + negative proof |
| `tests/phase8/codec_compaction_test.mojo` | NEW compaction in-place-branch probe + negative proof |
| `benchmarks/perf/baseline.json` | refreshed to the 0010-state canonical sweep (R 1.430) |
| `src/hyrx/amqp/frame_codec.mojo` | `append_body_frame` (additive); `_compact` in-place branch |
| `src/hyrxmq/amqp_service.mojo` | emit contiguous branch → `append_body_frame`, no part/wf lists; forced `raises` |
| `src/hyrxmq/listener.mojo` | open-ok computed pre-send |
