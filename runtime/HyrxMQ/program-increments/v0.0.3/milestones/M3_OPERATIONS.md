# Milestone M3 — Operations & Observability

**Priority:** 3
**Gate:** OPERATIONS GATE
**Depends on:** M0

---

## Objective

Implement metrics export, structured logging, and graceful shutdown.

## Tasks

### T3.1 — Metrics counters
- [ ] Implement counter: messages published
- [ ] Implement counter: messages routed
- [ ] Implement counter: messages delivered
- [ ] Implement counter: messages acknowledged
- [ ] Implement counter: redeliveries
- [ ] Implement counter: rejects/nacks
- [ ] Implement counter: confirms (publisher confirms)
- [ ] Implement gauge: queue depth
- [ ] Implement gauge: consumer count
- [ ] Implement gauge: connection count
- [ ] Implement gauge: channel count
- [ ] Implement counter: bytes in/out
- [ ] Implement histogram: routing latency
- [ ] Implement histogram: delivery latency

### T3.2 — Metrics export
- [ ] Expose metrics via HTTP endpoint (/metrics, Prometheus format)
- [ ] Test: GET /metrics returns valid Prometheus text
- [ ] Test: counters increment correctly after publish/consume cycle

### T3.3 — Structured logging
- [ ] Implement JSON log format
- [ ] Implement log levels (DEBUG, INFO, WARN, ERROR)
- [ ] Add structured fields: timestamp, level, component, message, correlation_id
- [ ] Test: log output is valid JSON
- [ ] Test: log level filtering works

### T3.4 — Graceful shutdown
- [ ] Implement signal handler (SIGTERM, SIGINT)
- [ ] On shutdown: stop accepting new connections
- [ ] On shutdown: send connection.close to all clients
- [ ] On shutdown: drain in-flight messages
- [ ] On shutdown: flush WAL journal
- [ ] On shutdown: close sockets
- [ ] Test: graceful shutdown completes within timeout
- [ ] Test: no messages lost during graceful shutdown

## Completion criteria

- Metrics exported via HTTP
- Structured logging works
- Graceful shutdown works
- Full test suite PASS
