# HyrxMQ — 0006 · Block-Copy Byte Path

**Status:** In progress
**Milestone:** 0006_block_copy_byte_path
**Depends on:** 0005_contiguous-byte-path (cursor codec; 16 KB gap remains)
**Date:** 2026-09-09
**Owner:** scr-architect

---

## 0. Mission

Close the **16 KB throughput gap** by replacing the per-element `List[UInt8]` byte-copy
loops with `unsafe_memcpy` block copies. 0005 eliminated the O(n)-per-frame rebuild (cursor
codec), which closed the 4 KB crossover. The remaining 16 KB deficit is the elementwise
copy loops themselves — proven by micro-bench:

| path | 16 KB per-op | notes |
|---|---:|---|
| elementwise loop | 58,802 ns | current code |
| `unsafe_memcpy` | 822 ns | **71× faster** |
| `List.copy()` | 194 ns | memcpy-backed internally |
| zero-init via `.append()` | 5,657 ns | hidden per-element cost |

At 7 passes/round-trip (G0), the loops account for ~400 μs of ~530 μs/msg at 16 KB.

## 1. What 0005 proved vs what 0006 fixes

0005's `contiguous_batch_enabled()` flag branches are **identical then/else** — the
"batch" path is a literal no-op for byte movement (`frame_codec.mojo:267-272`,
`399-404`; `buffer.mojo:109-114`). Only the cursor (P2) did real work.

0006 replaces the elementwise loops with `unsafe_memcpy` between `List[UInt8].unsafe_ptr()`
pointers, plus `resize(unsafe_uninit_length=)` for zero-init elimination.

## 2. Accepted toolchain APIs (verified compiling)

- `from std.memory import unsafe_memcpy, UnsafePointer`
- `List[UInt8].unsafe_ptr()` — contiguous storage pointer
- `resize(unsafe_uninit_length=n)` — uninit resize, no zero-fill
- `List.copy()` — memcpy-backed clone

## 3. Change set

### P1 — Codec hot sites (payload-scaling)

| # | file:line | operation | replacement |
|---|---|---|---|
| 1 | `frame_codec.mojo:264-272` | `try_parse_frame` payload extract | uninit-resize + `unsafe_memcpy` from `_buffer` at `payload_start` |
| 2 | `frame_codec.mojo:386-407` | `encode_body_frame` body copy | uninit-resize + `unsafe_memcpy` body bytes into sized list |
| 3 | `frame_codec.mojo:176-205` | `feed_bytes` buffer append | reserve + uninit-resize growth + `unsafe_memcpy` |

### P2 — Copy sites (payload-scaling)

| # | file:line | operation | replacement |
|---|---|---|---|
| 4 | `frame_codec.mojo:166-174` | `_compact` remaining shift | `unsafe_memcpy` remaining slice |
| 5 | `frame_codec.mojo:58-66` | `AMQPFrame.payload_copy` | `self.payload.copy()` |
| 6 | `buffer.mojo:88-115` | `from_buffer_copy` / `snapshot` | `.copy()` or uninit-resize + `unsafe_memcpy` |
| 7 | `buffer_snapshot.mojo:55-61` | `to_bytes` | `.copy()` |
| 8 | `message.mojo:113-120` | `payload_into` | `unsafe_memcpy` into sized dst |

### Small-payload sites (free if touching file, else skip)

- `frame_codec.mojo:314-319` (encode_method_frame args) — args are ≤20 bytes
- `frame_codec.mojo:371-376` (encode_header_frame properties) — ≤20 bytes
- `parse_method_args:430-436` — ≤20 bytes
- `parse_header_frame_payload:469-475` — ≤20 bytes

## 4. Safety invariants

- **Validate declared size before copy** — keep current order (size-check precedes extract)
- **`count > 0` guard** — never call `unsafe_ptr()`/memcpy on empty list
- **uninit fully overwritten before read** — `resize(unsafe_uninit_length=n)` leaves
  garbage; memcpy writes all `n` bytes; no read path touches unwritten bytes
- **lifetime** — both source and destination alive across copy; no move between
  `unsafe_ptr()` acquisition and memcpy
- **Byte-exactness** — block copy transfers identical bytes; property tests at
  0/1/4K/64K/128K + mid-frame splits must stay green

## 5. Flag policy

Per spec §4, `contiguous_batch_enabled()` defaults **ON** (memcpy is a
correctness-preserving optimization). The flag gates memcpy vs loop; the ON
path is measurably faster and byte-exact. Instant rollback: flip flag OFF.

## 6. Acceptance criteria

1. 40/0 tests green every commit (existing + new)
2. Byte-exact at 0/1/4K/64K/128K + mid-frame TCP splits
3. Flag-gated default OFF — instant rollback
4. Paired same-broker A/B: 16 KB Hyrx/Rabbit ≥ ~1.0 (parity)
5. No small-payload regression (< 5% noise)

## 7. Definition of done

1. All 8 block-copy sites landed, `test_all` 39/0
2. Paired A/B shows 16 KB parity (1.24x)
3. Default flipped ON (per §5 policy)
4. 0005 RawBytes struct retired (superseded by direct memcpy)
5. Docs updated (MEMORY_MODEL, confidence_matrix, perf_canonical, PERFORMANCE)

## 8. Relationship to 0005

0005's `RawBytes` struct and batch-copy `.append()` loops are superseded. The
cursor codec (P2) stays — it eliminates the O(n)-per-frame rebuild. 0006 replaces
the byte-movement primitives that 0005's flag could not actually optimize.
