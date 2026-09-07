# Manifestation Engine — Traceability Matrix

This document maps the Manifestation Engine subsystem to the existing SCR architecture.

| Manifestation Engine concept | SCR authority | Relationship |
|---|---|---|
| Semantic Field | Project Mandate / Semantic Model | Foundational source of meaning |
| Hypergraph | SCR semantic architecture | Structural manifestation of semantic relationships |
| Semantic capability | Project Mandate capability model | Bridge from semantics to realization |
| Provider | Project Mandate provider architecture | Implementation mechanism satisfying semantic contract |
| Manifestation | Semantic Field `M` | Physical-realisation concept represented semantically |
| Manifestation Engine | Runtime / orchestration architecture | Realizes semantic requirements physically |
| Reference Executor | Current runtime/verification artifacts | Semantic oracle, not production realization |
| Mojo | Current implementation stack | Preferred implementation technology |
| MLIR | Project Mandate MLIR-first policy | Canonical compiler representation substrate |
| AMQP | Messaging architecture | Potential internal/provider transport |
| Physical substrate | Runtime architecture | Final execution environment |

## Current repository alignment

The current repository describes SCR as a runtime in which semantic structure is primary and physical execution is its manifestation. It also defines `F = (E,R,T,C,S,K,M)` and explicitly identifies `M` as physical manifestations. The Manifestation Engine documentation therefore treats `M` as part of the semantic model while assigning the Engine responsibility for realization.

The repository currently documents a pipeline through Lean verification, Mojo semantic implementation, Reference Executor, semantic equivalence, MLIR representation/lowering and observation. The Manifestation Engine extends this architecture by specifying how executable semantic requirements cross from semantic representation into provider-backed physical execution.

## Documentation hierarchy

```text
SCR Project Mandate
        ↓
SCR Architecture
        ↓
Semantic Field / Semantic Model
        ↓
Manifestation Engine Contract
        ↓
Capability / Provider Contracts
        ↓
Manifestation Domains
        ↓
Implementation Architecture
        ↓
Validation / Conformance
```

## Important distinction

The Manifestation Engine MUST NOT be used to collapse the distinctions already established by SCR:

- semantics vs representation;
- provider vs runtime;
- runtime vs substrate;
- semantic identity vs physical identity;
- API compatibility vs semantic equivalence;
- documentation status vs implementation status.

## Required repository integration

The implementation should ultimately connect this documentation set to:

- semantic library control-plane definitions;
- provider declarations;
- runtime implementation;
- Reference Executor tests;
- MLIR/compiler tests;
- integration tests;
- program-increment verification reports.

No documentation statement should be treated as evidence that an implementation exists unless the corresponding code and tests demonstrate it.
