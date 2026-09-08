# Persistence Readiness Audit (audit §15)

**Status: persistence is NOT IMPLEMENTED.** No WAL, no segments, no fsync, no
checkpoint, no recovery scanner exists anywhere in `src/` (grep for
`wal|fsync|checkpoint|recovery|segment` returns zero production hits). This
report does not pretend otherwise. It audits whether the current architecture
has *accidentally made durable recovery impossible*, defines the required
semantics before any implementation, and answers §34 Q34–Q39 with the honest
no-persistence behavior.

All line references verified against the working tree at audit time.
`docs/PERSISTENCE.md` is the intended design; this report reconciles against it
(see §0.1). Nothing in this report is implemented; §3 modes are target
definitions only.

## 0. Method and reconciliation with docs/PERSISTENCE.md

Read: `docs/PERSISTENCE.md`, `src/hyrx/core/{message,queue,router,
buffer_snapshot,exchange,buffer,consumer}.mojo`, `src/hyrxmq/{broker,config,
amqp_service,listener}.mojo`, `src/hyrx/amqp/adapter.mojo`,
`src/hyrx/embedded/api.mojo`, audit defect registry D1–D12
(`docs/MEMORY_MODEL.md:209-220`).

Reconciliation: PERSISTENCE.md proposes exactly the architecture this audit
assumes (WAL, append-only segments, checkpoints, recovery scanner, configurable
durability modes, PERSISTENCE.md:9-17) and states "Exact semantics must be
specified before implementation" (PERSISTENCE.md:28). This report supplies that
specification (§3). One direct tension: PERSISTENCE.md:60 requires "Recovery
must fail safely rather than silently producing incorrect topology or message
state" — the *current* engine silently destroys message state without any
crash at all (defects D3, D4, D7, §2 below). The existing code already
violates the anti-pattern the persistence doc forbids; a WAL built on top
without fixing those would faithfully log the destruction.

The single-authority design is a real asset: all mutable message/topology
state lives in exactly one `Router` (`router.mojo:29-30`), and the broker
surface adds no state of its own (`broker.mojo:3-8`). A recovery writer has
one object to dump and one choke point to instrument. Nothing found makes
persistence *impossible*; several things make it *wrong* unless fixed first.

## 1. Is durable recovery architecturally POSSIBLE? Required WAL/replay inputs

| # | Required input | Verdict | Evidence |
|---|---|---|---|
| 1.1 | **Stable message identity** | **ABSENT (in practice)** | The type exists and claims "Globally unique message identifier" (`message.mojo:15-27`), and `Envelope` carries it (`message.mojo:32`), with a getter (`message.mojo:46-47`). But **every message is constructed as `MessageID(0)`**: the AMQP ingest path (`adapter.mojo:105`) and every fan-out clone (`router.mojo:168`). No ID generator exists anywhere in `src/` (only three `MessageID(` call sites total, all literal 0). Identity is a constant — meaningless. WAL replay cannot dedupe, order by id, or match a persisted publish record to a queued message. Additionally the core exposes **no envelope read-back**: only `read_payload`/`read_routing_key` (`queue.mojo:107-127`, `router.mojo:138-141` docstring), so even the id that *would* be lost by D1 is unobservable and untestable. |
| 1.2 | **Ordering** | **PARTIAL — recoverable positionally, not stably** | Per-queue FIFO is an emergent property of the two-stack layout (`queue.mojo:11-14`, `_transfer` `queue.mojo:76-79`, enqueue to `_inbox` `queue.mojo:88`, dequeue from `_outbox` head-oldest `queue.mojo:100`). Serializing `[_outbox..., reversed(_inbox)...]` reconstructs order — the data to do so exists. But there is **no sequence stamp per message**; order is positional only. Delivery tags are a per-queue `UInt64` counter starting at 0 per process (`queue.mojo:59,67`, issued `queue.mojo:102-103`): **after restart it restarts at 0 and collides with any persisted in-flight tags**, so a recovered unacked set keyed by tag is ambiguous. Reject requeues to the tail (`queue.mojo:140`, defect D9) — a recovery writer relying on RabbitMQ-comparable redelivery order is silently wrong today. |
| 1.3 | **Message content + headers/envelope** | **PARTIAL** | Payload bytes are extractable as owned copies — `Message.payload()` (`message.mojo:82-88`), `Buffer.snapshot()` (`buffer.mojo:64`), `BufferSnapshot.to_bytes()` (`buffer_snapshot.mojo:48-57`) — so content *can* reach a writer without breaking ownership. Envelope fields are plain values (`String`, `Dict[String,String]`, `UInt64`, `message.mojo:32-34`). Gaps: (a) no serializer of any kind; (b) on the fan-out path the *queued* copy is **not the published message** — `message_id` replaced by 0 and headers replaced by an empty dict (`router.mojo:166-169`, defect D1), so a post-fan-out WAL log records a different envelope than the one the producer sent; (c) `delivery_count` exists (`message.mojo:63,90-95`) but is not readable through `Queue`/`Router`, so redelivery counters cannot be persisted. |
| 1.4 | **Ack state / unacked set** | **PARTIAL — data present, not enumerable** | The unacked set is `Dict[UInt64, Message]` keyed by delivery tag (`queue.mojo:57`); values are full Messages still owned by the Queue (`queue.mojo:1-9` model), so the delivered-but-unacked state a recovery needs (requeue these) exists per queue in a structurally serializable form. But there is **no API to enumerate unacked tags or messages** — only `unacked_count` (`queue.mojo:148-150`). And defect D8 (`router.mojo:204-209`): `unregister_consumer` removes the Consumer but leaves its unacked messages in the Queue's dict with **no owner and no reclaim trigger** (test `test_unregister_leaves_unacked_message_owned_by_queue`), so the unacked set already drifts without a crash. |
| 1.5 | **Durable vs transient queue flag** | **DECLARED-BUT-DEAD (gap)** | `QueueConfig._durable: Bool` exists (`queue.mojo:26`) but the only constructor hardcodes `False` (`queue.mojo:28-30`); there is no setter, no reader, and `Router.declare_queue` never receives it (`router.mojo:62-69`). The AMQP `durable` bit is read-and-discarded at every boundary: wire (`amqp_service.mojo:281,297`), adapter no-op (`adapter.mojo:67,78`), broker hardcodes `durable=False` (`broker.mojo:79,84`). Registered as defect D11 (`MEMORY_MODEL.md:219`). Net: **no queue can be marked durable today**, which is honest (persistence absent) but means the flag plumbing is a required first step, not a bolt-on. |
| 1.6 | **Topology (exchanges/queues/bindings)** | **NEARLY PRESENT — no dump API; metadata gaps** | All topology is plain-value data inside the Router: exchanges keyed by name with type enum 0–3 (`router.mojo:29`, `exchange.mojo:19-44`), queues keyed by name with capacity (`router.mojo:30`, `queue.mojo:25`), bindings carrying `(queue_name, routing_key, arguments Dict)` (`exchange.mojo:49-64`) — enough to dump and restore *what exists today*. Gaps: `Exchange` has **no durable/auto-delete fields at all** (constructor takes only name+type, `exchange.mojo:142`); no enumeration API (Router exposes only counts, `router.mojo:291-296`); and the destructive path is lossy-silent: `delete_queue` "always returns an empty list while the Queue — with its pending and unacked messages — is destroyed" (defect D7, `router.mojo:71-76`) — a future WAL author trusting the docstring ("Returns list of unacked messages for cleanup", `router.mojo:72`) would implement delete-logging on top of a lie. |
| 1.7 | **Recovery metadata / checkpoint points** | **ABSENT** | No checkpoint, commit-marker, segment or log-offset concept exists. `HyrxMQConfig` has no data-dir, log-path, or durability keys (`config.mojo:55-62`). Platform prerequisite gap: file I/O is **not available in this Mojo 1.0 environment** ("Mojo 1.0 does not expose a portable `os`/`File` module here", `config.mojo:134-138`) — the first persistence work package must first land a byte-level write/fsync surface, or it cannot even write a WAL. |

**Bottom line:** durable recovery remains architecturally POSSIBLE. State is
centralized (one Router), value-typed, and copy-out-able by design — the
ownership model (moves + explicit snapshots, `message.mojo:1-10`,
`buffer_snapshot.mojo:1-18`) is a *help*, not an obstacle, because serialization
can proceed through existing copy APIs without weakening ownership. But with
today's semantics a WAL would faithfully persist the wrong facts: identity-less
messages, tag-colliding unacked sets, envelopes already mangled by fan-out, and
destructions that never signal.

## 2. Blocking gaps, ranked — smallest forward-compatible design decisions

Ranked by "hardness to retrofit once a WAL exists". The first three are the
must-fix-before-WAL set.

1. **Message identity is a constant (blocks dedupe/replay).** *Gap:* no
   MessageID generator; all messages born as `MessageID(0)`
   (`adapter.mojo:105`), and D1 re-zeros it per destination (`router.mojo:168`).
   A WAL needs a primary key per event; today there is none, and replay cannot
   tell a duplicate from a distinct message. *Smallest forward-compatible
   decision:* a broker-wide monotonic `UInt64` generator owned by the Router
   (single authority), stamped at ingest; publish records carry it; fan-out
   clones **must carry the source id** (fix D1 in the same package as the
   envelope read-back accessor so it becomes testable). Persisting per-queue
   position is then expressible as (message_id, queue, seq) without inventing a
   second identity scheme later.

2. **Delivery-tag namespace is per-process, starting at 0 (blocks restart).**
   *Gap:* `_next_delivery_tag = 0` per Queue construction (`queue.mojo:67`).
   After crash+replay, newly issued tags collide with tags persisted in the
   recovered unacked set — recovery cannot decide "is tag 3 the old
   unacknowledged delivery or a brand-new one?" *Smallest decision:* make the
   tag counter a property of *queue state* (initialized from a checkpoint
   `next_tag` / from the WAL high-water mark, never from a constructor), or
   namespace tags as (epoch, counter). Either preserves the current `UInt64`
   wire type; choosing this *after* a WAL format exists would force a format
   migration.

3. **Silent destruction semantics contradict every durability guarantee
   (blocks the core contract).** *Gap:* enqueue-at-capacity returns `False` and
   **the moved message is destroyed** (defect D3, `queue.mojo:86-88` +
   `router.mojo:182-184`, "a destination at capacity silently drops its copy");
   unroutable publishes are destroyed silently (D4, `router.mojo:152-153`);
   `delete_queue` destroys and signals nothing (D7). The minimal promise any
   durable mode must make — "publish returned ⇒ the message exists or the
   producer was told" — is already violated without any crash. *Smallest
   decision:* settle the overflow policy as *blocking* or *explicit rejection
   per destination* (MEMORY_MODEL.md:198-203 already lists these three
   exhaustion paths as a reported design gap needing a decision record), and
   make `delete_queue` either drain-and-return or refuse. This is a
   producer-visible semantics change, so it must be its own decision record —
   but it must not be *frozen in* by a WAL that logs drops as accepted events.

4. **Durable-flag plumbing never reaches the core (D11).** Field exists and is
   dead (`queue.mojo:26,30`); flag discarded at `adapter.mojo:67,78`, hardcoded
   `False` at `broker.mojo:79,84`. Cheap to fix *with* the WAL (thread
   `durable` through `Router.declare_queue` → `QueueConfig`), but it must be
   honored at declare time, since a WAL cannot retroactively make a queue that
   was never logged durable. Also add the missing `durable`/`auto_delete`
   fields to `Exchange` (`exchange.mojo:142`) at the same time.

5. **No enumeration/read-back API for state (blocks any checkpoint).** Unacked
   set not enumerable (`queue.mojo:148-150` is a count only); pending lists
   opaque (`depth()` `queue.mojo:144-146`); topology opaque
   (`router.mojo:291-296`); `delivery_count` unreadable through the Queue. A
   checkpoint writer needs *something*: a snapshot/traverse API that yields
   owned copies without violating the move-ownership model (e.g.
   `unacked_snapshot() -> List[(tag, Message)]`). Design it now — later, WAL
   replay will *require* these reads, and inventing them ad hoc risks copying
   messages out of the unacked dict by move.

6. **Orphaned unacked on consumer lifecycle (D8).** `unregister_consumer`
   (`router.mojo:204-209`) leaves messages parked with no reclaim path.
   Persistence-adjacent because the recovered unacked set will contain entries
   for long-dead consumers; define the connection/channel-close requeue policy
   now so the WAL's deliver/ack/requeue records have a complete lifecycle to
   record.

## 3. The four durability modes — PRECISE target semantics

**None of the four is implemented. Nothing here is PROVEN behavior.** Mode 1
describes current reality; modes 2–4 are target definitions to be specified
before implementation, per PERSISTENCE.md:28 and audit §15
(spec.md:726-737). "publish" means any path that returns after fan-out
(`router.mojo:126-186`); "ack" means `Queue.acknowledge` (`queue.mojo:129-134`).

Shared preconditions for all durable modes (2–4), each currently absent and
each a §2 gap: stable per-message id (#1); persistent tag/sequence namespace
(#2); non-silent overflow policy (#3). The WAL must record the **pre-fan-out
publish** (original id, headers, body, source exchange/routing key) plus a
routing-result record per destination, so replay reconstructs the message a
producer actually sent, not the D1-mangled copy. Message destruction must be
ordered *after* the ack record is committed; a crash in between must cause
**duplicate redelivery, never loss**. Torn final records (crash mid-append) are
detected by length-prefix + checksum and discarded at the last commit marker —
the recovery test matrix for this is PERSISTENCE.md:32-44 and is NOT PROVEN.

### `ephemeral` — current behavior, the only honest mode

- **publish →** count of destination queues whose `enqueue` accepted the
  in-memory copy (`router.mojo:145-147,182-184`). Guarantee: none beyond that
  count being truthful about RAM state; accepted copies may still be destroyed
  later without any crash by `delete_queue` (D7).
- **ack →** `True` = message destroyed in RAM (`queue.mojo:129-134`). No
  persistence side of the return exists.
- **Crash-loss window:** 100% — all pending, all unacked, all topology,
  process termination or worse (Q35 below).
- **Producer-visible contract:** best effort / at-most-once, and strictly
  weaker: silent drops (D3/D4) mean even "at-most-once" is a ceiling, not a
  floor.
- **Consumer-visible contract:** redelivery exists only in-process via
  `reject` (tail requeue, D9); after any restart, delivered-unacked are gone.

### `buffered durable` — survives process crash, not machine failure

- **publish →** returns after the message record has been appended to the WAL
  with the bytes handed to the OS (a `write` completed; no `fsync`).
- **Guarantee:** the message survives broker-process crash/termination (OS
  holds the bytes); it does **not** survive kernel panic or power loss.
- **ack →** ack record appended, not synced. A machine crash between append
  and OS writeback may resurrect an already-acked message → duplicate
  redelivery. At-least-once, explicitly.
- **Crash-loss window:** machine crash: unbounded (whatever dirty pages were
  unwritten — OS writeback policy decides, the broker does not). Process
  crash: zero for published-and-written records.
- **Producer-visible contract:** "durably buffered against broker failure";
  the return value must additionally reflect the non-silent overflow policy
  (§2 #3), otherwise the mode promises against a drop path that still eats
  messages. No fsync cost is hidden in the publish latency.
- **Consumer-visible contract:** the unacked set is reconstructed at recovery
  from deliver-minus-ack records (requires §2 #2's persistent tag namespace
  and §1.4's enumerable unacked state); delivered-unacked messages are
  requeued/redelivered.

### `flush-bounded durable` — bounded loss window by configuration

- **publish →** returns after append (as buffered); the WAL commits with a
  batched `fsync` at a configured bound: every T milliseconds and/or every N
  records (group commit). The commit point is the checkpoint.
- **Guarantee:** on machine crash, loss is bounded to the records accepted
  after the last completed commit — a count/time the operator configures and
  the docs name. Everything before the last commit marker survives.
- **ack →** same batched commit; a duplicate (resurrected acked message) is
  possible within the window, loss is not.
- **Crash-loss window:** ≤ T / ≤ N records. Producer cannot know *which*
  boundary its publish landed on at return time.
- **Producer-visible contract:** publish return does **not** mean durable. A
  commit-progress signal is required (per-message confirm callback or a
  queryable committed-sequence watermark, AMQP publisher-confirm style) so a
  producer that cares can wait for its record to cross the commit point.
- **Consumer-visible contract:** at-least-once within the window; recovery
  replays deliver/ack records only up to the last commit marker.

### `strict durable` — fsync barrier before return

- **publish →** returns only after the record covering this message has been
  `fsync`ed past the commit point. Durability is synchronous with the return.
- **Guarantee:** zero loss of any publish whose return reached the producer
  (modulo the atomicity convention: records are length+CRC-framed so a crash
  can only tear the *in-flight* record, which recovery discards — so "zero
  loss" means "no half-record is ever presented as a message").
- **ack →** `True` returns only after the ack record is fsynced; message
  destruction happens after that commit. A crash in the gap redelivers
  (duplicate), never loses.
- **Crash-loss window:** zero for returned operations; at most the torn final
  record.
- **Producer-visible contract:** the publish/ack return *is* the durability
  guarantee; latency includes the sync. Exactly-once is **not** promised —
  duplicate redelivery after crash remains possible (idempotence stays the
  producer's problem; SCR rule 12: semantic vs numerical vs bitwise
  equivalence must be stated, not assumed).
- **Consumer-visible contract:** delivered-unacked state is committed;
  recovery requeues exactly the committed unacked set.

Performance disclosure obligation (PERSISTENCE.md:46-54): modes 3–4 must be
benchmarked separately from `ephemeral`, and the current in-memory latency
numbers must never be quoted as durable-mode numbers — and vice versa: none of
the current numbers say anything about modes 2–4.

## 4. §34 Reliability questions (Q34–Q39) — CURRENT honest answers

- **Q34. Abrupt disconnect?** Nothing reclaims anything. Consumers are
  broker/engine-scoped; the wire layer has no close/cancel handshake
  (NOT-IMPLEMENTED list, `amqp_service.mojo:33-45`) and
  `unregister_consumer` leaves the Consumer's unacked messages owned by the
  Queue with no owner and no reclaim trigger (D8, `router.mojo:204-209`).
  Single-node, so the data is safe in RAM; the *delivery* is stranded —
  delivered-but-unacked messages sit in `_unacked` (`queue.mojo:57`) until
  process end, and the consumer that could have acked them is gone.
- **Q35. Process termination?** All messages and all topology lost —
  confirmed. `HyrxMQBroker.shutdown()` only flips a state flag
  (`broker.mojo:68-70`); there is no flush because there is nothing to flush
  to (§1.7). Ephemeral-only is the honest current state.
- **Q36. Resource exhaustion?** Bounded only by queue capacities (count
  ceilings, `queue.mojo:86-88`) and the frame_max ceiling; memory cost per
  destination is two full payload copies (D2, `router.mojo:170-181`) and the
  BufferPool is unwired (D12). None of the three exhaustion paths (queue
  full, payload too large, unacked parked) raises or blocks
  (`MEMORY_MODEL.md:198-203`). No disk exists, so no disk-exhaustion path
  exists yet.
- **Q37. Queue exhaustion?** The per-destination copy is destroyed silently —
  `enqueue` returns `False` on a moved-in message the caller cannot recover
  (D3, `queue.mojo:86-88`), the publish loop just skips the increment
  (`router.mojo:182-184`), and the producer-visible return cannot distinguish
  "no bindings" (0, `router.mojo:153`) from "full everywhere". Cross-ref D3
  (+ D4 for unroutable). With persistence this becomes the durability lie
  vector: §2 gap #3.
- **Q38. Connection storms?** Fail-closed accept gate: over
  `max_connections` (default 1024, `config.mojo:67`) the accepted socket is
  closed immediately without AMQP handling; refusals counted
  (`listener.mojo:130-137,120`). Engine-side consumer registrations are
  uncapped, but on the current path each connection is a single slot and
  unbounded registrations follow unbounded accepted connections only within
  the gate.
- **Q39. Persistence failure?** N/A — persistence is not implemented, so there
  is no failure path to have. Note the platform prerequisite this hides: a
  portable file write/fsync surface does not exist in this Mojo 1.0 environment
  (`config.mojo:134-138`), so the first persistence work package is I/O
  capability, not WAL format.

## 5. Verdict

**PERSISTENCE: NOT IMPLEMENTED; architecture recovery-readiness =
NEEDS-DESIGN-FIXES.**

Must-fix-before-WAL (the three that become progressively harder to retrofit
once a log format exists):

1. **Real message identity** — monotonic broker-wide `MessageID` generated at
   ingest and *carried through fan-out* (replaces constant `MessageID(0)`:
   `src/hyrx/amqp/adapter.mojo:105`, `src/hyrx/core/router.mojo:168`; fixes
   D1 and requires the envelope read-back accessor it unblocks).
2. **Persistent delivery-tag/sequence namespace** — tags must derive from
   checkpointed queue state, never a per-process counter starting at 0
   (`src/hyrx/core/queue.mojo:59,67,102-103`), plus an enumerable unacked set
   (`queue.mojo:57,148-150`).
3. **End silent destruction** — overflow must block or signal per-destination
   (`queue.mojo:86-88` + `router.mojo:182-184`, D3) and `delete_queue` must
   drain-or-refuse instead of destroy-and-return-empty
   (`router.mojo:71-76`, D7); every durability mode is defined on top of
   "returned ⇒ exists", which the code violates today.

Everything else in §1–§2 (dead `durable` flag `queue.mojo:26,30` D11, missing
Exchange flags, missing dump API, D8 orphan policy, no I/O surface
`config.mojo:134-138`) is a gap the WAL work package must include, but only
these three change *semantics* — and therefore producer/consumer contracts —
and freezing a WAL format around them later forces a migration.

No code or tests were modified for this report; this file is the only
deliverable.
