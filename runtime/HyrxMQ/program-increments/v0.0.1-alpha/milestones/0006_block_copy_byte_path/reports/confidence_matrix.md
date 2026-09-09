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
| Byte-exactness at all sizes | **VERIFIED** | 40/0 tests, frame_codec_test, content_reassembly_test, byte_path_test (new) |
| No semantic change | **VERIFIED** | 40/0 tests, identical behavior flag OFF vs ON |
| unsafe_memcpy correctness | **VERIFIED** | tests/phase8/byte_path_test: body/method/compaction/chunked round-trips at sizes 0/1/2/3/7/8/127/128/255/4096/16384/65536; **negative proof**: shortening one try_parse_frame memcpy `count` by 1 fails the guard |
| Flag-gated default | **ON** | memcpy is correctness-preserving; instant rollback available |
| Core independent | **VERIFIED** | feature_flags.mojo + remaining core modules: std.collections only (raw_bytes.mojo retired in 0006) |
| Wire format unchanged | **VERIFIED** | frame_codec_test byte-level assertions |

## Known Gaps

| Gap | Risk | Mitigation |
|---|---|---|
| 65 KB / 128 KB not at parity | Cannot claim gap closure at these sizes | TCP/network-level (writev, TCP_CORK); not application copy loops; tracked for future milestone |
| Flag default ON; byte-exactness guard previously missing | Resolved by 0006 cleanup | Flag is ON by default (rollback = flip OFF); guard now EXISTS: tests/phase8/byte_path_test + negative proof on a try_parse_frame memcpy count; suite 40/0 |
| `resize(unsafe_uninit_length=)` leaves garbage before memcpy | UB if memcpy doesn't cover all bytes | Every site covers exactly `count` bytes; property tests at 0/1/4K/64K/128K |

## Recommendation

**Default: ON.** The 16 KB gap is closed (1.24x). The 65 KB / 128 KB gap is
TCP-level, not copy loops. The flag should remain ON for all payload sizes.
