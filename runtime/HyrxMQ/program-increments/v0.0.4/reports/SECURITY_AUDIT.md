# Security Audit — HyrxMQ v0.0.4

## Scope

`src/hyrxmq/amqp_service.mojo` (3282 lines) — the frame-level dispatch layer. Checks cover auth enforcement, ACL gates, vhost isolation, error safety, message size limits, and connection limits.

---

## 1. Auth Enforcement on Every Connection

**Question:** Is SASL auth validated before any business method is served?

**Finding:** YES.

- `amqp_service.mojo:1472-1535` — `CONNECTION_START_OK` handler validates SASL PLAIN credentials against `_users` table.
- `amqp_service.mojo:1505-1524` — on failure: `_auth_failures` incremented, SERVER-initiated `connection.close` with reply-code 403 `ACCESS_REFUSED` returned immediately. The listener closes the socket after sending (no further serving).
- `amqp_service.mojo:1496-1504` — only `"PLAIN"` mechanism accepted. Non-PLAIN or empty mechanism → auth failure.

**Coverage:** Auth refusal is gated BEFORE `connection.tune` is sent. The connection never reaches OPEN state.

**Tested:** `tests/phase7/connection_negotiation_test.mojo`, `tests/phase7/amqp_service_test.mojo`

**Risk:** LOW — auth is the first gate after start-ok; no business method path bypasses it.

---

## 2. ACL Checks Before Operations

**Question:** Are ACL permissions checked at every operation point?

**Finding:** YES — all five operation classes are gated.

| Operation | Permission | Location |
|-----------|-----------|----------|
| exchange.declare | configure | `amqp_service.mojo:1622-1629` |
| queue.declare | configure | `amqp_service.mojo:1754-1761` |
| basic.publish | write | `amqp_service.mojo:2012-2019` |
| basic.consume | read | `amqp_service.mojo:2086-2093` |
| basic.get | read | `amqp_service.mojo:2133-2140` |

**Mechanism:** `_PermBits` struct (line 672-689) stores per-connection configure/write/read booleans. Set at SASL auth time from `UserRecord` (line 1528-1534). Checked via `if conn_id in self._conn_permissions: if not self._conn_permissions[conn_id].<perm>`.

**Gap:** ACL checks are conditional (`if conn_id in self._conn_permissions`). If a connection reaches a business method without `_conn_permissions` being set (e.g., pre-auth frames bypass the check), the ACL is silently permissive. However, this cannot happen in practice because auth sets the permissions at start-ok, and business methods only arrive after OPEN state.

**Untested:** No dedicated ACL test in the test suite. Only code-verified.

**Risk:** LOW — the conditional check is redundant given the lifecycle, but a defense-in-depth test would strengthen confidence.

---

## 3. Vhost Isolation

**Question:** Is vhost isolation working? Can a connection access resources outside its vhost?

**Finding:** PARTIAL — vhost is recorded but NOT enforced as an isolation boundary.

- `amqp_service.mojo:1529` — `self._conn_vhost[conn_id] = self._users[matched_user_idx].vhost.copy()` records the user's vhost.
- `amqp_service.mojo:966-967` — `_conn_vhost: Dict[UInt64, String]` stored per-connection.
- **No vhost filtering on resource access.** The broker is single-vhost (`"/"`); all queues/exchanges live in one namespace. The vhost string is stored but never consulted in queue.declare, exchange.declare, publish, or consume paths.
- Error messages hardcode `"' in vhost '/'"` (e.g., `amqp_service.mojo:1646`, `1779`, `2724`).

**Tested:** No vhost isolation test exists.

**Risk:** MEDIUM — vhost is cosmetic only. A user configured for vhost `/a` can access all queues/exchanges. This is honest scope (single vhost broker), but the `_conn_vhost` storage creates a false sense of isolation.

---

## 4. Error Response Safety (Information Leakage)

**Question:** Do error responses leak sensitive information (stack traces, internal paths, credentials)?

**Finding:** MOSTLY SAFE.

- **Auth errors:** `amqp_service.mojo:1511-1513` — generic text: `"ACCESS_REFUSED - Login was refused using authentication mechanism PLAIN. For details see the broker logfile."` No username/password in the reply. Password is never logged (line 371 comment, but `amqp_service.mojo:1486-1493` DOES log `authcid` — the username — which is acceptable).
- **Channel errors:** `amqp_service.mojo:2801-2826` — `_channel_error` carries reply-code + reply-text + failing method IDs. Text includes queue/exchange names (e.g., `"NOT_FOUND - no queue 'X' in vhost '/'"`) which is standard AMQP behavior.
- **Content errors:** `amqp_service.mojo:2532-2534` — `_fail_content` prints to broker log only, never sent to client.
- **Exception handling:** `listener.mojo:508-524` — `serve_one_frame` catches all exceptions, closes the slot, returns SERVE_FAILED. No exception text reaches the client.

**Gaps:**
- Queue/exchange names in error text are sent to the client (standard AMQP, but could reveal internal topology to unauthorized clients).
- The authcid (username) is printed to stdout (line 1486-1493) — acceptable for server logs but should not be in production stdout.

**Risk:** LOW — no credentials in wire responses. Topology names in errors are AMQP-standard.

---

## 5. max_message_size Enforcement

**Question:** Is the configured `max_message_size` enforced on inbound publishes?

**Finding:** YES.

- `amqp_service.mojo:2858-2864` — `_on_content_header` checks `size > self._max_message_size` BEFORE accepting the body. On exceed: `_fail_content` drops the publish, increments `_content_errors`. No reply is sent (the message is silently dropped, which is the fail-closed behavior).
- `amqp_service.mojo:2865-2871` — a second check against `MAX_PENDING_BODY() = 8 MiB` (hard ceiling).
- `amqp_service.mojo:2907-2915` — each BODY frame is checked: `have + frame.payload_size() > want` → overflow dropped.
- `config.mojo:197` — default `max_message_size = 134217728` (128 MiB).
- `config.mojo:407-408` — `validate()` ensures `max_message_size > 0`.

**Tested:** `tests/phase7/content_reassembly_test.mojo` covers body overflow.

**Risk:** LOW — enforced at the header stage before any body accumulation.

---

## 6. Connection Limits Enforcement

**Question:** Is `_max_connections` enforced in the listener?

**Finding:** YES.

- `listener.mojo:293-296` — `_max_connections = config.max_connections`.
- `listener.mojo:366-369` — `register` checks `_active >= _max_connections`. On exceed: `_refused += 1`, connection closed immediately, returns -1.
- `listener.mojo:731-738` — `_fill_tcfg` copies `max_connections` to TransportConfig (descriptive; authority is the accept gate).
- `config.mojo:178` — default `max_connections = 1024`.
- `config.mojo:372-373` — `validate()` ensures `max_connections > 0`.

**Tested:** `tests/phase2/bounded_resource_test.mojo`

**Risk:** LOW — enforced at accept time before any AMQP handling.

---

## 7. Additional Security Observations

### 7a. Pending Body Accumulation Ceiling

`MAX_PENDING_BODY() = 8 MiB` (line 228-229) bounds the total reassembled body per connection. A hostile client cannot dribble unbounded BODY frames toward memory exhaustion. The per-frame codec limit (`frame_max`) provides a second bound.

### 7b. Channel Close on Auth/ACL Failure

When ACL is denied, the channel is closed (`_mark_channel_closed`) and the connection stays alive for other channels. This is correct AMQP behavior (channel-level errors don't kill the connection).

### 7c. Idle Timeout

`listener.mojo:282-285` — `_idle_timeout_ms` tracked per-connection. `check_idle_connections()` (line 419-437) returns expired slots. The event-driven loop closes them (line 948-955). Default 300 seconds.

### 7d. Buffer Pool Safety

`router.mojo:56-61` — `_pool` declared before `_queues` for safe deinit ordering. Pool release happens at every message death site (ack, delete-drain, shutdown-drain, dead-letter). No orphaned pooled buffers.

---

## Summary

| Check | Status | Risk |
|-------|--------|------|
| Auth on every connection | ENFORCED | LOW |
| ACLs before operations | ENFORCED (untested) | LOW |
| Vhost isolation | **COSMETIC ONLY** | MEDIUM |
| Error response safety | SAFE | LOW |
| max_message_size enforced | ENFORCED | LOW |
| max_connections enforced | ENFORCED | LOW |

**Key finding:** Vhost isolation is recorded but not enforced as a resource boundary. This is honest scope for a single-vhost broker, but `_conn_vhost` creates a false sense of isolation. If multi-vhost support is planned, the vhost field must be checked on every resource access.

**Recommended actions:**
1. Add a dedicated ACL test covering exchange.declare, queue.declare, basic.publish, basic.consume, basic.get with denied permissions.
2. Either enforce vhost isolation or remove `_conn_vhost` to avoid false安全感.
3. Add a resource-limit test for max_queues/max_exchanges.
