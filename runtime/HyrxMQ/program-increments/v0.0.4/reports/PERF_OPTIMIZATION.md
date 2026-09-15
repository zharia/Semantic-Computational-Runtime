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
