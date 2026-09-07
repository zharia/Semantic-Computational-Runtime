# ADR-0002 — AMQP Boundary

## Status

Accepted seed decision.

## Decision

AMQP 0-9-1 is an interoperability boundary. It is not the canonical internal
message representation.

## Consequence

The future architecture should resemble:

```text
AMQP client
    ↓
AMQP codec/protocol state
    ↓
Hyrx semantic API
    ↓
Hyrx core
    ↓
Hyrx semantic API
    ↓
AMQP codec
    ↓
AMQP client
```

Native Hyrx clients should be able to bypass AMQP framing entirely.
