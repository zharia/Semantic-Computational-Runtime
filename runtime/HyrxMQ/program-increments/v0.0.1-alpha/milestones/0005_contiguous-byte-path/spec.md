# HyrxMQ — 0005 · Contiguous Byte-Path Performance

**Status:** Draft for approval
**Milestone:** 0005_contiguous-byte-path
**Depends on:** 0004_phase-1-7-optimisation (copy-cut landed; the gap below is what it did **not** close)
**Date:** 2026-09-09
**Owner:** scr-architect (coordinator/implementer, sole source writer)

---

## 0. Mission

Close HyrxMQ's **large-message throughput deficit** against RabbitMQ by replacing the
per-element `List[UInt8]` byte path with **contiguous buffers + block copies** and
removing the **O(n)-per-frame buffer rebuild** in the AMQP codec.

> Governing principle unchanged: **implementation convenience must not redefine
> semantics.** This is an implementation/performance milestone. Byte-exactness is a
> hard acceptance gate — a faster broker that changes delivered bytes has failed.

0004 established (honestly): HyrxMQ beats RabbitMQ on small messages and the large-
message gap **narrowed but did not close**. The remaining cost is structural and on
the wire/codec path, which 0004 did not touch. This milestone attacks that structure.

## 1. Measured baseline (from 0004 canonical, `0004.../reports/performance_canonical.md`)

Closed-loop `publish→basic_get(auto_ack)`, single connection, same-host,
RabbitMQ 4.3.5 (reference) vs HyrxMQ `fa65e28`, 5 reps:

| payload | RabbitMQ (tcp) | HyrxMQ native | HyrxMQ/ Rabbit | 
|---:|---:|---:|---:|
| 64 B    | 4,438  | 7,277 | **1.64×** (Hyrx faster) |
| 256 B   | 4,502  | 7,145 | 1.59× |
| 1,024 B | 4,525  | 6,235 | 1.38× |
| 4,096 B | 4,382  | 2,586 | **0.59× (Hyrx slower)** |
| 16,384 B| 4,040  | 1,356 | **0.34× (Hyrx ~3× slower)** |

RabbitMQ throughput is ~flat with size (IO/scatter-gather-bound, ~one copy); HyrxMQ
**collapses** with size (native 7.3k→1.4k). The crossing is ≈1–4 KB. **Target:** HyrxMQ
throughput ≥ RabbitMQ (ratio ≥ ~1.0) at 4 KB and 16 KB, with **no small-payload
regression**.

## 2. Root cause (verified, file:line)

**(a) Every byte path is `List[UInt8]` with per-element loops** — each byte is a
boxed element; copies are element-by-element, never a block `memcpy`:
- `src/hyrx/core/buffer.mojo:27` `var _data: List[UInt8]` (backing store)
- `src/hyrx/core/buffer_snapshot.mojo:55` `to_bytes` — per-byte loop
- `src/hyrx/amqp/frame_codec.mojo:59` `payload_copy` — per-byte loop
- `src/hyrx/amqp/frame_codec.mojo:167` `feed_bytes` — per-byte append of inbound data
- encode/write path — per-byte appends into the outbound frame

A 16 KiB message is therefore touched **~5× elementwise** per round-trip
(publish copy-in → snapshot-out → encode → decode → queue copy).

**(b) O(n) full-buffer rebuild per frame:**
- `src/hyrx/amqp/frame_codec.mojo:224` extract payload byte-by-byte, **and**
- `src/hyrx/amqp/frame_codec.mojo:238` rebuild `remaining` byte-by-byte,
  re-scanning the whole accumulated buffer on **every** frame.

0004's copy-cut reduced the *queue-side* per-destination passes (2→1) and helped ≥1 KB
by ~5–16% (measured), but left (a)+(b) — the dominant large-message cost — intact.

## 3. Scope

**IN:** contiguous byte-buffer primitive; block-copy in Buffer/Snapshot/codec; cursor/
frame-slice inbound handling (no per-frame rebuild); minimal end-to-end copies on
publish/deliver/get; measurement harnesses + paired same-broker A/B.

**OUT (explicit non-goals):**
- No new wire format; AMQP 0-9-1 framing/semantics unchanged (byte-exact gate).
- No "SCR IR"/shadow IR/Rust-as-IR (project MLIR-first policy). This is buffer
  *representation*, not a semantic/IR change.
- No push-to-idle / async / concurrency (deferred with evidence; single-connection
  closed-loop stays the benchmark).
- No feature additions (TLS, confirms, durability, clustering).
- Not chasing the in-broker 20→66 MB/s figure as a headline (open-loop ceiling from
  0003/§21); the acceptance metric is the **paired closed-loop ratio table** (§6).

## 4. Non-negotiable invariants

- **Byte-exactness** at all payload sizes incl. multi-frame 64 KiB / 128 KiB and
  mid-frame TCP splits (property tests + the existing `content_reassembly` suite).
- **No observable semantic change**: routing, ownership, boundedness (frame_max,
  queue capacity, `List`→raw capacity), `deliveries` byte-identical.
- **Flag-gated, default OFF** each phase (`List[UInt8]` stays behind the interface);
  instant rollback = flag off. (0004 `buffer_pool_enabled` precedent.)
- **Correctness suite green (39/0) every commit**; **negative proof** per behavioural
  change; **no perf claim without a measured, same-broker paired A/B**.
- `src/hyrx/core/**` stays independent (no AMQP/socket/flare/broker imports).

## 5. Phases (each independently green + committed + measured)

### G0 — Attribute the cost (measure first, no behavior change)
- Instrument a copy/append/rebuild **counter** (bytes moved + per-element op count per
  publish→get, per payload size) into the `pool_bench`/fan-out harnesses.
- **Accept:** a per-payload "bytes-touched vs payload-size" table that shows superlinear
  elementwise ops today. Proves which of §2(a)/(b) dominates before code changes.

### P1 — `RawBytes` contiguous buffer
- Introduce a contiguous byte buffer (`UnsafeMutablePointer[DType.uint8]` + block
  `copyBytesFrom`/SIMD; **probe exact Mojo API first**). Back `Buffer` (and the frame
  `payload`) with it behind the existing interface; `List[UInt8]` path kept behind flag.
- O(1) `clear`/`resize` semantics (no per-byte pop; recall 0004's O(n)-`clear` trap).
- `BufferSnapshot.to_bytes` / `payload_copy` / `feed_bytes` / frame encode become
  **block copies**.
- **Accept:** unit tests byte-exact at 0/1/4K/128K; capacity honored; leak/no-stale
  tests (0004) still pass; **G0 counter shows fewer bytes-touched**; A/B vs HEAD in
  `pool_bench` (paired, CIs). Default OFF.

### P2 — Cursor / frame-slice codec (kill O(n) rebuild)
- Replace `feed_bytes`+`remaining` with a **read cursor** over a growable inbound
  buffer; compaction only when the buffer fills, **not per frame**. Frame parse =
  O(1)-amortized slice, payload copied once.
- **Accept:** `frame_codec*`, `content_reassembly`, `framing`, bounds tests green
  unchanged; property fuzz (multi-frame, mid-frame splits, oversize→reject) yields
  identical frames; per-frame parse cost linear in *frame size*, not *buffered total*.

### P3 — Eliminate redundant end-to-end copies
- Map every byte touch on publish/deliver/get; reduce to the minimum
  (target: **one copy** from producer payload to the socket write, zero-copy slices
  from the contiguous buffer into the writev). Remove snapshot→bytes→frame double
  materialization.
- **Accept:** per-`basic_get` copy count = `payload + O(1)` (was superlinear); 39/0
  green; no stale/leak regression; fan-out slope improved vs 0004 (`pool_bench`/
  fan-out A/B).

### P4 — Measure + decide the default
- **Paired same-broker A/B**: build 0005-OFF vs 0005-ON against the **same** RabbitMQ
  (fresh `hyrxmq-bench-rabbit`), alternating order, ≥10 reps, per-payload deltas +
  95% CIs; then the full fair matrix.
- **Accept / flip criteria:** 4 KB and 16 KB HyrxMQ/Rabbit ratio **≥ ~1.0**, no
  small-payload regression, no per-cell noise-flagged "regression" that is actually
  environmental (use the unchanged-reference null-control test from 0004). Only then
  set the contiguous path default ON; otherwise document and leave OFF.

### P5 — Closeout docs
- `MEMORY_MODEL.md` byte-ownership (RawBytes vs List[UInt8], copy counts);
  `confidence_matrix.md`; 0005 board; canonical perf report updated with the paired
  A/B and the closed (or narrowed) gap. No overclaim.

## 6. Measurement methodology (mandatory — 0004 lessons)
- **Never** compare against a *different broker instance* or different `git_head`
  without saying so; the 0004 `1.051→1.063` was confounded (different rabbit
  container + code head) → not trustworthy. 0005 uses **same-session, same-broker,
  alternating-order, paired** runs with CIs.
- Report **per-payload ratios + deltas**, not a single composite `R` (averaging a
  throughput geomean with a 3-point latency geomean masked the win and the gap).
- State the **noise ceiling** (governor, loadavg, per-cell spread); flag a
  "regression" as environmental only if the **unchanged reference** cell moves too.

## 7. Risks & mitigations
- **P1 is a core memory-ownership change** (highest-risk surface). Mitigate: keep
  `List[UInt8]` behind the interface, swap internals under a flag, exhaustive
  byte-exact + property tests, 0004 leak/negative-proof suites retained, incremental.
- **Mojo API uncertainty** (block-copy/SIMD/pointer lifetime) — G0/P1 start with
  compile probes (as 0004 did for `ref`-return/`Optional`/`swap`) before committing
  to a shape.
- **Multibuffer lifetime vs the existing BufferPool (0004, off)** — decide interaction
  early: RawBytes likely supersedes the need for the size-class pool; if so, 0005
  retires or repurposes `buffer_pool_enabled` (document; don't leave two byte models).

## 8. Definition of done
1. G0→P5 landed, each `test_all` 39/0, negative-proofed, committed as clean
   conventional-commit slices.
2. **Measured** large-payload closure (≥ ~parity at 4 KB/16 KB) on a paired same-broker
   A/B; small-payload not regressed.
3. Default flipped ON **only if P4 criteria met**; else OFF with a written verdict.
4. MEMORY_MODEL / confidence / board / canonical report reflect the real, honest state
   (what closed, what remains).

## 9. Relationship to prior milestones
- 0003 audit: §21 measured the in-broker copy ceiling (~20 MB/s vs Rabbit ~66.8) and
  named the per-byte copy path as root cause — **0005 is the direct implementation of
  that recommendation**; 0004 (P1a copy-cut + metadata/wire fidelity + evaluated-and-
  disabled pool) set the stage but left the wire path per-element.
- No source-of-truth change; semantics authoritative and unchanged.
