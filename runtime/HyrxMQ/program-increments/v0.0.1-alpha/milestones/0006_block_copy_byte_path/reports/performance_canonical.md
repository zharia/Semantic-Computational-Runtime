# 0006 — Block-Copy Byte Path Performance Report

**Date:** 2026-09-09
**Milestone:** 0006_block_copy_byte_path
**Depends on:** 0005_contiguous-byte-path

---

## Summary

0006 closes the **16 KB and 65 KB throughput gaps** by replacing per-element
`List[UInt8]` byte-copy loops with `unsafe_memcpy` block copies across all
hot-path sites, plus eliminates a second copy in the read path via
`BufferSnapshot.take_bytes()`.

### What changed

| Component | Before (0005 flag-ON) | After (0006) |
|---|---|---|
| Codec byte ops | `.append()` loops (identical branches) | `unsafe_memcpy` via `List[UInt8].unsafe_ptr()` |
| Response assembly | elementwise `out.append()` per byte | pre-alloc + `unsafe_memcpy` |
| Inbound body accumulation | elementwise append per frame | `resize_uninit` + `unsafe_memcpy` |
| Buffer/snapshot/message | `.append()` loops | `unsafe_memcpy` or `.copy()` |
| Publish path (adapter) | elementwise copy into Buffer | `resize_uninit` + `unsafe_memcpy` |
| Read path (adapter) | snapshot + `to_bytes()` (2 copies) | snapshot + `take_bytes()` (1 copy) |

---

## Paired Same-Broker A/B Results

**Run:** 2026-09-09, quiet, same-host. **Reference:** RabbitMQ 4.3.5.
**Subject:** HyrxMQ (flag ON), native TCP loopback. **Client:** pika 1.4.4.

### Throughput matrix — native (median msgs/s)

| payload | RabbitMQ | HyrxMQ 0006 | 0006 vs Rabbit |
|---:|---:|---:|---:|
| 64 B | 4,472 | 7,367 | **1.65x** |
| 256 B | 4,338 | 7,202 | **1.66x** |
| 1,024 B | 4,232 | 7,258 | **1.72x** |
| 4,096 B | 4,105 | 6,792 | **1.65x** |
| 16,384 B | 3,924 | 6,217 | **1.58x** |
| 65,536 B | 2,866 | 2,961 | **1.03x** |
| 131,072 B | 1,896 | 1,635 | **0.86x** |

### Headline

**65 KB at parity (1.03x).** The elementwise copy loops were the dominant cost;
block copy eliminates them. Adapter publish/read path changes (memcpy + take_bytes)
had no measurable impact — the remaining 128 KB gap is closed by 0007
(transport recv_bytes per-element loops; was NOT TCP/kernel — see 0007 reports).

**128 KB improved from 0.49x to 0.86x** — 75% improvement but not at parity.
(0006 attribution "TCP send/recv buffer management / Erlang kernel buffering"
was wrong — retired: the gap was HyrxMQ user-space per-element loops in the
transport read path. Closed by 0007; see 0007 reports.)

### Acceptance verdict

| Criterion | 0006 Status |
|---|---|
| 16 KB Hyrx/Rabbit >= ~1.0 (native) | **PASS (1.58x)** |
| 4 KB Hyrx/Rabbit >= ~1.0 | **PASS (1.65x)** |
| 65 KB Hyrx/Rabbit >= ~1.0 | **PASS (1.03x)** |
| 128 KB Hyrx/Rabbit >= ~1.0 | **FAIL (0.86x)** — closed by 0007 (transport recv_bytes per-element loops; was NOT TCP/kernel — see 0007 reports) |
| No small-payload regression | **PASS** (all sizes faster) |

### Flag policy

Default ON (memcpy is a correctness-preserving optimization). The flag gates
memcpy vs loop; the ON path is measurably faster and byte-exact. For >65 KB
payloads, the gap is TCP-level and the flag does not help or hurt.

---

## Files changed (0006 additions)

| File | Change |
|---|---|
| `src/hyrx/amqp/frame_codec.mojo` | `unsafe_memcpy` in try_parse, encode_body, feed_bytes, compact, payload_copy |
| `src/hyrx/core/buffer.mojo` | `resize_uninit` + `unsafe_memcpy` in from_buffer_copy, snapshot |
| `src/hyrx/core/buffer_snapshot.mojo` | `.copy()` in to_bytes; new `take_bytes()` move method |
| `src/hyrx/core/message.mojo` | `resize_uninit` + `unsafe_memcpy` in payload_into |
| `src/hyrx/amqp/adapter.mojo` | `unsafe_memcpy` in publish body copy; `take_bytes()` in read_payload |
| `src/hyrxmq/amqp_service.mojo` | `unsafe_memcpy` in emit_message_frames, _handle_body, _drain_consume, write_short_string, write_long_string |
