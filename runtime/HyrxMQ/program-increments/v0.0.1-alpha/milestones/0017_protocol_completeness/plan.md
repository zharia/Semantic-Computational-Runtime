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
- **T2 — content properties**: inbound header decode (property list bytes:
  content_type/content_encoding/headers/user-id/delivery_mode/priority/
  reply_to/message_id/timestamp/expiration...) preserved INTO Message and
  OUTBOUND on deliver/get-ok (byte-identical transmit), redelivered bit set
  on actual redeliveries; the flag=0 shortcut removed.
- **T3 — declare bits + queue arguments**: passive (404 reply on missing),
  durable flag stored (in-memory lifecycle;, persistence = 0018),
  exclusive (bind-lifetime conn + auto-delete on conn close),
  auto_delete (delete on last consumer), x-message-ttl (per-message
  dequeue timer), x-dead-letter-exchange (route rejected/expired bodies
  into the DLX), x-expires honored, queue-length caps via x-max-length.
- **T4 — extension classes + reliability**: publisher confirms (85:
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

## Explicitly NOT claimed by THIS increment

- Disk persistence for durable queues/messages (0018 — real storage design:
  WAL + recovery, spec first). Until then durable flag is honored as a
  FLAG only (in-memory) and the report says exactly that.
- 100% RabbitMQ extent behaviors beyond 0-9-1 (plugins, federation,
  quorum queues) are OUT OF SCOPE of the compatibility claim; the matrix
  records them as effectively-unsupported-by-definition.
