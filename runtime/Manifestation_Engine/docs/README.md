# SCR Manifestation Engine

The Manifestation Engine is the execution and physical-realisation boundary of the Semantic Computational Runtime (SCR). It is the mechanism through which semantic requirements expressed by executable Semantic Fields are resolved into valid physical execution without allowing physical implementation details to become dependencies of the semantic hypergraph.

## Architectural position

```text
Semantic Field
    ↓
Hypergraph / semantic structure
    ↓
Executable semantics
    ↓
Execution context
    ↓
Semantic capability requirement
    ↓
Manifestation Engine
    ↓
Provider
    ↓
Physical manifestation
    ↓
Execution
    ↓
Observation / semantic state
```

The Manifestation Engine is therefore not an application server, graph database, message broker, package manager, or general-purpose VM. Those technologies may be used to implement it, but none defines its semantic contract.

## Documentation authority

`000_MANIFESTATION_ENGINE.md` is the normative architectural specification for this subsystem. The numbered documents refine it. Implementation documents describe mechanisms and MUST NOT redefine semantic meaning.

The Manifestation Engine documentation is subordinate to SCR's foundational semantic and architectural documents and MUST remain consistent with them. In particular, SCR's current repository defines the Semantic Field as `F = (E,R,T,C,S,K,M)` and identifies `M` as physical manifestations. The Engine is the machinery that resolves and realizes those manifestations; it is not a replacement for the Semantic Field model.

## Documents

- `000_MANIFESTATION_ENGINE.md` — normative subsystem contract.
- `001_CONCEPTUAL_MODEL.md` — ontology, boundaries and mental model.
- `002_SEMANTIC_EXECUTION_MODEL.md` — executable graph and execution semantics.
- `003_CAPABILITY_PROVIDER_MODEL.md` — capability contracts and provider selection.
- `004_MANIFESTATION_MODEL.md` — manifestation lifecycle and semantic/physical correspondence.
- `005_EXECUTION_CONTEXT.md` — context, scope, authority, locality and execution conditions.
- `006_DATA_MANIFESTATION.md` — semantic data identities and physical data realization.
- `007_COMMUNICATION_MANIFESTATION.md` — semantic messaging and transport realization.
- `008_COMPUTE_MANIFESTATION.md` — compute capabilities and execution realization.
- `009_OBSERVATION_AND_PROVENANCE.md` — observation, telemetry, provenance and traceability.
- `010_REFERENCE_EXECUTION.md` — relationship to the Reference Executor.
- `011_PROVIDER_CONFORMANCE.md` — provider contracts and conformance.
- `012_SECURITY_AND_ISOLATION.md` — authority, trust, isolation and capability security.
- `013_LIFECYCLE_AND_SUPERVISION.md` — loading, activation, suspension, recovery and termination.
- `014_PROTOCOL_ADAPTERS.md` — external protocol boundaries.
- `015_IMPLEMENTATION_ARCHITECTURE.md` — implementation decomposition without semantic leakage.
- `016_VALIDATION_AND_CONFORMANCE.md` — verification strategy and acceptance criteria.
- `017_FAILURE_AND_RECOVERY.md` — failure semantics, retries, compensation and degraded operation.
- `018_RESOURCE_AND_SCHEDULING.md` — resource accounting, admission and scheduling.
- `019_IDENTITY_AND_ADDRESSING.md` — semantic identity, references and physical addresses.
- `020_TRANSACTION_AND_CONSISTENCY.md` — atomicity, consistency and distributed state.
- `021_TRACEABILITY_MATRIX.md` — traceability into existing SCR architecture and repository artifacts.
