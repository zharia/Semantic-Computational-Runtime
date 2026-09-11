# Security

## Scope

Security is part of product correctness.

## Implementation status (v0.0.3)

| Control | Status | Evidence |
|---------|--------|----------|
| SASL PLAIN authentication | IMPLEMENTED | users table; negative-password test |
| TCP TLS | PROVEN | TLS 1.3 handshake, AMQP-over-TLS (`scripts/interop/tls_probe.py`) |
| TLS certificate validation | IMPLEMENTED | server loads cert/key; config validated |
| Frame size enforcement | IMPLEMENTED | `frame_max` ceiling; `tests/phase6/frame_codec_bounds.mojo` |
| Hostile input fuzzing | IMPLEMENTED | `tests/phase10/frame_fuzz_test.mojo` |
| Authorization (ACLs/vhosts) | NOT IMPLEMENTED | single vhost, all authenticated users full access |
| Connection/I/O timeouts | NOT IMPLEMENTED | — |
| Connection limits | NOT IMPLEMENTED | single synchronous serving |
| TLS on UDS | NOT IMPLEMENTED | — |

## Network security

- TLS
- certificate validation/configuration
- secure credential handling
- SASL authentication
- connection limits
- frame/message size limits
- timeout controls

## Authorization

Support:

- users
- credentials
- virtual hosts
- resource permissions
- operation permissions

The authorization model must be explicit and testable.

## Host security

Use systemd hardening where compatible with operation.

Candidate controls include:

- dedicated service account
- NoNewPrivileges
- ProtectSystem
- ProtectHome
- PrivateTmp
- capability bounding
- resource limits
- restricted filesystem access

## Hostile input

Fuzz and adversarially test:

- frame length
- malformed fields
- recursive/large tables where applicable
- invalid UTF-8 where relevant
- channel identifiers
- method sequencing
- heartbeat behavior
- oversized payloads
- connection storms
- authentication failures

A malformed client must not crash the process or corrupt broker state.
