# Security

## Scope

Security is part of product correctness.

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
