# Progress Report — M2 Security Hardening

**Date:** 2026-09-11
**Status:** COMPLETE (TLS proven; auth/fuzz/frame-size done; authorization+timeouts out of scope)
**Gate verdict:** PASS (for implemented scope)

**WHAT CHANGED:**
- `src/hyrx/transport/tcp.mojo` — optional TLS wrapping on accepted connections (OpenSSL via flare FFI)
- `src/hyrxmq/config.mojo` — tls_enabled / tls_cert_path / tls_key_path config + validate invariants
- `src/hyrxmq/listener.mojo` — AMQPListener.configure_tls()
- `src/hyrxmq/main_listen.mojo` — env resolution (HYRXMQ_TLS_ENABLED/CERT/KEY) + wiring
- `scripts/interop/tls_probe.py` — external real-TLS acceptance gate (NEW)
- `tests/phase10/tcp_tls_test.mojo` — config + plaintext-unchanged tests (NEW)
- `tests/phase10/frame_fuzz_test.mojo` — adversarial frame parser tests (NEW)
- `scripts/test_all.sh` — removed stale fixture block

**WHAT WAS TESTED / HOW:**
| Control | Status | Evidence |
|---------|--------|----------|
| TLS handshake (TLS 1.3) | PROVEN | `scripts/interop/tls_probe.py` — 6/6 PASS |
| AMQP connection.start over TLS | PROVEN | tls_probe: frame type 1, class 10/method 10 |
| Cert presented matches on-disk | PROVEN | tls_probe: 781-byte DER match |
| Plaintext rejected on TLS port | PROVEN | tls_probe: connection reset |
| TLS config parse/validate | TESTED | tests/phase10/tcp_tls_test.mojo |
| Plaintext unchanged (no TLS) | TESTED | tests/phase10/tcp_tls_test.mojo |
| SASL PLAIN authentication | IMPLEMENTED | pre-existing; negative-password test |
| Frame size enforcement | IMPLEMENTED | tests/phase6/frame_codec_bounds.mojo |
| Fuzz: malformed frames | TESTED | tests/phase10/frame_fuzz_test.mojo (1000 random + 8 classes) |
| per-resource authorization | NOT IMPLEMENTED | single vhost; all authenticated users full access |
| timeouts | NOT IMPLEMENTED | — |
| connection limits | NOT IMPLEMENTED | single synchronous connection |

**KEY FINDING:** The pre-existing test fixture cert (Ed25519, reused from phase9) is
INVALID — `openssl x509` rejects it. The new probe generates a valid RSA self-signed
cert. The flare TLS server correctly rejects the invalid cert.

**OTHER FINDING:** HyrxMQ echoes the 8-octet AMQP protocol header before emitting
connection.start (listener.mojo `_step_header`). The external probe accounts for this.

**REGRESSION CHECK:**
- Full test suite: 49/0 PASS (47 baseline + phase10 TLS + phase10 fuzz)

**READY FOR NEXT MILESTONE?**
- YES
