# 0006 — Resolve-outstanding-issues plan

**Status:** planning → delegated · **Owner:** scr-architect · **Date:** 2026-09-09
**Audience:** delegating subagents (cavecrew-builder / general) + coordinator verification.

## Status

T1/T2/T3 complete — suite 40/0, negative proof recorded, RawBytes retired, flag docs corrected, reports reconciled; 65/128 KB open → 0007.

## Why (verified discrepancies, not opinions)
1. `scripts/test_all.sh:51-53` discovers **only phase0–7**; `tests/phase8` (if any) never
   runs. So the "byte-exact at all sizes / property tests at 0/1/4K/64K/128K" the 0006
   spec §4/§6 *assert* is **not actually executed**.
2. `reports/confidence_matrix.md` and `spec.md` claim **"40/0 … raw_bytes_test"**; no such
   test exists and `MEMORY_MODEL.md` says **39/0**. Contradiction + phantom artifact.
3. `src/hyrx/core/raw_bytes.mojo` (`RawBytes`) is **dead** — self-referenced only. 0006
   DoD #4 already says "retire the 0005 RawBytes struct"; it wasn't done.
4. `src/hyrx/core/feature_flags.mojo` `contiguous_batch_enabled()` **returns True** but its
   docstring says "When False (default)". Stale/contradictory.
5. The unsafe path (`resize(unsafe_uninit_length=)` + `unsafe_memcpy`) has **no
   byte-exactness guard** actually run — the whole safety argument is untested.

## Scope
IN: add a genuine guard test + wire phase8; retire dead `raw_bytes`; fix flag docstring;
make report numbers reflect a real run; add a negative proof. 65/128 KB stays documented
(not closed) → note as 0007.
OUT: no new perf optimization, no source-semantics change, no benchmark default flips.

## Tasks (delegated)

### T1 (cavecrew-builder) — guard test + discovery wiring   [2 files] — **DONE**
- CREATE `tests/phase8/byte_path_test.mojo`. Use `from hyrx.testing import check`
  (Mojo `assert` is inert). Print `BYTE_PATH_TEST=PASS` at end of `main() raises`.
  APIs (verified): 
    * `Buffer(cap:Int)` (len 0), `.append(UInt8)`, `.size()`, `.capacity()`, `[i]`,
      `[i]=UInt8`, `Buffer.from_buffer_copy(ref b)`, `.snapshot()`→`BufferSnapshot`
      (`.size()`, `[i]`, `.to_bytes()`).
    * `AMQPFrameCodec(max_frame_size:Int)`; `.feed_bytes(List[UInt8])`;
      `.try_parse_frame()`→`Optional[AMQPFrame]`; frame `.payload_copy()`→`List[UInt8]`,
      `.frame_type`, `.channel`; `AMQPFrameCodec.encode_body_frame(UInt16 chan,
      List[UInt8] body)->List[UInt8]`; `AMQPFrameCodec.encode_method_frame(chan,cls,mid,
      List[UInt8])->List`.
    * `Message(Envelope(MessageID(UInt64),String,Dict[String,String]), Buffer)`;
      `.payload_into(var dst:Buffer)->Buffer`; `.payload()->BufferSnapshot`.
  Required coverage (round-trip **byte-for-byte equal**, incl. every copy site):
    a) `Buffer.from_buffer_copy` at sizes **0,1,2,3,7,8,127,128,255,4096,16384,65536**.
    b) `Buffer.snapshot().to_bytes()` same size list.
    c) `Message.payload_into(dst)` (dst pre-sized `Buffer(size)`, len 0) fills exactly,
       `dst.size()==size`, bytes equal; sizes **0,1,512,16384**.
    d) codec **feed→parse** round-trip of a body frame: feed the exact `encode_body_frame`
       output; parse; `payload_copy()` equals source. sizes **0,1,4095,4096,4097,65536**.
    e) **chunked / mid-frame** feed: feed the frame bytes in **1- and 3-byte chunks** to
       exercise `feed_bytes` growth + `_compact` (use `max_frame_size` small enough that a
       later frame triggers compaction) — assert the reassembled body equals source.
    f) a **method frame** round-trip with a >8-byte args vector.
  Use a helper that builds a deterministic pattern (e.g. `(i*31+7)&0xFF`).
- EDIT `scripts/test_all.sh`: add `tests/phase8` to the `find` list (line ~51-52).
- Do NOT edit `src/` (no prod changes).

### T2 (cavecrew-builder) — retire dead RawBytes + fix flag docstring   [≤2 files, see note] — **DONE**
- DELETE `src/hyrx/core/raw_bytes.mojo` (confirm nothing imports `RawBytes` — grep shows only
  self-references + `MEMORY_MODEL.md` mentions; the phase6 `frame_codec_test` uses the WORD
  `raw_bytes` as a local name, NOT the struct — verify, and if it imports it, STOP and
  report instead of deleting).
- EDIT `src/hyrx/core/feature_flags.mojo`: docstring → "Default ON: byte paths use
  unsafe_memcpy block copies; when False they fall back to per-element loops." (matches the
  `return True`).
- NOTE: if deleting the file also requires editing MEMORY_MODEL (it references the path),
  do that edit too but keep total ≤2 files; otherwise leave MEMORY_MODEL to T3.

### T3 (coordinator / me) — evidence reconciliation + verification (NOT delegated) — **DONE**
- Re-run `bash scripts/test_all.sh`; record the REAL pass count (expect 40/0 with phase8).
- **Negative proof**: temporarily change one `unsafe_memcpy` `count` (e.g. `- 1`) in
  `frame_codec` feed/parse, confirm `byte_path_test` FAILS, restore, confirm PASS.
- Fix report/spec numbers + remove the "raw_bytes_test" phantom → cite `byte_path_test`;
  update `MEMORY_MODEL.md` RawBytes section (retired), flag default ON, actual suite count;
  reconcile 0005 board "default OFF" vs 0006 ON (one canonical statement: flag default ON,
  rollback = OFF).
- Commit as `test:` + `refactor:` + `docs:` slices after T1/T2 land and pass.

## Acceptance
- phase8 discovered & green; `test_all` N/N with a **real** byte-exact guard.
- Negative proof recorded (mutate → fail → restore).
- No dead `raw_bytes`, no contradictory flag docstring, reports match reality.
- No production-semantics change; 65/128 KB remains honestly open (0007).

## Sequencing
T1 and T2 are independent → run in parallel. T3 integrates/verifies after both return.
I (coordinator) own verification + commits — delegating unverified code is exactly the
discipline slip we're here to fix.
