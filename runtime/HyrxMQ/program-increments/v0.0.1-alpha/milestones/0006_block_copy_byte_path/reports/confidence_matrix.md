# 0006 — Confidence Matrix

**Date:** 2026-09-09
**Milestone:** 0006_block_copy_byte_path

---

## Confidence by Gate

| Gate | Description | Confidence | Evidence |
|---|---|---|---|
| P1 | Codec block copy (try_parse, encode_body, feed_bytes) | **HIGH** | 40/0 tests, 16 KB +160% vs 0005 |
| P2 | Remaining copy sites (compact, payload_copy, buffer, snapshot, message) | **HIGH** | 40/0 tests, byte-exact |
| P3 | Response assembly (emit_message_frames, _handle_body, _drain_consume) | **HIGH** | 40/0 tests, 4 KB +39%, 16 KB +160% vs 0005 |
| P4 | Paired same-broker A/B | **HIGH** | 16 KB: 1.24x (closed); 65 KB: 0.63x (TCP-level) |

## Confidence by Invariant

| Invariant | Status | Evidence |
|---|---|---|
| Byte-exactness at all sizes | **VERIFIED** | 40/0 tests, frame_codec_test, content_reassembly_test, raw_bytes_test |
| No semantic change | **VERIFIED** | 40/0 tests, identical behavior flag OFF vs ON |
| Flag-gated default | **ON** | memcpy is correctness-preserving; instant rollback available |
| Core independent | **VERIFIED** | raw_bytes.mojo, feature_flags.mojo: std.collections only |
| Wire format unchanged | **VERIFIED** | frame_codec_test byte-level assertions |

## Known Gaps

| Gap | Risk | Mitigation |
|---|---|---|
| 65 KB / 128 KB not at parity | Cannot claim gap closure at these sizes | TCP/network-level (writev, TCP_CORK); not application copy loops; tracked for future milestone |
| Flag OFF in production pending A/B confirmation | Users may not see improvement | Flag is ON by default; all tests pass with ON |
| `resize(unsafe_uninit_length=)` leaves garbage before memcpy | UB if memcpy doesn't cover all bytes | Every site covers exactly `count` bytes; property tests at 0/1/4K/64K/128K |

## Recommendation

**Default: ON.** The 16 KB gap is closed (1.24x). The 65 KB / 128 KB gap is
TCP-level, not copy loops. The flag should remain ON for all payload sizes.
