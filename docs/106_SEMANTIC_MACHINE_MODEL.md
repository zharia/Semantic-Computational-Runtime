# Semantic Machine Model (SMM)

**Document ID:** `SCR-DOC-SMM-106`
**Status:** Normative architectural specification
**Version:** 0.2.0
**Scope:** SCR architecture
**Authority:** Project architecture; this document does not replace domain-level specifications.

---

## 1. Purpose

The Semantic Machine Model (SMM) defines the implementation-independent computational machine induced by a computational Semantic Field.

The SMM establishes a precise boundary between:

1. what a computation means;
2. what semantic transformations are lawful;
3. what semantic state exists;
4. the contexts in which that state is interpreted;
5. what outcomes are semantically permitted;
6. what an implementation must preserve;
7. how computation may be organised into computational spaces;
8. how spatial locality and state residency participate in computation; and
9. how those semantics may be physically realised.

The SMM is therefore an **abstract machine specification**, not a runtime component architecture.

The central architectural law is:

$$
\boxed{\text{Machine Semantics} \neq \text{Machine Implementation}}
$$

and:

$$
\boxed{\text{Implementation} \models \text{Machine Semantics}}
$$

---

# 2. Semantic Machine

> **The Semantic Machine is the implementation-independent abstract computational system induced by a computational Semantic Field. It defines the semantically observable state of the field, the contexts in which that state is interpreted, the lawful transformations applicable to that state, the constraints governing their admissibility, the outcomes permitted by their realization, the relationships governing their composition and flow, and the equivalence relations by which alternative realizations are determined to preserve semantic meaning.**

The Semantic Machine does **not** prescribe:

* physical representation;
* processor architecture;
* memory organization;
* instruction encoding;
* scheduling mechanism;
* storage mechanism;
* communication mechanism;
* execution strategy;
* provider;
* deployment environment;
* operating system;
* container runtime;
* device;
* network topology;
* physical resource allocation.

It may, however, express semantic requirements concerning:

* computational locality;
* spatial association;
* state residency;
* execution capability;
* resource constraints;
* persistence;
* migration;
* replication;
* temporal behaviour;
* causal relationships.

These are semantic requirements only where they are part of the Semantic Field's meaning.

---

# 3. Semantic Machine Model

> **The Semantic Machine Model is the formal specification of the Semantic Machine and its conformance boundary.**

The historical minimal kernel was:

$$
SMM_0=
\langle
\mathcal S,
\mathcal C,
\mathcal T,
\mathcal K,
\mathcal O,
\equiv
\rangle
$$

where:

* \(\mathcal S\) — semantic states;
* \(\mathcal C\) — semantic contexts;
* \(\mathcal T\) — semantic transformations;
* \(\mathcal K\) — semantic constraints;
* \(\mathcal O\) — semantic outcomes;
* \(\equiv\) — semantic equivalence.

This tuple remains useful as the historical kernel hypothesis.

However, STC formalisation demonstrated that it is insufficient as the complete carrier for composition and independence.

The adopted machine kernel is therefore the typed graph carrier defined by the post-STC-002 model.

---

# 4. Adopted Machine Kernel

The Semantic Machine is now modelled over a typed graph carrier.

Conceptually:

```text
GMKernel

  domains
    T  transformations
    S  states
    C  interpretation contexts
    K  constraint environments

  admissibility
    Applicable(T,S,C)
    Consents(T,S,C,K)

  carrier
    Out  : T → Type
    edge : ∀ τ, K → S → C → Out τ → Prop

  well-formedness
    edge ⇒ admissible

  equivalence
    context-indexed consE
    setoid
    value congruence
    successor congruence

  composition
    relational successor composition

  order / flow
    causal dependence
    conflict
    footprint / interference

  observation
    derived from edges and equivalence

  provenance
    derived from labelled paths
```

The graph carrier is the authoritative computational carrier.

The historical set-valued outcome model remains retained only for compatibility and historical formalisation.

`OutcomeOf` and `ResultState` are **deprecated for new development**.

---

# 5. Semantic Field Primacy

SCR's Semantic Field remains architecturally prior.

A Semantic Field describes meaningful semantic structure.

A **computational Semantic Field** is one for which lawful transformation semantics are defined.

A useful criterion is:

$$
ComputationalField(F)
\iff
F\text{ admits defined transformation semantics}
$$

The SMM is therefore derived from the field:

$$
\boxed{
SMM(F)=FormalComputationalSemantics(F)
}
$$

The SMM is not:

$$
SMM=F+Runtime
$$

and not:

$$
SMM=RuntimeArchitecture
$$

The runtime is a realisation of semantics that are already defined.

---

# 6. Semantic State

A semantic state is the portion of Semantic Field state relevant to computational interpretation at a particular semantic context.

The SMM does not require semantic state to correspond to:

* a memory object;
* a process;
* a database row;
* a file;
* an MLIR SSA value;
* a CPU register;
* a GPU buffer;
* a network message;
* a container;
* a Kubernetes object.

An implementation state may contain substantially more information:

$$
IState \supseteq S
$$

where implementation state may contain:

* caches;
* scheduling metadata;
* indexes;
* allocation state;
* device state;
* synchronization state;
* compiled code;
* provider metadata;
* transport state;
* partition metadata.

A semantic projection may therefore be defined:

$$
\pi:IState\rightarrow S
$$

Correctness requires preservation of the relevant semantic state:

$$
\pi(IState_{t+1})\equiv_C S_{t+1}
$$

where equivalence is evaluated under the applicable semantic context.

---

# 7. Semantic Context

Context determines how semantic state and transformations are interpreted.

Context is not equivalent to:

* a process;
* a thread;
* a runtime object;
* a namespace implementation;
* a CPU execution context;
* a container;
* a Kubernetes context.

A context may contain:

* semantic conditions;
* references;
* temporal interpretation;
* spatial interpretation;
* authority;
* capabilities;
* environmental assumptions;
* computational locality;
* state residency;
* resource requirements;
* other information required by a transformation.

Existing Core `Context` remains the semantic authority for context.

SMM MUST reuse that definition rather than introduce a parallel context ontology.

---

# 8. Computational Context

A computational context is a semantic context in which a transformation may be interpreted and realised.

A computational context MAY identify:

```text
Semantic Field
    ↓
Computational Space
    ↓
Semantic State
    ↓
Applicable Transformations
```

A computational context MAY therefore include:

* the computational space in which a transformation is interpreted;
* the spatial region to which it applies;
* the partition locality associated with that region;
* state residency;
* available semantic capabilities;
* authority;
* temporal conditions;
* constraints.

The existence of these attributes does not make them SMM kernel primitives.

They remain context properties.

---

# 9. Computational Space

A **Computational Space** is a semantic space within which computational state, transformations, and relationships may be interpreted.

A computational space is not necessarily:

* a CPU;
* a process;
* a VM;
* a container;
* a Kubernetes node;
* a memory region;
* a network endpoint.

Those may be physical realisations of a computational space.

A computational space MAY be realised by:

```text
process
thread group
VM
container
runtime
node
device
GPU
cluster
distributed namespace
persistent storage space
network-attached computational environment
```

The semantic space remains distinct from its physical manifestation.

---

# 10. Computational Space Identity

A computational space MAY have a semantic identity.

That identity is distinct from:

* machine hostname;
* IP address;
* process ID;
* container ID;
* Kubernetes UID;
* device address;
* memory address.

A computational space may therefore migrate or be re-realised without necessarily changing its semantic identity.

Where semantic identity is intentionally transferred, the operation MUST be explicit.

---

# 11. Computational Space Hierarchy

Computational spaces MAY be hierarchical.

Conceptually:

```text
Semantic Machine
    │
    ├── computational space
    │       │
    │       ├── child space
    │       │      │
    │       │      └── computational field
    │       │
    │       └── sibling space
    │
    └── storage space
```

A space may contain:

* semantic state;
* executable hypergraphs;
* child spaces;
* partitions;
* resources;
* references;
* computational fields.

Containment is semantic.

Physical nesting is only one possible realisation.

---

# 12. Space and Field

A computational space provides a semantic locality in which a computational field may exist.

A field is not necessarily equivalent to a space.

Likewise:

$$
\boxed{
Field \neq Space
}
$$

A space may contain multiple fields.

A field may be associated with multiple spaces.

The relationship MUST be explicit.

---

# 13. Storage as a Space

Storage MAY be represented as a semantic space.

This permits:

```text
Computational Space
Storage Space
Execution Space
Communication Space
Spatial State Space
```

to participate in the same general semantic model while retaining their domain-specific semantics.

A storage space answers:

> Where can state be retained or recovered?

It does not necessarily answer:

> Where is computation executed?

Therefore:

$$
StorageSpace \neq ExecutionSpace
$$

unless explicitly declared equivalent by the semantic model.

---

# 14. Process as a Semantic Object

A process MAY be represented as a semantic object associated with:

* a computational space;
* an executable hypergraph;
* semantic state;
* capabilities;
* resources;
* spatial locality.

A process is therefore a possible semantic manifestation of computation, not the fundamental definition of computation.

The Semantic Machine remains valid without requiring process semantics.

---

# 15. Transformation

A semantic transformation is a lawful semantic change applicable to a state under a context.

A transformation is not identified with:

* a function pointer;
* a Mojo function;
* an MLIR operation;
* a CPU instruction;
* a provider call;
* a system call;
* a message;
* a database transaction;
* a process;
* a kernel launch.

The distinction is:

$$
\boxed{
SemanticTransformation\neq PhysicalInstruction
}
$$

and:

$$
\boxed{
Representation(\tau)\neq Realization(\tau)
}
$$

One semantic transformation may be realised by:

* zero physical instructions;
* one machine instruction;
* many machine instructions;
* a GPU kernel;
* distributed execution;
* interpretation;
* JIT compilation;
* AOT compilation;
* a remote provider;
* multiple providers.

All are valid if they preserve the required semantics.

---

# 16. Constraints

Constraints determine admissibility.

Let:

$$
Applicable(\tau,S,C)
$$

mean that transformation \(\tau\) is meaningful for state \(S\) in context \(C\).

Let:

$$
Admissible(\tau,S,C,K)
$$

mean that the transformation satisfies the applicable semantic constraints.

Then:

$$
Admissible(\tau,S,C,K)
\Rightarrow
Applicable(\tau,S,C)
$$

Applicability and admissibility are semantic properties.

Physical capability is not.

---

# 17. Semantic Transition

A semantic transition is an instantiated application of a transformation to semantic state under a context and constraint environment.

Conceptually:

$$
\delta =
Instantiate(\tau,S,C,K)
$$

provided:

$$
Applicable(\tau,S,C)
\land
Admissible(\tau,S,C,K)
$$

The Semantic Transition Calculus is specified separately in:

`docs/107_SEMANTIC_TRANSITION_CALCULUS.md`

The SMM MUST NOT duplicate the STC formalism.

---

# 18. Typed Consequences

The adopted graph carrier associates transformations with typed consequences.

Conceptually:

$$
Out:T\rightarrow Type
$$

and:

$$
edge:
\forall \tau,K,S,C,o:
Out(\tau)
\rightarrow Prop
$$

A semantic transition therefore does not require a universal undifferentiated `Outcome` type.

The consequence type is determined by the transformation.

This permits transformations whose consequences are:

* state changes;
* values;
* references;
* structural changes;
* relation changes;
* creation;
* deletion;
* migration;
* failure;
* domain-specific semantic objects.

---

# 19. Well-Formedness

A transition edge is well formed only if the associated transformation is admissible.

Conceptually:

$$
edge(\tau,K,S,C,o)
\Rightarrow
Admissible(\tau,S,C,K)
$$

This makes invalid semantic transitions structurally distinguishable from valid transitions.

---

# 20. Composition

Semantic transformations compose relationally through their successors.

Composition is not a physical instruction sequence.

Conceptually:

```text
τ1
 │
 ↓
S1
 │
 ↓
τ2
 │
 ↓
S2
```

Composition therefore follows semantic successor relationships.

Associativity is structural in the graph carrier rather than being introduced as an independent machine law.

---

# 21. Independence

Semantic independence is not physical parallelism.

Two transformations may be independent when their semantic footprints do not conflict.

Conceptually:

$$
\delta_1\perp\delta_2
$$

may be established from footprint and interference information.

Independence MUST NOT be inferred merely because two transformations happen to execute on different processors.

---

# 22. Footprint

A transformation MAY declare a semantic footprint.

A footprint identifies the semantic state or relations potentially affected by a transformation.

Conceptually:

```text
Transformation
     │
     └── Footprint
            ├── reads
            ├── writes
            ├── creates
            ├── deletes
            └── conflicts
```

Footprint is semantic metadata.

It is not a memory access trace.

---

# 23. Causal Flow

Causal dependence is derived from semantic relationships.

The adopted model treats causal dependence as arising from:

* enablement;
* conflict;
* data-flow relationships.

A physical execution order is not automatically a semantic causal relationship.

---

# 24. Concurrency

Semantic concurrency is distinct from physical parallelism.

$$
\boxed{
SemanticConcurrency\neq PhysicalParallelism
}
$$

Two semantically independent transitions may be:

* executed concurrently;
* executed sequentially;
* executed speculatively;
* distributed across machines;
* fused into one physical operation.

Any of these may be correct if observations remain equivalent.

---

# 25. Ordering

Semantic ordering is distinct from physical scheduling.

$$
\boxed{
SemanticOrdering\neq PhysicalScheduling
}
$$

Physical execution order only becomes semantically relevant when the semantic contract makes ordering observable.

---

# 26. Atomicity

Atomicity is a property or constraint of a semantic transition.

A transition may require that no externally observable intermediate semantic state exist.

The implementation may realise atomicity through:

* locks;
* transactional memory;
* copy-on-write;
* versioning;
* compare-and-swap;
* message ordering;
* database transactions;
* single-threaded execution;
* graph replacement;
* other mechanisms.

No physical mechanism is normative at the SMM level.

---

# 27. Temporal Semantics

Temporal and causal ordering are semantic relations.

Physical:

* timestamps;
* wall-clock time;
* CPU cycles;
* event-loop ticks;
* network latency;
* scheduler order;

are implementation mechanisms unless explicitly elevated into field semantics.

The SMM distinguishes:

* semantic time;
* duration;
* deadline;
* temporal precedence;
* causal precedence;
* physical execution time.

Where timing is itself semantic, it becomes part of the observation and equivalence contract.

---

# 28. Spatial Semantics

Spatial semantics are part of the computational context when a Semantic Field has spatial structure.

The SMM MUST NOT define the spatial ontology itself.

Spatial semantics are defined by:

* `docs/114_SPATIAL_SEMANTICS.md`;
* `docs/115_SPATIAL_PARTITIONING_MODEL.md`;
* `docs/116_SPATIAL_STATE_MODEL.md`;
* `lib/spatial/101_spec.md`.

The SMM consumes those semantics.

---

# 29. Spatial Context

A spatial computational context MAY contain:

```text
Spatial Space
Reference Frame
Location
Region
Spatial State Association
Partition Association
Locality Requirements
```

These attributes determine where a transformation is semantically applicable.

For example:

$$
Applicable(\tau,S,C)
$$

may depend upon whether \(S\) is associated with the spatial domain represented by \(C\).

Spatial interpretation therefore belongs to context rather than becoming a new universal SMM primitive.

---

# 30. Spatial Partition

A spatial partition identifies computational locality.

The distinction is:

$$
\boxed{
Coordinate\neq Partition
}
$$

and:

$$
\boxed{
Partition\neq State
}
$$

A partition may determine:

* computational locality;
* state locality;
* routing locality;
* scheduling affinity;
* resource affinity;
* failure domain.

A partition does not define the spatial coordinate system.

---

# 31. Partition Residency

A semantic state may be associated with one or more partitions.

Conceptually:

$$
Residency(S,P)
$$

means that a representation of state \(S\) is resident within partition \(P\).

Residency is not identity.

A state may be:

* resident in one partition;
* replicated across multiple partitions;
* temporarily cached;
* unmaterialised;
* migrated.

---

# 32. Computational Locality

Computational locality describes semantic affinity between computational activity and spatial/state structure.

Locality MAY be based on:

* spatial proximity;
* state dependency;
* partition adjacency;
* communication cost;
* data movement;
* execution affinity.

Locality is an optimisation and semantic constraint only where explicitly declared.

The runtime MUST NOT infer semantic meaning from physical proximity.

---

# 33. State Residency

The SMM distinguishes semantic state from its physical residency.

$$
\boxed{
State \neq Residency
}
$$

A semantic state may have representations resident in:

* CPU memory;
* GPU memory;
* persistent storage;
* remote memory;
* distributed storage;
* provider-managed storage;
* cache.

The spatial state model defines the semantics of these relationships.

---

# 34. State Migration

Migration may occur at several levels:

1. state representation migration;
2. partition residency migration;
3. computational-space migration;
4. execution migration;
5. semantic spatial relocation.

These are not equivalent.

In particular:

$$
\boxed{
PhysicalMovement\neq SpatialMovement
}
$$

and:

$$
\boxed{
SpatialMovement\neq StateIdentityChange
}
$$

Migration MUST preserve semantic identity unless the operation explicitly defines identity transformation.

---

# 35. Space Migration

A computational space MAY be re-realised elsewhere.

For example:

```text
Semantic Space S1
       │
       ↓
physical node A
       │
       ↓
migration
       │
       ↓
physical node B
```

The semantic computational space remains `S1` if migration preserves its semantic identity.

Physical movement therefore does not require semantic identity change.

---

# 36. State Migration vs Space Migration

State and computational spaces MAY migrate independently.

For example:

```text
Space S1
    │
    ├── State A
    ├── State B
    └── State C
```

may become:

```text
Space S1
    │
    ├── State A
    └── State C

Space S2
    │
    └── State B
```

without requiring that `S1` itself move.

Likewise, a whole computational space may migrate while retaining state residency relationships.

These operations MUST remain semantically distinct.

---

# 37. Storage and Persistence

Persistence is a semantic capability.

A storage provider is one possible realisation.

Persistence may be expressed conceptually as:

$$
Persist(S_t)\rightarrow R
$$

and recovery as:

$$
Restore(R)\rightarrow S'
$$

with:

$$
S'\equiv_C S_t
$$

subject to the declared persistence contract.

Storage implementation is not part of the SMM kernel.

---

# 38. Replication

Replication is a semantic capability with an explicit equivalence and divergence model.

Replication MUST define:

* identity relationship;
* version;
* authority;
* consistency;
* divergence;
* conflict handling.

Replication MUST NOT be assumed to mean bitwise duplication.

---

# 39. Representation

Representation is a physical or logical encoding of semantic structure.

Examples include:

* executable hypergraph;
* MLIR;
* tensor;
* sparse volume;
* mesh;
* bytecode;
* machine code;
* database representation;
* provider object.

Representation is not meaning.

$$
\boxed{
Representation\neq Semantics
}
$$

---

# 40. Executable Semantic Hypergraph

An executable semantic hypergraph is a semantic representation of executable structure.

It may express:

* entities;
* transformations;
* dependencies;
* constraints;
* relationships;
* observations;
* execution requirements;
* spatial associations;
* partition associations;
* state references.

It is not the Semantic Machine itself.

It is one representation of executable semantic structure.

---

# 41. Provider Firewall

The executable hypergraph MUST NOT directly select a physical provider.

$$
\boxed{
ExecutableHypergraph
\not\rightarrow
PhysicalProvider
}
$$

An executable hypergraph may express a required capability.

Provider selection belongs to realization infrastructure such as:

* compilation;
* EGS;
* capability resolution;
* resource management.

Replacing a provider with another provider satisfying the same semantic contract MUST NOT require modification of the semantic hypergraph.

---

# 42. Capabilities

A capability expresses what a realization can provide.

Conceptually:

$$
Provider\models Capability
$$

not:

$$
Capability=Provider
$$

Capabilities may include:

```text
compute
storage
spatial_partition
spatial_state
spatial_transform
render
stream
tensor
graph
topology
communication
```

Capability semantics are defined by the relevant domain.

---

# 43. Providers

A provider realises a declared semantic capability.

Provider identity MUST remain distinct from capability identity.

For example:

```text
SpatialStateCapability
       │
       ├── OpenVDB
       ├── tensor provider
       └── custom sparse provider
```

Likewise:

```text
SpatialPartitionCapability
       │
       ├── H3
       └── alternative partition provider
```

The provider is replaceable where semantic contracts remain equivalent.

---

# 44. H3 as a Provider

H3 may provide spatial partitioning capabilities.

H3 may supply:

* hierarchical partitioning;
* partition identity;
* neighbour relationships;
* parent/child hierarchy;
* locality;
* routing keys.

H3 does not define:

* SCR's universal coordinate system;
* SCR spatial state;
* SCR computational space;
* SCR Semantic Machine.

An H3 cell is therefore a possible partition representation.

$$
H3Cell \rightarrow SpatialPartition
$$

not:

$$
H3Cell = SCRCoordinate
$$

---

# 45. OpenVDB as a Provider

OpenVDB may provide sparse spatial state representation.

It may supply:

* sparse volumetric state;
* hierarchical representation;
* voxel access;
* provider-local topology;
* transforms;
* materialisation.

OpenVDB's native index space is provider-local.

Therefore:

$$
OpenVDBIndex\neq SCRCoordinate
$$

unless an explicit semantic transformation establishes the relationship.

---

# 46. H3 and OpenVDB

H3 and OpenVDB may be used together.

A conforming architecture may therefore express:

```text
                    Semantic Machine
                           │
                    Spatial Context
                           │
             ┌─────────────┴─────────────┐
             │                           │
        Partition                   State
             │                           │
            H3                       OpenVDB
             │                           │
      computational              sparse state
        locality                  representation
```

This is a provider composition.

It is not a merger of their ontologies.

---

# 47. Observation

Observation defines what semantic behaviour is exposed to an observer.

A physical implementation may differ internally while remaining correct if:

$$
Obs(I_1)\equiv_C Obs(I_2)
$$

for the observations required by the semantic contract.

Observation is therefore the principal boundary for determining implementation equivalence.

Internal differences do not constitute semantic differences unless they are observable under the applicable contract.

---

# 48. Semantic Equivalence

Semantic equivalence establishes whether states, transformations, outcomes, representations, or realizations preserve the same required meaning.

Equivalence is contextual:

$$
x\equiv_C y
$$

rather than necessarily universal bitwise equality.

This permits:

* representation equivalence;
* state equivalence;
* observational equivalence;
* transition equivalence;
* implementation equivalence;
* spatial representation equivalence;
* provider equivalence.

Provider equivalence MUST be judged by semantic behaviour, not internal representation.

---

# 49. Reference Executor

The Reference Executor is a canonical executable realization of the semantic model.

It is not:

* the Semantic Machine;
* the SMM;
* the only legal implementation;
* the physical runtime architecture;
* a spatial provider;
* EGS.

Let:

$$
RE(\delta)=O_R
$$

and another implementation produce:

$$
I(\delta)=O_I
$$

Correctness requires:

$$
O_I\equiv_{sem}O_R
$$

subject to the same semantic contract.

The Reference Executor is therefore an executable oracle and witness for semantics.

---

# 50. EGS

The canonical operational component is:

> **SCR Executable Graph Server (EGS): the operational execution environment that hosts executable semantic hypergraphs, establishes execution contexts, resolves semantic capabilities, and provides the physical mechanisms through which graph execution occurs.**

EGS is not the Semantic Machine.

The distinction is:

$$
\boxed{
EGS=ExecutionEnvironment(SMM)
}
$$

EGS performs realization work.

It MUST NOT redefine semantic meaning.

EGS MAY resolve:

* computational spaces;
* partitions;
* providers;
* state residency;
* execution resources;
* transport;
* storage;
* capability implementations.

These are realization responsibilities, not semantic ontology.

---

# 51. Manifestation

"Manifestation" is an architectural process, not a subsystem name.

$$
\boxed{
PhysicalExecution=Manifestation(SemanticTransition)
}
$$

The governing firewall is:

$$
\boxed{
Manifestation\not\rightarrow Meaning
}
$$

Physical realization may change while semantic meaning remains invariant.

---

# 52. Resources

Physical resources are realization concepts.

A resource MAY include:

* processor;
* GPU;
* memory;
* storage;
* network;
* accelerator;
* node;
* device.

A semantic machine may express resource requirements or capabilities without making any physical resource a machine primitive.

---

# 53. Processor

A processor is a physical resource through which semantic transformations may be realised.

A processor does not define:

* semantic state;
* transformation meaning;
* semantic concurrency;
* spatial locality.

---

# 54. Scheduler

A scheduler is a physical mechanism that realises:

* semantic ordering;
* concurrency;
* resource allocation;
* locality optimisation;
* execution placement.

Scheduling is not itself semantic unless explicitly represented in the Semantic Field.

---

# 55. Communication

Communication is a physical mechanism through which semantic relationships may be realised.

Examples include:

* messages;
* shared memory;
* RPC;
* AMQP;
* RDMA;
* GPU interconnects.

Transport choice is not semantic unless the transport itself forms part of the Semantic Field.

---

# 56. HyrxMQ and State Movement

A transport provider such as HyrxMQ may realise state movement or communication between computational spaces.

The semantic layer may express:

```text
State Reference
Partition
Destination
Version
Capability
```

while the transport determines how the data or reference physically moves.

The semantic state MUST NOT depend upon the transport protocol.

---

# 57. Semantic Machine and Network Topology

Physical network topology may influence:

* latency;
* bandwidth;
* placement;
* partition affinity;
* state migration cost.

It MUST NOT automatically define semantic topology.

A semantic locality relation may be realised through a physical network topology, but:

$$
PhysicalTopology\neq SemanticTopology
$$

unless explicitly declared.

---

# 58. Spatial Partitioning and Resource Placement

A spatial partition MAY map to a resource.

Conceptually:

$$
M:\Pi\rightarrow R
$$

where:

* \(\Pi\) = semantic spatial partitions;
* \(R\) = physical resources.

This mapping is a realization relation.

Changing the resource mapping MUST NOT necessarily change partition identity.

For example:

```text
Partition P7
    ↓
GPU 0
```

may become:

```text
Partition P7
    ↓
GPU 3
```

without changing `P7`.

---

# 59. State Locality and Resource Placement

The runtime MAY place computation near state.

For example:

```text
Spatial State
      ↓
Partition
      ↓
Resource Affinity
      ↓
Execution
```

This is a performance optimisation unless locality is itself semantic.

The runtime SHOULD prefer movement of computation toward data when that reduces total realization cost, subject to semantic constraints.

---

# 60. Cost Model

A realization MAY optimise:

$$
Cost =
C_{compute}
+
C_{movement}
+
C_{communication}
+
C_{memory}
+
C_{synchronisation}
$$

Additional terms MAY include:

* power;
* latency;
* availability;
* reliability;
* provider cost;
* failure risk.

The cost model is not part of semantic meaning unless explicitly made observable.

---

# 61. Spatial State and Execution

A spatial state may be:

* read by computation;
* modified by computation;
* generated by computation;
* replicated;
* migrated;
* materialised;
* dematerialised.

The execution resource remains distinct from state identity.

Conceptually:

```text
Spatial State
      ↓
Transformation
      ↓
Execution Resource
      ↓
New Semantic State
```

---

# 62. Semantic Machine and Identity

Semantic identity MUST remain independent of:

* physical address;
* process ID;
* machine ID;
* provider object ID;
* memory location;
* network location;
* execution resource.

This is particularly important for migration and distributed execution.

An object may change physical location while retaining semantic identity.

---

# 63. Identity and Location

Identity and location are independent dimensions.

$$
\boxed{
Identity\neq Location
}
$$

A state may move.

A process may move.

A computational space may move.

A representation may move.

None necessarily implies identity change.

Identity change must be explicit.

---

# 64. Semantic Machine and Address Space

An address is meaningful only relative to an addressing domain.

The SMM therefore distinguishes:

```text
Semantic Identity
Semantic Address
Spatial Address
Partition Address
Provider Address
Physical Address
```

These MUST NOT be silently substituted for one another.

A provider address may be used to resolve a semantic object, but it is not necessarily that object's identity.

---

# 65. Space, Address, and Identity

Conceptually:

```text
Identity
   │
   ├── may be resolved through
   ↓
Semantic Address
   │
   ├── interpreted within
   ↓
Semantic Space
   │
   ├── mapped to
   ↓
Provider Address
   │
   └── realised as
   ↓
Physical Location
```

Each mapping is explicit.

---

# 66. Containers

A container MAY be interpreted as a realisation of a computational space.

It MAY provide:

* namespace isolation;
* resource boundaries;
* filesystem space;
* process space;
* network space.

However:

$$
Container\neq SemanticSpace
$$

unless the semantic contract explicitly establishes that relationship.

The SMM therefore does not require containers.

---

# 67. Virtual Machines

A VM MAY realise a computational space.

The VM may provide:

* ISA;
* memory;
* storage;
* network;
* device abstraction.

These are physical or virtual realisations.

The Semantic Machine remains independent of the VM implementation.

---

# 68. RISC-V, JVM, CLR, Node

Systems such as:

* RISC-V;
* JVM;
* .NET CLR;
* Node.js;

are useful comparison points because they demonstrate different ways of defining execution environments.

They are not architectural templates for SCR.

SCR differs in that executable semantic structure is not required to collapse into a linear instruction stream or conventional process model.

An SCR implementation may use:

* graph execution;
* interpretation;
* compilation;
* JIT;
* AOT;
* heterogeneous execution;
* distributed execution.

---

# 69. ISA

"Semantic ISA" is not a machine ontology.

An ISA is one possible representation of a machine's transformations:

$$
SemanticISA\subseteq Representation(SM)
$$

It is not:

$$
SM=SemanticISA
$$

SCR may use graph-native executable representations without requiring a linear instruction stream.

---

# 70. Semantic Machine and Hypergraph

The executable semantic hypergraph is the natural representation of executable relationships.

It may encode:

```text
entities
states
transformations
dependencies
constraints
footprints
spatial associations
partition associations
capabilities
references
observations
```

The hypergraph is therefore richer than a conventional instruction stream.

It remains a representation of the Semantic Machine rather than the machine itself.

---

# 71. Semantic Machine and MLIR

MLIR is a representation and lowering framework.

It is not the SCR Semantic Machine.

MLIR may represent:

* semantic structures;
* executable graph fragments;
* transformations;
* provider implementations;
* lowering stages.

The semantic meaning originates in SCR's semantic model.

Therefore:

$$
MLIR\neq SCRSemantics
$$

---

# 72. Semantic Machine and Mojo

Mojo is an implementation language.

It may implement:

* Reference Executor;
* EGS components;
* provider adapters;
* semantic libraries;
* execution infrastructure.

Mojo does not define SCR semantics.

$$
Mojo\neq SCRSemantics
$$

---

# 73. Implementation State

An implementation may maintain arbitrary hidden state:

$$
IState=S\cup H
$$

where \(H\) contains realization information.

Examples include:

* caches;
* compiled kernels;
* scheduler queues;
* memory allocators;
* GPU handles;
* network connections;
* provider handles;
* partition indexes;
* spatial indexes;
* state caches.

Hidden state is permissible provided it does not violate semantic observation.

---

# 74. Implementation Independence

An implementation is correct when it realises the semantic contract, not when it reproduces an implementation strategy.

Correctness is evaluated by:

$$
\pi(IState)\equiv_C S
$$

and:

$$
Obs(I)\equiv Obs(SMM)
$$

Two implementations may therefore differ substantially internally while remaining semantically equivalent.

---

# 75. Failure Taxonomy

SCR distinguishes at least four classes.

## 75.1 Semantic Rejection

The requested transformation is not admissible.

Examples:

* invalid input domain;
* violated constraint;
* invalid spatial association;
* transformation unavailable in context.

## 75.2 Semantic Failure

The transformation is semantically valid but its defined semantic result is a failure.

## 75.3 Realisation Failure

The semantic transformation is valid, but the selected implementation cannot currently realise it.

Examples:

* unavailable capability;
* incompatible provider;
* resource exhaustion;
* unsupported resolution;
* unsupported state representation.

## 75.4 Physical Failure

A selected physical realisation failed during execution.

These classes MUST NOT be collapsed into one generic execution error.

---

# 76. Spatial Failure Separation

Spatial implementations MUST distinguish, where relevant:

```text
Invalid Spatial Semantics
Invalid Coordinate
Invalid Reference Frame
Invalid Partition
Invalid State Association

State Unavailable
State Unmaterialised
State Invalid

Partition Unavailable
Provider Unavailable

Resource Unavailable
Physical Execution Failure
```

A provider failure MUST NOT automatically imply semantic state failure.

---

# 77. Observation Boundary

Observation determines what differences matter.

For example, two spatial representations may differ in:

* indexing;
* memory layout;
* compression;
* resolution;
* provider topology;

while remaining equivalent for a particular semantic observation.

Conversely, a seemingly minor difference becomes semantic if it affects an observable contract.

Therefore:

$$
RepresentationDifference
\not\Rightarrow
SemanticDifference
$$

but:

$$
ObservableDifference
\Rightarrow
PotentialSemanticDifference
$$

---

# 78. Provider Equivalence

Two providers are equivalent for a capability when their observable behaviour satisfies the same semantic contract.

For providers \(P_1,P_2\):

$$
Obs(P_1(op,S))
\equiv_C
Obs(P_2(op,S))
$$

subject to declared:

* precision;
* resolution;
* consistency;
* approximation;
* ordering;
* capability limits.

---

# 79. Reference-Frame Equivalence

Spatial provider representations may use different coordinate systems.

Two representations may nevertheless be semantically equivalent when transformed through declared reference-frame mappings.

Conceptually:

```text
SCR Spatial State
      │
      ├── representation A
      │       ↓
      │   transform A
      │
      └── representation B
              ↓
          transform B
```

The semantic state remains authoritative.

---

# 80. Provider Firewall and Spatial State

The provider firewall applies equally to spatial state.

The following is prohibited:

```text
OpenVDB
   ↓
defines SCR spatial ontology
```

or:

```text
H3
   ↓
defines SCR coordinate semantics
```

The permitted relationship is:

```text
SCR Semantic Model
       ↓
Capability
       ↓
Provider
       ↓
Physical Representation
```

---

# 81. Architectural Firewall

The normative dependency direction is:

```text
                    Semantic Field
                         │
                         ▼
              Semantic Machine Model
                         │
                         ▼
                 Semantic Machine
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
     Semantic Context       Semantic Transformation
              │                     │
              └──────────┬──────────┘
                         ▼
                 Semantic Transition
                         │
                         ▼
                    Graph Carrier
                         │
                         ▼
                Semantic Observation
                         │
                         ▼
                Semantic Equivalence
                         │
             ┌───────────┴───────────┐
             ▼                       ▼
      Reference Executor       Other Realisations
             │                       │
             └───────────┬───────────┘
                         ▼
                        EGS
                         │
                         ▼
                   Capabilities
                         │
             ┌───────────┼───────────┐
             ▼           ▼           ▼
          Providers    Providers    Providers
             │           │           │
             ▼           ▼           ▼
        Physical Resources / Infrastructure
                         │
                         ▼
                    Manifestation
```

The reverse semantic dependency is forbidden.

A provider, runtime component, representation, processor, storage system, spatial index, or physical resource MUST NOT become the source of semantic meaning.

---

# 82. What SMM Is Not

SMM is not:

* an operating system;
* a process model;
* a scheduler;
* a memory manager;
* a storage system;
* a message broker;
* a graph database;
* an MLIR dialect;
* a programming language;
* a provider registry;
* EGS;
* the Reference Executor;
* a collection of Mojo classes;
* a spatial database;
* H3;
* OpenVDB;
* a replacement for the Semantic Field;
* a replacement for the Spatial domain specifications.

---

# 83. Design Invariants

The following are normative architectural invariants.

1. Meaning precedes representation.
2. Semantic state is distinct from implementation state.
3. Semantic transformation is distinct from physical instruction.
4. Semantic ordering is distinct from physical scheduling.
5. Semantic concurrency is distinct from physical parallelism.
6. Semantic validity is distinct from physical realisability.
7. Semantic outcome is distinct from physical success.
8. Providers realise capabilities; they do not define them.
9. EGS realises execution; it does not define semantics.
10. MLIR represents and lowers; it does not define SCR semantics.
11. Mojo implements; it does not define SCR semantics.
12. The Reference Executor witnesses semantics; it does not monopolise realisation.
13. Persistence, migration, replication, propagation, and scheduling are derived concerns.
14. Executable hypergraphs express semantic requirements, not physical provider choices.
15. Manifestation cannot alter meaning.
16. Identity is distinct from physical location.
17. Coordinate is distinct from partition.
18. Partition is distinct from state.
19. State is distinct from representation.
20. Representation is distinct from residency.
21. Residency is distinct from execution resource.
22. Physical movement does not imply semantic identity change.
23. Spatial locality does not define spatial ontology.
24. Provider coordinate systems do not define SCR coordinate semantics.
25. A new primitive requires a demonstrated semantic necessity.

---

# 84. Spatial Invariants

The SMM adopts the following spatial architectural invariants from the Spatial domain.

### SMM-SP-001 — Spatial Independence

Spatial semantics MUST remain independent of physical implementation.

### SMM-SP-002 — Coordinate Independence

Provider coordinate systems MUST NOT become canonical SCR coordinates by implementation convenience.

### SMM-SP-003 — Partition Independence

Partition identity MUST remain distinct from coordinate identity and execution-resource identity.

### SMM-SP-004 — State Independence

Spatial state identity MUST remain independent of representation and residency.

### SMM-SP-005 — Locality Independence

Semantic locality MUST remain distinct from physical network or memory topology unless explicitly made semantic.

### SMM-SP-006 — Migration Preservation

Valid state and space migration MUST preserve semantic identity unless identity transformation is explicit.

### SMM-SP-007 — Provider Substitution

Equivalent spatial providers SHOULD be substitutable without changing semantic computation.

### SMM-SP-008 — Materialisation Independence

A semantic spatial state MAY exist without physical materialisation.

### SMM-SP-009 — Partition/State Separation

Partitioning organises computational locality; state represents semantic information.

### SMM-SP-010 — Execution Separation

Execution resource identity MUST remain distinct from spatial and state identity.

---

# 85. Relationship to Existing SCR Library

SMM MUST reuse existing authoritative definitions where possible.

Relevant authorities include:

* `101_Core` — identity, state, transformation, constraint, context, observation, provenance, equivalence;
* `301_Field` — field semantics;
* `203_Graph` — semantic hypergraph structure;
* `303_Topology` — topology;
* `801_Spatial` — existing spatial semantics;
* `902_Interfaces` — declared capabilities/interfaces;
* `904_Providers` — realisation;
* `905_Transforms` — semantic and representation transformations;
* `903_Lowering` — representation and lowering.

The new spatial specifications provide the architectural clarification:

```text
docs/114_SPATIAL_SEMANTICS.md
docs/115_SPATIAL_PARTITIONING_MODEL.md
docs/116_SPATIAL_STATE_MODEL.md
```

The library contract is:

```text
lib/spatial/
    README.md
    101_spec.md
    102_status.yaml
    103_library.graph.json
```

SMM therefore remains an architectural formalisation layer rather than a parallel spatial ontology.

---

# 86. Relationship to Semantic Transition Calculus

The SMM defines the machine in which semantic transitions occur.

The STC defines the formal transition semantics.

The relationship is:

```text
Semantic Field
      │
      ▼
Semantic Machine
      │
      ▼
Transition Context
      │
      ▼
Semantic Transition Calculus
      │
      ▼
Graph-Carried Transition
      │
      ▼
Realisation
```

SMM SHOULD NOT introduce transition rules that belong in STC.

STC SHOULD NOT become responsible for physical realisation.

---

# 87. Relationship to Spatial Transition

Spatial operations such as:

* partition refinement;
* partition coarsening;
* state migration;
* state relocation;
* state materialisation;
* state dematerialisation;
* spatial transformation;

are semantic transitions when they change semantic state or relationships.

Their formal transition rules belong in STC.

Their domain meaning belongs in the Spatial specifications.

Their physical realisation belongs to EGS and providers.

---

# 88. Formal Separation of Concerns

The architecture can therefore be expressed as:

$$
\boxed{
Field
\rightarrow
SMM
\rightarrow
STC
\rightarrow
Executable\ Hypergraph
\rightarrow
EGS
\rightarrow
Capability
\rightarrow
Provider
\rightarrow
Physical\ Resource
}
$$

For spatial computation:

$$
\boxed{
Spatial\ Semantics
\rightarrow
Spatial\ Partition
\rightarrow
Spatial\ State
\rightarrow
Computational\ Locality
\rightarrow
Realisation
}
$$

These are intersecting semantic dimensions, not competing ontologies.

---

# 89. Formal Machine View

A useful abstract machine state can therefore be understood as:

$$
M =
(F,S,C,G,P,R)
$$

where:

* \(F\) = Semantic Field;
* \(S\) = semantic state;
* \(C\) = semantic context;
* \(G\) = executable semantic graph;
* \(P\) = semantic partition/locality relationships;
* \(R\) = realisation information.

However, this tuple is **descriptive**, not a proposal for expanding the minimal kernel.

The kernel remains the graph-carrier model.

`P` and `R` are derived semantic or realisation structures represented through existing graph/context/state mechanisms.

---

# 90. Machine Observation

The observable machine behaviour is determined by the semantic contract.

A physical implementation may maintain:

```text
cache
scheduler
memory allocator
GPU handles
provider objects
partition indexes
network connections
compiled kernels
state replicas
```

without exposing them semantically.

The implementation is correct when:

$$
Obs(I)\equiv Obs(SMM)
$$

under the applicable observation context.

---

# 91. Formalisation Status

The following formalisation results are adopted.

### STC-001

The original kernel:

$$
\langle S,C,T,K,O,\equiv\rangle
$$

was demonstrated to be sound for several semantic properties but insufficiently expressive for composition and independence.

### STC-002

The graph-carrier model settled the transition-carrier question.

The adopted kernel provides:

* typed transformation domains;
* typed consequences;
* semantic states;
* contexts;
* constraint environments;
* applicability;
* consent;
* graph-carried successor relations;
* context-indexed equivalence;
* value congruence;
* successor congruence;
* structural composition;
* causal flow;
* footprint/interference;
* derived observation;
* derived provenance.

`OutcomeOf` and `ResultState` are deprecated for new development.

The physical-provider firewall remains formally preserved.

---

# 92. Current Formal Kernel

The current conceptual kernel is:

```text
GMKernel
│
├── T
│   transformations
│
├── S
│   states
│
├── C
│   contexts
│
├── K
│   constraints
│
├── Applicable
│
├── Consents
│
├── Out
│   typed consequences
│
├── edge
│   semantic transition relation
│
├── GWellFormed
│
├── consE
│   contextual equivalence
│
├── gCompose
│   relational composition
│
├── Footprint
│
├── Overlap
│
├── causal dependence
│
└── observation
```

No additional primitive is justified merely because it is convenient for implementation.

---

# 93. Open Formal Questions

The following remain formalisation work rather than reasons to expand the SMM kernel:

1. state/transition-level equivalence and congruence laws;
2. general commutation law;
3. causal and temporal relations;
4. spatial transition laws;
5. state migration semantics;
6. partition refinement/coarsening semantics;
7. state/partition residency semantics;
8. computational-space containment semantics;
9. authority and ownership semantics;
10. reference invalidation and deletion semantics.

These SHOULD be resolved through the relevant formal domain specifications and STC work.

---

# 94. Architectural Test

The following questions SHOULD be used to falsify proposed SMM extensions.

### Test 1 — Provider Independence

Can the proposed semantic concept exist if all current providers disappear?

If not, it is probably implementation ontology.

### Test 2 — Representation Independence

Can two different representations express the same semantic object?

If not, the proposed concept may be conflating representation with meaning.

### Test 3 — Migration

Can the object move without changing identity?

If not, physical location may have been incorrectly promoted to identity.

### Test 4 — Spatial Independence

Can spatial semantics exist without H3 or OpenVDB?

They MUST.

### Test 5 — Execution Independence

Can the same semantic computation execute on a different processor or device?

It SHOULD.

### Test 6 — Materialisation Independence

Can semantic state exist without physical materialisation?

It MUST.

### Test 7 — Kernel Necessity

Can the behaviour be represented using:

* state;
* context;
* transformation;
* constraint;
* graph-carried consequence;
* equivalence;

without introducing a new primitive?

If yes, no new primitive is justified.

---

# 95. Architectural Summary

The Semantic Machine is not a machine in the conventional hardware sense.

It is the semantic computational structure induced by a Semantic Field.

Its fundamental concern is:

```text
What exists?
What may change?
Under what conditions?
What consequences may result?
How do transformations compose?
What relationships constrain them?
What does an observer consider equivalent?
```

Its physical realisation may then answer:

```text
Where?
On what?
Using which provider?
With what representation?
At what resource?
Using which transport?
With what schedule?
```

The two questions must not be confused.

---

# 96. Final Architectural Model

The resulting architecture is:

```text
                         SEMANTIC FIELD
                               │
                               ▼
                    SEMANTIC MACHINE MODEL
                               │
                               ▼
                       SEMANTIC MACHINE
                               │
                 ┌─────────────┼─────────────┐
                 │             │             │
                 ▼             ▼             ▼
              State         Context    Transformations
                 │             │             │
                 │             │             │
                 └─────────────┼─────────────┘
                               ▼
                      GRAPH-CARRIED STC
                               │
                               ▼
                  EXECUTABLE SEMANTIC GRAPH
                               │
                 ┌─────────────┼─────────────┐
                 │             │             │
                 ▼             ▼             ▼
             Spatial       Partition       State
             Context       Locality       Residency
                 │             │             │
                 └─────────────┼─────────────┘
                               ▼
                         OBSERVATION
                               │
                               ▼
                      SEMANTIC EQUIVALENCE
                               │
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
        REFERENCE EXECUTOR              OTHER REALISATIONS
                 │                           │
                 └─────────────┬─────────────┘
                               ▼
                              EGS
                               │
                               ▼
                         CAPABILITIES
                               │
                ┌──────────────┼──────────────┐
                ▼              ▼              ▼
             PROVIDER       PROVIDER       PROVIDER
                │              │              │
                ▼              ▼              ▼
               H3           OpenVDB         Other
                │              │              │
                └──────────────┼──────────────┘
                               ▼
                       PHYSICAL RESOURCES
                               │
                               ▼
                         MANIFESTATION
```

The critical architectural firewall is:

$$
\boxed{
Semantic\ Meaning
\rightarrow
Semantic\ Structure
\rightarrow
Semantic\ Transition
\rightarrow
Realisation
}
$$

and never:

$$
\boxed{
Physical\ Implementation
\rightarrow
Semantic\ Meaning
}
$$

The corresponding spatial separation is:

$$
\boxed{
Coordinate
\neq
Partition
\neq
State
\neq
Representation
\neq
Residency
\neq
Execution
}
$$

And the corresponding machine principle is:

> **The Semantic Machine defines what computation means. Computational spaces define where semantic computation may be organised. Spatial partitions define computational locality. Spatial state defines what information is manifested. Providers and physical resources determine how those semantics are realised. None of the latter may redefine the former.**
