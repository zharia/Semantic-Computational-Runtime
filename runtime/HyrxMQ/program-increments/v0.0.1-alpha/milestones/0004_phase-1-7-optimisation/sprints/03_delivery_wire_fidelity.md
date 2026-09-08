# Sprint 03 — Delivery and Get-OK Wire Fidelity (WP-C)

Status: **done** — routing key + post-pop `message-count` surfaced on
deliver/get-ok via `queue_routing_key`/`queue_message_count` (decision D1);
`exchange` stays empty (spec §8, NOT DONE).

## Contract

`basic.deliver` and `basic.get-ok` must encode the delivered message's routing
key. `exchange` remains deliberately empty and documented as a known envelope
schema limitation. `basic.get-ok message-count` must have an explicitly chosen
engine-count meaning.

## Planned slice

1. Surface `Queue.read_routing_key(tag)` through Router, HyrxEngine,
   AMQPAdapter and HyrxMQBroker.
2. Encode that result in `_handle_get` and `_flush_deliveries`.
3. Surface the approved queue-count API along the same route and encode it in
   get-ok after delivery.
4. Extend phase-7 unit and TCP/UDS wire tests to parse and assert routing key
   and message-count. Update interop evidence only after a real pika run.

## Feedback / blocker evidence

- `Queue.depth()` exists, returns `Int`, and is normatively documented and
  tested as **pending only**, excluding unacknowledged messages.
- The increment requests a method of the same name returning `UInt64` for
  pending plus unacked. This is an observable semantic change, not a harmless
  optimization. A new named count API preserves compatibility; renaming depth
  changes its established contract. Approval is required.
- The AMQP placeholders are confirmed at `amqp_service.mojo` get handling and
  delivery flush. The existing routing-key source is real and is available only
  after a delivery claim.
