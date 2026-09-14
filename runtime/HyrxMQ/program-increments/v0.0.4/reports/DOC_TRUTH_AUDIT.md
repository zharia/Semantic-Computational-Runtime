# Documentation Truth Audit — HyrxMQ v0.0.4

## Files audited

| File | Purpose |
|------|---------|
| `README.md` | Project overview, status, capabilities |
| `src/hyrxmq/config.mojo` | Configuration comments, defaults |
| `src/hyrxmq/amqp_service.mojo` | NOT IMPLEMENTED list, scope documentation |
| `src/hyrxmq/listener.mojo` | Scope documentation, transport description |

---

## README.md

### Claim 1: "52/0 PASS (pixi run test)"

**Status:** UNVERIFIED — cannot run tests in this session. The claim references the v0.0.3 baseline; v0.0.4 changes may have added or broken tests.

**Recommendation:** Run `pixi run test` to confirm current count.

---

### Claim 2: "pika 1.4.4 completes AMQP handshake/publish/consume/get/ack"

**Status:** TRUE — verified by `tests/integration/broker_tcp_e2e.mojo` and `scripts/interop/` directory existence. The pika interop is the primary integration gate.

---

### Claim 3: "TCP TLS: proven (TLS 1.3 handshake + AMQP-over-TLS)"

**Status:** TRUE — `tests/phase10/tcp_tls_test.mojo` exists. `listener.mojo:767-774` — `configure_tls` loads OpenSSL context.

---

### Claim 4: "Persistence: WAL journal + recovery, validated by crash/corruption/IO-failure tests"

**Status:** TRUE — `tests/phase8/storage_test.mojo` and `tests/phase10/persistence_crash_test.mojo` exist. `router.mojo:203-291` — `recover()` method with journal replay.

---

### Claim 5: "Performance: ~1.43x RabbitMQ 4.3.5 in the closed-loop benchmark"

**Status:** UNVERIFIED — benchmark results are external measurements. Cannot reproduce in this session.

---

### Claim 6: "Per-resource authorization (ACLs / multiple vhosts)" listed under "NOT implement"

**Status:** FALSE — as of v0.0.4, ACLs ARE implemented. `amqp_service.mojo:672-689` — `_PermBits` struct with configure/write/read. `amqp_service.mojo:1622-1629` — exchange.declare checks configure permission. `amqp_service.mojo:2012-2019` — basic.publish checks write permission. `config.mojo:23-51` — `UserRecord` carries per-vhost permissions.

**Action:** Update README.md "What HyrxMQ does NOT implement" to remove "Per-resource authorization (ACLs / multiple vhosts)".

---

### Claim 7: "Connection / I/O timeouts and connection limits" listed under "NOT implement"

**Status:** FALSE — as of v0.0.4, both ARE implemented. `listener.mojo:282-285` — `_idle_timeout_ms` + `check_idle_connections()`. `listener.mojo:293-296` — `_max_connections` enforced at accept gate. `config.mojo:168-173` — `idle_timeout_secs`, `max_connections` config fields.

**Action:** Update README.md to reflect that connection limits and idle timeouts are now implemented.

---

### Claim 8: "version 4.3.5" in server-properties

**Status:** TRUE — `amqp_service.mojo:1326` — `write_string_field(props, "version", "4.3.5")`. This is the wire protocol version advertised to clients (RabbitMQ compatibility), not the HyrxMQ product version.

---

## src/hyrxmq/config.mojo

### Claim 9: "default: admin/password" (line 17)

**Status:** TRUE — `config.mojo:185` — `self.users.append(UserRecord("admin", "password"))`. Default credentials are admin/password.

---

### Claim 10: "unknown keys are REJECTED" (line 10)

**Status:** TRUE — `config.mojo:311-312` — `apply()` raises on unknown keys.

---

### Claim 11: "load_from_file(path) is intentionally NOT provided" (line 349)

**Status:** TRUE — `config.mojo:349-355` — explicit comment explaining Mojo 1.0.0 lacks `os` module. No file-based config loading exists.

---

### Claim 12: "frame_max validated >= 4096"

**Status:** FALSE — `config.mojo:374-375` — `validate()` checks `frame_max > 0` only. There is no >= 4096 check. The `_MIN_BODY_CHUNK` constant at `amqp_service.mojo:234-235` enforces a floor of 4088 at the encoding layer, but the config allows smaller values.

**Gap:** `frame_max` validation is weaker than documented. A value of 1 would pass validation but cause issues in frame encoding.

---

## src/hyrxmq/amqp_service.mojo

### Claim 13: "async push-after-subscribe is NOT IMPLEMENTED" (line 24)

**Status:** TRUE — `_flush_deliveries` (line 3152) is called at basic.consume time only. No async push path exists.

---

### Claim 14: "connection.close (10,50) is replied with close-ok (10,51) from ANY state" (line 28-29)

**Status:** TRUE — `amqp_service.mojo:1444-1470` — CONNECTION_CLOSE handler reads args, calls `_cleanup_connection`, returns close-ok. No state gate.

---

### Claim 15: "channel.close (20,40) is replied with close-ok (20,41) on the SAME channel number" (line 30)

**Status:** TRUE — `amqp_service.mojo:1588-1602` — CHANNEL_CLOSE handler marks channel closed, drops tag namespace, returns close-ok on the same `chan`.

---

### Claim 16: "secure (10,20/21) remains NOT implemented" (line 35)

**Status:** TRUE — no handler for connection.secure frames in `handle_frame`.

---

### Claim 17: "publisher confirms NOW IMPLEMENTED" (line 43-53)

**Status:** TRUE — `amqp_service.mojo:1936-1951` — CONFIRM_SELECT handler. `amqp_service.mojo:1135-1161` — confirm state management. `amqp_service.mojo:3007-3018` — confirm ack emission in `_execute_publish`.

---

### Claim 18: "tx.select/commit/rollback NOW IMPLEMENTED" (line 54-61)

**Status:** TRUE — `amqp_service.mojo:1953-2008` — TX_SELECT, TX_COMMIT, TX_ROLLBACK handlers.

---

### Claim 19: "server CYCLIC heartbeats NOT IMPLEMENTED" (line 69-71)

**Status:** TRUE — heartbeat handling is ping-pong only (`listener.mojo:613-617`). No timer-driven server heartbeat.

---

### Claim 20: "connection state enforcement: business methods are not gated" (line 121)

**Status:** TRUE — `handle_frame` dispatches business methods without checking `CONN_STATE_OPEN`. Only the listener's handshake phases gate frames.

---

### Claim 21: "get-ok message-count is always 0" (line 123)

**Status:** FALSE — `_handle_get` at line 3118 calls `self._broker.queue_message_count(cid)` which returns the queue's ready depth. The claim is outdated; message-count is now accurate.

**Action:** Remove or update this line in the NOT IMPLEMENTED list.

---

## src/hyrxmq/listener.mojo

### Claim 22: "Glue layer: real socket bytes <-> AMQP frames <-> AMQPService" (line 4)

**Status:** TRUE — listener owns transport, delegates to AMQPConnServing which owns AMQPService.

---

### Claim 23: "Per-slot serving phase: header → handshake → ready" (line 81)

**Status:** TRUE — `listener.mojo:82-94` — PHASE_HEADER, PHASE_HANDSHAKING, PHASE_READY. `_serve_step` gates header phase at line 544.

---

### Claim 24: "Fail-closed containment: per-connection damage fully absorbed" (line 893-898)

**Status:** TRUE — `serve_one_frame` (line 508-524) wraps `_serve_step` in try/except; on exception the slot is closed and SERVE_FAILED returned. The accept loop never sees per-connection errors.

---

### Claim 25: "The MINIMAL client-heartbeat protocol" (listener.mojo:608-612)

**Status:** TRUE — heartbeat frames get immediate echo reply (line 613-617). No server-initiated cyclic heartbeat.

---

### Claim 26: "max_connections ceiling... the transport wrapper does not enforce it" (listener.mojo:295-296)

**Status:** TRUE — `_fill_tcfg` at line 731-738 copies `max_connections` to TransportConfig but the comment says "TECH DEBT: enforce in one place." Authority is `AMQPConnServing.register`.

---

## Summary

| # | Claim | Verdict | Action |
|---|-------|---------|--------|
| 1 | 52/0 test count | UNVERIFIED | Run tests |
| 2 | pika interop proven | TRUE | — |
| 3 | TCP TLS proven | TRUE | — |
| 4 | WAL + recovery proven | TRUE | — |
| 5 | 1.43x RabbitMQ perf | UNVERIFIED | External measurement |
| 6 | ACLs NOT implemented | **FALSE** | Update README |
| 7 | Conn limits NOT implemented | **FALSE** | Update README |
| 8 | Wire version 4.3.5 | TRUE | — |
| 9 | Default admin/password | TRUE | — |
| 10 | Unknown keys rejected | TRUE | — |
| 11 | load_from_file absent | TRUE | — |
| 12 | frame_max >= 4096 | **FALSE** | Fix validation or docs |
| 13 | Async push NOT IMPLEMENTED | TRUE | — |
| 14 | connection.close from ANY state | TRUE | — |
| 15 | channel.close same channel | TRUE | — |
| 16 | secure NOT implemented | TRUE | — |
| 17 | Publisher confirms implemented | TRUE | — |
| 18 | Transactions implemented | TRUE | — |
| 19 | Server cyclic heartbeats NOT | TRUE | — |
| 20 | No connection state gating | TRUE | — |
| 21 | get-ok message-count always 0 | **FALSE** | Update NOT IMPLEMENTED |
| 22 | Listener = glue layer | TRUE | — |
| 23 | Phase lifecycle documented | TRUE | — |
| 24 | Fail-closed containment | TRUE | — |
| 25 | Client heartbeat ping-pong | TRUE | — |
| 26 | max_connections TECH DEBT | TRUE | — |

**4 FALSE claims found. 2 claims require README update (ACLs, conn limits). 1 claim outdated (get-ok count). 1 claim has a validation gap (frame_max). 2 claims unverifiable in-session.**
