# 0010 — response-path copy elimination (emit + codec compaction)

**Status:** Complete
**Mode:** coordinator; T1 delegated (general), T3 delegated (general), verify = coordinator

## Why (0009 profile, µs-probed)

At 128 KB/msg the post-0007 broker spends most of its user CPU in the response
path, and the 0009 costing probe quantified the mechanism (per response):

- `emit_message_frames` grows `out` ONE RESIZE PER PIECE (cascade): each resize
  reallocs and copies everything assembled so far. Probe: cascade 81.9 µs vs
  one-shot reserve + in-place writes 8.2 µs — **10x**.
- Intermediate `part`/`wf` Lists per body chunk: extra full-size allocs+copies.
- `AMQPFrameCodec._compact` allocates a FRESH buffer per parse (List downsize
  does NOT retain capacity — regrow probe 3.46 µs): ~3.6 µs+copy per frame,
  plus feed-time regrow penalties.
- `List::extend`/`_realloc` profile shares (~27% combined) are these sites.

## Change (wire-identical by construction; flag-gated fallback preserved)

- `frame_codec.mojo`: NEW `append_body_frame(mut out: List[UInt8], chan,
  payload_ptr, count)` writing the exact encode_body_frame octets in place
  (7B header + payload + 1B end; shared size math with encode_body_frame so
  the two paths cannot drift). `_compact` contiguous path: in-place back-shift
  via memmove-class copy (fallback branch: keep existing fresh-alloc when
  `contiguous_batch_enabled()` is False — rollback intact).
- `amqp_service.mojo::emit_message_frames`: compute total response length,
  single `resize(unsafe_uninit_length=total)`, write method frame + header
  frame + body chunks in place (via the new append API); delete `part`/`wf`
  intermediate buffers. Legacy path (flag off) untouched.
- `listener.mojo`: compute `_resp_is_open_ok` BEFORE sending (today:
  `send_bytes(resp.value().copy())` then inspect — the copy exists only to
  keep resp alive after send; copy retained for send but open-ok computed on
  the original first — cold-path only; plus accurate spec comments).

## Verification (no-regression gate)

1. suite 41/0; byte_path_test + transport_byte_path_test + negative proofs
   (mutate new writer size math → guard must fail).
2. Native bench A/B (same client, same host): improve @128KB/65KB.
3. Full pika harness sweep (4 cells incl. rabbit reference) + baseline gate:
   no cell below previous baseline; refresh baseline upward.

## Explicitly NOT claimed

- No cross-broker ordering claims; no multi-connection changes.
- Direct-into-codec ingest deferred to 0011 (feed path measured cheaper to
  leave until compaction fix lands; 0011 scripts it by numbers).

## Task receipts

- **T1 — DONE:** `frame_codec.mojo` `append_body_frame` + `_compact`
  in-place branch landed; byte-identity probe at 8 boundary sizes
  (0/1/2/3/7/8/255/131064) PASS, negative proof: frame-type byte 3→2 →
  CHECK FAILED byte 0 (3 vs 2), restored → PASS — this probe UPGRADED the
  plan's suite-41 guard coverage to cover the new writer, not just the
  original encoder. Dedicated compaction probe added because the purpose-
  built compaction test predated the in-place branch (no suite coverage of
  it): large+pail feed (90000-octet frame + 2000 chunk) drives
  cursor-past-half compaction; negative proof: memcpy count−1 → CHECK
  FAILED frame2 byte 1992 stale 200 vs 213, restored → PASS.
  `tests/phase8/append_body_frame_identity_test.mojo` +
  `tests/phase8/codec_compaction_test.mojo`; suite 43/0; flag-OFF rollback
  suite 43/0 byte-identical.
- **T2 — DONE:** `amqp_service.mojo::emit_message_frames` contiguous branch
  rewritten onto `append_body_frame` reading `body` via `unsafe_ptr()+pos`
  (no part/wf lists); forced `raises` (raise-context, harmless).
  `listener.mojo` open-ok computed pre-send; copy retained for send only.
  No production API change beyond the addition.
- **T3 — DONE:** native A/B 128 KB 1,494→1,552 msg/s (+3.9%, 669→644 µs);
  pika gate sweep 4-cell: docker +19.8/+18.5/+8.5%, uds +9.6/+10.5/+9.9%,
  native +7.1/+4.4% (16K −0.6% within noise); gate verdict verbatim
  `R 1.364 -> 1.430 (delta +0.066, threshold +-0.10) PASS [95% CI now:
  1.4205-1.435]`; baseline refreshed via compare.py `--update-baseline`
  (explicit step); microbench 81.9 vs 8.2 µs with honestly-recorded
  in-wall shortfall (emit no longer dominates realloc share; 0011 targets
  feed/parse allocs + loop serialization). Evidence:
  `reports/performance_canonical.md`.
