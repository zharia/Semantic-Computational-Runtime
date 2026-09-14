# SCR Data Library Specification

**Document:** `lib/201_Data/101_spec.md`
**Status:** Normative
**Version:** 0.0.1
**Domain:** Data
**Library ID:** `SCR.Data`
**Specification Class:** Semantic Library Specification

---

# 1. Purpose

The SCR Data library defines the foundational semantic model for representing, organizing, transforming, transporting, and interpreting data within the Semantic Computational Runtime.

Data is treated as a semantic structure rather than merely a sequence of bytes stored in memory.

The Data library provides the abstractions required to represent information-bearing structures while preserving their:

* semantic identity;
* structure;
* type;
* relationships;
* provenance;
* representation;
* lifecycle;
* transformation semantics.

Data is therefore a semantic object within SCR, not merely a runtime storage concern.

---

# 2. Architectural Position

Data is a foundational SCR domain built upon Core.

```text
SCR
│
├── 101_Core
│
├── 201_Data
│
├── 202_Tensor
├── 203_Field
├── 204_Graph
├── ...
```

The exact numbering and domain ordering are governed by the repository's canonical library structure.

The fundamental dependency is:

```text
Data
  ↓
Core
```

Higher-level domains may depend upon Data.

Data should not depend upon higher-level domain semantics merely to represent generic data.

For example:

```text
Tensor → Data
Graph  → Data
Field  → Data
Stream → Data
```

but Data should not require Tensor, Graph, Field, or Stream semantics merely to establish its foundational abstractions.

---

# 3. Fundamental Principle

The fundamental principle of SCR Data is:

> **Data is information represented as semantic structure, with a distinction between what the data means and how that information is physically represented.**

Consequently:

```text
Semantic Data
      ≠
Memory Buffer
      ≠
File
      ≠
Network Packet
      ≠
Database Record
      ≠
GPU Buffer
      ≠
Serialized Bytes
```

These may be manifestations or representations of the same semantic data.

The Data library must preserve this distinction.

---

# 4. Relationship to Information

SCR treats information as something that can be represented, related, transformed, and manifested.

Data is one means through which semantic information becomes computationally manipulable.

Conceptually:

```text
Information
     ↓
Semantic Data
     ↓
Representation
     ↓
Manifestation
```

The Data library is concerned principally with the semantic data layer.

Physical representation belongs to the appropriate runtime, storage, transport, or provider subsystem.

---

# 5. Data as Semantic Structure

A Data object may contain:

```text
Identity
Type
Structure
Values
Relations
Metadata
Provenance
Representation
Constraints
```

Not every data object must contain every property explicitly.

The relevant semantic properties must nevertheless be representable where required.

Data should therefore be capable of representing both:

```text
simple value
```

and:

```text
complex structured information
```

without requiring unrelated domain semantics.

---

# 6. Semantic Identity

Data must participate in the SCR identity model.

A data object's semantic identity must remain distinct from:

* memory address;
* storage location;
* file name;
* URI;
* database key;
* buffer handle;
* process-local pointer;
* GPU address;
* network address.

Conceptually:

```text
SemanticID
    ↓
Data Entity
    ↓
Manifestation
```

A data manifestation may move or be recreated without changing the semantic identity of the data.

---

# 7. Data Representation

The Data library distinguishes at least three conceptual levels:

```text
Semantic Data
      ↓
Logical Representation
      ↓
Physical Representation
```

### Semantic Data

What the information represents.

### Logical Representation

The structural organization through which the semantic data is expressed.

Examples include:

* sequences;
* records;
* maps;
* sets;
* trees;
* tables;
* multidimensional structures.

### Physical Representation

How the data is encoded or stored.

Examples include:

* bytes;
* memory buffers;
* files;
* pages;
* compressed blocks;
* GPU memory;
* network frames.

A change between physical representations must not automatically constitute a semantic change.

---

# 8. Values

Data may contain values.

A value is an information-bearing semantic element that can participate in computation or structure.

Examples include:

```text
integer
floating-point value
boolean
character
string
symbol
identifier
structured value
```

The Data library may provide generic value containers and structures.

Specialized mathematical semantics belong in the Math domain.

Tensor-specific semantics belong in Tensor.

Spatial values belong in the appropriate spatial/geometry domains.

---

# 9. Collections

Data must support general collection semantics.

A collection represents multiple data elements according to defined structural rules.

Common collection semantics include:

```text
Sequence
Set
Map
Record
Tuple
Collection
```

Each collection type must define, where applicable:

* membership;
* ordering;
* multiplicity;
* key semantics;
* element type;
* structural constraints;
* mutation semantics;
* identity semantics.

The existence of a collection implementation does not by itself define its semantic behaviour.

---

# 10. Sequence

A sequence represents an ordered collection.

Conceptually:

```text
S = [x₀, x₁, ..., xₙ]
```

Sequence semantics include:

* positional ordering;
* element membership;
* cardinality;
* element access;
* iteration;
* insertion;
* removal;
* replacement where mutable.

A sequence must preserve ordering as part of its semantic definition.

---

# 11. Set

A set represents a collection in which membership is the primary semantic property.

Conceptually:

```text
S = {x₀, x₁, ..., xₙ}
```

A set does not acquire ordering semantics merely because a particular implementation happens to iterate elements in a deterministic order.

If ordering is semantically significant, a sequence or explicitly ordered collection should be used.

---

# 12. Map

A map represents associations between keys and values.

Conceptually:

```text
key → value
```

Map semantics include:

* key identity;
* key uniqueness;
* value association;
* insertion/removal;
* lookup;
* replacement;
* membership.

The physical implementation may use hashing, trees, arrays, radix structures, or another mechanism without changing the semantic definition.

---

# 13. Records and Structured Data

A record represents data composed of named or otherwise identified fields.

Conceptually:

```text
Record
├── field A
├── field B
├── field C
└── ...
```

A record may define:

* field identity;
* field type;
* optionality;
* ordering where semantically relevant;
* constraints;
* defaults;
* provenance.

Record structure must remain distinguishable from its serialization format.

For example:

```text
Record
  ≠
JSON
  ≠
CBOR
  ≠
binary struct
```

These may be representations of the same semantic record.

---

# 14. Schema

A schema defines structural and semantic constraints applicable to data.

A schema may describe:

* fields;
* types;
* cardinality;
* relationships;
* constraints;
* versions;
* required properties;
* permitted representations.

A schema is itself semantic data.

Therefore:

```text
Data
  ↔
Schema
```

is a semantic relationship rather than merely a compiler mechanism.

---

# 15. Type Information

Data may carry or reference type information.

The distinction between:

```text
value
```

and:

```text
type of value
```

must remain explicit.

Likewise:

```text
representation type
```

must not automatically be confused with:

```text
semantic type
```

For example, two different physical encodings may represent the same semantic type.

---

# 16. Strings

Strings are Data-domain structures with explicit semantic and representation properties.

SCR's string semantics must preserve the project's established requirements regarding:

* mutability;
* encoding;
* length;
* termination;
* storage;
* indexing.

In particular, SCR's established semantic model permits **mutable, non-null-terminated strings**.

A physical representation may contain termination or padding for interoperability, but such implementation details must not silently become semantic requirements.

---

# 17. Binary Data

Binary data represents information whose immediate semantic structure is not necessarily interpreted by the Data layer.

Binary data may be represented as:

```text
byte sequence
buffer
blob
binary object
```

The Data layer should distinguish:

```text
opaque binary data
```

from:

```text
typed semantic data
```

An opaque byte sequence may subsequently be interpreted through an explicit schema or decoder.

---

# 18. Serialization

Serialization transforms semantic data into a representation suitable for persistence or transport.

Conceptually:

```text
Semantic Data
      ↓
Serialization
      ↓
Representation
```

Deserialization performs the inverse semantic reconstruction:

```text
Representation
      ↓
Deserialization
      ↓
Semantic Data
```

Serialization is therefore a transformation, not the semantic identity of the data.

A serialization format must not be treated as the canonical semantic definition merely because it is convenient or widely supported.

---

# 19. Persistence

Persistence provides durable manifestation of data.

Examples include:

```text
file
database
object store
distributed storage
memory-mapped storage
```

Persistence is a manifestation concern.

The semantic Data object must remain distinguishable from its persistent representation.

Conceptually:

```text
Semantic Data
      ↓
Persistence Manifestation
      ↓
Storage
```

A persistent representation may survive runtime destruction while remaining semantically associated with the same data entity.

---

# 20. Copy and Reference Semantics

Data operations must explicitly distinguish between:

```text
copy
reference
view
alias
move
transfer
```

These operations may have materially different semantic consequences.

For example:

```text
Copy
A → B
```

may create a new semantic entity or a new manifestation depending upon the defined operation.

Whereas:

```text
Reference
A ← B
```

does not necessarily create a new semantic entity.

The distinction must not be left solely to physical implementation behaviour.

---

# 21. Views

A view represents a semantic or logical projection of underlying data.

Conceptually:

```text
Data
 ↓
View
```

A view may expose:

* subset;
* projection;
* reordered elements;
* transformed representation;
* filtered structure;
* alternate interpretation.

A view does not necessarily own the underlying data.

Its lifetime and validity must therefore be explicitly defined.

---

# 22. Mutation

Data mutation changes semantic state.

Conceptually:

```text
D₁
 │
 │ mutation
 ▼
D₂
```

The system must distinguish:

```text
mutable data
```

from:

```text
immutable data
```

and must define whether mutation preserves semantic identity.

In general:

> **Mutation of state does not inherently imply mutation of semantic identity.**

The applicable identity and versioning semantics must be defined by the relevant data type.

---

# 23. Versioning

Data may have multiple versions.

A version represents a distinct semantic state or representation according to the applicable versioning model.

Versioning must distinguish:

```text
semantic version
```

from:

```text
storage version
```

and:

```text
implementation version
```

A storage rewrite must not automatically create a new semantic version.

---

# 24. Provenance

Data may carry provenance describing its origin and transformation history.

Provenance can describe:

```text
source
creator
transformation
timestamp
dependency
authority
derivation
```

Provenance is distinct from data identity.

```text
Identity
    = what entity is this?

Provenance
    = where did it come from / how was it derived?
```

Cryptographic provenance may be used where required.

---

# 25. Transformation

Data transformation is a semantic operation.

Conceptually:

```text
Data A
   ↓
Transformation
   ↓
Data B
```

A transformation may:

* change representation;
* change structure;
* filter data;
* combine data;
* split data;
* encode/decode data;
* derive new data.

The transformation must define whether the resulting data:

* retains identity;
* derives a new identity;
* retains provenance;
* creates a new semantic entity;
* is merely a new manifestation.

---

# 26. Data and Computation

Data is an active participant in computation.

SCR computation can be expressed as:

```text
Data / Semantic State
        ↓
Operation
        ↓
Transformed Semantic State
```

Data should therefore be representable directly within SCR computational graphs.

The Data library must not assume that data is passive storage external to computation.

---

# 27. Data and Graph

Data and Graph have complementary roles.

```text
Data
  = information-bearing structures

Graph
  = relationships between semantic entities
```

A data object may therefore participate in a semantic graph.

```text
Data A
  │
  ├── relation
  │
  ▼
Data B
```

Graph semantics govern the relationship.

Data semantics govern the entities and structures being related.

Neither abstraction should unnecessarily absorb the other.

---

# 28. Data and Field

A Field represents semantic structure distributed across some domain.

Data may constitute:

* the contents of a field;
* field state;
* field metadata;
* field boundaries;
* field observations.

The Field domain defines field semantics.

Data defines the information carried by or associated with those fields.

---

# 29. Data and Tensor

A tensor is a structured mathematical/data object with dimensional semantics.

The Data library may provide generic multidimensional storage or structural mechanisms where necessary.

However:

> **Tensor semantics belong to the Tensor domain.**

Data should provide reusable underlying structures without prematurely introducing mathematical tensor semantics.

---

# 30. Data and Stream

A stream represents an ordered flow or temporal sequence of semantic data.

The Data library defines the data being transferred.

The Stream domain defines streaming semantics such as:

* ordering;
* flow;
* backpressure;
* delivery;
* temporal progression;
* buffering;
* subscription.

The two concepts must remain separate.

---

# 31. Data and Storage

Storage is a manifestation of data.

Conceptually:

```text
Semantic Data
      ↓
Storage Manifestation
```

A file, database row, memory region, or object-store object is not inherently the semantic data itself.

This distinction is required for:

* migration;
* replication;
* caching;
* persistence;
* distributed execution;
* provider substitution.

---

# 32. Data and Messaging

Messages carry semantic data through communication infrastructure.

The message transport is not necessarily the semantic identity of the data.

Conceptually:

```text
Semantic Data
      ↓
Message
      ↓
Transport
```

AMQP and HyrxMQ may provide transport and messaging infrastructure.

Data semantics remain defined by SCR.

---

# 33. Physical Representation

Data may be physically represented using:

```text
CPU memory
GPU memory
DMA-BUF
file
database
network buffer
shared memory
persistent object
compressed representation
```

These are manifestations.

The Data semantic model must remain independent of any one representation.

Where zero-copy or shared-memory mechanisms are used, they are implementation optimizations unless explicitly elevated into semantic guarantees.

---

# 34. Memory and Ownership

Physical data storage may have ownership semantics independent of semantic identity.

The implementation must distinguish:

```text
semantic ownership
physical memory ownership
reference lifetime
provider ownership
```

This is particularly important when data crosses:

* Mojo;
* MLIR;
* runtime;
* GPU;
* messaging;
* storage;
* provider boundaries.

A borrowed physical buffer must not be interpreted as ownership of the semantic data entity.

---

# 35. Canonical Representation

SCR should maintain a distinction between:

```text
canonical semantic representation
```

and:

```text
optimized physical representation
```

Multiple physical representations may correspond to one semantic object.

For example:

```text
Semantic Data
 ├── CPU representation
 ├── GPU representation
 ├── serialized representation
 └── cached representation
```

The semantic layer determines equivalence.

---

# 36. MLIR Implementation

Data semantic primitives intended for compiler/runtime representation must have canonical SCR MLIR representations.

These may include:

* Data types;
* collection types;
* data operations;
* transformations;
* schema constructs;
* references;
* views;
* serialization operations;
* data constraints.

The MLIR representation must preserve the semantic properties required by the Data specification.

Compiler optimizations may alter physical representation provided that the applicable semantic invariants remain satisfied.

---

# 37. Mojo API

User-facing Data functionality must be exposed through idiomatic Mojo.

The preferred abstraction is:

```mojo
let data = Data(...)
let value = data.get(...)
let result = data.transform(...)
```

rather than exposing raw MLIR construction.

The exact API is determined by implementation and subsequent API specifications.

The Mojo interface is a projection of Data semantics.

It is not an independent data model.

The project-wide relationship between MLIR and Mojo is defined by:

`docs/architecture/101_language_and_api.md`

---

# 38. API Traceability

A user-facing Mojo Data operation must be traceable to its SCR semantic meaning.

Conceptually:

```text
Mojo API
   ↓
Data semantic operation
   ↓
MLIR operation
   ↓
verification
   ↓
runtime/provider
```

The implementation should make this relationship inspectable where practical.

---

# 39. Verification

Data operations must be verified against their semantic contracts.

Verification may include:

* type validity;
* structural validity;
* schema validity;
* bounds;
* cardinality;
* ownership;
* lifetime;
* representation validity;
* provenance;
* transformation constraints.

The verification layer should distinguish:

```text
invalid data
```

from:

```text
unsupported representation
```

and:

```text
runtime failure
```

where possible.

---

# 40. Determinism

Where a Data operation is defined as deterministic, equivalent inputs under equivalent semantic state must produce semantically equivalent outputs.

Physical implementation may vary.

For example:

```text
CPU execution
GPU execution
distributed execution
```

may use different representations while producing equivalent semantic results.

If an operation is intentionally nondeterministic, that property must be explicitly represented in its semantic contract.

---

# 41. Equality and Equivalence

Data equality must be explicitly defined.

Possible distinctions include:

```text
Identity equality
Structural equality
Value equality
Semantic equality
Representation equality
Byte equality
```

These must not be conflated.

For example:

```text
same bytes
```

does not necessarily imply:

```text
same semantic entity
```

and:

```text
different bytes
```

does not necessarily imply:

```text
different semantic value
```

---

# 42. Ordering

Ordering must be explicit.

A Data structure is ordered only where ordering is part of its semantics.

Implementation iteration order must not silently become semantic ordering.

Where canonical ordering is required, it must be defined by the applicable data type.

---

# 43. Serialization Boundary

Serialization formats are provider/representation concerns unless explicitly adopted as semantic canonical forms.

Examples include:

```text
JSON
CBOR
MessagePack
Protocol Buffers
Arrow
binary formats
```

The Data semantic model must not become coupled to any one format merely because that format is used by a runtime component.

---

# 44. Data Integrity

Data integrity includes preservation of applicable semantic invariants across transformations and manifestations.

At minimum, implementations should consider:

```text
identity integrity
type integrity
structure integrity
value integrity
provenance integrity
ownership integrity
lifetime integrity
representation integrity
```

The appropriate integrity properties must be specified by individual data types and operations.

---

# 45. Data Lifecycle

A generic data lifecycle may be represented as:

```text
DEFINED
   ↓
CREATED
   ↓
ACTIVE
   ↓
TRANSFORMED
   ↓
PERSISTED / TRANSMITTED / MANIFESTED
   ↓
RETIRED
```

Not every Data object must implement every lifecycle state.

Lifecycle semantics must be explicitly defined where they apply.

Retirement of a manifestation does not necessarily imply retirement of the semantic data entity.

---

# 46. Data as a Semantic Resource

Data may be computationally expensive to:

* create;
* copy;
* move;
* serialize;
* deserialize;
* transmit;
* transform.

These costs are implementation/runtime properties unless explicitly represented as semantic constraints.

The semantic Data model must nevertheless permit runtime systems to attach resource and cost information without changing the underlying meaning.

---

# 47. Resource Locality

Data may have locality relationships with computational spaces.

Conceptually:

```text
Semantic Data
      ↓
Manifestation
      ↓
Computational Space
```

The Data model must not equate semantic identity with physical locality.

This permits the runtime to move data between:

```text
CPU
GPU
node
container
process
storage
network
```

while preserving semantic identity.

---

# 48. Data Graphability

Data structures must be representable as semantic structures that can participate in SCR graphs where required.

For example:

```text
Data
 ├── has_type
 ├── contains
 ├── references
 ├── derived_from
 ├── represented_by
 └── manifested_as
```

These relationships may be represented through the Graph domain while remaining semantically associated with Data.

---

# 49. Core/Data Boundary

The distinction between Core and Data is:

```text
Core
  = foundational semantic primitives

Data
  = information-bearing structures built from those primitives
```

Core may define:

```text
identity
type
object
relation
operation
state
```

Data may define:

```text
sequence
set
map
record
schema
value collections
serialization
views
data transformations
```

The boundary must remain flexible enough to evolve as implementation exposes genuine semantic gaps.

---

# 50. Data/Domain Boundary

Data should not absorb domain semantics merely because a domain requires data.

For example:

```text
Image
    → Data + domain-specific representation

Tensor
    → Data + mathematical tensor semantics

Graph
    → Data + graph semantics

Spatial field
    → Data + spatial/field semantics
```

The correct architecture is composition rather than duplication.

---

# 51. Data Primitive Rule

Before creating a new Data primitive:

```text
Can an existing Core/Data primitive represent this concept
without semantic distortion?
```

If yes:

> Reuse it.

If no:

> Identify the semantic gap.

Then determine whether the gap belongs in:

```text
Core
Data
another domain
provider integration
application composition
```

A new primitive must not be introduced solely because a new implementation type is convenient.

---

# 52. Library Development Model

Data development follows:

```text
Describe
   ↓
Specify
   ↓
Implement in MLIR
   ↓
Verify
   ↓
Lift into Mojo
   ↓
Test
   ↓
Integrate with runtime/providers
   ↓
Validate
```

Development evidence must distinguish:

```text
specified
implemented
verified
tested
validated
```

---

# 53. Library Structure

The Data library follows the SCR library convention:

```text
lib/201_Data/
├── 101_spec.md
├── 102_status.yaml
├── 103_library.graph.json
└── ...
```

Subdomains should use the established SCR specification structure.

The implementation may contain separate areas for:

```text
definition
MLIR
verification
runtime
Mojo
tests
```

where appropriate.

The exact directory structure must follow the repository's current conventions.

---

# 54. Architectural Invariants

### DATA-I001 — Semantic Data

Data represents information as semantic structure, not merely physical bytes.

### DATA-I002 — Representation Independence

Semantic data is distinct from its physical representation.

### DATA-I003 — Identity Separation

Semantic identity is distinct from storage, memory, transport, and runtime handles.

### DATA-I004 — Structural Integrity

Data transformations must preserve all applicable structural invariants.

### DATA-I005 — Type Integrity

Data must remain consistent with its applicable semantic type constraints.

### DATA-I006 — Explicit Ownership

Ownership, reference, view, copy, and move semantics must not be conflated.

### DATA-I007 — Explicit Ordering

Ordering is semantic only when explicitly defined.

### DATA-I008 — Serialization Independence

Serialization format does not define semantic identity unless explicitly specified.

### DATA-I009 — Provenance Preservation

Transformations must preserve or explicitly transform applicable provenance.

### DATA-I010 — Manifestation Independence

Changing a physical manifestation does not inherently change semantic identity.

### DATA-I011 — MLIR Canonicality

The canonical implementation representation of Data semantics is SCR MLIR.

### DATA-I012 — Mojo Projection

Mojo exposes Data semantics without establishing an independent semantic data model.

### DATA-I013 — Primitive Reuse

Existing SCR semantic primitives must be reused where sufficient.

### DATA-I014 — Explicit Semantic Extension

New primitives require an identified semantic gap.

### DATA-I015 — Verifiability

Data semantics must have explicit verification criteria.

---

# 55. Completion Criteria

A Data capability intended for user-facing SCR development should not be considered complete until the applicable stages have been satisfied:

```text
[ ] Semantic meaning defined
[ ] Specification documented
[ ] Correct library/domain placement established
[ ] MLIR representation implemented
[ ] MLIR verification implemented
[ ] Relevant invariants identified
[ ] Tests implemented
[ ] Mojo API implemented
[ ] Mojo API is idiomatic
[ ] Mojo tests implemented
[ ] Runtime integration implemented where required
[ ] Provider integration implemented where required
[ ] End-to-end validation completed where required
[ ] Status recorded
```

Compiler-internal or implementation-only capabilities may omit the public Mojo stage where explicitly justified.

---

# 56. Final Principle

The Data library exists to make information computationally meaningful without collapsing semantic information into its physical representation.

The essential relationship is:

```text
                Information
                     │
                     ▼
                Semantic Data
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
       Structure   Relations   Values
          │          │          │
          └──────────┼──────────┘
                     ▼
                  MLIR
                     │
             verification /
             transformation
                     │
                     ▼
                Mojo API
                     │
                     ▼
              SCR Application
                     │
                     ▼
             Runtime Manifestation
```

The governing rule is:

> **Define data semantically, represent it canonically in MLIR, expose it naturally through Mojo, and allow runtime and provider layers to choose physical manifestations without changing the underlying meaning.**
