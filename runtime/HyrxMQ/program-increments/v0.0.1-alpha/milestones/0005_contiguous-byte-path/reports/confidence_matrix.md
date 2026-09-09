# 0005 — Confidence Matrix

**Date:** 2026-09-09
**Milestone:** 0005_contiguous-byte-path

---

## Confidence by Gate

| Gate | Description | Confidence | Evidence |
|---|---|---|---|
| G0 | Cost attribution (measure first) | **HIGH** | Harness produced clear 7× table; §2(a)+(b) both confirmed |
| P1 | RawBytes contiguous buffer | **HIGH** | 16 unit tests, byte-exact 0/1/4K/128K, 40/0 suite |
| P1 wiring | Batch ops in Buffer/Snapshot/codec | **HIGH** | 40/0 with flag OFF and ON; instant rollback verified |
| P2 | Cursor frame-slice codec | **HIGH** | frame_codec_test, frame_codec_bounds, content_reassembly_test all green; p4_codec_ab shows O(n) rebuild eliminated |
| P3 | Eliminate redundant copies | **MEDIUM** | emit_message_frames pre-alloc confirmed; full end-to-end copy count not measured (needs profiler) |
| P4 | Paired same-broker A/B | **DONE** | 4 KB: 1.16× (closed) / 16 KB: 0.47× (narrowed not closed) |

## Confidence by Invariant

| Invariant | Status | Evidence |
|---|---|---|
| Byte-exactness at all sizes | **VERIFIED** | phase8/raw_bytes_test (0/1/4K/128K), frame_codec_test, content_reassembly_test |
| No semantic change | **VERIFIED** | 40/0 tests, identical behavior flag OFF vs ON |
| Flag-gated default OFF | **VERIFIED** | `contiguous_batch_enabled()` returns False |
| Instant rollback | **VERIFIED** | Toggle flag, 40/0 in both states |
| Core independent | **VERIFIED** | raw_bytes.mojo, feature_flags.mojo: std.collections only |
| Wire format unchanged | **VERIFIED** | frame_codec_test byte-level assertions, content_reassembly_test multi-frame round-trip |

## Known Gaps

| Gap | Risk | Mitigation |
|---|---|---|
| No RabbitMQ A/B measurement | Cannot claim gap closure at 4K/16K | Honest assessment in perf report; measurement deferred to environment with RabbitMQ |
| Cursor compaction not stress-tested with many small frames | Potential regression if compaction triggers too often | _compact() only triggers when cursor > half-buffer; amortized O(1) |
| Batch operations are same complexity as per-element | No algorithmic improvement from batch flag alone | Real win depends on future Mojo compiler optimizations (SIMD, memcpy elision); flag kept for that purpose |
| `_pending_bodies` not pre-allocated | Body frame accumulation may resize list | List[UInt8] cannot be pre-allocated without copy in Mojo 1.0; acceptable for now |

## Recommendation

**Default: OFF** — per spec §8.3. The 4 KB crossover is closed (1.16×), but the
16 KB gap remains at 0.47×. Flag stays OFF until 16 KB reaches parity.

The cursor codec (P2) is always active and provides the real performance win. The
batch-copy flag (P1) is an optimization hook for future Mojo compiler improvements.
The remaining 16 KB cost is per-element `List[UInt8]` overhead + memory bandwidth —
requires either compiler-level optimization or a deeper rewrite (RawBytes as Buffer
backing store) tracked as a future milestone.
