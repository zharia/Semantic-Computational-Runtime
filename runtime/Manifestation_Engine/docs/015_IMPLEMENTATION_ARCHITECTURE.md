# Manifestation Engine — Implementation Architecture

This document describes a possible implementation decomposition. It is subordinate to the normative semantic contract.

## 1. Suggested components

```text
Executable Graph Server / Manifestation Engine
├── Graph Registry
├── Identity Resolver
├── Execution Manager
├── Context Manager
├── Capability Registry
├── Provider Registry
├── Provider Selector
├── Resource Manager
├── Manifestation Manager
├── Data Manager
├── Messaging Manager
├── Compute Manager
├── State Manager
├── Transaction Manager
├── Lifecycle Supervisor
├── Failure/Recovery Manager
├── Observation/Telemetry
├── Policy/Security
├── Protocol Adapters
└── Control Plane
```

These are implementation responsibilities, not SCR semantic entities.

## 2. Graph registry

Stores or discovers executable semantic graph structures and their semantic identities.

It MUST NOT become a physical resource registry disguised as graph state.

## 3. Identity resolver

Resolves semantic identities, graph regions and execution references.

## 4. Capability registry

Provides machine-readable capability contracts and provider declarations.

## 5. Provider registry

Tracks available provider implementations and their conformance metadata.

## 6. Resource manager

Tracks physical capacity, allocations, quotas and availability.

## 7. Manifestation manager

Maintains semantic-to-physical correspondence and manifestation lifecycle.

## 8. Execution manager

Coordinates execution requests, dependencies, scheduling, context and results.

## 9. Security/policy

Evaluates authorization, trust, resource policy and provider admission.

## 10. Control plane

Administrative APIs may expose graph loading, provider management, metrics, health and configuration. These are not semantic graph operations unless explicitly modeled as such.

## 11. Data plane

The data plane executes semantic work and manifests required resources.

## 12. No hidden second IR

The Engine MUST NOT introduce an independent graph execution IR that duplicates the SCR semantic model or MLIR. Internal scheduling structures are allowed when they are derived and do not become semantic authority.

## 13. Mojo/MLIR boundary

Mojo/MLIR components may produce executable artifacts or runtime requirements. The Engine consumes semantic execution contracts and/or derived executable representations according to the selected implementation architecture.

## 14. AMQP boundary

If AMQP is used internally, it belongs below the semantic messaging capability boundary.
