# GATE_05_SECURITY_ISOLATION.md

**Date:** 2026-09-11
**Commit:** 4ec2a0650807777d61a02b3a0242ccd2cc9b9eb0
**Assessor:** Automated + code review

---

## Gate verdict: PASS (for implemented scope)

---

## 1. Network security

| Requirement | Status | Evidence |
|-------------|--------|----------|
| TLS (TCP transport) | PROVEN | `scripts/interop/tls_probe.py` 6/6 PASS against the real listen binary: TLS 1.3 handshake, AMQP `connection.start` received over TLS, presented cert matches on-disk cert, plaintext connect rejected. In-process config test: `tests/phase10/tcp_tls_test.mojo` |
| Certificate validation/configuration | IMPLEMENTED | `config.mojo` (`tls_enabled`, `tls_cert_path`, `tls_key_path`) + `validate()` invariants (enabled requires both paths; disabled requires both empty); `main_listen.mojo` env overrides `HYRXMQ_TLS_ENABLED` / `HYRXMQ_TLS_CERT` / `HYRXMQ_TLS_KEY` |
| TLS on UDS transport | NOT IMPLEMENTED | TLS is TCP-tier only |
| Secure credential handling | NOT IMPLEMENTED | Credentials hardcoded in tests |
| SASL authentication | PARTIAL | PLAIN only (SASL negotiation + PLAIN mechanism in adapter.mojo) |
| Connection limits | NOT IMPLEMENTED | Synchronous single connection |
| Frame/message size limits | PARTIAL | `frame_max` negotiated; no enforcement of inbound frame size |
| Timeout controls | NOT IMPLEMENTED | No connection/read/write timeouts |

**SASL/TLS assessment:** PLAIN mechanism works and SASL negotiation completes; no other mechanisms supported. TLS is implemented and proven on the TCP transport with a real external client. Certificate *matching against a trust root / chain validation* is not implemented — the probe verifies the presented cert equals the configured cert (self-signed reference model). This is acceptable for the reference implementation scope.

---

## 2. Authorization

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Users | NOT IMPLEMENTED | Hardcoded admin/password in tests |
| Credentials | NOT IMPLEMENTED | No credential store |
| Virtual hosts | NOT IMPLEMENTED | Hardcoded "/" |
| Resource permissions | NOT IMPLEMENTED | No permission model |
| Operation permissions | NOT IMPLEMENTED | No permission model |

**Assessment:** The authorization model is documented in SECURITY.md but not implemented. The product accepts any connection with valid credentials (PLAIN). No per-vhost or per-resource authorization.

---

## 3. Host security

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Dedicated service account | NOT IMPLEMENTED | No systemd unit |
| NoNewPrivileges | NOT IMPLEMENTED | — |
| ProtectSystem | NOT IMPLEMENTED | — |
| ProtectHome | NOT IMPLEMENTED | — |
| PrivateTmp | NOT IMPLEMENTED | — |
| Capability bounding | NOT IMPLEMENTED | — |
| Resource limits | NOT IMPLEMENTED | — |
| Restricted filesystem access | NOT IMPLEMENTED | — |

**Assessment:** Systemd hardening is out of scope for the reference implementation.

---

## 4. Hostile input

| Test Category | Status | Evidence |
|---------------|--------|----------|
| Frame length | TESTED | `tests/phase10/frame_fuzz_test.mojo` — truncated header, oversized declared size |
| Malformed fields | TESTED | `tests/phase10/frame_fuzz_test.mojo` — 8 malformed classes (empty, truncated header/body, invalid type, zero-length, truncated method args) |
| Recursive/large tables | NOT TESTED | — |
| Invalid UTF-8 | NOT TESTED | — |
| Channel identifiers | NOT TESTED | — |
| Method sequencing | PARTIAL | truncated method args in `frame_fuzz_test.mojo`; no ordering state machine test |
| Heartbeat behavior | NOT TESTED | — |
| Oversized payloads | TESTED | `tests/phase10/frame_fuzz_test.mojo` — oversized declared size fails closed |
| Random fuzzing | TESTED | `tests/phase10/frame_fuzz_test.mojo` — 1000 random byte buffers, no crash |
| Connection storms | NOT TESTED | — |
| Authentication failures | PARTIAL | test_amqp_authentications (negative password test) |

**Assessment:** A parser fuzz harness now exists (`tests/phase10/frame_fuzz_test.mojo`): 1000 random inputs plus 8 named malformed classes, none crash the process — malformed frames fail closed. Coverage is bounded: no corpus-driven/coverage-guided fuzzing, no heartbeat- or connection-storm tests, and no invalid-UTF-8 or channel-identifier abuse tests.

---

## 5. Known security gaps

1. **TLS is TCP-tier only** — UDS transport is plaintext; no client-certificate / trust-chain validation (self-signed cert-match model).
2. **No authorization** — Any authenticated user can access any vhost, exchange, or queue. Single vhost (`/`), no ACLs, no per-resource permission model.
3. **No timeout controls** — A slow client could block the server connection (no connection/read/write timeouts).
4. **No connection limits** — Single synchronous connection; no DoS protection.
5. **No inbound frame-size enforcement** — `frame_max` is negotiated but oversized inbound frames are not rejected by policy.
6. **Hardcoded credentials** — admin/password in all test configurations.
7. **Fuzz coverage is bounded** — random + named malformed classes pass, but no coverage-guided corpus and no heartbeat/connection-storm tests.

---

## 6. Regression check

- Full test suite: **52/0 PASS**

---

## 7. Gate artifacts

| Artifact | Location |
|----------|----------|
| Security Policy | `docs/SECURITY.md` |
| TLS acceptance probe | `scripts/interop/tls_probe.py` |
| TLS config tests | `tests/phase10/tcp_tls_test.mojo` |
| Frame fuzz tests | `tests/phase10/frame_fuzz_test.mojo` |
| This Gate | `docs/engineering/GATE_05_SECURITY_ISOLATION.md` |
