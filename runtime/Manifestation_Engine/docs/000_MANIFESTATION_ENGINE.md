# SCR Manifestation Engine — Normative Architecture

**Status:** Architectural specification
**Scope:** Manifestation Engine subsystem of SCR
**Authority:** Normative for this subsystem; subordinate to the SCR Project Mandate, Semantic Model and Architecture

## 1. Purpose

The Manifestation Engine provides the mechanism by which executable semantic structures acquire physical execution while preserving semantic independence from physical implementation.

Its central responsibility is:

> Resolve semantic execution requirements into valid manifestations without importing physical implementation dependencies into the semantic world.

The Engine is the membrane between semantic computation and physical reality.

## 2. Fundamental model

SCR models computation as transformation of semantic structure within a Semantic Field. The current SCR field model is:

`F = (E, R, T, C, S, K, M)`

where `E` is entities, `R` relationships, `T` transformations, `C` context, `S` state, `K` constraints and `M` physical manifestations.

The Manifestation Engine operates on the boundary represented by `M`: it interprets semantic requirements for manifestation and realizes them through providers and physical substrates.

The Engine MUST NOT redefine the Semantic Field.

## 3. Semantic closure

An executable hypergraph is semantically closed when every dependency required to understand or execute it can be expressed as semantic identity, relationship, transformation, state, context, constraint or capability requirement.

Physical resources MAY exist outside the semantic graph, but they MUST enter execution only through Engine-managed manifestations.

A graph MUST NOT directly depend on:

- CPU/GPU identities;
- filesystem paths;
- database table names;
- broker-specific routing identifiers;
- socket addresses;
- operating-system handles;
- vendor-specific libraries;
- device addresses;
- physical memory addresses;
- provider implementation names.

Such information belongs to manifestation and provider layers.

## 4. Execution contract

Conceptually:

`execute(node, context) -> (semantic_state', observations)`

Execution may additionally produce manifestation effects, resource effects and external observations, but their semantic consequences MUST remain explicit.

An execution request MUST identify semantic execution intent, not a physical implementation.

## 5. Capability resolution

The canonical resolution path is:

`Semantic requirement → Capability contract → Candidate providers → Selection → Manifestation → Execution`

A provider satisfies a capability. It does not define the capability's semantics.

Provider selection MAY use hardware, locality, load, precision, determinism, cost, latency, throughput, resource availability and other execution facts, provided the semantic contract remains invariant.

## 6. Manifestation transparency

If provider `P1` and provider `P2` satisfy the same semantic capability under the same applicable contract, replacing `P1` with `P2` MUST NOT require modification of the semantic hypergraph.

This does not imply that all providers are semantically equivalent. Equivalence MUST be established against the applicable contract, including precision, ordering, stochasticity, side effects, temporal behavior and observability where relevant.

## 7. Context

Manifestation is context-dependent. The same semantic requirement may be realized differently under different execution contexts.

Context may include:

- authority and security policy;
- available resources;
- locality;
- time and temporal constraints;
- consistency requirements;
- precision requirements;
- determinism requirements;
- provider availability;
- cost or policy constraints;
- execution lineage.

Context MUST constrain realization without silently changing semantic meaning.

## 8. State and effects

The Engine MUST distinguish:

1. semantic state;
2. manifestation state;
3. provider state;
4. physical resource state;
5. observations about execution.

A physical effect is not automatically a semantic state transition. The Engine MUST define the correspondence explicitly.

## 9. Data

A semantic data entity is identified semantically. The Engine maps it to a physical manifestation when execution requires material access.

Conceptually:

`semantic data ID → data manifestation → provider → physical block`

The physical block may be memory, file storage, database state, object storage, remote state, device memory or generated data.

The graph MUST NOT require knowledge of the physical location.

## 10. Communication

Communication is a semantic capability. A graph may request semantic message publication, delivery, subscription, acknowledgement or stream transformation.

The Engine resolves these requirements through messaging providers. AMQP may be an internal or preferred manifestation substrate, but AMQP identifiers and broker topology MUST NOT become semantic graph dependencies.

## 11. Compute

Compute requirements are semantic operations plus capability constraints. A provider may realize them through CPU, GPU, accelerator, numerical library, external runtime or other machinery.

Representation selection, compilation and specialization MAY occur before or during execution.

## 12. Observation

The Engine MUST expose sufficient observation to determine what semantic computation occurred and whether manifestation preserved the contract.

Observations SHOULD distinguish:

- semantic results;
- execution telemetry;
- provider telemetry;
- physical resource telemetry;
- provenance;
- errors;
- policy decisions.

## 13. Failure

Failure MUST be modeled explicitly. The Engine MUST distinguish at least:

- semantic invalidity;
- capability unsatisfied;
- provider unavailable;
- resource exhaustion;
- transient transport failure;
- physical execution failure;
- timeout;
- cancellation;
- policy denial;
- consistency conflict;
- unrecoverable state corruption.

Retries MUST NOT silently duplicate non-idempotent semantic effects.

## 14. Security

Physical manifestation is an authority boundary. A graph's semantic request does not itself grant unlimited physical access.

The Engine MUST enforce authorization before capability acquisition and resource access. Provider capabilities MUST be least-privilege and auditable.

Untrusted semantic graphs MUST NOT be able to bypass the Engine to reach physical resources.

## 15. Lifecycle

The Engine MUST support a defined lifecycle for executable semantic structures and their manifestations, including discovery/loading, validation, activation, execution, suspension, resumption, migration where supported, failure handling and termination.

Lifecycle state MUST NOT be confused with semantic state.

## 16. Resource management

The Engine MUST treat compute, memory, storage, communication bandwidth, concurrency, device capacity and other execution resources as managed resources.

Resource decisions MAY influence provider selection and scheduling but MUST NOT silently alter semantic requirements.

## 17. Distributed execution

A semantic graph MAY be realized across multiple physical hosts or providers. Distribution is a manifestation property unless distributed semantics are explicitly part of the contract.

Network partitions, ordering, consistency and retries MUST be represented according to the semantic contract rather than hidden as implementation details.

## 18. Reference Executor

The Reference Executor is a semantic oracle and validation baseline. It is not the production Manifestation Engine and is not the authority for physical provider selection.

Where an optimized or physical realization disagrees with the Reference Executor, the semantic specification is authoritative.

## 19. Mojo and MLIR

Mojo and MLIR are implementation and compilation technologies in the SCR stack. They may interpret semantic operations, specialize them and generate executable representations.

The Manifestation Engine contract MUST remain defined at the semantic capability boundary and MUST NOT require a particular Mojo artifact or MLIR representation as its semantic input.

## 20. Applications and packages

Application, package, executable artifact and bootstrap are implementation-level packaging concepts. They MUST NOT become foundational SCR ontology.

The Engine ultimately hosts and executes semantic structures, regardless of how those structures are packaged by Mojo/MLIR tooling.

## 21. Normative invariants

**ME-INV-001 Semantic isolation:** semantic graphs MUST NOT contain physical provider dependencies.

**ME-INV-002 Provider independence:** provider selection MUST occur outside semantic identity.

**ME-INV-003 Capability mediation:** physical access MUST be mediated by semantic capability contracts.

**ME-INV-004 Manifestation transparency:** provider replacement MUST not require semantic graph modification when the replacement satisfies the same contract.

**ME-INV-005 Identity preservation:** semantic identity MUST survive manifestation and representation changes.

**ME-INV-006 Observable correspondence:** manifestation MUST expose enough information to validate semantic effects.

**ME-INV-007 Authority separation:** semantic specification, compiler, provider, Engine and physical substrate MUST remain distinct authorities.

**ME-INV-008 Failure explicitness:** failures that can affect semantic correctness MUST be observable as semantic execution outcomes.

**ME-INV-009 Security mediation:** physical resource access MUST be capability- and policy-mediated.

**ME-INV-010 Reproducibility:** execution requiring reproducibility MUST expose deterministic seeds, versions, provider identity and relevant environmental facts.

**ME-INV-011 No hidden semantic mutation:** provider or Engine behavior MUST NOT silently alter semantic state outside the declared contract.

**ME-INV-012 Traceability:** every realized execution SHOULD be traceable from semantic requirement to provider and physical manifestation.

## 22. Non-goals

The Manifestation Engine is not:

- the definition of SCR semantics;
- a replacement for MLIR;
- a second IR;
- a graph database;
- a message broker;
- an application framework;
- a universal operating system abstraction;
- a provider implementation itself.

## 23. Conformance

An Engine implementation conforms when it preserves the applicable semantic contracts while resolving executable requirements into physical execution, and when it satisfies the invariants and validation requirements defined by this documentation set.
