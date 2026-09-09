# HyrxMQ — 0007 · Transport Byte Path

**Status:** Complete
**Milestone:** 0007_transport_byte_path
**Depends on:** 0006_block_copy_byte_path (memcpy sweep stopped at codec/service layer; transport not covered)
**Date:** 2026-09-09
**Owner:** scr-architect

---

## 0. Problem

0006 attributed the residual 128 KB throughput gap (0.86x vs RabbitMQ) to
"TCP/kernel-level". That claim was **wrong**. Measured exculpation:

- **Kernel floor** (bare loopback, same host/kernel, same send/recv pattern):
  11,554 msg/s = 86.6 µs/msg. A common term both brokers pay cannot create a
  ratio gap. TCP/kernel exonerated.
- **`perf` on the live broker** (128 KB load): 78% of user-CPU samples in
  `TCPConnection::recv_bytes`; 30.66 G insns / 8 s ≈ 2.5 M insns/msg ≈ 9–19
  insns/byte (one memcpy pass ≈ 0.2 insns/byte); ~0 minor faults/msg
  (allocator/mmap theory dead).
- **Syscall census:** ~5.2 reads + 1.06 sends/msg — syscall count is not the
  bottleneck either.

**Real cause:** per-element loops in the transport `recv_bytes`. Every socket
read allocated a fresh 64 KiB `List[UInt8]`, **element-wise** zero-filled it
(`_zeroed` → `resize(n, 0)`), then did a second element-wise `append` pass into
another fresh list. Why exactly 128 KB hurts: body 131,072 B > per-frame
capacity (frame_max − 8 = 131,064) → 2 body frames; `_READ_SIZE` = 65,536 →
~4 reads/msg (vs ~2 at 65 KB). The waste is linear in read count. 0006's
memcpy sweep never reached the transport layer.

## 1. Hypothesis

Replacing the per-element loops in `recv_bytes` with an uninitialized buffer +
one read + shrink to bytes read removes the ~9–19 insns/byte of user-space
waste and brings 128 KB to ≥ parity with RabbitMQ. The byte path is unchanged:
**length = bytes read, contents = those bytes, empty = EOF**.

## 2. Change (one function per transport)

| # | file:line | operation | replacement |
|---|---|---|---|
| 1 | `src/hyrx/transport/tcp.mojo:120-133` | `TCPConnection.recv_bytes` | `List[UInt8](unsafe_uninit_length=max_bytes)` + one `read(buf.unsafe_ptr(), max_bytes)` + `resize(unsafe_uninit_length=got)` when `0 < got < max_bytes`; `got == max_bytes` returns the full buffer; `got <= 0` returns empty |
| 2 | `src/hyrx/transport/uds.mojo:106-119` | `UDSConnection.recv_bytes` | identical transform |

`_zeroed` is removed from both files (dead after the transform).

## 3. Safety invariants — no semantic change

- **Byte path identical:** length = bytes read; contents = those bytes; empty
  result = EOF. Same signature, same return contract.
- **Uninit never observed:** the buffer is fully overwritten by the read up to
  `got` before any byte is returned; the shrink to `got` drops the
  never-written tail; `got <= 0` returns a fresh empty list.
- **Byte-exactness guards:** suite 40/0 (incl. `tests/phase8/byte_path_test`);
  harness publish→get body byte-compare green at 16/65/128 KB on TCP and UDS.

## 4. Measured, not speculative

The transform was A/B measured before and after landing (perf on the live
broker + same-harness fair pair), per rule 17 (optimization follows
measurement). Effect at 128 KB: instructions −80%, task-clock −45%. It is not
a speculative optimization and needs no feature flag: the read path is
byte-identical, so there is no flag to flip.

## 5. Acceptance criteria

1. Byte-path identity: suite 40/0 every round; harness publish→get body
   byte-compare green at 16/65/128 KB, TCP and UDS;
   `tests/phase8/byte_path_test` green
2. Fair pair 128 KB ≥ parity (~1.0x) on this host/run
3. UDS large-payload measurable gain
4. `_zeroed` gone from `tcp.mojo` and `uds.mojo`

## 6. Definition of done

1. Both `recv_bytes` transformed; `_zeroed` removed from both transports
2. Suite 40/0
3. Fair pair and UDS A/B recorded in `reports/performance_canonical.md`
4. 0006 wrong claims corrected with a pointer to 0007;
   `docs/MEMORY_MODEL.md` carries the 0007 note

## 7. Verdict

Fair pair (TCP): 16 KB 1.52x (within run noise of v1's 1.58x), 65 KB
**1.59x** (was 1.03x), 128 KB **1.21x** (was 0.86x). UDS A/B: 16 KB ±0,
65 KB +47%, 128 KB **+62%**. Gain is linear in per-message read count —
predicted and observed. 128 KB ≥ parity: PASS on this host/run (single-host
caveat noted; CI-style gate stays "≥ ~1.0"). The 0006 "TCP/kernel-level"
claim is retired.
