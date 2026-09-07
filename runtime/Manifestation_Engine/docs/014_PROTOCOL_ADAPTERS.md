# Manifestation Engine — Protocol Adapters

## 1. Purpose

Protocol adapters connect external technologies to SCR without allowing external protocol semantics to become the semantic authority.

## 2. Direction

```text
External protocol
      ↓
Protocol adapter
      ↓
Semantic capability
      ↓
Manifestation Engine
```

or:

```text
Semantic capability
      ↓
Manifestation Engine
      ↓
Protocol adapter
      ↓
External protocol
```

## 3. Examples

Potential adapters include:

- AMQP;
- HTTP;
- WebSocket;
- gRPC;
- database protocols;
- filesystem interfaces;
- GPU APIs;
- operating-system interfaces.

These are implementation boundaries.

## 4. Adapter rules

An adapter MUST:

1. translate protocol behavior into an applicable semantic contract;
2. preserve identity and relevant ordering;
3. map errors explicitly;
4. expose delivery/consistency guarantees honestly;
5. avoid leaking physical identifiers into semantic identity.

## 5. Protocol mismatch

If an external protocol cannot satisfy the semantic contract, the adapter MUST fail or expose degraded semantics explicitly. It MUST NOT silently weaken the contract.

## 6. External services

A remote service is a provider only when its behavior is wrapped by a capability contract that the Engine can reason about.
