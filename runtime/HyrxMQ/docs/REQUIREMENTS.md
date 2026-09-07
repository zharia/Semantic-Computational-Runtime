# Requirements

Requirement identifiers are normative. "SHALL" is mandatory. "SHOULD" is recommended unless a documented exception exists. "MAY" is optional.

## Core

- RQ-CORE-001 Hyrx SHALL be independently buildable.
- RQ-CORE-002 Hyrx SHALL be usable without HyrxMQ.
- RQ-CORE-003 Hyrx SHALL be usable without a network.
- RQ-CORE-004 Hyrx SHALL contain no simulation-specific ontology.
- RQ-CORE-005 Hyrx SHALL expose transport-independent messaging semantics.
- RQ-CORE-006 Hyrx SHALL provide bounded-resource behavior.
- RQ-CORE-007 Hyrx SHALL define ownership/lifetime behavior for messages and buffers.

## HyrxMQ

- RQ-MQ-001 HyrxMQ SHALL be independently deployable.
- RQ-MQ-002 HyrxMQ SHALL target GNU/Linux.
- RQ-MQ-003 HyrxMQ SHALL integrate with systemd.
- RQ-MQ-004 HyrxMQ SHALL implement AMQP 0-9-1 to its published compatibility profile.
- RQ-MQ-005 HyrxMQ SHALL provide TCP interoperability.
- RQ-MQ-006 HyrxMQ SHALL provide management API/CLI/UI.
- RQ-MQ-007 HyrxMQ SHALL provide observability.
- RQ-MQ-008 HyrxMQ SHALL provide documented persistence/recovery semantics where persistence is enabled.

## Transport

- RQ-TR-001 Transports SHALL preserve applicable Hyrx semantics.
- RQ-TR-002 Direct transport SHALL avoid unnecessary serialization.
- RQ-TR-003 TCP SHALL support external AMQP interoperability.
- RQ-TR-004 Optional transports SHALL be explicitly identified as Hyrx extensions unless standardized otherwise.
- RQ-TR-005 Transport selection SHALL not require application-level redesign.

## Performance

- RQ-PERF-001 Performance SHALL be benchmarked.
- RQ-PERF-002 Tail latency SHALL be measured.
- RQ-PERF-003 Copies and allocations SHALL be measurable.
- RQ-PERF-004 Persistence cost SHALL be measured separately.
- RQ-PERF-005 Accepted optimizations SHALL have evidence.
- RQ-PERF-006 Performance regressions SHALL be detected by CI/qualification benchmarks where practical.

## Protocol

- RQ-PROTO-001 Frame parsing SHALL reject malformed input safely.
- RQ-PROTO-002 Protocol state transitions SHALL be explicit.
- RQ-PROTO-003 Heartbeats SHALL be implemented according to the supported profile.
- RQ-PROTO-004 Errors SHALL be deterministic and documented.
- RQ-PROTO-005 Unsupported features SHALL not be falsely advertised.

## Security

- RQ-SEC-001 Authentication SHALL be explicit.
- RQ-SEC-002 Authorization SHALL be enforced.
- RQ-SEC-003 TLS SHALL be supported for production network deployment.
- RQ-SEC-004 Resource limits SHALL mitigate denial-of-service conditions.
- RQ-SEC-005 Malformed network input SHALL not crash the service.

## Operations

- RQ-OPS-001 Configuration SHALL be validated.
- RQ-OPS-002 Health and readiness SHALL be distinguishable.
- RQ-OPS-003 Metrics SHALL be available.
- RQ-OPS-004 Logs SHALL identify operational failures sufficiently for diagnosis.
- RQ-OPS-005 systemd startup/shutdown/restart behavior SHALL be tested.

## Documentation

- RQ-DOC-001 Public behavior SHALL be documented.
- RQ-DOC-002 Unsupported features SHALL be documented.
- RQ-DOC-003 Compatibility claims SHALL identify evidence/version.
- RQ-DOC-004 Performance claims SHALL identify methodology and environment.
