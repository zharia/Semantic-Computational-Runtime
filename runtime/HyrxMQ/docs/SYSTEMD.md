# systemd Integration

HyrxMQ is a GNU/Linux/systemd-native product.

## Service requirements

The service should support:

- deterministic startup
- readiness signaling
- graceful shutdown
- restart policy
- optional watchdog
- dedicated user/group
- journal logging
- runtime directory
- data directory
- configuration validation before start
- safe reload where supported

## Hardening

Evaluate and document:

- NoNewPrivileges
- ProtectSystem
- ProtectHome
- PrivateTmp
- RestrictAddressFamilies
- capability restrictions
- resource controls
- filesystem access
- device access

Do not enable a hardening control until it has been tested against all supported operations.

## Service acceptance

A release candidate must:

1. install the unit
2. start successfully
3. become ready
4. pass health checks
5. survive controlled restart
6. recover expected durable state
7. stop cleanly
8. emit useful journal output
