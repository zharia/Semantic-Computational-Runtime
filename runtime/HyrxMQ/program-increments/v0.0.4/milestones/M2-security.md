# M2: Security & Multi-Tenant Isolation

**Gate:** C (Security)
**Status:** PARTIAL — auth, vhost isolation, ACLs and TLS trust done; repeated
auth-failure rate limiting and dedicated ACL tests remain.
**Spec:** Sections 20-26

## Sprint 2.1 — Authentication Hardening ✅ (Partial)
- [x] SASL PLAIN credentials table (config.mojo:18-26)
- [x] Connection.close 403 on auth failure (amqp_service.mojo)
- [ ] Repeated auth failure rate limiting (connection refusal after N failures) —
  **NOT DONE**: failures are counted (`_auth_failures`) but no refusal threshold.
- [ ] Auth failure audit logging — counter is exposed via status/`to_prometheus`
  (`hyrxmq_auth_failures`); no dedicated auth audit log stream.

## Sprint 2.2 — Vhost Namespace Isolation ✅
**File:** `src/hyrxmq/amqp_service.mojo`, `src/hyrx/core/router.mojo`
- [x] Scope exchange/queue operations to vhost (`_vhost_scope` name-prefix boundary)
- [x] Cross-vhost access denied (403)
- [x] Config: per-user `vhost` (enforced at routing boundary)
- Tested: `tests/phase10/vhost_isolation_test.mojo`

## Sprint 2.3 — Authorization ACLs ✅ (code-verified)
- [x] Per-user operation permissions (configure, write, read)
- [x] Config: `users[].can_configure` / `can_write` / `can_read`
- [x] Evaluate BEFORE operation takes effect
- Enforced: exchange.declare/queue.declare → configure (`amqp_service.mojo:1622,1754`),
  basic.publish → write (:2012), basic.consume/basic.get → read (:2086,:2133); invariant R16.
- [ ] Dedicated ACL test — **NOT DONE**: enforced in code; no unit test asserts
  the deny paths (invariant audit R16 gap).

## Sprint 2.4 — TLS Trust ✅
- [x] Certificate chain validation (TLS transport)
- [x] `tls_verify_peer` policy (default True) — listener.mojo
- [x] `tls_allow_self_signed` configurable behavior
- [x] `tls_ca_path` trust anchor
- Tested: `tests/phase10/tls_validation_test.mojo`
- [ ] Expired/revoked certificate and hostname-validation tests — not separately covered.

## Exit Criteria
- [ ] Auth failure rate limiting
- [x] Vhost isolation proven
- [x] Authorization enforced (code-verified; test gap noted)
- [x] TLS trust validated