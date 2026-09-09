# HyrxMQ — 0010 · Response Copy Elimination

**Status:** Complete
**Milestone:** 0010_response_copy_elimination
**Depends on:** 0009_native_measurement_profile (evidence-ranked target list: `emit_message_frames` 23.6% + List realloc/extend ~27% at 128 KB; profiling only, zero production change)
**Date:** 2026-09-09
**Owner:** scr-architect

---

## 0. Problem

The 0009 profile attributed the post-0007 128 KB hot path to the response
path, and the 0009 costing probe quantified the mechanism (per response):

- **Emit cascade.** `emit_message_frames` (23.6% of samples) grows the `out`
  list ONE RESIZE PER PIECE: method frame + header frame + per-chunk body
  frames, each resize reallocating and copying everything assembled so far.
  Probe: cascade 81.9 µs vs one-shot reserve + in-place writes 8.2 µs for the
  3-piece 128 KB response — 10x.
- **Intermediate `part`/`wf` Lists per body chunk** on the emit path: extra
  full-size allocs + copies per chunk (`encode_body_frame(chan, part)` builds
  a fresh list that is then copied onto `out` again).
- **Codec compaction fresh-alloc.** `AMQPFrameCodec._compact` allocates a
  FRESH buffer per parse (List downsize does NOT retain capacity): ~3.6 µs +
  copy per frame, plus feed-time regrow penalties.
- **Listener open-ok copy-ordering.** `send_bytes(resp.value().copy())` was
  followed by inspecting the response: the copy exists only to keep `resp`
  alive after send; open-ok can be computed pre-send on the original.

Combined `_realloc` + `extend` shares at 128 KB ≈ **27%** — these emit and
compaction sites are the measured contributors.

## 1. Change (wire-identical by construction; flag-gated fallback preserved)

| # | item | operation |
|---|---|---|
| 1 | `frame_codec.mojo` — NEW `AMQPFrameCodec.append_body_frame` | Appends ONE body frame in place onto a caller-owned `out` list: byte-identity contract with `encode_body_frame` (type=3 header, big-endian chan/size shared size math, payload, frame-end). Contiguous path: single `resize(unsafe_uninit_length=old_len + 7 + count + 1)` + in-place header/payload/end octets — no part/wf lists. Elementwise fallback mirrors the encode sequence exactly for the flag-OFF rollback |
| 2 | `frame_codec.mojo` — `_compact` in-place left-shift | When `contiguous_batch_enabled()` and the invariant `remaining <= cursor` holds (feed compacts only when cursor is past the half), the write region `[0, remaining)` cannot overlap the read region `[cursor, cursor+remaining)` — plain memcpy is overlap-safe under the guard. Guard is an explicit branch: violation ⇒ fresh-alloc fallback (overlap-free). Flag OFF keeps the original fresh-alloc path |
| 3 | `amqp_service.mojo::emit_message_frames` | Contiguous branch rewritten: compute method+header frames, then body chunks appended directly onto `out` via `append_body_frame`, reading `body` through `unsafe_ptr() + pos` (count-based pointer reads; `body` is not moved and stays valid). Deletes the `part`/`wf` intermediate buffers. Legacy path (flag off) untouched. `emit_message_frames` is now explicitly forced `raises` (raise-context, harmless — it already calls raising code) |
| 4 | `listener.mojo` | `_resp_is_open_ok` computed on the ORIGINAL response BEFORE `send_bytes(resp.value().copy())`; the copy is retained only for the send (cold open-ok path; accurate spec comments) |
| 5 | NO production API changes beyond the addition | `append_body_frame` is additive; no existing signature, wire format or flag default changes |

## 2. Safety invariants — no semantic change

- **Byte-identity contract:** `append_body_frame` is pinned to
  `encode_body_frame` octet-for-octet by
  `tests/phase8/append_body_frame_identity_test.mojo` across the boundary
  sizes; a negative proof mutates the frame-type byte (3→2) and the probe
  must fail.
- **Compaction overlap safety is guarded, not assumed:** the in-place branch
  executes ONLY under `remaining <= cursor`; the guard is branch-tested with
  a purpose-built probe (`tests/phase8/codec_compaction_test.mojo`) feeding a
  large frame + small chunk that drives cursor-past-half compaction.
- **Rollback intact:** with `contiguous_batch_enabled()` == False the emit
  path and `_compact` run the original per-element/fresh-alloc code; suite
  byte-identical (verified flag-OFF).
- **Gate authority unchanged:** pika fair-pair gate remains the regression
  authority; native numbers are ceiling evidence (0009 rule stands).

## 3. Measured, not speculative

All numbers come from this host's runs: microbench costing from the 0009
plan's step (81.9 µs vs 8.2 µs), native closed-loop A/B
(`benchmarks/native_cycle_bench.mojo`, same client both states), and the full
pika fair-pair 4-cell sweep (5-rep medians, env identical to 0008) with
compare.py gate + `--update-baseline`. Two probes were executed with
negative proofs. One caveat is recorded honestly: measured in-wall gains are
smaller than the microbench predicted (see report — the closed-loop wall is
now bounded by the REMAINING List realloc/extend sites and loop
serialization, not by emit).

## 4. Acceptance criteria

1. `append_body_frame` byte-identity probe PASS at 0/1/2/3/7/8/255/131064
   octets, with a negative proof (frame-type byte mutation ⇒ CHECK FAILED)
2. Compaction in-place branch purpose-fully covered by a new probe (the
   pre-existing compaction test predates the branch and had NO coverage of
   it), with a negative proof (memcpy count−1 ⇒ stale-byte CHECK FAILED)
3. Suite green with both new probes (43/0); flag-OFF rollback byte-identical
4. Native closed-loop A/B: no regression at any size; improvement at
   131072 (0009: 669 µs/msg → 0010: 644 µs/msg)
5. Full pika gate sweep (4 cells): no cell below previous baseline at any
   gate size (within run noise); gate PASS with baseline refreshed upward
6. No production API change beyond the addition of `append_body_frame`

## 5. Definition of done

1. Changes landed; `spec.md`, `plan.md` receipts, and
   `reports/performance_canonical.md` complete
2. Suite 43/0 including `append_body_frame_identity_test.mojo` and
   `codec_compaction_test.mojo` (both negative-proofed)
3. `benchmarks/perf/baseline.json` refreshed via compare.py
   `--update-baseline` to the 0010-state sweep (R 1.430)
4. `docs/MEMORY_MODEL.md` carries the 0010 note (after the 0009 note)
5. 0011 handoff: remaining List realloc/extend sites are re-attributed (from
   feed/parse payload allocations and loop serialization, NOT emit) and
   ranked by measurement

## 6. Verdict

**The emit cascade is eliminated and compaction no longer reallocates.**
Response assembly drops from a per-piece cascade with intermediate part/wf
lists to a single-contiguous append onto one buffer via
`append_body_frame` (byte-identical, proven); `_compact` shifts unparsed
bytes in place under the `remaining <= cursor` guard. Wire format is
byte-identical at all sizes (probe-proven), the flag-OFF rollback path is
exercised and byte-identical, and the pika gate stays PASS with the baseline
refreshed upward (R 1.364 → 1.430). Measured in-wall gains (+4% native
closed-loop at 128 KB, +4–19% across pika cells) are SMALLER than the 82-vs-
8 µs microbench delta — honestly recorded: the closed-loop wall now bends on
the remaining candidates (feed/parse payload allocations, 1-in-flight loop
serialization), which 0011 targets by numbers.
