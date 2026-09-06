# SCR Library Metadata

## `000_meta`

The `000_meta` directory contains metadata, governance information, conventions, taxonomic information, provenance, and other descriptive material used to organize and interpret the SCR semantic library.

It is **not a semantic computational domain**.

The contents of `000_meta` describe the library.

They do not define the computational meaning of the domains contained within the library.

---

# 1. Purpose

SCR is organized as a semantic computational library rather than simply as a collection of source-code modules.

As the library grows, the system requires information about:

* what domains exist
* how domains are organized
* which definitions are authoritative
* how terminology is used
* how identifiers are assigned
* how versions are represented
* how semantic relationships are classified
* how provenance is maintained
* how implementation status is represented
* how derived library graphs are generated
* how agents should interpret the filesystem
* how architectural conventions are maintained

This information belongs in the metadata and governance layer.

Therefore:

```text
Semantic Domains
      │
      │ defined by
      ▼
101_definition.md
      │
      │ described by
      ▼
000_meta
      │
      │ implemented by
      ▼
Source / IR / Runtime
```

`000_meta` describes the organization and governance of the semantic library.

It does not replace the semantic definitions.

---

# 2. Architectural Position

The SCR library should be understood as having several distinct information layers:

```text
                    SCR LIBRARY
                         │
          ┌──────────────┴──────────────┐
          │                             │
          ▼                             ▼
   Semantic Domains                 Metadata
          │                             │
          ▼                             ▼
101_definition.md                 000_meta
          │                             │
          ▼                             ▼
 Semantic Contracts             Organization
          │                     Governance
          │                     Taxonomy
          │                     Provenance
          │                     Conventions
          ▼
Implementation
```

The semantic definition answers:

> **What does this domain mean?**

Metadata answers:

> **How is the library organized and how should that information be interpreted?**

These questions MUST remain separate.

---

# 3. What `000_meta` Is

`000_meta` is a repository-level metadata scope.

It may contain information about:

* taxonomy
* naming conventions
* identifiers
* versioning
* document conventions
* semantic relationship vocabulary
* lifecycle conventions
* status conventions
* provenance
* traceability
* architectural classifications
* generated artifacts
* library inventory
* governance
* agent guidance
* terminology
* compatibility
* migration
* deprecation
* historical decisions

Metadata MAY describe semantic domains without becoming part of their semantic definition.

---

# 4. What `000_meta` Is Not

`000_meta` is not:

* a semantic domain
* an implementation module
* an MLIR dialect
* a runtime subsystem
* a provider
* a transformation pass
* a lowering
* a storage system
* a database schema
* a source of semantic meaning
* a replacement for `101_definition.md`

In particular:

```text
000_meta ≠ Core
000_meta ≠ Data
000_meta ≠ Graph
000_meta ≠ Metadata Domain
```

Metadata is cross-cutting information about the library.

---

# 5. Metadata Authority

Metadata has a lower semantic authority than normative domain definitions.

The general authority hierarchy is:

```text
Project Architecture
        ↓
Parent 101_definition.md
        ↓
Child 101_definition.md
        ↓
Explicit Contracts / Interfaces
        ↓
Tests
        ↓
Implementation
        ↓
102_status.yaml
        ↓
Derived Metadata / Graphs
```

Metadata MUST NOT redefine a semantic contract.

If a metadata document conflicts with a normative semantic definition, the normative definition takes precedence and the metadata MUST be corrected.

---

# 6. Metadata Scope

Metadata can exist at different scopes.

## 6.1 Library scope

```text
lib/
└── 000_meta/
```

This describes the SCR library as a whole.

Examples:

* library taxonomy
* naming conventions
* document conventions
* relationship vocabulary
* global identifiers
* governance
* library-wide terminology

---

## 6.2 Domain scope

A domain may contain metadata describing its own organization.

For example:

```text
203_Graph/
└── Hypergraph/
    └── 000_meta/
```

This metadata is scoped to `Graph/Hypergraph`.

It MUST NOT automatically be interpreted as library-wide metadata.

---

## 6.3 Subdomain scope

Metadata MAY also exist within a deeper semantic hierarchy where local conventions or historical material require it.

The governing rule is:

> **Metadata applies to the narrowest scope explicitly associated with it unless the document declares a broader scope.**

---

# 7. Metadata vs Semantic Definitions

The distinction is fundamental.

For example:

```text
203_Graph/
├── 101_definition.md
└── Hypergraph/
    ├── 000_meta/
    │   └── ...
    └── ...
```

The Graph definition establishes the semantics of Graphs.

Metadata may explain:

* why Hypergraph exists as a subdomain
* naming conventions
* historical references
* source terminology
* implementation mappings
* document provenance

It must not silently define what a hypergraph means.

That belongs in the appropriate semantic definition.

---

# 8. Library Taxonomy

The current library is organized into several broad scopes.

## Foundational and semantic domains

```text
101_Core
201_Data
202_Math
203_Graph

301_Field
302_Geometry
303_Topology

401_Morphology

501_Physics
502_Dynamics
503_Simulation

601_Agent
602_Neural
603_Perception
604_Control

701_Optimization
702_Learning
703_Adaptation
704_Evolution
705_Ecology
```

## Cross-cutting computational domains

```text
801_Spatial
802_Stream

901_Analysis
902_Interfaces
903_Lowering
904_Providers
905_Transforms

A01_Render
```

This taxonomy is descriptive and architectural.

It does not imply that the numbered domains form a single inheritance hierarchy.

The semantic relationships between them are represented separately.

---

# 9. Filesystem Hierarchy Is Not Semantic Hierarchy

Filesystem placement is organizational.

Semantic relationships are explicit.

For example:

```text
202_Math/
└── Optimization/

701_Optimization/
```

does not mean that one directory is a filesystem duplicate of the other.

Likewise:

```text
502_Dynamics/
└── Evolution/

704_Evolution/
```

represents different semantic scopes.

Agents MUST NOT infer semantic equivalence solely from names or directory placement.

---

# 10. Domain-Local Concepts

A concept may occur inside a domain without being a first-class SCR domain.

For example:

```text
202_Math/Optimization
```

represents optimization as a mathematical concept.

```text
701_Optimization
```

represents optimization as a first-class semantic computational domain.

Similarly:

```text
502_Dynamics/Evolution
```

concerns evolution in the context of dynamical systems.

```text
704_Evolution
```

defines evolutionary change as an independent computational domain.

Metadata SHOULD help preserve these distinctions where naming alone could cause confusion.

---

# 11. Naming Conventions

Directory names SHOULD use:

```text
PascalCase
```

for semantic concepts.

Examples:

```text
Hypergraph
Differential
Morphology
Pathfinding
Canonicalization
Vectorization
```

Top-level library domains use their numeric or alphanumeric identifiers:

```text
101_Core
201_Data
...
A01_Render
```

Definitions use:

```text
101_definition.md
```

Status documents use:

```text
102_status.yaml
```

Derived library graphs use:

```text
103_library.graph.json
```

These filenames have semantic meaning within the SCR documentation system and SHOULD NOT be repurposed.

---

# 12. Definition Documents

`101_definition.md` is the normative semantic definition of its scope.

A definition should answer:

```text
What is this?
What does it mean?
What does it contain?
What are its invariants?
What does it compose with?
What does it depend upon semantically?
What does it produce?
What does it consume?
How can it be represented?
How can it be transformed?
How can it be implemented?
How can it be validated?
```

The definition SHOULD remain implementation-independent.

---

# 13. Status Documents

`102_status.yaml` records engineering state.

It may describe:

```text
Specified
Partially Implemented
Implemented
Tested
Validated
Integrated
Blocked
Deprecated
```

Status MUST describe evidence.

It MUST NOT be used to redefine semantics.

For example:

```yaml
status: implemented
```

means implementation exists.

It does not mean:

```text
the implementation defines the meaning of the domain
```

---

# 14. Derived Library Graph

`103_library.graph.json` represents relationships across the library.

It may contain relationships such as:

```text
CONTAINS
REFINES
SPECIALIZES
COMPOSES
DEPENDS_ON
REPRESENTS
LOWERS_TO
IMPLEMENTED_BY
EXECUTES_ON
ADAPTS
PRODUCES
CONSUMES
INTERACTS_WITH
CONSTRAINS
OBSERVES
TRANSFORMS
```

The graph is derived information.

It SHOULD be generated from authoritative source documents wherever possible.

It MUST NOT be treated as the primary architectural authority.

---

# 15. Relationship Vocabulary

SCR uses explicit relationship semantics.

The filesystem should not be used as a substitute for semantic relationships.

For example:

```text
Geometry ──COMPOSES──> Topology
Fields ──CONSTRAINS──> Morphology
Morphology ──REPRESENTS──> Pattern
Simulation ──USES──> Dynamics
Rendering ──OBSERVES──> Simulation
Provider ──IMPLEMENTS──> Capability
Lowering ──TRANSFORMS──> Representation
```

Only relationships that are semantically justified should be recorded.

---

# 16. Metadata Categories

The library may use the following broad metadata categories.

## Identity

Information identifying a domain, concept, document, version, or artifact.

## Taxonomy

Information describing organizational relationships.

## Provenance

Information describing origin, authorship, derivation, source, or transformation history.

## Versioning

Information describing semantic and implementation versions.

## Lifecycle

Information describing creation, maturity, deprecation, replacement, or retirement.

## Governance

Information describing architectural authority and decision processes.

## Traceability

Information connecting requirements, definitions, implementation, tests, and validation.

## Compatibility

Information describing compatibility between versions, representations, providers, or domains.

## Documentation

Information explaining organization, terminology, and usage.

## Generation

Information identifying generated or derived artifacts.

---

# 17. Provenance

Metadata SHOULD preserve provenance whenever information is derived.

For example:

```text
Definition
    ↓
Status
    ↓
Library Graph
```

The derived graph should be able to identify the definitions and status records from which its information originated.

Generated metadata MUST NOT appear to be manually authoritative.

Where appropriate, generated documents SHOULD identify:

* source documents
* source versions
* generation timestamp
* generator version
* generation method
* semantic scope

---

# 18. Generated Artifacts

Generated artifacts MUST be distinguishable from authoritative source documents.

For example:

```text
Authoritative:

101_definition.md
102_status.yaml


Derived:

103_library.graph.json
```

Generated artifacts MAY be regenerated.

Agents MUST NOT manually modify a generated artifact when the correct solution is to modify its source.

---

# 19. Metadata and Automation

Metadata exists partly to make the semantic library machine-readable.

It should enable tooling to answer questions such as:

```text
What domains exist?

Which domains are defined?

Which domains are implemented?

Which domains depend on Core?

Which domains implement a capability?

Which transformations apply to a representation?

Which providers can implement an operation?

Which definitions are incomplete?

Which concepts are duplicated?

Which domains have unresolved semantic questions?

Which transformations preserve a given invariant?
```

This enables the library to become analyzable as a semantic system rather than merely a filesystem.

---

# 20. Agent Use

AI agents SHOULD consult `000_meta` before making broad structural changes.

In particular, agents should inspect metadata when:

* adding a new top-level domain
* introducing a new identifier
* renaming a domain
* moving a concept
* adding a new document type
* generating library graphs
* changing taxonomy
* changing naming conventions
* interpreting ambiguous relationships
* determining whether a concept is domain-local or cross-cutting

Agents MUST still inspect the relevant `101_definition.md`.

Metadata is guidance and governance.

It is not a replacement for semantic definitions.

---

# 21. Adding a New Top-Level Domain

A new top-level domain SHOULD NOT be created merely because a new implementation module is needed.

Before creating one, determine:

```text
1. What semantic concept is being introduced?
2. Does the concept already exist?
3. Is it domain-local or cross-cutting?
4. Which parent domain owns it?
5. Does it require independent invariants?
6. Does it require independent interfaces?
7. Does it have independent composition semantics?
8. Does it justify a first-class semantic contract?
```

Only then should a new top-level domain be proposed.

---

# 22. Adding a New Subdomain

A subdomain should represent a meaningful semantic subdivision.

Examples include:

```text
202_Math/
├── Algebra
├── Calculus
├── Probability
└── Statistics
```

or:

```text
905_Transforms/
├── Fusion
├── Tiling
├── Vectorization
└── Specialization
```

A subdomain does not automatically require a separate `101_definition.md`.

It should receive an independent definition when it becomes sufficiently semantically independent to warrant its own normative contract.

---

# 23. Metadata and Standards

SCR should reuse established standards where appropriate.

Metadata may reference standards for:

* identifiers
* timestamps
* media types
* serialization
* schemas
* provenance
* signatures
* spatial references
* units
* versioning

Standards provide interoperable mechanisms.

They do not supersede SCR semantic authority.

---

# 24. Metadata and MLIR

MLIR itself distinguishes MLIR concepts such as operations, types, attributes, dialects, interfaces, and transformations. SCR metadata may describe how SCR concepts relate to these mechanisms, but metadata MUST NOT replace the actual semantic definition of an SCR concept.

For example:

```text
SCR Domain
    │
    ├── Semantic Definition
    │
    ├── MLIR Representation
    │
    ├── Interfaces
    │
    ├── Transformations
    │
    └── Lowerings
```

The metadata layer may describe these relationships.

It does not define them.

---

# 25. Metadata and Transformations

Transformation metadata may describe:

* source abstraction
* target abstraction
* preserved invariants
* changed properties
* required capabilities
* required interfaces
* provider constraints
* hardware constraints
* applicability
* cost
* reversibility
* provenance

This is particularly important because SCR distinguishes general transformation from lowering.

MLIR's Transform dialect is itself a transformation-control mechanism operating over payload IR, which is conceptually consistent with keeping transformation metadata separate from the semantic definition of the underlying computation.

---

# 26. Versioning

Metadata SHOULD distinguish at least:

```text
Semantic Version
Document Version
Implementation Version
Provider Version
Representation Version
Schema Version
```

These MUST NOT be conflated.

A provider update does not necessarily imply a semantic version change.

An implementation change does not necessarily imply a semantic change.

A semantic change generally requires review of dependent definitions, interfaces, tests, and derived metadata.

---

# 27. Deprecation

Deprecated concepts SHOULD retain their identity and provenance where practical.

A deprecated concept should identify:

```text
Deprecated Since
Reason
Replacement
Migration Path
Compatibility
Removal Target
```

Do not silently delete historical semantic information when doing so would destroy provenance or make previous states impossible to interpret.

---

# 28. Historical Material

Historical notes MAY exist in metadata.

Historical material is descriptive.

It does not automatically become current normative architecture.

For example:

```text
Historical Decision
       ↓
Current Definition
       ↓
Current Implementation
```

The historical decision explains why something exists.

The current definition establishes what it currently means.

---

# 29. Metadata Integrity

Metadata MUST satisfy the following invariants.

### META-INV-001 — Scope

Every metadata artifact has an identifiable scope.

### META-INV-002 — Non-authority

Metadata MUST NOT silently redefine semantic meaning.

### META-INV-003 — Provenance

Derived metadata SHOULD retain sufficient provenance to identify its source.

### META-INV-004 — Determinism

Generated metadata SHOULD be deterministic given identical source inputs.

### META-INV-005 — Traceability

Metadata SHOULD support tracing concepts from definition through implementation and validation.

### META-INV-006 — Consistency

Identifiers and terminology SHOULD remain consistent across the library.

### META-INV-007 — Separation

Metadata MUST remain distinguishable from semantic definitions.

### META-INV-008 — Regenerability

Derived metadata SHOULD be regenerable from authoritative sources.

### META-INV-009 — Scope Preservation

Nested metadata MUST NOT silently escape its declared scope.

### META-INV-010 — Historical Integrity

Historical information MUST NOT be presented as current normative architecture without explicit designation.

---

# 30. Recommended `000_meta` Contents

The library-level directory may eventually contain material such as:

```text
000_meta/
├── README.md
├── taxonomy.md
├── naming.md
├── identifiers.md
├── terminology.md
├── relationships.md
├── document-types.md
├── provenance.md
├── versioning.md
├── lifecycle.md
├── governance.md
├── standards.md
└── history/
```

This is a **recommended conceptual organization**, not a requirement that all files exist immediately.

The directory should grow only as metadata needs become real.

---

# 31. Metadata Control Plane

The complete library control plane can be understood as:

```text
                    000_meta
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
       Taxonomy     Governance   Conventions
          │            │            │
          └────────────┼────────────┘
                       │
                       ▼
              Semantic Definitions
                 101_definition
                       │
                       ▼
                  Implementation
                       │
                       ▼
                   Validation
                       │
                       ▼
                 102_status.yaml
                       │
                       ▼
              103_library.graph.json
```

The important distinction is:

```text
000_meta
    = describes and governs organization

101_definition
    = defines semantic meaning

102_status
    = records engineering reality

103_library.graph
    = derives relationships
```

---

# 32. Final Principle

The `000_meta` directory exists to make the SCR semantic library understandable, governable, traceable, and machine-processable without contaminating the semantic definitions with repository-management concerns.

Its fundamental rule is:

> **Metadata describes the semantic library; it does not define the semantics of the library.**

Or, more compactly:

```text
000_meta
    describes

101_definition
    defines

Implementation
    realizes

102_status
    records

103_library.graph
    derives
```

These responsibilities MUST remain separate.

The integrity of the SCR architecture depends on preserving that separation.
