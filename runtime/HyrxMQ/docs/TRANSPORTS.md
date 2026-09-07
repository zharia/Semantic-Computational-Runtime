# Transport Architecture

## Principle

Transport is a replaceable realization of Hyrx messaging semantics.

### Transport classes

| Transport | Purpose | Compatibility |
|---|---|---|
| Direct | same-process | Hyrx-native |
| Unix domain socket | same-host IPC | Hyrx extension |
| Shared memory | ultra-low-cost same-host IPC | Hyrx extension |
| TCP | general network | Hyrx-native / AMQP |
| TLS/TCP | secure network | AMQP |
| QUIC | Hyrx-native modern network transport | Hyrx extension |

## TCP

TCP is the baseline external transport because AMQP 0-9-1 clients expect conventional TCP connectivity.

TCP must be fully supported before optional transport optimization becomes a release blocker.

## QUIC

QUIC may be implemented as a Hyrx-native transport.

Do not describe arbitrary QUIC transport as "standard AMQP 0-9-1 over QUIC". It is a Hyrx transport extension unless a separate protocol specification establishes interoperability.

## Unix domain sockets

Evaluate before shared memory because they provide a comparatively simple local IPC mechanism.

Benchmark:

- latency
- throughput
- CPU/message
- copies
- wakeups
- connection setup
- failure behavior

## Shared memory

Shared memory is an optimization candidate, not an architectural assumption.

It requires explicit treatment of:

- process lifecycle
- stale state
- synchronization
- ownership
- crash recovery
- ABI/version compatibility
- security
- NUMA
- memory quotas

A shared-memory transport must never corrupt core semantics merely to reduce latency.

## Transport-independent contract

Every transport must preserve, or explicitly document limitations for:

- message identity
- routing
- delivery
- acknowledgement
- ordering guarantees
- backpressure
- failure semantics
- cancellation
- deadlines/timeouts where supported

## Transport selection

Applications should be able to select a transport based on deployment topology without rewriting their messaging model.

Future optimization opportunity:

```text
same process     -> direct
same host        -> direct / UDS / SHM
same cluster     -> QUIC/TCP
external AMQP    -> TCP/TLS + AMQP 0-9-1
```

Selection may eventually be automatic, but only after deterministic behavior and observability are established.
