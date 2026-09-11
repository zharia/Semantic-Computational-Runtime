# Milestone M2 — Security Hardening

**Priority:** 2
**Gate:** SECURITY GATE
**Depends on:** M0

---

## Objective

Implement TLS, authorization model, fuzz tests, frame size enforcement, and timeout controls.

## Tasks

### T2.1 — TLS transport
- [ ] Investigate Mojo TLS options (Flare TLS, openssl FFI, native TLS)
- [ ] Implement TLS listener (upgrade from TCP or dedicated TLS port)
- [ ] Add certificate configuration (self-signed for dev, CA-signed for prod)
- [ ] Test: pika connects via TLS to HyrxMQ
- [ ] Test: plaintext connection refused when TLS required

### T2.2 — Authorization model
- [ ] Design authorization model (users, vhosts, resource permissions)
- [ ] Implement user store (in-memory, configurable)
- [ ] Implement vhost isolation
- [ ] Implement resource permissions (exchange/queue declare, bind, publish, consume)
- [ ] Test: user can only access permitted vhost
- [ ] Test: user can only perform permitted operations
- [ ] Test: unauthorized operation returns 403 ACCESS_REFUSED

### T2.3 — Fuzz tests
- [ ] Create AMQP frame parser fuzzer
- [ ] Fuzz: frame length field
- [ ] Fuzz: method class/id
- [ ] Fuzz: field table encoding
- [ ] Fuzz: content properties
- [ ] Fuzz: body frames
- [ ] Assert: no crash, no corruption, no hang

### T2.4 — Frame size enforcement
- [ ] Enforce frame_max from connection.tune negotiation
- [ ] Reject frames exceeding frame_max with connection.close
- [ ] Test: oversized frame rejected

### T2.5 — Timeout controls
- [ ] Implement connection timeout (close if no handshake within N seconds)
- [ ] Implement read timeout (close if no data within N seconds)
- [ ] Implement write timeout (close if write blocks beyond N seconds)
- [ ] Test: slow client times out

### T2.6 — Connection limits
- [ ] Implement max connections config
- [ ] Reject new connections when limit reached
- [ ] Test: connection limit enforced

## Completion criteria

- TLS works with pika
- Authorization model enforced
- Fuzz tests pass (no crashes)
- Frame size enforced
- Timeouts work
- Connection limits work
- Full test suite PASS
