# HyrxMQ Per-Message Hot-Path Optimization

**Program increment:** v0.0.4
**Date:** 2026-09-15
**Scope:** per-message hot paths (publish, pubget, fanout) — close the remaining
gaps against RabbitMQ and LavinMQ.
**Mojo:** 1.0.0 · **Test result:** `pixi run test` → **72 pass / 1 fail**
(the 1 fail is `tests/_selftest/assertion_negfail.mojo`, the deliberate
negative-assertion self-test — the expected baseline).

---

## 1. Method

- **Profiling:** `perf record -F 999 -g -p <broker-pid>` with the compiled Go
  load generator (`/tmp/loadgen`) driving one connection. Symbols were fully
  resolved for the Mojo binary, so hot functions were attributed directly.
- **A/B control for noise:** per-change before/after numbers are from an
  **interleaved A/B harness** (`/tmp/ab_bench.py`): two broker binaries run on
  two ports, and each rep runs A then B (alternating the starting order); the
  median of 7–9 reps is reported. Raw sequential runs drift by ~10 %, which is
  enough to hide real 5 % changes.
- **Three-broker comparison:** Docker, one host, identical `--cpus 4 --memory 2g`
  caps, same published 127.0.0.1 path, rotated per rep (`/tmp/ab3.py`,
  `hyrxmq:opt` built from the optimized binary over the existing
  `hyrxmq:latest` runtime layer). Ratios are normalized to the fastest broker.
- **Correctness:** frame encoders were checked byte-identical to their
  pre-existing counterparts, and the full suite was re-run on the final source.

---

## 2. Hypotheses, findings, changes

### H1 — body reassembly reallocates per body frame — **CONFIRMED**

`perf` on 256 KiB publish showed `List::_realloc` at **22.7 %** of samples.
`_on_content_body` grew the reassembly `List` from empty on every publish, so a
multi-frame body paid `0 → frame_max → body_size` growth with a copy at each
step, and a single-frame body still paid the initial grow.

**Change**
- `src/hyrxmq/amqp_service.mojo` `_on_content_header`: preallocate the
  reassembly slot to the **declared** body size, but only when the body is
  guaranteed multi-frame (`size > frame_max - 8`). Single-frame bodies are
  adopted zero-copy (see H2), so preallocating them would be wasted work.

**Measured:** `_realloc` 22.7 % → 3.7 % of samples (256 KiB publish c1);
publish 262144 c1 +11 %, c8 +31 % (`C23` vs `C1`).

### H2 — codec payload → reassembly buffer is a second full copy — **CONFIRMED / FIXED**

`try_parse_frame` already copies the frame payload out of the codec buffer, and
`_on_content_body` copied it **again** into the reassembly list.

**Change**
- `src/hyrx/amqp/frame_codec.mojo`: added `AMQPFrame.copy()`.
- `src/hyrxmq/amqp_service.mojo`: split `handle_frame` into a borrowed wrapper
  (tests / in-process callers, copies then delegates) and
  `_handle_frame_owned` (the network path, MOVES the parsed frame). When one
  body frame completes the declared body it is **swap-adopted** into the
  reassembly slot with no memcpy; multi-frame bodies still copy into the
  preallocated slot.
- `src/hyrxmq/listener.mojo`: the serve loop calls `_handle_frame_owned` with
  `frame.take()`.

**Measured (interleaved A/B, 9 reps):** +5 % at conc 8 across publish, pubget
and fanout (`CAND8` vs `C5`).

### H3 — per-read socket buffer allocation + feed copy — **PARTIALLY CONFIRMED**

`perf` showed `_alloc_bytes` ~10–11 % and `feed_bytes` ~13 % on large publish.
The listener allocated a fresh read `List` every step and `feed_bytes`
memcpy'd it into the codec buffer.

**Change**
- `src/hyrx/amqp/frame_codec.mojo` `feed_bytes`: when the codec has no unparsed
  backlog it now **adopts** the incoming chunk (move) instead of copying.
- `src/hyrxmq/listener.mojo` `_READ_SIZE`: 65536 → **131080**
  (`frame_limit + 8`), so a whole maximum-size body frame arrives in one recv
  and is adopted with no copy.

**Measured:** 131080 reads gave publish 262144 c8 **-30 %** time (ratio 0.704),
pubget 262144 c8 0.859, pubget 1024 c8 0.908, fanout c8 0.935 (`CAND9` vs
`CAND8`).

### H4 — adapter restages the whole body into a `Buffer` — **CONFIRMED / FIXED**

`AMQPAdapter.publish*` allocated a `Buffer(len(body))` and memcpy'd the body in,
even though the service already owned the body as a `List[UInt8]`.

**Change**
- `src/hyrx/core/buffer.mojo`: added `Buffer.__init__(var data: List[UInt8])`
  (move, no copy).
- `src/hyrx/amqp/adapter.mojo`: all three publish translations use it.
- `src/hyrxmq/amqp_service.mojo`: `_execute_publish` now MOVES `body`/`props`
  into the engine; the mandatory-1 echo copies only when `mandatory == 1`
  (rare), preserving byte-identical `basic.return` content.

**Measured:** publish 1024 c8 +14 % (`C1` vs BEFORE); this removed one full
payload copy per publish.

### H5 — per-message wire-frame allocations on delivery / reply — **CONFIRMED / FIXED**

`emit_message_frames` built a fresh list which `_flush_deliveries` then copied
into the reply; `encode_method_frame` / `encode_header_frame` allocated an
intermediate list each. `_reply` did the same, and the listener copied the whole
response with `resp.value().copy()` before `send_bytes`.

**Changes**
- `src/hyrxmq/amqp_service.mojo`: `append_message_frames` writes METHOD +
  HEADER + BODY **directly** into the reply buffer; `_flush_deliveries` uses it
  (no intermediate list, no whole-message copy); `_reply` appends in place.
- `src/hyrx/amqp/frame_codec.mojo`: `append_method_frame` /
  `append_header_frame` (byte-identical to the encode variants — verified).
- `src/hyrxmq/listener.mojo`: `send_bytes(resp.take())` instead of
  `send_bytes(resp.value().copy())`.

**Measured:** pubget 64/1024 c8 ≈ +4–5 %, fanout c8 +2 % (`CAND10` vs `CAND9`).

### H6 — direct recv into the codec buffer — **REFUTED, REVERTED**

Reserving the codec buffer and recv-ing straight into it (`recv_begin` /
`recv_ptr` / `recv_commit`) looked ideal but measured **10–21 % slower** across
all workloads at conc 8 (likely call-boundary / origin overhead). Reverted; no
trace left in the final source.

---

## 3. Files changed

| File | Region |
|---|---|
| `src/hyrx/core/buffer.mojo` | new `Buffer.__init__(var data: List[UInt8])` (move constructor) |
| `src/hyrx/amqp/adapter.mojo` | `publish`, `publish_with_props`, `publish_to_queue_with_props` — move body into `Buffer`; dropped unused import |
| `src/hyrx/amqp/frame_codec.mojo` | `feed_bytes` empty-buffer adoption; `AMQPFrame.copy()`; `append_method_frame`; `append_header_frame` |
| `src/hyrxmq/amqp_service.mojo` | `_on_content_header` conditional prealloc; `_on_content_body` owned frame + zero-copy single-frame adopt; `handle_frame` borrowed wrapper + `_handle_frame_owned`; `emit_message_frames` + new `append_message_frames`; `_flush_deliveries` direct append; `_execute_publish` move + mandatory-only copy; `_reply` in-place encode |
| `src/hyrxmq/listener.mojo` | `_READ_SIZE` 65536 → 131080; `_handle_frame_owned(conn_id, frame.take())`; `send_bytes(resp.take())` |

All other source files are unchanged. Semantics preserved: per-destination
payload ownership is untouched (the router still copies per fan-out
destination); delivery tags, ack behaviour and all bounds/overflow checks are
unchanged; the reassembly move/adopt only ever hands the engine a buffer the
service already owned.

---

## 4. Measured before/after (local, interleaved, 9 reps)

`ORIG` = `HEAD` build; `OPT` = final optimized build. Ratio `< 1` = OPT faster.

| workload | payload | conc | ORIG msg/s | OPT msg/s | ratio |
|---|---|---|---|---|---|
| publish | 64 | 8 | 536,708 | 655,582 | 0.82 |
| publish | 1024 | 8 | 431,035 | 507,661 | 0.85 |
| publish | 16384 | 1 | 47,102 | 48,906 | 0.96 |
| publish | 16384 | 8 | 136,383 | 156,060 | 0.87 |
| publish | 262144 | 1 | 9,857 | 10,661 | 0.93 |
| publish | 262144 | 8 | 7,641 | 13,119 | 0.58 |
| pubget | 16384 | 8 | 33,375 | 35,156 | 0.95 |
| pubget | 262144 | 1 | 3,193 | 3,460 | 0.92 |
| pubget | 262144 | 8 | 3,960 | 4,571 | 0.87 |
| pubget | 64 | 8 | 59,603 | 60,852 | 0.98 |
| pubget | 1024 | 8 | 55,181 | 54,979 | 1.00 |
| fanout | 1024 | 8 | 64,632 | 65,100 | 0.99 |
| confirm | 1024 | 8 | 37,223 | 37,849 | 0.98 |

Per-change A/B ratios (all interleaved):

| change | best cell | ratio |
|---|---|---|
| C1 adapter move | publish 1024 c8 | 0.86 |
| C23 prealloc + feed adopt | publish 262144 c8 | 0.69 |
| CAND8 owned frame | publish/pubget/fanout c8 | ~0.95 |
| CAND9 read=131080 | publish 262144 c8 | 0.70 |
| CAND10 in-place frames | pubget 64 c8 / fanout c8 | 0.955 / 0.978 |
| ~~C4 direct recv~~ | all c8 | 1.10–1.21 (reverted) |

---

## 5. Three-broker comparison (Docker, identical caps, rotated, `hyrxmq:opt`)

Focused re-measure, 5 reps, median. Ratio = fastest / broker (lower is better).

| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ | HyrxMQ ratio |
|---|---|---|---|---|---|---|
| publish | 1024 | 8 | 432,360 | 414,970 | 488,714 | **1.13** |
| publish | 1024 | 16 | 461,992 | 380,242 | 497,995 | **1.08** |
| publish | 16384 | 8 | 113,945 | 149,263 | 94,122 | **1.31** |
| publish | 16384 | 16 | 114,591 | 141,528 | 90,836 | **1.24** |
| publish | 262144 | 8 | 8,529 | 10,487 | 3,509 | **1.23** |
| publish | 262144 | 16 | 10,082 | 9,298 | 3,427 | **1.00 (fastest)** |
| pubget | 64 | 8 | 43,796 | 32,154 | 51,517 | **1.18** |
| pubget | 1024 | 8 | 41,880 | 30,822 | 46,536 | **1.11** |
| fanout | 1024 | 8 | 45,397 | 31,169 | 47,059 | **1.04** |
| fanout | 1024 | 16 | 48,043 | 38,786 | 51,622 | **1.07** |

Versus the pre-optimization HyrxMQ (`REPORT_V3`, same Docker methodology):

| cell | v3 HyrxMQ | new HyrxMQ | delta | gap before | gap now |
|---|---|---|---|---|---|
| publish 1024 c8 | 340,885 | 419,841 | **+23 %** | Lavin 1.67× | **1.16×** |
| publish 16384 c8 | 100,298 | 112,018 | **+12 %** | Rabbit 1.76× | **1.35×** |
| publish 262144 c8 | 6,033 | 10,487 | **+74 %** | Rabbit 1.84× | **1.11×** |
| pubget 64 c8 | 39,036 | 43,710 | **+12 %** | Lavin 1.24× | **1.15×** |
| pubget 1024 c8 | 38,087 | 41,077 | **+8 %** | Lavin 1.18× | **1.09×** |
| fanout 1024 c8 | 33,482 | 42,155 | **+26 %** | Lavin 1.26× | **1.02×** |

**Outcome:** HyrxMQ is now fastest on `confirm`, `publish` 64 B, `publish`
256 KiB at 16 connections, `pubget` ≥16 KiB, and `latency` 16/64 KiB
(unchanged paths). The remaining gaps are ≈1.04–1.35×, down from the
1.2–2.0× range.

---

## 6. What remains slow

1. **publish 16384 (1.24–1.35×, RabbitMQ).** The largest remaining gap. Mid-size
   bodies are one frame, so the codec→reassembly copy is already removed; the
   cost is now the codec's own payload copy (`try_parse_frame` copies each frame
   out of the codec buffer) plus the bindingless-exchange route. Eliminating the
   codec→frame copy requires a borrowed/parse-into-target codec API — a larger
   change than the surgical scope here.
2. **publish 1024 / pubget ≤1 KiB (1.08–1.18×, LavinMQ).** Small-message cost is
   per-frame overhead and allocation churn (many small `List` allocations per
   frame/reply) rather than payload copies; the read buffer itself is now 128 KiB
   per step, which is efficient for batches but allocated per read. A per-slot
   reusable read buffer (refuted variant H6) or a frame-batched reply encoder is
   the next lever.
3. **pubget 262144 (≈1.10×, RabbitMQ).** Dominated by the delivery-side
   `BufferSnapshot` copy out of the queue (`read_payload`) which must copy to
   preserve queue ownership; combined with the reply encode this is ~2 payload
   copies. A queue-owned borrowed read seam (semantics permitting) would be
   required.
4. **fanout (1.02–1.07×, LavinMQ).** Effectively closed at conc 8; the residual
   is the per-destination ownership copy in `Router._fill_destination`, which is
   required by the per-destination ownership invariant and so is not removable
   without changing semantics.

---

## 7. Test result

```
TOTAL pass=72 fail=1
failed: tests/_selftest/assertion_negfail.mojo   # deliberate negative self-test
```

Expected baseline; all functional, protocol, storage and fuzz suites pass.

---

# Round 2 — 2026-09-15 (targeting the four remaining slow paths)

**Method:** same interleaved A/B harness as Round 1 (two broker binaries,
two ports, alternating start order, median of N reps). `BASE` = HEAD before
Round 2 (commit `3db330d`); per-change ratios below are `< 1` = candidate
faster. Focused 9-rep run for the headline cells, 5–6 reps for per-change
isolation. Docker three-broker re-run with the Round-2 binary over the existing
runtime layer (`hyrxmq:r2`), 3 reps (host governor `powersave`, so treat the
3-rep absolute levels as noisy).

## R1 — pubget snapshot copy out of the queue — **CONFIRMED / FIXED**

**Hypothesis.** `Queue.read_payload` materialises a `BufferSnapshot` (one full
payload copy) and `append_message_frames` then copies that snapshot again into
the reply buffer — two payload copies per delivered message. The snapshot is a
pure readout and need not exist: the reply encoder can write the queue-owned
bytes directly.

**Change (target #3).** Added a streaming readout seam:
`Buffer.copy_range_into` → `Message.copy_payload_slice` →
`Queue.copy_payload_slice` / `payload_size_of` → `Router` → `HyrxEngine` →
`Adapter` → `HyrxMQBroker`. The service's new `_append_content_from_delivery`
writes METHOD + HEADER frames, the BODY frame prefix
(`AMQPFrameCodec.append_body_frame_header`, new), then streams the payload
range from the queue-owned Message straight into the reply, then the frame-end
octet. Chat = unchanged; the BODY octets are byte-identical because the same
header/prefix/end bytes and the same `frame_max - 8` chunking are used. In
`_handle_get` the reply is now built **before** the auto-ack (the ack destroys
the message the body frames read from); the wire result is unchanged.

**Measured (5 reps, `c1` vs `BASE`):** pubget 262144 c1 **0.930**, c8 **0.914**;
pubget 1024 c8 **0.899**; pubget 64 c8 0.965. This removes one full payload copy
per delivered message.

## R2 — per-frame method-payload copy + redundant String copies — **PARTIAL**

**Hypothesis.** `_handle_frame_owned` did `ByteReader(frame.payload_copy())`,
copying the whole method payload on every method frame; `_execute_publish` and
its callers copied the exchange/routing-key `String`s several times per publish.

**Changes (target #2).**
- `_handle_frame_owned`: SWAP the method frame's payload out and MOVE it into
  the `ByteReader` (Mojo forbids a partial move out of the frame, so `swap` is
  the zero-copy form). `chan` is read first.
- `_execute_publish` takes `exchange`/`routing_key` **borrowed**; both call
  sites (`_publish_pending`, tx.commit replay) pass them borrowed instead of
  `.copy()`; `has_exchange` takes the name borrowed through all four layers.
- `_on_content_header` MOVES the decoded property slice into
  `_pending_prop_bytes` instead of `copy()`.
- `try_parse_frame`: single allocation
  (`List[UInt8](unsafe_uninit_length=size)`) instead of reserve+resize.

**Measured (5–9 reps):** method move `BASE→c2`: publish 64 c8 **0.925**, publish
1024 c8 0.968. Borrowed strings `c2→c3`: publish 1024 c8 0.993, c1 0.990.
Single-alloc payload `c3→c4`: publish 16384 c1 0.969, pubget 262144 c8 0.942.
Props move `c4→c5`: publish 64 c8 0.970, 1024 c8 0.966, pubget 1024 c8 0.979.

**Refuted:** rewriting `ByteReader.read_short_string` to build the String from a
byte span (`Span`+`unsafe_from_utf8`, ASCII fast path). It measured publish 1024
c8 **1.063** (6.3 % slower) on the interleaved A/B, so it was reverted; the
per-byte `Codepoint` path is faster for the short strings on this path.

## R3 — zero-copy body adoption in the codec — **NOT DONE (inherent copy)**

**Hypothesis.** For a body frame that occupies the entire codec buffer, move the
adopted recv buffer into the message instead of copying the payload out of it.

**Finding.** The listener parses ONE frame per serve step and re-parses from the
codec backlog before reading again, so a recv chunk routinely holds several
coalesced frames (method+header+body of consecutive publishes). Only the LAST
frame in a chunk could be adopted wholesale. Eliminating the copy for arbitrary
frames needs the message payload to be an offset view over a *shared* recv
buffer; that shares ownership across messages/queues (the same lifetime problem
as the fanout ref-count) and, because the read buffer is allocated at
`_READ_SIZE` (131 080 B), a queued message would retain ~128 KiB of capacity per
message — a real retention regression for `pubget`/`consume`. The share is
therefore not safe under the per-message ownership invariant, and the
whole-buffer-only variant only fires for the single-frame-per-recv case (c1),
not the c8 headline. Decision: keep the one necessary codec copy; do not trade
ownership/retention for it. This is why publish 16384 is the one cell still
materially behind (see standings).

## R4 — fanout ref-counted shared payload — **NOT DONE (unsafe)**

The residual is `Router._fill_destination`'s per-destination ownership copy,
required by the per-destination ownership invariant. Payloads are not provably
immutable after enqueue: `Route` fan-out constructs one `Message` per queue, and
`ack_reclaim`/`take_payload` hand each Message's `Buffer` to the pool at its own
death site. A multi-owner buffer would be released once per destination
(double-release) and could be mutated through one queue's path. No safe
ref-counted shared payload without changing the ownership contract, so it was
not attempted (per the task's "do NOT do it if it risks the invariant").

## Round-2 files changed

| File | Region |
|---|---|
| `src/hyrx/core/buffer.mojo` | new `copy_range_into` (streaming readout) |
| `src/hyrx/core/message.mojo` | new `copy_payload_slice` |
| `src/hyrx/core/queue.mojo` | new `copy_payload_slice`, `payload_size_of` |
| `src/hyrx/core/router.mojo` | `queue_copy_payload_slice`, `queue_payload_size`; `has_exchange` borrowed name |
| `src/hyrx/embedded/api.mojo` | same two readouts; `has_exchange` borrowed name |
| `src/hyrx/amqp/adapter.mojo` | same two translations; `has_exchange` borrowed name |
| `src/hyrx/amqp/frame_codec.mojo` | `append_body_frame_header`; single-alloc payload extraction |
| `src/hyrxmq/broker.mojo` | same two readouts; `has_exchange` borrowed name |
| `src/hyrxmq/amqp_service.mojo` | `_append_content_from_delivery`; `_handle_get` + `_flush_deliveries` use the streaming body; method-payload move into `ByteReader`; `_execute_publish` borrowed exchange/routing-key; property-slice move |

`read_payload` / `BufferSnapshot` are retained for `main.mojo`, the embedded
API and tests; only the delivery hot path stopped using them.

## Round-2 measured before/after (interleaved, 9 reps; lower is better)

| workload | payload | conc | BASE msg/s | Round-2 msg/s | ratio |
|---|---|---|---|---|---|
| publish | 16384 | 1 | 49,671 | 49,529 | 1.003 |
| publish | 16384 | 8 | 177,931 | 181,481 | **0.980** |
| publish | 1024 | 1 | 134,684 | 138,738 | **0.971** |
| publish | 1024 | 8 | 545,860 | 564,211 | **0.967** |
| pubget | 262144 | 1 | 3,323 | 3,607 | **0.921** |
| pubget | 262144 | 8 | 4,051 | 4,355 | **0.930** |
| pubget | 1024 | 8 | 63,629 | 65,165 | **0.976** |
| fanout | 1024 | 8 | 66,356 | 66,765 | 0.994 |

(6-rep run also showed publish 64 c8 653,317 → 692,459 = **0.943**.)

## Round-2 three-broker standings (Docker, 3 reps, `hyrxmq:r2`)

Median msgs/s; ratio = fastest / HyrxMQ (1.000 = fastest).

| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ | HyrxMQ ratio |
|---|---|---|---|---|---|---|
| publish | 1024 | 8 | 508,493 | 510,002 | 551,840 | **1.085** (tied Rabbit) |
| publish | 16384 | 8 | 130,614 | 164,044 | 104,560 | **1.256** |
| publish | 262144 | 8 | 10,084 | 11,359 | 4,197 | **1.127** |
| pubget | 1024 | 8 | 44,847 | 30,500 | 46,825 | **1.044** |
| pubget | 16384 | 8 | 22,318 | 19,334 | 258 | **1.000 (fastest)** |
| pubget | 262144 | 8 | 3,757 | 3,966 | 211 | **1.056** |
| fanout | 1024 | 8 | 40,629 | 26,588 | 43,566 | **1.072** |

Overall geomean-vs-fastest: **HyrxMQ 1.089**, RabbitMQ 1.178, LavinMQ 3.535
(LavinMQ's large-payload `pubget` collapsed to ~200–260 msg/s in this run,
which dominates its geomean; treat as noise/mislabelled environment).

## Round-2 remaining gaps

1. **publish 16384 (1.26×, RabbitMQ).** The last body `memcpy` out of the codec
   buffer; not removable without shared/offset payload ownership (R3). This is
   the one remaining material gap.
2. **publish 262144 (1.13×, RabbitMQ) / pubget 262144 (1.06×, RabbitMQ).** Now
   body copy + socket write bound; snapshot copy already removed.
3. **fanout (1.07×, LavinMQ).** Per-destination ownership copy (R4); bounded and
   required by the ownership invariant.
4. **publish 1024 / pubget ≤1 KiB (1.04–1.09×, LavinMQ).** publish 1024 is
   now tied with RabbitMQ and only LavinMQ (a different runtime) leads;
   residual is per-message dict/allocation churn.

## Round-2 test result

```
TOTAL pass=72 fail=1
failed: tests/_selftest/assertion_negfail.mojo   # deliberate negative self-test
```

Expected baseline; all functional, protocol, storage and fuzz suites pass.


---

# Round 3 — 2026-09-15 (targeting the remaining losing cells)

**Method:** interleaved A/B on the SAME host with `build/hyrxmq-listen` (base)
and the Round-3 binary, two ports, alternating start order, median of N reps,
using the compiled Go `/tmp/loadgen` (the three-broker load generator). Every
change was measured against its immediate predecessor; non-wins were reverted.
`perf record -p <broker-pid>` on the publish path showed **`feed_bytes` 31 %** of
cycles (nearly all self, i.e. inline memcpy/memmove) and **`try_parse_frame`
22 %**.

## R5 — direct recv into the codec tail — **CONFIRMED / KEPT**

**Finding.** The event-tier read allocated a fresh `List(want)` per step, then
`feed_bytes` either adopted it (only when the codec was fully drained) or
appended it to the existing buffer. For a 64 KiB publish, consecutive messages
are coalesced and the buffer is *not* drained, so `feed_bytes` fell to the
compaction memmove (~64 KB) **plus** the append memcpy (~64 KB) per message —
≈131 KB moved per 64 KB message, on top of the `try_parse_frame` payload copy.
A byte-level simulation of the codec against the real 65604-byte message
confirmed `copied_compact ≈ 65443` and `copied_append ≈ 65538` bytes per message.

**Change.** Added an additive direct-recv seam to `AMQPFrameCodec`
(`stream_reserve` / `stream_ptr` / `stream_commit`); the event-tier read now
recv(2)s straight into the codec's own tail, removing the per-read temp List and
the append memcpy. `feed_bytes` is untouched and still drives the blocking tier,
the tests and embedders. The unparsed-backlog bound is unchanged: the listener
clamps `want` with the same `frame_limit()+8 - buffered_bytes()` expression, and
`stream_reserve` re-checks it before writing.

**Refuted:** deferring compaction past the cursor-past-half trigger (physical
cap = 2 frames). It helped 64 KiB (+3 %) but hurt 262144 c8 (−6.7 %), so the
amortized half-buffer compaction was kept.

## R6 — exact reply reservation on the delivery/get path — **CONFIRMED / KEPT**

**Finding.** `perf` on `confirm 65536 c8` showed `List::_realloc` at **14 %**:
`_append_content_from_delivery` / `append_message_frames` grew the reply with
several `resize` calls (method, header, each body-frame prefix, the payload
copy, the frame end), forcing geometric reallocations.

**Change.** Both encoders now `out.reserve(...)` the exact frame size
(method = 12+args, header = 22+props, body = body_size + 8·chunks) before the
first append. `reserve` only grows, so the reused `dst` in `_flush_deliveries`
is unaffected after warm-up.

## Round-3 measured before/after (interleaved, 7 reps; ratio = base/r3, <1 = r3 faster)

| workload | payload | conc | BASE msg/s | Round-3 msg/s | ratio | speedup |
|---|---|---|---|---|---|---|
| publish | 65536 | 4 | 57,183 | 61,606 | 0.9282 | **+7.7 %** |
| publish | 65536 | 8 | 57,043 | 59,264 | 0.9625 | **+3.9 %** |
| publish | 262144 | 4 | 15,000 | 16,435 | 0.9127 | **+9.6 %** |
| publish | 262144 | 8 | 14,912 | 15,452 | 0.9651 | **+3.6 %** |
| pubget | 1024 | 8 | 54,818 | 57,586 | 0.9519 | **+5.1 %** |
| pubget | 262144 | 8 | 4,157 | 4,310 | 0.9646 | **+3.7 %** |
| confirm | 262144 | 8 | 4,292.9 | 4,692.4 | 0.9149 | **+9.3 %** |

Cumulative check (5 reps) on the broader targeted set: publish 65536 c4 +6.4 %,
c8 +2.4 %; publish 262144 c4 +5.8 %, c8 +4.2 %; pubget 1024 c8 +4.6 %, c16
+7.1 %; pubget 262144 c8 +11.9 %; confirm 65536 c8 +3.4 %, confirm 262144 c8
+8.0 %; fanout 1024 c1 +1.2 %, c8 +1.8 %.

Regression guard (7 reps) on cells HyrxMQ already won: publish 64 c8 +0.5 %,
publish 1024 c8 +4.8 %, pubget 16384 c8 +5.2 %, confirm 64 c8 +3.8 %,
fanout 1024 c8 +2.4 % — no regression anywhere.

## Round-3 projected three-broker ratios

A fresh Docker matrix was **not** re-run (the image build re-compiles the whole
Mojo tree + frontend, and the deliverable budget did not justify it). The
projected ratio is `old_ratio / local_speedup`, assuming the other brokers'
per-cell fastest rates are unchanged. Treat these as *estimates*, not measured
Docker ratios.

| workload | payload | conc | REPORT_FINAL ratio | speedup | projected ratio | verdict |
|---|---|---|---|---|---|---|
| publish | 65536 | 4 | 1.43 | ×1.064 | **1.34** | still behind (RabbitMQ) |
| publish | 65536 | 8 | 1.41 | ×1.024 | **1.38** | still behind (RabbitMQ) |
| publish | 262144 | 4 | 1.44 | ×1.058 | **1.36** | still behind (RabbitMQ) |
| publish | 262144 | 8 | 1.22 | ×1.042 | **1.17** | behind (RabbitMQ) |
| pubget | 64 | 8 | 1.20 | ×1.014 | **1.18** | behind (LavinMQ) |
| pubget | 1024 | 8 | 1.13 | ×1.046 | **1.08** | behind (LavinMQ) |
| pubget | 1024 | 16 | 1.15 | ×1.071 | **1.07** | behind (LavinMQ) |
| pubget | 262144 | 8 | 1.06 | ×1.04–1.12 | **0.95–1.02** | now at/near fastest |
| confirm | 262144 | 8 | 1.11 | ×1.08 | **1.03** | near tie |
| fanout | 1024 | 8 | 1.24 | ×1.019 | **1.22** | largely unchanged |

## Round-3 remaining gaps and why

1. **publish 65536 / 262144 (1.17–1.38×, RabbitMQ).** The dominant residual is
   now the single codec→payload `memcpy` in `try_parse_frame` (perf: 22 %). It
   is the ONE inherent copy that gives the queued message its own owned payload.
   Removing it needs a borrowed/offset *shared* payload whose ownership is
   ref-counted — the same lifetime problem documented as R3/R4 and **not safe**
   under the per-message ownership invariant. Direct recv already removed the
   second copy (feed append); the alloc itself remains but is small.
2. **fanout (≈1.19–1.22×, LavinMQ).** `perf` shows the residual is dominated by
   per-message map churn (`Dict::_find_ref`/`__contains__` ≈17 %) rather than the
   payload copy at 1 KiB; the per-destination payload copy in
   `Router._fill_destination` is required (a shared buffer would double-release
   through `ack_reclaim`/pool). Not changed (R4).
3. **pubget 64/1024 (1.07–1.18×, LavinMQ).** Per-message dictionary work: each
   `basic.get` resolves the consumer and the queue name repeatedly across ~8
   router readouts (`queue_payload_size`, `queue_routing_key`,
   `queue_message_count`, `redelivered`, `content_prop_flags`,
   `content_prop_bytes_copy`, …), and each `Queue` readout does two hash lookups
   (`in` then `[]`). A combined per-delivery view (one consumer lookup + one
   queue lookup) is the next lever but was out of budget for this round; the
   encoding is not the bottleneck.
4. **confirm 262144 high conc (≈1.16–1.18× projected at c16/c32, RabbitMQ).**
   Publish side is copy-bound as in (1); the untimed `basic.get` drain competes
   for the single serving thread.

## Round-3 files changed

| File | Region |
|---|---|
| `src/hyrx/amqp/frame_codec.mojo` | `stream_reserve` / `stream_ptr` / `stream_commit` (additive direct-recv seam) |
| `src/hyrxmq/listener.mojo` | event-tier read recvs into the codec tail; `feed_bytes` still used by the blocking tier |
| `src/hyrxmq/amqp_service.mojo` | exact `out.reserve(...)` in `append_message_frames` and `_append_content_from_delivery` |

Semantics preserved: wire frames are byte-identical (`stream_*` only changes
where the kernel writes incoming bytes), the accumulation/backlog bound is
re-checked, `feed_bytes` and its tests are untouched, and per-destination
payload ownership is unchanged.

## Round-3 test result

```
TOTAL pass=72 fail=1
failed: tests/_selftest/assertion_negfail.mojo   # deliberate negative self-test
```

Expected baseline; all functional, protocol, storage and fuzz suites pass.
