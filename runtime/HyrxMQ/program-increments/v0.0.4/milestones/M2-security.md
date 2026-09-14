# M2: Security & Multi-Tenant Isolation

**Gate:** C (Security)
**Spec:** Sections 20-26

## Sprint 2.1 — Authentication Hardening ✅ (Partial)
- [x] SASL PLAIN credentials table (config.mojo:18-26)
- [x] Connection.close 403 on auth failure (amqp_service.mojo)
- [ ] Repeated auth failure rate limiting (connection refusal after N failures)
- [ ] Auth failure audit logging

## Sprint 2.2 — Vhost Namespace Isolation
**File:** `src/hyrxmq/amqp_service.mojo`, `src/hyrx/core/router.mojo`
- Scope exchange/queue operations to vhost
- Cross-vhost access denied (403)
- Config: vhost name (already exists, scope enforcement needed)

## Sprint 2.3 — Authorization ACLs
- Per-user operation permissions (connect, publish, consume, declare)
- Config: `users[].permissions` map
- Evaluate BEFORE operation takes effect

## Sprint 2.4 — TLS Trust
- Certificate chain validation (already has TLS transport)
- Expired certificate rejection
- Self-signed certificate configurable behavior

## Exit Criteria
- [ ] Auth failure rate limiting
- [ ] Vhost isolation proven
- [ ] Authorization enforced
- [ ] TLS trust validated
