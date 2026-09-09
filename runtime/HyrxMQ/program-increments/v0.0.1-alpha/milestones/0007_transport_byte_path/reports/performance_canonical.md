# 0007 — Transport Byte Path Performance Report

**Date:** 2026-09-09
**Milestone:** 0007_transport_byte_path
**Depends on:** 0006_block_copy_byte_path

---

## Summary

0007 closes the **128 KB throughput gap** by removing the per-element loops
from the transport `recv_bytes` (one function per transport: `tcp.mojo`,
`uds.mojo`). The 0006 attribution of the residual gap to "TCP/kernel-level"
was wrong — the gap was HyrxMQ user-space per-element work on every socket
read.

### What changed

| Component | Before (0006) | After (0007) |
|---|---|---|
| `TCPConnection.recv_bytes` (`tcp.mojo:120`) | fresh 64 KiB `List[UInt8]` element-wise zero-filled (`_zeroed`) + element-wise append pass, per socket read | `List[UInt8](unsafe_uninit_length=max_bytes)` + one `read()` + shrink to bytes got |
| `UDSConnection.recv_bytes` (`uds.mojo:106`) | same pattern | same transform |
| `_zeroed` helper | defined in `tcp.mojo` + `uds.mojo` | removed (dead) |

**No semantic change:** the byte path is identical — length = bytes read,
contents = those bytes, empty result = EOF. The change was A/B measured, not
speculative.

---

## Environment

- **Host:** AMD Ryzen 5 3600, CachyOS kernel 7.1.8
- **Reference broker:** RabbitMQ 4.3.5 (docker, 127.0.0.1:5673)
- **Client:** pika 1.4.4, `frame_max` 131072
- **Harness:** batched in-flight pattern, 5 reps, median
- **Kernel-for-benchmark:** bench rabbit (`hyrxmq-bench-rabbit`); node-rabbitmq
  untouched.

---

## Fair pair, TCP, before/after (median msgs/s)

| size | rabbit msg/s | hyrx v1 (0006) | hyrx v2 (0007) | ratio v1 | ratio v2 |
|---:|---:|---:|---:|---:|---:|
| 16,384 | 3,947 | 6,217 | 6,013 | 1.58x | 1.52x |
| 65,536 | 2,691 | 2,961 | 4,278 | 1.03x | 1.59x |
| 131,072 | 1,965 | 1,635 | 2,383 | 0.86x | 1.21x |

Notes:

- v1 (0006) numbers and ratios come from the **0006 canonical run**, on a
  **different rabbit instance** than this run's; the v1 ratios are computed
  against that run's rabbit (3,924 / 2,866 / 1,896). The rabbit column above is
  this run's instance.
- The 16 KB v2 delta (1.58x → 1.52x) is within run noise: 16 KB bodies fit in
  ~2 reads/msg, so the read-path fix has almost nothing to remove there.

## UDS cell A/B (same harness, HEAD rebuild vs 0007 binary)

| size | HEAD rebuild | 0007 binary | delta |
|---:|---:|---:|---:|
| 16,384 | 6,988 | 6,994 | ±0 |
| 65,536 | 3,216 | 4,735 | **+47%** |
| 131,072 | 1,698 | 2,745 | **+62%** |

The gain is linear in per-message read count — predicted and observed.
16 KB (~2 reads/msg) is unaffected, as predicted.

---

## Profile evidence (128 KB TCP load, `perf` on live broker)

- **Kernel floor:** bare loopback, same host/kernel, same send/recv pattern:
  11,554 msg/s = 86.6 µs/msg. This is a common term both brokers pay; a common
  term cannot create a ratio gap. TCP/kernel exonerated.
- **v1 (0006):** 78% of user-CPU samples in `TCPConnection::recv_bytes`;
  30.66 G instructions / 8 s ≈ 2.5 M insns/msg ≈ 9–19 insns/byte (one memcpy
  pass ≈ 0.2 insns/byte); task-clock 4.899 s; cycles 14.66 G; ~0 minor
  faults/msg (allocator theory dead).
- **v2 (0007):** instructions 6.00 G (**−80%**); task-clock 2.695 s (**−45%**,
  ≈ 220 µs CPU saved/msg); cycles 4.28 G.
- **Syscall census (128 KB):** ~5.2 reads + 1.06 sends/msg (137,735 B in /
  137,696 B out) — syscall count is NOT the bottleneck either.

---

## Acceptance verdict

| Criterion | Status |
|---|---|
| Byte-path identity | **VERIFIED** — suite 40/0 every round; harness publish→get body byte-compare green at 16/65/128 KB, TCP and UDS; `tests/phase8/byte_path_test` green |
| 128 KB ≥ parity | **PASS this host/run** — measured 1.21x; single-host caveat noted (CI-style gate stays "≥ ~1.0") |
| UDS large-payload gain | **VERIFIED** — +62% at 128 KB |

### Wrong claim retired

The 0006 report sentences "**the remaining 128 KB gap is TCP/kernel-level**"
and "**RabbitMQ's erlang runtime has better kernel buffer management**" are
factually wrong. The gap was HyrxMQ user-space per-element loops in the
transport read path (`recv_bytes`), which 0006's memcpy sweep did not cover.
Both 0006 sentences now carry a corrective pointer to this report.

---

## Files changed (0007)

| File | Change |
|---|---|
| `src/hyrx/transport/tcp.mojo` | `recv_bytes`: uninit buffer + read + shrink; `_zeroed` removed |
| `src/hyrx/transport/uds.mojo` | `recv_bytes`: same transform; `_zeroed` removed |
