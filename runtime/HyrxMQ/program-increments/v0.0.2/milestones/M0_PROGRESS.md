# Progress Report — M0 Baseline

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Status:** COMPLETE

---

**WHAT CHANGED:**
- `docs/engineering/CURRENT_STATE.md` created — full baseline report

**WHAT WAS TESTED:**
- Full test suite: `pixi run test` — 47/0 PASS (phase0-phase9 + 8 integration tests)
- Toolchain: Mojo >=1.0.0,<2 via pixi
- Storage: journal framing, CRC-32, MemoryStorage, FileStorage, recovery builder all exercised by phase8/storage_test
- Transport: TCP, UDS, WSS, abstract namespace all tested
- AMQP: frame codec, connection state, adapter, service all tested

**OBSERVATIONS:**
- Architecture separation is clean: Hyrx Core ≠ HyrxMQ ≠ AMQP ≠ Transport
- Single routing authority (Router inside HyrxEngine) — no parallel routing objects
- Ownership model is well-documented in MEMORY_MODEL.md with detailed lifecycle trace
- 12 documented defects (D1-D12), 4 fixed, 8 open
- BufferPool wired but disabled (no perf win) — honest engineering
- Headers exchange is a stub (matches all)
- No external AMQP client tests exist (tests/interop/ empty)
- No crash/recovery tests exist
- No security implementation (TLS, auth, SASL)
- Performance: 1.43x vs RabbitMQ at gate R

**INVARIANTS ESTABLISHED:**
- Message identity preserved through fan-out (routing_matrix_test)
- Delivery identity unique per dequeue (queue_test, consumer_test)
- Routing deterministic for fixed topology (routing_matrix_test)
- Queue capacity enforced (bounded_resource_test)
- FIFO ordering preserved (queue_test)
- Reject requeues (queue_test, routing_matrix_test)
- Consumer prefetch enforced (consumer_test)
- Buffer snapshot is owned copy, not view (buffer_test)
- WAL journal integrity via CRC-32 (storage_test)
- Recovery materialization works (storage_test)

**KNOWN GAPS:**
- No external AMQP client interop tests
- No crash/recovery controlled-termination tests
- No TLS, authentication, or authorization
- Headers exchange matching is a stub
- No mandatory publish / basic.return
- Resource limits (message size, unacked total, consumers, queues, exchanges) not enforced
- Error model inconsistent (raise vs None/False)
- 8 open defects (D3-D7, D9-D11)

**RISKS/BLOCKERS:**
- No blocker for M1-M6
- Interop testing (M3) requires external RabbitMQ instance and pika client — environment dependency
- Persistence crash testing (M4) requires controlled process termination infrastructure
- Security (M5) requires implementing TLS/auth from scratch

**READY FOR NEXT MILESTONE?**
- YES
