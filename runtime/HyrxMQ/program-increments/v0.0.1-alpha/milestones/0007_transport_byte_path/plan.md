# 0007 — transport byte path: remove per-element loops from `recv_bytes`

**Status:** complete — T1/T2/T3 done; suite 40/0; fair pair 16K 1.52x / 65K 1.59x / 128K 1.21x (128K was 0.86x)
**Mode:** coordinator (`scr-architect`); T1 delegated (cavecrew-builder), T3 delegated (general)

## Why (measured, not assumed)

The 0006 report claimed the residual 128 KB throughput gap (0.86x vs RabbitMQ)
was "TCP/kernel-level". That claim was **wrong**. Evidence chain:

1. **Kernel floor** (bare loopback, same host/kernel, send 131072B + recv
   131072B): 11,554 msg/s = 86.6 µs/msg. Rabbit at 128 KB: 1965 msg/s (kernel
   ≈ 4% of its cycle); Hyrx v1: 1635 msg/s (14%). A common term both brokers
   pay cannot create a ratio gap. TCP/kernel exonerated.
2. **perf on the live broker** (128 KB load): 78% of user-CPU samples in
   `TCPConnection::recv_bytes`; 30.66 G instructions / 8 s window ≈ 2.5 M
   insns/msg ≈ 9–19 insns/byte (one memcpy pass ≈ 0.2 insns/byte). Zero
   page faults/msg — allocator/mmap theories dead.
3. **Cause**: `recv_bytes` allocated and **element-wise** zero-filled a fresh
   64 KiB `List[UInt8]` per read (`_zeroed` → `List.resize(n, 0)`), then did a
   second element-wise `append` pass into another fresh list. 0006's memcpy
   sweep did not cover the transport layer.
4. **Why exactly 128 KB**: body 131072 B > per-frame capacity
   (frame_max−8 = 131064) → 2 body frames; `_READ_SIZE=65536` → ~4 reads/msg
   vs ~2 at 65 KB. The waste is linear in read count.
5. **Fix + A/B** (one function, TCP): uninit buffer + read + shrink to `got`.
   perf after: instructions −80% (6.0 G), task-clock −45% (≈220 µs CPU/msg
   saved). Same-harness fair pair: 16 K 1.52x, 65 K 1.59x, 128 K **1.21x**
   (was 0.86x). Byte-exactness: harness body-compare green at all sizes.

## Tasks

- **T1 — DONE** (cavecrew-builder): apply the proven TCP transform to
  `src/hyrx/transport/uds.mojo::recv_bytes` (identical `_zeroed` + append
  pattern at lines 119–124); remove the now-dead `_zeroed` defs from both
  tcp.mojo and uds.mojo. No behavior change: `recv_bytes` still returns a
  `List[UInt8]` of exactly the bytes read; empty = EOF.
- **T2 — DONE** (coordinator): rebuild, suite 40/0, measure `hyrx-uds` cell
  post-fix, record evidence.
- **T3 — DONE** (general): milestone docs (`spec.md`,
  `reports/performance_canonical.md`), correct the wrong "TCP/kernel-level"
  sentence in `0006_block_copy_byte_path/reports/performance_canonical.md`,
  add 0007 note to `docs/MEMORY_MODEL.md`.

## Explicitly NOT claimed

- No new perf numbers beyond the runs recorded in `reports/`.
- 128 K parity (1.0x) is NOT claimed: 1.21x measured on this host/run — above
  parity, but single-host evidence (hardened 2026-09-09 by 0008: 5-rep sweep
  all cells >= parity, see 0008 reports); the CI-style gate stays "≥ ~1.0".
- `recv_exact`/header-step per-element appends in the serving path remain
  (small frames only, no large-payload impact measured).
