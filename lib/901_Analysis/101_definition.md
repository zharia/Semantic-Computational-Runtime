---

document: 101_definition
document_type: normative_semantic_definition
schema_version: 1.0.0

id: SCR-LIB-ANALYSIS
name: Analysis

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-05

parent: SCR-LIB-CORE

authority: SCR
domain: semantic-library
------------------------

# SCR Analysis

## Definition

Analysis is the cross-cutting semantic domain concerned with deriving meaningful knowledge, properties, relationships, constraints, capabilities, behaviours, costs, risks, and other information about computational structures and their possible or observed behaviour.

Analysis transforms one body of semantic information into another body of information **about that information**.

Analysis therefore operates one level above the structures being analysed while remaining semantically grounded in them.

Examples include:

* determining the type of a value
* determining dependencies between operations
* determining whether an operation is deterministic
* determining whether a computation is differentiable
* determining whether two representations are equivalent
* determining available parallelism
* determining memory requirements
* determining spatial locality
* determining computational complexity
* determining dataflow
* determining control flow
* determining resource requirements
* determining whether a transformation is valid
* determining whether a provider can satisfy a capability contract
* determining whether an execution strategy preserves semantics.

Analysis is not limited to programs.

It may operate over:

* semantic graphs
* hypergraphs
* data
* fields
* geometry
* topology
* morphology
* physics
* dynamics
* simulations
* agents
* neural systems
* streams
* spatial structures
* rendering pipelines
* transformations
* providers
* runtime state
* hardware capabilities.

---

# Semantic Model

An analysis can be represented conceptually as:

```text id="p7y9n4"
A = (I, Q, D, M, R, C, P, U)
```

where:

* `I` = input semantic object or state
* `Q` = analysis question or property
* `D` = domain of analysis
* `M` = analysis method
* `R` = result
* `C` = confidence, certainty, or approximation characteristics
* `P` = provenance
* `U` = uncertainty and limitations.

Analysis is therefore not merely computation over values.

It is computation whose result describes properties of another computational object, process, state, representation, or possible execution.

---

# Analysis Primacy

Analysis is fundamentally concerned with the question:

> **What can we know about this computation, structure, state, representation, or execution without necessarily performing the complete computation itself?**

Analysis may operate:

```text id="p5q7jz"
Semantic Object
      │
      ▼
    Analysis
      │
      ├── Properties
      ├── Capabilities
      ├── Dependencies
      ├── Constraints
      ├── Costs
      ├── Equivalence
      ├── Risks
      ├── Behaviour
      └── Execution Opportunities
```

The result of analysis is itself semantic information.

---

# Scope

SCR Analysis encompasses, but is not limited to:

* semantic analysis
* structural analysis
* dependency analysis
* dataflow analysis
* control-flow analysis
* state analysis
* type analysis
* capability analysis
* compatibility analysis
* equivalence analysis
* representation analysis
* topology analysis
* geometry analysis
* spatial analysis
* locality analysis
* parallelism analysis
* vectorization analysis
* differentiability analysis
* determinism analysis
* stochasticity analysis
* complexity analysis
* cost analysis
* memory analysis
* resource analysis
* scheduling analysis
* data-dependency analysis
* effect analysis
* side-effect analysis
* alias analysis
* provenance analysis
* temporal analysis
* causal analysis
* stream analysis
* graph analysis
* field analysis
* morphological analysis
* runtime analysis
* profiling
* telemetry analysis
* performance analysis
* numerical analysis
* precision analysis
* stability analysis
* safety analysis
* validation
* verification
* invariant analysis
* constraint analysis
* reachability analysis
* observability analysis
* controllability analysis
* optimization analysis
* provider analysis
* hardware analysis
* execution-plan analysis
* transformation analysis
* compatibility analysis.

---

# 1. Analysis Object

The object of analysis is the semantic structure being examined.

It may be:

* a value
* a type
* an operation
* a function
* a graph
* a hypergraph
* a field
* a geometry
* a topology
* a morphology
* a simulation
* an agent
* a neural network
* a stream
* a transformation
* a complete program
* a runtime state
* a provider
* a hardware target.

The analysis object MUST remain identifiable throughout the analysis lifecycle.

---

# 2. Analysis Question

An analysis MUST have a declared or inferable question, property, predicate, metric, or objective.

Examples include:

```text
Is this operation deterministic?

Can these operations execute in parallel?

What memory does this computation require?

Are these two representations equivalent?

Which provider can execute this operation?

What transformations are valid?

What resources are required?

Which operations depend upon this value?
```

An analysis without a defined semantic question has no well-defined result.

---

# 3. Analysis Domain

Analysis MAY be:

* domain-independent
* domain-specific
* cross-domain
* representation-specific
* execution-specific.

Examples:

```text
Core analysis
Data analysis
Graph analysis
Field analysis
Spatial analysis
Geometry analysis
Topology analysis
Morphology analysis
Physics analysis
Stream analysis
Runtime analysis
Hardware analysis
```

Domain-specific analyses MUST build upon the relevant domain definitions rather than redefine them.

---

# 4. Static Analysis

Static analysis derives properties without requiring complete execution of the analysed computation.

Examples include:

* type analysis
* dependency analysis
* control-flow analysis
* dataflow analysis
* capability analysis
* resource estimation
* alias analysis
* effect analysis
* semantic validation.

Static analysis may provide guarantees over classes of possible executions when its assumptions and approximation model are sufficiently strong.

Static analysis does not necessarily mean compile-time analysis.

It may also be performed:

* during design
* during planning
* during deployment
* during runtime adaptation
* offline
* incrementally.

---

# 5. Dynamic Analysis

Dynamic analysis derives information from actual or observed execution.

Examples include:

* profiling
* telemetry
* tracing
* runtime state observation
* memory monitoring
* performance measurement
* event analysis
* execution sampling
* runtime dependency discovery.

Dynamic analysis MUST remain distinguishable from static analysis.

---

# 6. Hybrid Analysis

Analysis MAY combine static and dynamic information.

For example:

```text id="v6o4zn"
Static Analysis
      │
      ├── predicted cost
      ├── possible dependencies
      └── capability requirements
              │
              ▼
          Execution
              │
              ▼
      Dynamic Observation
              │
              ├── actual cost
              ├── actual locality
              └── actual behaviour
              │
              ▼
        Updated Analysis
```

Hybrid analysis is particularly important for adaptive runtime behaviour.

---

# 7. Abstract Analysis

Analysis may reason over an abstraction rather than the complete concrete state.

Examples include:

* abstract values
* intervals
* symbolic expressions
* type domains
* shape abstractions
* topology abstractions
* graph summaries
* resource bounds.

Abstract analysis MUST declare the relationship between the abstraction and the concrete semantic object.

---

# 8. Approximation

Many analyses necessarily approximate properties of complex systems.

An analysis result MAY be:

* exact
* conservative
* optimistic
* bounded
* probabilistic
* heuristic
* approximate
* incomplete.

The approximation semantics MUST be explicit.

A result that says:

```text
possibly parallel
```

is not semantically equivalent to:

```text
guaranteed parallel
```

---

# 9. Soundness

Where an analysis claims soundness, the claim MUST be defined relative to:

* a semantic model
* an abstraction
* a property
* a set of assumptions.

Soundness MUST NOT be used as an unqualified implementation claim.

---

# 10. Completeness

An analysis MAY be incomplete.

For example, failure to establish a property does not necessarily imply that the property is false.

The result states:

```text
unknown
```

when the analysis cannot establish either:

```text
true
```

or:

```text
false.
```

This distinction is fundamental to analysis semantics.

---

# 11. Confidence and Certainty

Analysis results MAY contain confidence or certainty information.

However:

> Confidence is not automatically probability.

An analysis result MUST identify the semantics of any confidence measure it provides.

---

# 12. Properties

Analysis may derive properties such as:

* deterministic
* stochastic
* differentiable
* parallelizable
* vectorizable
* tileable
* stateful
* stateless
* streamable
* spatial
* temporal
* composable
* distributable
* renderable
* controllable
* learnable
* optimizable.

These properties may map to SCR Interfaces and Capabilities.

---

# 13. Capability Analysis

Capability analysis determines whether a computational entity can satisfy a declared capability requirement.

Conceptually:

```text id="y0jzq2"
Operation Requirements
        │
        ▼
 Capability Analysis
        │
        ├── CPU
        ├── GPU
        ├── Provider A
        ├── Provider B
        └── Distributed Runtime
```

Capability analysis MUST distinguish:

* required capability
* available capability
* preferred capability
* unsupported capability
* conditionally supported capability.

---

# 14. Compatibility Analysis

Compatibility analysis determines whether two or more semantic entities can interact, compose, transform, or substitute for one another.

Compatibility MAY concern:

* types
* units
* shapes
* dimensions
* coordinate systems
* topology
* semantics
* capabilities
* interfaces
* representations
* providers
* hardware.

Compatibility does not imply equivalence.

Two entities may be compatible while remaining semantically distinct.

---

# 15. Equivalence Analysis

Equivalence analysis determines whether two computational structures satisfy an explicitly declared equivalence relation.

Possible equivalence classes include:

* semantic equivalence
* observational equivalence
* numerical equivalence
* structural equivalence
* representation equivalence
* behavioural equivalence
* temporal equivalence
* spatial equivalence.

Implementation similarity is insufficient to establish equivalence.

---

# 16. Dependency Analysis

Dependency analysis identifies relationships upon which an operation, object, state, or result depends.

Dependencies may be:

* data dependencies
* control dependencies
* semantic dependencies
* temporal dependencies
* causal dependencies
* resource dependencies
* provider dependencies
* spatial dependencies.

Dependency relationships SHOULD be representable in the Semantic Hypergraph.

---

# 17. Dataflow Analysis

Dataflow analysis determines how information moves through computational structures.

Examples include:

```text id="d8c8gk"
Input
  │
  ▼
Operation A
  │
  ├──────► Operation B
  │
  ▼
Operation C
  │
  ▼
Output
```

Dataflow analysis may identify:

* producers
* consumers
* dependencies
* live values
* transformations
* bottlenecks
* parallelism.

---

# 18. Control-Flow Analysis

Control-flow analysis determines possible execution paths through computational structures.

It may identify:

* branches
* loops
* conditions
* merges
* unreachable paths
* cycles
* execution regions.

Control-flow analysis MUST remain distinguishable from semantic dataflow.

---

# 19. State Analysis

State analysis determines:

* mutable state
* immutable state
* state dependencies
* state transitions
* lifecycle
* persistence requirements
* synchronization requirements.

State analysis composes with Core State, Dynamics, Simulation, Agents, Streams, and Runtime semantics.

---

# 20. Effect Analysis

Effect analysis identifies effects produced by operations.

Effects may include:

* state mutation
* I/O
* communication
* allocation
* synchronization
* randomness
* external interaction
* rendering
* resource consumption.

Effect information may constrain:

* parallelization
* reordering
* caching
* memoization
* transformation
* distribution.

---

# 21. Determinism Analysis

Determinism analysis determines whether an operation or computation has deterministic semantic behaviour under declared conditions.

Possible sources of nondeterminism include:

* randomness
* concurrency
* race conditions
* unordered reductions
* external state
* timing
* distributed execution
* hardware variation.

Determinism analysis MUST distinguish semantic nondeterminism from incidental implementation nondeterminism.

---

# 22. Parallelism Analysis

Parallelism analysis identifies computations that may safely execute concurrently.

Analysis may consider:

* data dependencies
* control dependencies
* effects
* state
* synchronization
* resource constraints
* reduction semantics.

A computation being syntactically independent does not necessarily establish semantic parallelizability.

---

# 23. Vectorization Analysis

Vectorization analysis determines whether computations may be transformed into vector or SIMD-style execution while preserving semantics.

It may consider:

* data independence
* operation compatibility
* memory access
* reductions
* dependencies
* numerical semantics.

---

# 24. Locality Analysis

Locality analysis determines the degree and structure of spatial, temporal, graph, memory, or computational locality.

Examples include:

* spatial locality
* temporal locality
* graph locality
* field locality
* cache locality
* communication locality.

Locality analysis is particularly important for:

* tiling
* partitioning
* distributed execution
* spatial computation
* stream processing
* GPU execution.

---

# 25. Complexity Analysis

Complexity analysis estimates computational or resource growth.

Possible measures include:

* time complexity
* space complexity
* communication complexity
* memory complexity
* synchronization complexity
* energy cost
* storage cost.

Complexity results MUST identify their assumptions and asymptotic or measured basis.

---

# 26. Cost Analysis

Cost analysis estimates resource consumption under a declared execution strategy.

Costs may include:

* compute
* memory
* bandwidth
* latency
* storage
* energy
* accelerator occupancy
* network communication
* synchronization.

Cost models MAY be static, dynamic, empirical, symbolic, or learned.

---

# 27. Resource Analysis

Resource analysis determines resource requirements, availability, or constraints.

Resources may include:

* CPU
* GPU
* accelerator
* memory
* storage
* network
* bandwidth
* energy
* runtime capacity.

Resource analysis feeds runtime scheduling and provider selection.

---

# 28. Scheduling Analysis

Scheduling analysis determines feasible or preferred execution arrangements subject to:

* dependencies
* resource constraints
* priorities
* deadlines
* locality
* latency
* throughput
* synchronization.

Scheduling analysis may produce:

```text
Operation
   ↓
Dependency Analysis
   ↓
Resource Analysis
   ↓
Scheduling Analysis
   ↓
Execution Plan
```

---

# 29. Representation Analysis

Representation analysis determines properties of different representations of the same or related semantic objects.

Examples include:

* dense versus sparse
* structured versus unstructured
* explicit versus implicit geometry
* mesh versus field
* graph versus matrix
* exact versus approximate
* compressed versus uncompressed.

Representation analysis MUST preserve the distinction between representation and semantic meaning.

---

# 30. Transformation Analysis

Transformation analysis determines whether a transformation:

* is valid
* preserves semantics
* changes precision
* changes ordering
* changes resource requirements
* changes representation
* changes observable behaviour.

Transformation analysis is therefore fundamental to safe compiler optimization.

---

# 31. Numerical Analysis

Numerical analysis determines properties such as:

* precision
* error
* conditioning
* stability
* convergence
* approximation quality
* numerical sensitivity.

Numerical analysis MUST remain distinguishable from mathematical semantics.

A numerically approximate implementation may still represent an exact mathematical operation, provided its approximation semantics are declared.

---

# 32. Topology Analysis

Topology analysis determines properties such as:

* connectivity
* components
* incidence
* boundaries
* cycles
* genus
* manifoldness
* topology-preserving transformations.

Topology analysis MUST operate according to SCR Topology semantics.

---

# 33. Geometry Analysis

Geometry analysis determines properties such as:

* intersection
* containment
* proximity
* collision
* dimensionality
* shape
* spatial extent
* geometric validity.

Geometry analysis MUST remain distinct from rendering representation.

---

# 34. Graph Analysis

Graph analysis determines properties such as:

* connectivity
* paths
* components
* centrality
* clustering
* communities
* reachability
* cycles
* embeddings
* graph similarity.

Graph analysis MUST support genuine hypergraph semantics where required.

---

# 35. Field Analysis

Field analysis determines properties such as:

* gradients
* divergence
* curl
* extrema
* smoothness
* continuity
* sampling characteristics
* locality
* stability
* temporal evolution.

Field analysis composes with Mathematics, Physics, Dynamics, Spatial, and Simulation.

---

# 36. Morphological Analysis

Morphological analysis determines properties of:

* form
* structure
* organisation
* symmetry
* hierarchy
* segmentation
* differentiation
* pattern
* shape
* growth
* deformation
* structural equivalence.

Morphological analysis MUST preserve the bidirectional relationship between Pattern and Morphology.

---

# 37. Stream Analysis

Stream analysis determines properties of:

* ordering
* temporal behaviour
* causality
* throughput
* latency
* state
* delivery guarantees
* partitioning
* backpressure
* resource consumption.

Stream analysis may operate both statically and dynamically.

---

# 38. Runtime Analysis

Runtime analysis derives knowledge from actual execution.

Examples include:

* profiling
* telemetry
* tracing
* resource measurements
* latency
* throughput
* memory consumption
* scheduling behaviour
* provider performance
* hardware utilisation.

Runtime analysis feeds adaptive execution.

---

# 39. Hardware Analysis

Hardware analysis determines capabilities and characteristics of execution substrates.

Examples include:

* instruction sets
* vector width
* accelerator capabilities
* memory hierarchy
* bandwidth
* cache topology
* core count
* GPU characteristics
* available devices
* supported numerical formats.

Hardware analysis MUST inform execution decisions without becoming semantic authority.

---

# 40. Provider Analysis

Provider analysis determines whether an external implementation can satisfy a semantic operation or contract.

It may consider:

* supported operations
* capabilities
* precision
* determinism
* performance
* resource requirements
* representation support
* hardware compatibility
* semantic guarantees.

---

# 41. Analysis Composition

Analyses may depend upon other analyses.

For example:

```text id="d7u3ba"
Semantic Analysis
      │
      ▼
Dependency Analysis
      │
      ▼
Capability Analysis
      │
      ▼
Resource Analysis
      │
      ▼
Scheduling Analysis
      │
      ▼
Execution Plan
```

Analysis dependencies MUST be explicit.

---

# 42. Analysis Results

An analysis result is itself a semantic object.

It SHOULD contain:

* identity
* analysed object
* analysis type
* result
* assumptions
* confidence
* approximation characteristics
* provenance
* timestamp or validity interval
* analysis method
* version.

Analysis results may themselves be analysed.

---

# 43. Incremental Analysis

Analysis MAY be performed incrementally when only part of the analysed semantic state changes.

For example:

```text
State₀
  │
  ▼
Analysis₀
  │
  ├── semantic delta
  ▼
Incremental Analysis
  │
  ▼
Analysis₁
```

Incremental analysis is especially important for:

* streams
* semantic graphs
* simulations
* fields
* adaptive systems
* interactive runtimes.

---

# 44. Analysis Provenance

Analysis results MUST preserve sufficient provenance to establish:

* what was analysed
* when it was analysed
* how it was analysed
* under which assumptions
* using which semantic definitions
* using which provider or implementation
* using which hardware context where relevant.

---

# 45. Analysis Validity

An analysis result MAY have a limited validity interval.

For example:

```text
Provider Capability
      │
      ▼
Analysis Result
      │
      ▼
Hardware State Changes
      │
      ▼
Result May Become Invalid
```

Runtime systems MUST be able to invalidate or recompute analyses when their assumptions cease to hold.

---

# 46. Analysis and Compilation

Analysis provides information used by compilation.

Typical relationships include:

```text id="7z5t2j"
Semantic Model
      │
      ▼
Analysis
      │
      ├── capabilities
      ├── dependencies
      ├── legality
      ├── costs
      └── opportunities
              │
              ▼
       Transformation
              │
              ▼
             MLIR
```

Compiler architectures commonly use analysis information to guide optimization and transformation.

---

# 47. Analysis and Runtime

Runtime analysis feeds adaptive execution.

```text
Compile-Time Analysis
        │
        ▼
Initial Execution Plan
        │
        ▼
Runtime
        │
        ▼
Dynamic Analysis
        │
        ▼
Updated Knowledge
        │
        ▼
Re-analysis
        │
        ▼
Adaptive Execution
```

This establishes a feedback relationship between analysis and execution.

---

# 48. Analysis and Semantic Hypergraph

Analysis results SHOULD be representable within the Semantic Hypergraph.

For example:

```text id="w5a1l7"
Operation A
    │
    ├── requires ─────► Capability X
    ├── depends-on ───► Data B
    ├── analysed-as ──► Deterministic
    ├── estimated-cost ► C
    └── executable-on ► Provider P
```

Analysis therefore becomes part of the semantic knowledge structure rather than remaining hidden inside compiler implementation.

---

# 49. Analysis and Uncertainty

Analysis results may be uncertain.

Uncertainty may arise from:

* approximation
* incomplete information
* runtime variation
* probabilistic models
* heuristic analysis
* unknown provider behaviour.

Uncertainty MUST remain explicit.

---

# 50. Analysis and Equivalence

Analysis MAY establish or contribute evidence toward semantic equivalence.

However:

> Analysis evidence is not automatically proof of equivalence.

Where formal equivalence is required, the analysis MUST state the level of guarantee established.

---

# 51. Analysis and Security

Analysis MAY identify:

* unsafe operations
* resource risks
* isolation violations
* information flows
* dependency risks
* unexpected effects
* capability escalation.

Security analysis MUST preserve the distinction between:

* detected risk
* proven violation
* unknown condition.

---

# 52. Analysis and Validation

Validation determines whether an implementation or result conforms to declared expectations.

Analysis may provide evidence for validation.

Validation MUST remain distinguishable from analysis itself.

---

# 53. Analysis and Verification

Verification establishes whether declared properties or invariants hold according to a specified formal or executable criterion.

Analysis may support verification.

Analysis MUST NOT automatically be described as verification unless the required guarantee is established.

---

# 54. MLIR Representation

SCR Analysis MAY be represented through MLIR attributes, operations, interfaces, analyses, metadata, and transformation infrastructure.

Analysis information may be attached to semantic operations or represented as separate semantic objects.

MLIR provides compiler infrastructure.

It does not define SCR analysis semantics.

---

# 55. Runtime Semantics

The SCR runtime MAY:

1. identify applicable analyses;
2. determine analysis dependencies;
3. execute static analyses;
4. inspect runtime observations;
5. combine static and dynamic evidence;
6. determine capabilities;
7. estimate resources and costs;
8. evaluate transformations;
9. select execution strategies;
10. invalidate stale analysis results;
11. recompute affected analyses;
12. use results to adapt execution.

Analysis MUST remain semantically traceable.

---

# 56. Performance Semantics

Analysis itself consumes computational resources.

Analysis MAY therefore be:

* eager
* lazy
* cached
* incremental
* approximate
* demand-driven
* speculative.

The runtime MAY trade analysis precision against analysis cost where the semantic contract permits it.

---

# 57. Determinism

Analysis may be deterministic or nondeterministic.

If an analysis is declared deterministic, equivalent inputs and assumptions MUST produce semantically equivalent results.

Dynamic analyses may necessarily depend upon execution conditions.

---

# 58. Representation Independence

Analysis semantics MUST remain independent of:

* compiler implementation
* programming language
* IR representation
* database
* storage mechanism
* runtime
* hardware
* provider.

Different implementations MAY use different algorithms to establish equivalent analysis results.

---

# 59. Provider Independence

Analysis implementations may be supplied by:

* compiler analyses
* MLIR passes
* runtime systems
* external libraries
* hardware introspection
* profilers
* static analyzers
* numerical systems
* graph systems.

Providers MUST NOT become semantic authorities.

---

# 60. Standards and Interoperability

SCR Analysis SHOULD reuse established standards where applicable.

Relevant mechanisms may include:

* URI / IRI
* JSON / JSON-LD
* RDF / RDF-star
* SHACL
* ISO GQL
* established compiler IR metadata
* profiling and tracing standards
* hardware capability descriptions
* established provenance models.

Standards provide interoperability.

SCR remains authoritative over SCR Analysis semantics.

---

# Expected Subdomains

```text id="j2a6fh"
analysis/
├── analysis-core
├── semantic
├── structural
├── type
├── capability
├── compatibility
├── equivalence
├── dependency
├── dataflow
├── control-flow
├── state
├── effect
├── determinism
├── stochasticity
├── parallelism
├── vectorization
├── locality
├── complexity
├── cost
├── resource
├── scheduling
├── representation
├── transformation
├── numerical
├── stability
├── precision
├── topology
├── geometry
├── graph
├── field
├── morphology
├── spatial
├── temporal
├── causal
├── stream
├── runtime
├── profiling
├── telemetry
├── performance
├── hardware
├── provider
├── safety
├── security
├── validation
├── verification
├── provenance
├── uncertainty
├── incremental
└── query
```

---

# Invariants

### ANALYSIS-INV-001 — Semantic Primacy

Analysis semantics are normative and MUST NOT be silently redefined by implementation.

### ANALYSIS-INV-002 — Explicit Question

Every normative analysis MUST have an identifiable property, question, predicate, metric, or objective.

### ANALYSIS-INV-003 — Object Identity

The object being analysed MUST remain identifiable.

### ANALYSIS-INV-004 — Result Identity

Analysis results MUST remain identifiable independently of their implementation.

### ANALYSIS-INV-005 — Approximation Explicitness

Approximate analysis MUST be distinguishable from exact analysis.

### ANALYSIS-INV-006 — Uncertainty Preservation

Analysis uncertainty MUST NOT be silently converted into certainty.

### ANALYSIS-INV-007 — Assumption Explicitness

Material assumptions MUST be identifiable.

### ANALYSIS-INV-008 — Soundness Claims

Soundness claims MUST specify their semantic scope and assumptions.

### ANALYSIS-INV-009 — Unknown State

Analysis MUST be capable of representing an indeterminate result where the available evidence cannot establish the property.

### ANALYSIS-INV-010 — Static/Dynamic Distinction

Static and dynamic evidence MUST remain distinguishable.

### ANALYSIS-INV-011 — Provenance Preservation

Analysis results SHOULD preserve relevant provenance.

### ANALYSIS-INV-012 — Validity

Analysis results MAY expire when their underlying assumptions or environment change.

### ANALYSIS-INV-013 — Incremental Integrity

Incremental analysis MUST preserve equivalence with full analysis where such equivalence is claimed.

### ANALYSIS-INV-014 — Representation Independence

Analysis MUST remain independent of physical representation.

### ANALYSIS-INV-015 — Provider Independence

External analysis implementations MUST NOT become semantic authorities.

### ANALYSIS-INV-016 — Domain Integrity

Domain-specific analysis MUST conform to the semantics of the domain being analysed.

### ANALYSIS-INV-017 — Evidence Distinction

Evidence, inference, guarantee, and observation MUST remain distinguishable.

### ANALYSIS-INV-018 — Semantic Traceability

Analysis results MUST be traceable to the semantic object, definition, assumptions, and analysis method from which they were derived.

---

# Architectural Rules

1. Analysis MUST compose with Core.
2. Analysis MUST be applicable to every SCR semantic domain where meaningful analysis exists.
3. Analysis MUST compose with Data.
4. Analysis MUST compose with Mathematics.
5. Analysis MUST compose with Graphs.
6. Analysis MUST compose with Fields.
7. Analysis MUST compose with Geometry.
8. Analysis MUST compose with Topology.
9. Analysis MUST compose with Morphology.
10. Analysis MUST compose with Physics.
11. Analysis MUST compose with Dynamics.
12. Analysis MUST compose with Simulation.
13. Analysis MUST compose with Agents.
14. Analysis MUST compose with Neural.
15. Analysis MUST compose with Perception.
16. Analysis MUST compose with Control.
17. Analysis MUST compose with Optimization.
18. Analysis MUST compose with Learning.
19. Analysis MUST compose with Adaptation.
20. Analysis MUST compose with Evolution.
21. Analysis MUST compose with Ecology.
22. Analysis MUST compose with Spatial.
23. Analysis MUST compose with Stream.
24. Analysis MUST support static and dynamic forms where applicable.
25. Analysis MUST support uncertainty and approximation semantics.
26. Analysis MUST preserve provenance.
27. Analysis MUST support incremental analysis where practical.
28. Analysis MUST be usable by compilation.
29. Analysis MUST be usable by runtime scheduling.
30. Analysis MUST be usable by provider selection.
31. Analysis MUST be usable by adaptive execution.
32. Analysis MUST remain independent of any particular compiler implementation.
33. Analysis MUST remain independent of any particular hardware substrate.
34. Analysis results SHOULD be representable in the Semantic Hypergraph.
35. Analysis MUST NOT silently change the semantics of the object being analysed.

---

# Completeness Criteria

An implementation of SCR Analysis is semantically complete only when it can represent:

* analysis objects
* analysis questions
* analysis domains
* static analysis
* dynamic analysis
* hybrid analysis
* abstraction
* approximation
* soundness
* completeness
* confidence
* properties
* capabilities
* compatibility
* equivalence
* dependencies
* dataflow
* control flow
* state
* effects
* determinism
* parallelism
* vectorization
* locality
* complexity
* cost
* resource requirements
* scheduling constraints
* representation properties
* transformation legality
* numerical properties
* topology
* geometry
* graph structure
* field properties
* morphology
* spatial structure
* stream properties
* runtime behaviour
* hardware capabilities
* provider capabilities
* validation
* verification
* provenance
* uncertainty
* incremental analysis
* analysis validity.

---

# Testing Requirements

SCR Analysis implementations SHOULD include:

### Specification Tests

Tests validating conformance to this definition.

### Domain Analysis Tests

Tests validating analyses for individual semantic domains.

### Static Analysis Tests

Tests for compile-time and pre-execution reasoning.

### Dynamic Analysis Tests

Tests using actual execution observations.

### Hybrid Analysis Tests

Tests combining static predictions with runtime evidence.

### Equivalence Tests

Tests validating declared equivalence guarantees.

### Capability Tests

Tests validating capability discovery and matching.

### Dependency Tests

Tests validating dependency and dataflow extraction.

### Resource Tests

Tests validating resource and cost estimates.

### Transformation Tests

Tests validating analysis of legal and illegal transformations.

### Incremental Analysis Tests

Tests ensuring incremental analysis remains semantically consistent with full analysis where required.

### Runtime Tests

Tests validating analysis-driven adaptive execution.

### Provider Tests

Tests validating external analysis implementations against SCR Analysis contracts.

---

# Open Semantic Questions

1. What constitutes a minimal universal analysis result in SCR?
2. How should analysis confidence and uncertainty be represented in the Semantic Hypergraph?
3. How should analysis validity intervals be propagated through dependent analyses?
4. How should conflicting analysis results be represented?
5. How should analysis results from different providers be compared?
6. How should analysis provenance interact with semantic versioning?
7. How should analysis results participate in semantic equivalence?
8. How should analysis cost itself participate in runtime scheduling?
9. How should speculative analysis be represented?
10. How should incremental invalidation propagate through the analysis dependency graph?
11. How should dynamic observations update static analysis assumptions?
12. How should formal verification results differ structurally from heuristic analysis results?
13. How should cross-domain analyses combine results from different semantic domains?
14. How should hardware-dependent analyses remain valid across heterogeneous execution?
15. How should analysis results be exposed as capabilities to the compiler and runtime?
16. How should analysis itself be compiled, scheduled, and optimized?

These questions MUST NOT be resolved implicitly by implementation.

---

# Definition History

## 0.1.0

Initial normative semantic definition.

Establishes Analysis as a cross-cutting SCR capability for deriving semantic knowledge about computational objects, states, representations, transformations, resources, execution, and behaviour.

---

# Definition Authority

This document is the normative semantic authority for `SCR-LIB-ANALYSIS`.

Analysis implementations, compiler passes, runtime profilers, hardware introspection systems, external analysis engines, and provider-specific mechanisms MUST conform to this definition rather than redefine it.

---

# Definition Principle

> **Analysis is the semantic process of deriving knowledge about computational structures, states, transformations, resources, capabilities, and behaviour, together with the assumptions, uncertainty, provenance, and guarantees associated with that knowledge.**
