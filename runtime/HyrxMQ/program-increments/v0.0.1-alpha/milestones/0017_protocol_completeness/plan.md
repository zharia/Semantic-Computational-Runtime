# 0017 — AMQP 0-9-1 protocol completeness (100% compatibility program)

**Status:** in progress
**Mode:** coordinator (`scr-architect`); T1..T4 delegated per chunk; verify = coordinator

## Objective

Every AMQP 0-9-1 method a real client may emit gets either an implemented
behavior or the normative error reply (never silence). RabbitMQ extensions
clients rely on (confirm class) included. Compatibility claim = per-method,
per-behavior, verified by a pika conformance harness running the same client
operations against RabbitMQ 4.3.5 AND HyrxMQ and comparing outcomes
(room for honest PARTIAL rows with the exact limitation named).

## Chunks (each: code + its own negative proof + integration test)

- **T1 — DONE** (verified live vs pika: nack-requeue round-trip identical body,
  basic.ack multiple -> depth 0, queue.purge count, exchange.bind chain,
  queue.delete count, connection.close 0 ms (the 20 s client-hang removed);
  suite 44/0 after coordinator fix: _dest_exchanges field was initialized
  but never declared on the struct; 12 build errors + 18 suite failures all
  traced to that one declaration):
  teardown + rejection + unbound methods: connection.close / close-ok,
  channel.close / close-ok (incl. error-code behavior on violations),
  basic.nack (+ multiple, requeue=false → dead-letter path if DLX),
  basic.ack multiple=true, basic.return on unroutable (mandatory=1),
  queue.purge, queue.delete, exchange.delete, exchange.bind/unbind,
  queue.unbind; composer *_ok replies for each. e2e: close-ok latency (no
  20 s hang), nack-requeue, purge audience count.
- **T2 — DONE** (their conformance.py: ONE runner, same ops table on
  rabbit (ground truth, 5673 bench rabbit) + hyrx; rows: 19/19 PASS —
  13 property round-trip fields + redelivered.first/nack_requeue +
  tags.no_collision/per_channel + unknown_exchange.404 + mandatory_312.
  Tag numbering corrected to the 1-based per-channel
  spec via a root-caused namespace-lifetime fix (the map deleted itself when
  empty, resetting the counter to 1 after em).
  Coordinator integration fixes: adapter has_* signatures mut->ref (rvalue
  binding errors), per-row unique queue names in the props rows (the Rabbit
  exclusive-queue 405 across rows));
  content properties = T2):: inbound header decode (property list bytes:
  content_type/content_encoding/headers/user-id/delivery_mode/priority/
  reply_to/message_id/timestamp/expiration...) preserved INTO Message and
  OUTBOUND on deliver/get-ok (byte-identical transmit), redelivered bit set
  on actual redeliveries; the flag=0 shortcut removed.
- **T3 — DONE** (suite 44/0; conformance 27 rows: 25 PASS + 3 PARTIAL
  honestly-labeled (durable=flag-only pending 0018; x_message_ttl =
  delivery-time lazy check, no timer subsystem; x-expires lazy) + 1 DIFF =
  exclusive.second_conn_declare="$ needs the 0015 event loop's concurrent
  handshake (flag currently default-OFF) — the row is the Pfern
  justification for the loop's roll-forward; broker-death class
  (reactor fd-reuse stale registry during server-initiated/channel closes)
  found + FIXED via EventPoller.add unconditional-replace + purge-safety:
  a'already registered NetworkError' can no longer kill the serving process.
  Also: 7 wire-test declare writers missing arguments table fixed, the
  read_table semantics kept normative incl. 404/405/406 replies; adapter
  has_* mut->ref (T2 leftover) fixed by coordinator):  declare bits +
  queue arguments:: passive (404 reply on missing),
  durable flag stored (in-memory lifecycle;, persistence = 0018),
  exclusive (bind-lifetime conn + auto-delete on conn close),
  auto_delete (delete on last consumer), x-message-ttl (per-message
  dequeue timer), x-dead-letter-exchange (route rejected/expired bodies
  into the DLX), x-expires honored, queue-length caps via x-max-length.
- **T4 — DONE (code verified via suite 45/0 incl. the new negative-proof
  t4 test; conformance 26 PASS / 1 PARTIAL / 5-6 DIFF, matrix below):
  extension classes + reliability:: publisher confirms (85:
  confirm.select): per-publish ack-ids (multi_ack opt-in), tx (90):
  select/commit/rollback with pending-publish staging, heartbeats
  (tune heartbeat=60; server timer + client-responsiveness deadline),
  auth validation against cfg users (403 ACCESS_REFUSED close on fail),
  connection.close on client invalid (connection_close after error).

## Verification program

- NEW pika conformance script (benchmarks/compat/) running one OPERATION
  table against both brokers (rabbit = ground truth; hyrx = candidate):
  every T1..T4 flow plus the existing e2e paths → OUT diff audit recorded in
  this milestone's reports; deviations = named gaps (each with an owner
  fix), never annotated PASS without a check.
- suite 44/0 minimum → grows with per-protocol tests; negative proof per
  behavior (e.g. passive declare of a missing queue MUST yield 404: test the
  error row explicitly, not just the happy path).
- Gates: no regression on the pika matrix cells; the 0015 flag stays as-is
  until its gate is cleared in a calm window (unchanged rule).

## X. Remaining DIFF rows (honest, root-caused, owned)

1. **pika capability table** (CONFIRM tx etc clients throw
   "Confirm.Select not Supported by Server" because the connection.start
   server-properties table is EMPTY: no capabilities key): a REAL missing
   piece regardless of dispatch-side support -> fix in the 0018+ P1 scope
   (emit the normative server-properties with capabilities:
   publisher_confirms/exchange_exchange_bindings/basic.nack/tx).
2. **5 handshake-timeout rows** (exclusive.second_conn_declare + the rows
   after a pika client wedged a connection): the LEGACY serialized serving
   tier's one-conn-at-a-time bound (a stale pika connection holds the
   accept loop); the legit roll-forward = 0015 event loop default-ON after
   its batched-flow gate clears. Both brokers otherwise reach 405 rows
   correctly.
3. Not outstanding: the Reactor fd-reuse leak is FIXED via EventPoller
   unconditional-replace semantics (T3); suite 45/0 both tiers) plus the
   conformance script's own fixes by the coordinator (bytes-js audit).
   All DIFF rows get fix owners before any 100% claim is finalized.

## Explicitly NOT claimed by THIS increment

- Disk persistence for durable queues/messages (0018 — real storage design:
  WAL + recovery, spec first). Until then durable flag is honored as a
  FLAG only (in-memory) and the report says exactly that.
- 100% RabbitMQ extent behaviors beyond 0-9-1 (plugins, federation,
  quorum queues) are OUT OF SCOPE of the compatibility claim; the matrix
  records them as effectively-unsupported-by-definition.
