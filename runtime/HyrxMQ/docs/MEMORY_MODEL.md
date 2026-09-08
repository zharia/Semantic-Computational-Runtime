# Memory and Ownership Model

## Goals

- predictable lifetimes
- low allocation rate
- minimal copying
- cache locality
- bounded memory
- safe concurrent ownership transfer

Mojo's ownership and lifetime model is particularly relevant to this design.

## Proposed primitives

The implementation should investigate:

- `Buffer` — implemented (`src/hyrx/core/buffer.mojo`)
- `BufferSnapshot` — implemented (`src/hyrx/core/buffer_snapshot.mojo`); renamed
  from `BufferView` on 2026-09-08 because the old name claimed a borrowed view
  while the type COPIES bytes (see "§22 probe" below)
- `BufferChain` — not implemented
- `BufferPool` — implemented (`src/hyrx/core/buffer_pool.mojo`) but NOT on the
  message path: no production call site invokes `acquire()`/`release()`
  (only `tests/phase1/buffer_pool_test.mojo` does)
- slab allocator — partially, via `BufferPool`
- arena, ring buffer, segment — not implemented
- message envelope — implemented (`Message`/`Envelope`, `src/hyrx/core/message.mojo`)
- reference/view types with explicit lifetime rules — NOT implemented; there is
  currently no borrowed-view type at all, only owned copies

Names are provisional; semantics are normative.

## Copy policy

Every copy on a hot path must have a reason.

Instrumentation should expose:

- bytes copied/message
- copies/message
- allocations/message
- deallocations/message
- pooled reuse rate

## Ownership transitions

Normative intent below; the as-built trace (all stages, with owners, moves,
copies and reclaim points) is in "§5 Message lifecycle ownership trace" at the
end of this file.

Document ownership transitions for:

1. producer creates/acquires payload
2. routing acquires delivery ownership
3. queue owns pending delivery
4. consumer receives ownership/view
5. acknowledgement releases/reclaims resources

## Safety rule

Do not bypass Mojo's ownership/lifetime system with unsafe aliases unless the performance benefit is demonstrated and the lifetime contract is formally documented and tested.

## Resource exhaustion

All pools and queues must have explicit capacity behavior.

Exhaustion must result in one of:

- backpressure
- rejection
- blocking where explicitly configured
- controlled failure

Never uncontrolled memory growth.

---

# Audit record — 2026-09-08 (§5 lifecycle, §22 BufferView, §6 routing, §7 bounds)

Single-author pass over `src/hyrx/core/**` and `tests/phase1`, `tests/phase2`.
All claims below were read out of the code and, where marked *probe*, executed.

## §5 Message lifecycle ownership trace

Stages: producer → create → route → queue → consumer → delivery → ack/nack/reject → release.
Words are literal: **moved** = Mojo ownership transfer (`^`), **copied** = bytes duplicated,
**borrowed** = read-only access with a lifetime tie, **destroyed** = value leaves scope.

| # | Stage (code) | Payload owner | Metadata owner | Ownership event | Bytes | Immutability | Reclaim |
|---|---|---|---|---|---|---|---|
| 0 | Producer builds `Buffer` (`buffer.mojo:29`) | producer's `Buffer` | producer's `Envelope` (`message.mojo:36`) | allocation | fresh | none yet | producer scope |
| 1 | `Message(env, payload)` (`message.mojo:65`) | **moved** into `Message` | **moved** into `Message` | transfer | none | payload mutable only through the producer's `Buffer` handle, which no longer exists | — |
| 2 | `Router.publish(msg, ex)` entry (`router.mojo:126`) | **moved** into `publish` (param is `var msg`) | same | transfer | none | producer can no longer touch it; `msg` is destroyed at the end of publish | step 8 |
| 3 | `Exchange.match(key)` (`exchange.mojo:175`) | unchanged (`Message` still owned by publish) | unchanged | none — routing key **read** | key string copied | — | — |
| 4 | Per-destination clone (`router.mojo:167-179`) | **copied once** per destination via `Message.payload_copy()` → `Buffer.from_buffer_copy()` (`buffer.mojo`), a single append pass at the source's logical size (no intermediate `BufferSnapshot` + byte-loop + `resize` zero-fill). The single-eligible-queue path transfers the source `Message` directly via `Queue.enqueue_prechecked` (`router.mojo:159-165`) — **zero copies** | **preserved**: `Envelope(msg.message_id(), msg.routing_key(), msg.headers())` keeps the publisher's id and header map (headers is an independent copy). Read-back via `Queue.read_message_id`/`read_headers` and `Router.read_message_id`/`read_headers` (`queue.mojo:148/154`, `router.mojo:301/308`) | new `Message` per destination; one owned message on the move path | 1 copy of every byte per destination (0 on the single-dest move) | clone becomes immutable once enqueued | — |
| 5 | `Queue.enqueue(msg)` (`queue.mojo:81`) | **moved** into `Queue._inbox` | moved with it | transfer | none | **immutability point**: from here on no API can mutate the queued bytes (`Queue` exposes only `read_*`; `Message` exposes no mutating payload accessor). The only field that changes is `delivery_count` | step 9 or 10 |
| 5b | `enqueue` refused (capacity) (`queue.mojo:85-87`) | the destination's copy is **destroyed** | destroyed | none | the copy's bytes are freed | — | immediately |
| 6 | `Queue.dequeue()` (`queue.mojo:91`) | **moved** `_outbox` → `_unacked[tag]` — the Queue still owns it | same | internal move | none | still immutable | step 8 |
| 7 | `consume` returns `Delivery` (`queue.mojo:36`) | Queue (unchanged) | Queue | **no transfer**: `Delivery` carries only a `UInt64` tag | none | — | — |
| 8 | Consumer reads: `Router.read_payload` → `Queue.read_payload` → `Message.payload()` (`router.mojo:274`, `queue.mojo:107`, `message.mojo:82`) | bytes **copied** into a `BufferSnapshot` returned to the caller; caller owns that copy | routing key **copied** (`Queue.read_routing_key`) | none for the message | +1 copy of the payload per read (per consumer) | the snapshot is a frozen point-in-time copy: it survives ack, reject and queue deletion | consumer scope |
| 9 | `acknowledge` (`queue.mojo:129`) | **moved** out of `_unacked` into a local, then **destroyed** at scope end → payload freed | destroyed | release | none | — | **reclaim point** |
| 10 | `reject` (`queue.mojo:136`) | **moved** `_unacked` → `_inbox` (TAIL) | same | internal move | **none** — no re-copy on redelivery | unchanged | deferred to a later ack |
| 11 | Redelivery (`queue.mojo:91` again) | same `Message` object, `delivery_count` incremented (probe: 2 after one reject) | same | internal move | none | — | — |
| 12 | Disconnect | **N/A** — the core is single-node and has no connection/session lifetime. The closest event, `Router.unregister_consumer` (`router.mojo:204`), drops only the `Consumer` value and leaves its unacked `Message`s owned by the Queue forever (defect D8) | — | — | — | orphan reclaim only if someone presents the tag |

### Per-stage answers required by audit §5

- **Fate on failed delivery (destination full)**: only that destination's copy is destroyed;
  other destinations keep theirs; `publish` reports the smaller count (`router.mojo:182-184`).
- **Fate on unroutable publish**: no copy is ever made; the source `Message` is destroyed by the
  `publish` call; the only signal is `routed == 0` (defect D4).
- **Fate on redelivery**: no re-allocation, no re-copy — the Queue's own `Message` is moved back
  into the pending set, so `delivery_count` accumulates on the same bytes.
- **Multiple consumers on one queue**: there is ONE shared cursor. Each consumer gets a distinct
  `Delivery` tag and each `read_payload` call makes a distinct copy; two consumers never share a
  payload object, and neither can see the other's reads.
- **Multiple queues (fan-out)**: fully independent owned copies; acking/rejecting in queue A has
  no effect on queue B's copy (asserted in `tests/phase2/routing_matrix_test.mojo`).

## §22 probe: `BufferView` claimed "non-owning view" but COPIED

Empirical probe (`/tmp/opencode/bv_probe.mojo`, run
`pixi run mojo run -I src -I vendor/flare`):

```
after origin mutation:          view = 16 17 18 19   (origin set to 0xFF)
after origin move/drop:  size=2  view2 = 170 187
to_bytes:                       170 187
```

- Mutating the origin after `as_view()` did NOT change the view → snapshot, not aliasing.
- Reading the view after the origin `Buffer` was moved into a consuming function and destroyed
  still returned the original bytes → the view **owns** its allocation; it is not dangling and
  never was a borrowed pointer.
- Root cause: `BufferView` stored `var _data: List[UInt8]` (an owned list), and
  `Buffer.as_view()` copied every byte into it. The file header ("Non-owning reference…",
  "never allocates or frees", "borrows from an existing allocation") was false.

**Decision — rename, not doc-patch.** A type that owns a copy must not be called a *view*, and
"non-owning" was asserted in prose that no test pinned. Chosen name: **`BufferSnapshot`**
(it says what it is and matches the `Buffer` family; `PayloadSnapshot` would have been wrong —
the type is byte-generic and also used for empty reads and non-payload callers).

Applied 2026-09-08:

| Change | Sites |
|---|---|
| `struct BufferView` → `struct BufferSnapshot` | 1 definition |
| file `src/hyrx/core/buffer_view.mojo` → `buffer_snapshot.mojo` | 1 file |
| `hyrx.core.buffer_view` → `hyrx.core.buffer_snapshot` (imports) | 6 (buffer, message, queue, router, embedded/api, tests/phase1/buffer_test) |
| Type mentioned in signatures/docs | 8 (`Buffer.as_view`, `Message.payload`, `Queue.read_payload`, `Router.read_payload`, `Hyrx.read_payload`, comments in router + buffer) |
| `Buffer.as_view()` → `Buffer.snapshot()` (a method named `as_view` returning a copy is the same lie) | 3 (buffer.mojo def, message.mojo call, tests/phase1/buffer_test.mojo ×2) |
| Truthful copy/snapshot wording written into buffer, message, queue, router, embedded docs | 5 files |
| No changes required in `src/hyrx/amqp/**`, `src/hyrx/transport/**`, `src/hyrxmq/**` — they never named the type | 0 |

`grep -rn "BufferView\|buffer_view" src/ tests/` → no residual references.

Regression guard added: `test_snapshot_survives_origin_mutation`,
`test_snapshot_survives_origin_destruction`, `test_to_bytes_is_second_copy`
(`tests/phase1/buffer_test.mojo`) — the probe is now part of the suite.

## §6 routing outcome matrix (executable form: `tests/phase2/routing_matrix_test.mojo`)

| Case | Observed outcome | Bytes/ownership |
|---|---|---|
| 1 pub → 1 queue (direct, exact key) | `routed == 1`, one claim | payload copied per destination |
| 1 pub → N queues (fanout) | `routed == N`; `messages_routed += N` | N **independent owned copies** |
| N pub → 1 queue | FIFO preserved (`0x50..0x53` order) | N owned messages |
| N pub → N queues | full cross product; `routed == N` each publish | N×M owned copies |
| M consumers → 1 queue | **pull-by-call**: `consume(cid)` pops the queue head for whoever asks. No round-robin, no fairness, no per-consumer partition — one polling consumer drains everything. Per-consumer `prefetch` is the only gate (`prefetch=0` ⇒ unlimited) | one shared cursor; +1 copy per `read_payload` |
| Unroutable publish | `routed == 0`, source `Message` destroyed, no raise | nothing copied |
| Unknown exchange | `routed == 0`, no raise | nothing copied |
| Binding to missing queue/exchange | `bind_queue` returns `False` | — |
| Multiple matching bindings, different queues | one copy each | owned copies |
| Multiple matching bindings, SAME queue | **FIXED**: one copy (was 2 — see defect list) | one owned copy |
| Duplicate binding (same queue+key) | idempotent: stored once, routed once | one owned copy |
| Unbind | exact `(queue,key)` removal → unroutable | — |
| headers exchange | matches everything (stub) | — |

## §7 Bounded-resource matrix (executable form: `tests/phase2/bounded_resource_test.mojo`)

| Resource | Limit? | Enforced? | Producer-visible | Consumer-visible | Message fate | Recovery |
|---|---|---|---|---|---|---|
| Queue depth | `QueueConfig._capacity` | **yes**, against `inbox+outbox+unacked` | `publish` returns a lower count; `Queue.enqueue` returns `False`; no raise | no | the per-destination copy is **destroyed** | ack/reject frees a slot |
| Message size | none in core | **NO** — not bounded | none | none | accepted regardless of bytes | n/a |
| Bytes per queue | none | **NO** — capacity counts messages, not bytes; fan-out costs ~2 copies/destination + 1 more per payload read | none | none | — | n/a |
| Unacked total | none (only queue capacity indirectly) | **NO** (probe: 500 unacked parked) | none | none | parked forever if the consumer vanishes | only an `acknowledge`/`reject` with the right tag |
| Per-consumer unacked | `Consumer._prefetch` | **yes**; `prefetch=0` means unlimited | — | `consume()` returns `None` — **same value as "queue empty"** | — | ack frees a slot |
| Consumers | none | **NO** (probe: 300 registered) | — | — | — | `unregister_consumer` (does not reclaim unacked) |
| Queues | none | **NO** (probe: 300 declared) | — | — | `delete_queue` destroys all of them | n/a |
| Exchanges | none | **NO** (probe: 300) | — | — | — | `delete_exchange` |
| Bindings/exchange | none | **NO** (probe: 500) | — | — | — | `unbind_queue` |
| Unknown delivery tag | n/a | `read_payload` → empty snapshot; `ack`/`reject` → `False` | — | indistinguishable from an empty payload | — | n/a |
| BufferPool slabs | `max_slabs` | enforced **inside the pool only** — the pool is off the message path | no | no | n/a | n/a |

Audit §7 conclusion: only **queue depth** and **per-consumer prefetch** are enforced, and both
fail *implicitly* — silent drop with a count as the only trace, and `None` that cannot be
distinguished from "empty". `MEMORY_MODEL.md` §"Resource exhaustion" requires backpressure,
rejection, configured blocking or controlled failure. None of the three exhaustion paths
(queue full, payload too large, unacked parked) currently raises or blocks. That is a design
gap, reported here rather than silently redefined: changing it changes producer-observable
semantics and needs its own decision record.

## Reported defects (found, NOT fixed here)

| ID | Location | Defect | Why not fixed |
|---|---|---|---|
| D1 | `src/hyrx/core/router.mojo:163-169` | ~~Fan-out built each destination envelope with `MessageID(0)` and an empty headers `Dict`: the published message's id and headers were **discarded**, silently.~~ **FIXED in increment 0004 (WP-A):** `Router.publish` now builds `Envelope(msg.message_id(), msg.routing_key(), msg.headers())` per destination, and `Message` exposes `message_id()`/`headers()` accessors; `Queue`/`Router` add `read_message_id`/`read_headers` read-back so the behaviour is now pinned by `tests/phase2/routing_matrix_test.mojo` (`test_metadata_fidelity_preserved_on_fanout`, `test_metadata_fidelity_single_destination_move`). The loss is gone, not latent. |
| D2 | `router.mojo:170-181` + `buffer.mojo:64-73` | ~~Payload copied **twice** per destination (into a `BufferSnapshot`, then byte-by-byte into a `Buffer`)~~ **FIXED in increment 0004 (WP-B):** the per-destination build uses `Message.payload_copy()` → `Buffer.from_buffer_copy()`, a single append pass at logical size (no `resize` zero-fill then overwrite); the single-eligible-queue path moves the source `Message` with no copy. The Copy-policy "no instrumentation" half remains: `bytes copied/message` etc. are still not measured. |
| D3 | `queue.mojo:81-90` | `enqueue` at capacity returns `False` and **destroys the caller's message** — the payload cannot be recovered or retried by the producer. | Changing it to leave the message with the caller changes `var`-parameter ownership semantics (producer-visible API change). |
| D4 | `router.mojo:152-153` (unknown exchange) and the empty-match loop | Unroutable publishes are destroyed silently. No mandatory/return path, no alternate exchange (ROUTING.md lists both as required concepts). | Missing semantics, not a bug fix (rule 9/10). |
| D5 | `queue.mojo:107-121` | `read_payload` with an unknown tag returns an **empty snapshot** instead of raising — indistinguishable from a legitimate zero-byte payload. | Raising is an error-model change on a public read path (`Queue.read_payload`, `Router.read_payload`, the embedded API and the AMQP deliver path all call it); the core currently mixes `Optional`/`Bool`-false and raising per operation (D6). Needs one coherent error model, not a local patch. |
| D6 | `router.mojo:274-285` vs `:213`/`:238`/`:255` | Handle failures are inconsistent: unknown consumer `consume`/`acknowledge`/`reject` return `None`/`False`, but `read_payload` raises `DictKeyError` on the unguarded `_consumers[consumer_id]` lookup. | Consistency requires choosing one error model (report only). |
| D7 | `router.mojo:71-76` | `delete_queue` docstring promises "returns list of unacked messages for cleanup" but always returns an **empty list** while the Queue — with its pending and unacked messages — is destroyed. Message loss with no signal. | Real fix needs a drain-on-delete policy. |
| D8 | `router.mojo:204-209` | `unregister_consumer` removes the `Consumer` but leaves its unacked messages owned by the Queue with no owner and no reclaim trigger (asserted in `test_unregister_leaves_unacked_message_owned_by_queue`). | Requires a channel/session-close cleanup design. |
| D9 | `queue.mojo:136-141` | `reject` requeues to the **TAIL** of the pending set (`_inbox.append`), so a rejected message is redelivered after everything else, while RabbitMQ requeues near the head. `delivery_count` is preserved correctly. | Ordering semantics are normative, not obvious (AMQP-compat goal in ROUTING.md). Needs a decision + `docs/FAILURE_SEMANTICS.md` update. |
| D10 | `exchange.mojo:202-206` | headers exchange is a stub matching every binding regardless of headers. | Already declared a stub; needs header-matching semantics. |
| D11 | `queue.mojo:26,30` | `QueueConfig._durable` is dead: never settable, never read; `durable` is discarded at the AMQP boundary (`adapter.mojo:63`). | Persistence is a separate domain. |
| D12 | `buffer_pool.mojo` (no production call site) | `BufferPool` bounds slabs but no message path uses it, so the doc's "bounded memory" goal is currently met only by queue counts. | Wiring the pool in is the ownership redesign this audit explicitly avoids. |

### Fixed in this pass

| Location | Fix | Evidence |
|---|---|---|
| `src/hyrx/core/exchange.mojo:171-207` (`match`), `:121` (`_already_present`) | `match()` returned a destination **LIST**, so a queue bound by several matching patterns received one copy **per matching binding** (probe: `routed == 2` for a single queue). Now returns a destination **SET** — one copy per queue (ROUTING.md:4 AMQP-compatibility goal; RabbitMQ: "each queue receives exactly one copy"). | `test_multiple_matching_bindings_same_queue_one_copy`, `test_direct_same_queue_multiple_keys` |
| `src/hyrx/core/router.mojo:99-104` (`unbind_queue`) | Signature lacked `raises` while calling a `raises` Dict lookup → the function **could not compile when called**; it had zero call sites and was therefore never exercised. Now `raises -> Bool` and covered. | `test_unbind_removes_destination` |


## P1b implementation record (2026-09-08, post-audit — supersedes D12/D8 "not done")

- BufferPool is now size-classed and WIRED into Router (sole acquire/release owner),
  behind `buffer_pool_enabled` (default false). Commits 575fc70..fd92345; suite 39/0,
  each phase negative-proofed.
- R6 "pool outlives queues": `_pool` is declared before `_queues` inside Router, so
  Mojo's reverse-order field deinit tears the pool down last.
- Reclaimed death sites (in_use->0 proven): `acknowledge`, `delete_queue` drain.
  Consumer-unregister now **requeues** unacked messages (audit D8 fixed) rather than
  stranding them; requeued buffers stay owned until a real death site.
- Mojo-forced move-based primitives: `Buffer.take_data`/`Message.take_payload` (swap),
  `Message.payload_into` (move-in/out); `_unacked_tags` list because
  `Dict[UInt64, Message]` is not key-iterable (Message is not Copyable).
- The "acknowledgement releases/reclaims resources" line is now true (reclaims to the
  pool when enabled; frees on drop when disabled).
- PERFORMANCE (measured, `benchmarks/pool_ab.mojo`): the pool gives NO throughput win
  (0.79-1.00x vs direct allocation), so it is kept OFF by default per rule 17
  (optimization follows measurement). D12 resolved: wired, tested, measured, disabled.
