# M8: AMQP Interoperability

**Gate:** F (Interoperability)
**Status:** PARTIAL — Python/Node/Java clients and wire-level matrix done; Go
client not available (no toolchain).
**Spec:** Section 46

## Sprint 8.1 — Multi-Client Testing
**Dir:** `scripts/interop/` (`run_multi_interop.sh`)
- [x] Python (Pika) — existing, plus content/negotiation probes
- [x] Node.js (amqplib) — `scripts/interop/node_interop.js`
- [ ] Go (amqp091-go) — **NOT DONE**: no Go toolchain available.
- [x] Java (RabbitMQ client) — `scripts/interop/JavaInterop.java`

## Sprint 8.2 — Protocol Matrix
- [x] Publisher confirms
- [x] QoS / prefetch
- [x] Mandatory publish / basic.return
- [x] Heartbeat
- [x] Reconnect
- Wire-level interop suite: `tests/phase10/interop_test.mojo` (56 assertions)

## Exit Criteria
- [x] Pika + Node + Java interop
- [x] Protocol matrix (confirms, QoS, mandatory/return, heartbeat, reconnect)
- [ ] Go client