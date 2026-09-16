# Semantic Computational Runtime

# Serialization — Definition

**Document:** `representation/serialization/101_definition.md`
**Semantic ID:** `representation.serialization`
**Version:** `0.1.0`
**Status:** Normative Semantic Definition
**Parent Domain:** `representation`
**Related Domains:** `representation.interchange`, `representation.transport`, `representation.persistence`

---

# 1. Purpose

The `representation.serialization` subdomain defines the semantics of transforming structured information into a serialized representation and reconstructing structured information from that representation.

Serialization answers:

> **How is structured information encoded into a representation that can be stored, copied, transmitted, or otherwise materialized, and how can that representation be reconstructed?**

Serialization is concerned with **structural encoding and reconstruction**.

It does not define:

* the semantic meaning of the information;
* the interchange purpose of a representation;
* how information is transported;
* whether information is persistent;
* where information executes;
* which physical storage or communication mechanism is used.

The governing principle is:

> **Serialization encodes structure; it does not define semantics.**

---

# 2. Scope

This definition establishes the semantic foundations for:

* serialization;
* deserialization;
* encoded representations;
* serializers;
* deserializers;
* encoding schemes;
* decoding schemes;
* canonical serialization;
* deterministic serialization;
* schema association;
* version association;
* type preservation;
* structure preservation;
* identity preservation;
* reference preservation;
* null and absence semantics;
* ordering;
* numeric representation;
* binary and textual serialization;
* framing;
* length encoding;
* compression boundaries;
* serialization validation;
* serialization fidelity.

Concrete technologies such as:

* JSON;
* CBOR;
* MessagePack;
* Protocol Buffers;
* FlatBuffers;
* Cap'n Proto;
* BSON;
* Arrow IPC;
* custom binary formats;

are serialization formats or providers/implementations.

They do not define SCR semantic meaning.

---

# 3. Architectural Position

Serialization sits between structured representation and an encoded representation.

```text
Structured Information
        │
        ▼
 Serialization Semantics
        │
        ▼
Encoded Representation
        │
        ▼
Transport / Persistence / Interchange
```

The reverse direction is:

```text
Transport / Persistence / Interchange
        │
        ▼
Encoded Representation
        │
        ▼
 Deserialization Semantics
        │
        ▼
Structured Information
```

The fundamental distinction is:

```text
Semantic Meaning
    ≠
Structured Representation
    ≠
Serialization
    ≠
Transport
    ≠
Persistence
    ≠
Execution
```

---

# 4. Serialization Is Not Representation

Serialization produces a representation.

Serialization itself is the transformation that produces or reconstructs that representation.

Therefore:

```text
Serialization ≠ Representation
```

For example:

```text
Mesh
  │
  ▼
Serialize
  │
  ▼
Binary Representation
```

The binary representation is an artifact.

Serialization is the operation and contract governing its construction.

---

# 5. Serialization Is Not Interchange

A serialized representation may be used for interchange, but serialization does not imply interchange.

For example:

```text
Internal Runtime State
       ↓
Serialization
       ↓
Binary Memory Image
```

may be used only for local execution.

Conversely:

```text
SCR Semantic State
       ↓
Serialization
       ↓
glTF
```

may participate in interchange.

Therefore:

```text
Serialization ≠ Interchange
```

Interchange semantics determine the purpose and external compatibility contract.

---

# 6. Serialization Is Not Transport

Serialization creates an encoded representation.

Transport moves information.

Therefore:

```text
Serialization ≠ Transport
```

A serialized message MAY be transported by:

* AMQP;
* Hyrx;
* WebSocket;
* QUIC;
* TCP;
* shared memory.

Transport does not define the serialization semantics.

---

# 7. Serialization Is Not Persistence

Serialization MAY be used to create persistent data.

However:

```text
Serialization ≠ Persistence
```

For example:

```text
State
  ↓
Serialize
  ↓
Bytes
  ↓
Persist
```

Serialization creates the bytes.

Persistence establishes their lifetime guarantee.

---

# 8. Serialization Is Not Encoding in the Broadest Sense

Serialization is a structured transformation.

Generic encoding may transform arbitrary information without representing a structured object.

Examples include:

```text
Base64
Hexadecimal
Compression
Encryption
```

These MAY operate on serialized data.

Therefore:

```text
Serialization
    ≠
Arbitrary Encoding
```

A serialization format MAY itself define an encoding, but encoding alone does not imply serialization.

---

# 9. Structured Value

Serialization operates on a structured value or representation.

Conceptually:

```text
V =
    <Type,
     Value,
     Structure,
     References,
     Metadata>
```

The serialization contract defines which properties of `V` are represented in the encoded form.

---

# 10. Serialized Representation

A serialized representation is the result of applying a serialization contract to structured information.

Conceptually:

```text
SerializedRepresentation =
    <Format,
     Version,
     Schema,
     Encoding,
     Content>
```

The serialized representation MUST be distinguishable from the semantic object it represents.

---

# 11. Serialization Mapping

A serialization mapping defines the relationship between structured information and serialized content.

Conceptually:

```text
Serialize :
    Value × Schema × Context
        →
    SerializedRepresentation
```

and:

```text
Deserialize :
    SerializedRepresentation × Schema × Context
        →
    Value
```

A mapping MUST define:

* supported types;
* structural rules;
* ordering rules;
* reference rules;
* null semantics;
* absence semantics;
* numeric rules;
* encoding rules;
* version;
* error behavior.

---

# 12. Schema

A serialization schema describes the structure expected by a serialization format.

A schema MAY define:

* fields;
* types;
* cardinality;
* constraints;
* defaults;
* optionality;
* ordering;
* references;
* version compatibility.

A schema does not automatically define semantic meaning.

Therefore:

```text
Schema ≠ Semantic Ontology
```

An SCR semantic specification may define the meaning of a structure that is then serialized according to a schema.

---

# 13. Schema Identity

A schema MAY have its own identity.

Schema identity MUST remain distinct from:

```text
SemanticIdentity
RepresentationIdentity
ContentIdentity
SerializationIdentity
```

A schema change does not necessarily imply a semantic identity change.

---

# 14. Serialization Format

A serialization format defines the structural and encoding rules used to serialize information.

Examples include:

```text
JSON
CBOR
MessagePack
Protocol Buffers
FlatBuffers
Cap'n Proto
```

A serialization format MUST be treated as a representation mechanism rather than a semantic authority.

---

# 15. Binary Serialization

Binary serialization represents structured information using binary data.

Binary serialization MAY provide:

* compactness;
* efficient parsing;
* direct memory access;
* predictable layout;
* type tagging;
* efficient numerical representation.

Binary representation MUST NOT be confused with semantic meaning.

---

# 16. Text Serialization

Text serialization represents structured information using textual encoding.

Examples include:

```text
JSON
XML
YAML
CSV
```

Text representation MAY improve human inspection.

Human readability does not establish semantic correctness.

---

# 17. Deterministic Serialization

A serialization process is deterministic when the same input under the same serialization contract produces the same serialized result.

Conceptually:

```text
S(V,C) = R
```

and:

```text
S(V,C) = R
```

for every execution satisfying the contract.

Determinism MUST identify its scope.

Possible scopes include:

```text
ByteDeterministic
FieldOrderDeterministic
StructuralDeterministic
CanonicalDeterministic
```

---

# 18. Canonical Serialization

A canonical serialization defines one canonical serialized form for a given equivalence class of structured values.

Conceptually:

```text
Canonical(V) = R
```

Canonicalization MAY support:

* content hashing;
* signatures;
* deduplication;
* reproducibility;
* comparison;
* caching.

Canonical serialization MUST define:

* field ordering;
* numeric normalization;
* representation of optional values;
* whitespace rules;
* metadata rules;
* encoding;
* version.

---

# 19. Byte Equality

Byte equality means:

```text
R1 =bytes R2
```

Byte equality is stronger than structural equality in some contexts but does not imply semantic equality.

Therefore:

```text
ByteEquality
    ≠
StructuralEquality
    ≠
SemanticEquivalence
```

---

# 20. Structural Equality

Two serialized values may deserialize into structurally equal values even when their byte representations differ.

For example:

```text
{"a":1,"b":2}
```

and:

```text
{"b":2,"a":1}
```

may be structurally equivalent under a schema permitting unordered fields.

The serialization profile MUST explicitly define whether ordering is semantically relevant.

---

# 21. Deserialization

Deserialization reconstructs structured information from serialized content.

Conceptually:

```text
Serialized Representation
        │
        ▼
    Deserialize
        │
        ▼
Structured Value
```

Successful deserialization MUST NOT automatically imply semantic validity.

Therefore:

```text
DeserializationSuccess
    ≠
SemanticValidity
```

---

# 22. Parse and Deserialize

Parsing and deserialization are related but distinct.

Parsing identifies and validates serialized structure.

Deserialization reconstructs structured values.

A pipeline MAY be:

```text
Bytes
  ↓
Parse
  ↓
Validated Serialized Structure
  ↓
Deserialize
  ↓
Structured Value
```

A format MAY combine these operations operationally, but the semantic distinctions MUST remain available.

---

# 23. Type Preservation

A serialization contract MAY guarantee preservation of types.

For example:

```text
Int32
Float64
Boolean
String
Array
Map
Record
Reference
```

Type preservation MUST be explicit.

A serialization format MUST NOT silently change a type where the change can affect semantic interpretation.

---

# 24. Numeric Preservation

Numeric serialization MUST define:

* numeric domain;
* precision;
* range;
* signedness;
* overflow behavior;
* underflow behavior;
* NaN behavior;
* infinity behavior;
* rounding.

For example:

```text
Float32 → Float64
```

is not necessarily lossless.

Numeric conversion MUST therefore be treated as a potentially lossy transformation.

---

# 25. String Preservation

Serialization MUST define the character encoding and normalization rules applicable to strings.

Where Unicode is supported, the serialization profile SHOULD define:

* encoding;
* normalization expectations;
* invalid sequence behavior;
* null behavior;
* escaping.

A byte sequence that cannot be interpreted as valid text MUST NOT be silently repaired without declaring the recovery behavior.

---

# 26. Null Semantics

Serialization MUST distinguish where applicable between:

```text
Null
Absent
Empty
Default
Unknown
Invalid
```

These states MUST NOT be collapsed unless the schema explicitly declares them equivalent.

For example:

```text
field absent
    ≠
field = null
```

unless the serialization contract establishes that equivalence.

---

# 27. Optionality

Optional fields MUST have explicit semantics.

A field may be:

```text
Present
Absent
Null
Defaulted
```

The serializer and deserializer MUST agree on the interpretation.

Defaults MUST NOT silently create semantic state unless the governing semantic specification permits that interpretation.

---

# 28. Collection Semantics

Serialization MUST preserve the declared collection semantics.

Possible collection classes include:

```text
Sequence
Set
Multiset
Map
Tuple
Graph
Hyperedge
```

An unordered set MUST NOT silently become an ordered sequence if ordering has semantic significance.

Conversely, a sequence MUST NOT be treated as unordered unless explicitly permitted.

---

# 29. Map Ordering

Map key ordering MUST be explicit.

A serializer MAY:

* preserve insertion order;
* sort keys;
* use implementation-defined ordering;
* declare ordering irrelevant.

If canonical serialization is claimed, the ordering rule MUST be deterministic.

---

# 30. Reference Serialization

Structured values MAY contain references.

Serialization MUST define whether references are represented as:

* inline values;
* identifiers;
* offsets;
* indexes;
* URIs;
* handles;
* symbolic references.

External references MUST NOT automatically become SCR semantic references.

The governing distinction remains:

```text
SerializedReference
    ≠
SemanticReference
```

unless explicitly mapped.

---

# 31. Identity Serialization

Semantic identity MAY be serialized.

If an SCR SID is serialized, the serialization MUST preserve the SID according to the identity specification.

A serialization-specific object identifier MUST NOT be substituted for the SID without an explicit mapping.

Therefore:

```text
SerializedObjectID
    ≠
SID
```

unless the serialization contract explicitly preserves the SID itself.

---

# 32. Identity and Reconstruction

Deserialization MUST distinguish between:

```text
ReconstructExistingObject
CreateNewObject
CreateRepresentation
CreateReference
```

A serialized identifier MUST NOT automatically cause a new semantic object to be created.

Identity reconstruction is governed by the owning identity and lifecycle specifications.

---

# 33. Cyclic Structures

Serialization of cyclic graphs requires an explicit strategy.

Possible strategies include:

```text
ReferenceEncoding
ObjectTable
GraphIndex
CycleRejection
CycleExpansion
```

A serializer MUST NOT silently duplicate objects merely to eliminate cycles if doing so changes semantic identity.

---

# 34. Shared References

If multiple references point to the same object:

```text
A ──┐
    ├──→ X
B ──┘
```

the serialization MAY preserve:

```text
A ──┐
    ├──→ X
B ──┘
```

or may duplicate the representation.

If duplication occurs, the mapping MUST declare whether semantic identity is preserved.

Representation duplication MUST NOT silently become semantic object duplication.

---

# 35. Hypergraph Serialization

SCR hypergraphs MAY be serialized.

The serialization MUST preserve the semantics required by the hypergraph specification.

In particular:

* hyperedge identity;
* endpoint sets;
* endpoint multiplicity where relevant;
* labels;
* attributes;
* nullary relations;
* references;
* deletion semantics;

MUST NOT be silently altered.

A serialization format supporting only ordinary graphs MAY require an explicit projection or encoding strategy for hypergraphs.

---

# 36. Nullary Relations

If the serialized structure represents a nullary relation, its semantics MUST be preserved.

A nullary relation MUST NOT be transformed into:

* an empty node;
* a placeholder edge;
* a Boolean;
* an empty collection;

unless the serialization mapping explicitly establishes semantic equivalence.

---

# 37. Serialization of Deletion

Deletion state MAY be serialized.

Examples include:

```text
Tombstone
DeletionRecord
AbsentObject
LifecycleState
```

The serialization MUST distinguish representation of deletion from actual semantic deletion.

A serialized tombstone is information.

It does not itself perform the semantic deletion.

---

# 38. Versioning

Serialization formats and schemas evolve.

The following versions MUST remain distinguishable:

```text
SerializationFormatVersion
SchemaVersion
SemanticVersion
RepresentationVersion
ImplementationVersion
```

Therefore:

```text
SerializationVersion
    ≠
SemanticVersion
```

---

# 39. Compatibility

A serialization implementation SHOULD define compatibility classes such as:

```text
ReadCompatible
WriteCompatible
RoundTripCompatible
StructurallyCompatible
SemanticallyCompatible
```

These properties MUST NOT be conflated.

A schema MAY be readable by a newer implementation while not being safely writable by it.

---

# 40. Forward Compatibility

A serializer/deserializer MAY support fields or structures introduced by later schema versions.

Unknown fields MAY be:

* rejected;
* ignored;
* preserved;
* stored opaquely.

If unknown information can be preserved, the mechanism SHOULD do so where the profile requires round-trip fidelity.

---

# 41. Backward Compatibility

A newer implementation MAY deserialize older serialized representations.

If migration or default insertion is required, that behavior MUST be explicit.

A successful deserialization does not necessarily imply semantic equivalence with the original state.

---

# 42. Unknown Fields

Unknown fields SHOULD be preserved when round-trip fidelity requires them.

Unknown fields MUST NOT be interpreted as known semantics without an applicable schema or profile.

Therefore:

```text
Unknown ≠ Invalid
```

and:

```text
Unknown ≠ Known
```

---

# 43. Serialization Loss

Serialization MAY be lossy.

Possible causes include:

* precision conversion;
* unsupported types;
* unsupported references;
* schema projection;
* truncation;
* normalization;
* default substitution;
* unknown-field removal.

Loss MUST be explicit where it affects semantic or declared representation fidelity.

---

# 44. Serialization Fidelity

A serialization profile MAY define:

### Exact reconstruction

```text
Deserialize(Serialize(V)) ≡ V
```

### Structural equivalence

```text
Deserialize(Serialize(V)) ≈ V
```

### Subset preservation

```text
Deserialize(Serialize(V)) ⊑ V
```

### Opaque preservation

Unsupported information remains available without semantic interpretation.

A profile MUST NOT claim stronger fidelity than it provides.

---

# 45. Serialization and Compression

Compression MAY be applied before or after serialization.

For example:

```text
Structured State
      ↓
Serialize
      ↓
Compress
      ↓
Bytes
```

or:

```text
Serialized Data
      ↓
Compress
      ↓
Transport
```

Compression is not serialization.

Therefore:

```text
Compression ≠ Serialization
```

Lossless compression MUST preserve serialized bytes.

Lossy compression MUST be treated as an explicit potentially lossy transformation.

---

# 46. Serialization and Encryption

Encryption MAY protect serialized content.

Conceptually:

```text
Structured State
      ↓
Serialize
      ↓
Encrypt
      ↓
Ciphertext
```

Encryption is not serialization.

Therefore:

```text
Encryption ≠ Serialization
```

Decryption MUST precede deserialization where encryption applies to the serialized representation.

---

# 47. Framing

Framing establishes boundaries between serialized units.

Examples include:

```text
LengthPrefix
Delimiter
RecordBoundary
MessageBoundary
ContainerBoundary
```

Framing is distinct from serialization semantics.

Therefore:

```text
Framing ≠ Serialization
```

A transport may provide framing independently of the serialization format.

---

# 48. Streaming Serialization

A serializer MAY produce serialized output incrementally.

Conceptually:

```text
Value
 │
 ├── chunk 1
 ├── chunk 2
 ├── chunk 3
 └── ...
```

Streaming serialization MUST define:

* ordering;
* boundaries;
* partial state;
* completion;
* cancellation;
* error behavior.

Partial serialized output MUST NOT be treated as a complete representation unless the format explicitly supports incremental validity.

---

# 49. Incremental Deserialization

A deserializer MAY reconstruct values incrementally.

The implementation MUST distinguish:

```text
Incomplete
ValidPartial
Complete
Invalid
```

A partially reconstructed object MUST NOT automatically be treated as a complete semantic state.

---

# 50. Canonicalization and Hashing

Canonical serialization MAY be used to derive content identity.

For example:

```text
CID = Hash(CanonicalSerialize(V))
```

This creates content identity.

It does not create semantic identity.

Therefore:

```text
CID ≠ SID
```

---

# 51. Serialization Provenance

Serialization SHOULD preserve sufficient provenance where required.

Possible provenance includes:

```text
Serializer
Format
FormatVersion
Schema
SchemaVersion
SerializationProfile
Timestamp
SourceRepresentation
```

Serialization provenance is distinct from semantic provenance.

---

# 52. Serialization Authority

The serializer is not automatically authoritative over the serialized semantics.

Therefore:

```text
Serializer ≠ SemanticAuthority
```

A serializer may faithfully encode semantic state while having no authority to modify or define that state.

---

# 53. Serialization Ownership

Ownership of serialized bytes does not imply ownership of the semantic object.

Therefore:

```text
SerializedDataOwner
    ≠
SemanticOwner
```

unless explicitly established by the applicable authority model.

---

# 54. Security Boundary

Serialized input MUST be treated as untrusted unless the receiving context establishes trust.

The following implication is invalid:

```text
ValidSerialization
    →
SafeSemanticState
```

Deserialization MUST enforce:

* resource limits;
* size limits;
* nesting limits;
* recursion limits;
* allocation limits;
* numeric validation;
* reference validation;
* schema validation.

Where relevant, implementations MUST protect against:

* decompression bombs;
* resource exhaustion;
* malicious nesting;
* integer overflow;
* invalid references;
* cyclic allocation attacks.

---

# 55. Validation

Serialization validation SHOULD occur at multiple levels:

```text
1. Byte / encoding validity
2. Format validity
3. Schema validity
4. Structural validity
5. Reference validity
6. Representation validity
7. Semantic validity
```

These levels MUST NOT be conflated.

For example:

```text
SchemaValid
    ≠
SemanticValid
```

---

# 56. Serialization and Providers

Providers implement serialization mechanisms.

Examples include:

```text
JSON Library
CBOR Library
Protocol Buffers Runtime
MessagePack Library
Arrow
Custom Binary Serializer
```

The provider relationship is:

```text
Serialization Semantics
        ↓
Serialization Specification
        ↓
Provider / Implementation
        ↓
Encoded Bytes
```

Providers MUST NOT redefine semantic meaning.

---

# 57. Serialization and STC

Serialization operations MAY be modeled as semantic transitions where serialization itself is part of a semantic workflow.

Examples include:

```text
τserialize
τdeserialize
τcanonicalize
τvalidate
τmigrate
```

These operations MUST use the existing Semantic Transition Calculus.

Serialization MUST NOT introduce a second transition model.

Applicability and consent remain governed by:

```text
Applicable(τ,S,C)
Consents(τ,S,C,K)
```

---

# 58. Serialization Consequences

Serialization operations MAY produce consequences such as:

```text
Serialized
Deserialized
Canonicalized
SerializationValidated
DeserializationFailed
SerializationLossDetected
SchemaMigrated
```

These are domain-level consequences.

They MUST NOT replace the GMKernel edge model.

---

# 59. Formal Model

The serialization domain MAY be modeled as:

```text
Serialization =
    <V,R,F,S,E,D,Q,L,P,C>
```

where:

```text
V = structured values
R = serialized representations
F = serialization formats
S = schemas
E = encoders
D = decoders
Q = equivalence relations
L = loss relations
P = preservation properties
C = compatibility relations
```

Serialization:

```text
Serialize :
    V × F × S × Ctx → R
```

Deserialization:

```text
Deserialize :
    R × F × S × Ctx → V
```

Validity:

```text
ValidSerialized :
    R × F × S → Prop
```

Round-trip equivalence:

```text
RoundTripEquivalent :
    V × F × S → Prop
```

---

# 60. Formal Preservation

A serialization profile MAY claim preservation of properties such as:

```text
Type
Structure
Identity
References
Ordering
NumericPrecision
NullSemantics
CollectionSemantics
HypergraphStructure
```

Each preservation claim MUST identify:

* scope;
* assumptions;
* profile;
* version;
* evidence.

---

# 61. Lean Formalisation

Lean formalisation SHOULD be considered for:

* canonical serialization;
* deterministic serialization;
* schema compatibility;
* round-trip properties;
* type preservation;
* reference preservation;
* identity preservation;
* numeric conversion guarantees;
* null/absence semantics;
* hypergraph serialization;
* loss detection.

Lean MUST formalize the normative semantics rather than silently redefining them.

---

# 62. Formalisation Maturity

Serialization subdomains MAY use:

```text
none
described
axiomatized
modeled
proved
verified
```

Formalisation effort SHOULD be proportional to:

* semantic centrality;
* interoperability importance;
* security risk;
* complexity;
* claimed guarantees.

---

# 63. Conformance

A serialization implementation conforms to this definition when:

1. serialization is distinguished from representation;
2. serialization is distinguished from interchange;
3. serialization is distinguished from transport;
4. serialization is distinguished from persistence;
5. schemas are explicit;
6. format versions are explicit;
7. type semantics are explicit;
8. null and absence semantics are explicit;
9. reference semantics are explicit;
10. identity semantics are explicit;
11. loss is explicit;
12. fidelity claims are honest;
13. validation boundaries are explicit;
14. security constraints are enforced;
15. provider mechanisms do not redefine semantic meaning.

---

# 64. Normative Invariants

## SER-001 — Semantic Independence

Serialization MUST NOT define the semantic meaning of serialized information.

## SER-002 — Representation Separation

Serialization MUST remain distinct from representation.

## SER-003 — Interchange Separation

Serialization MUST remain distinct from interchange.

## SER-004 — Transport Separation

Serialization MUST remain distinct from transport.

## SER-005 — Persistence Separation

Serialization MUST remain distinct from persistence.

## SER-006 — Schema Explicitness

Serialization MUST identify the schema or structural contract applicable to the serialized value where required.

## SER-007 — Version Separation

Serialization format, schema, semantic, representation, and implementation versions MUST remain distinct.

## SER-008 — Type Preservation

Declared type-preservation guarantees MUST be satisfied.

## SER-009 — Null Explicitness

Null, absence, empty, default, unknown, and invalid states MUST NOT be silently conflated.

## SER-010 — Reference Separation

Serialized references MUST remain distinct from semantic references unless explicitly mapped.

## SER-011 — Identity Separation

Serialization identity MUST remain distinct from semantic identity.

## SER-012 — Shared Identity Preservation

Serialization MUST NOT silently duplicate a shared semantic object where identity preservation is claimed.

## SER-013 — Cycle Explicitness

Cyclic structures MUST have explicit serialization semantics.

## SER-014 — Ordering Explicitness

Ordering guarantees MUST be explicitly defined.

## SER-015 — Numeric Fidelity

Numeric precision, range, conversion, and loss behavior MUST be explicit.

## SER-016 — Collection Semantics

Collection ordering and multiplicity MUST preserve the declared semantics.

## SER-017 — Unknown-Field Honesty

Unknown fields MUST NOT be interpreted without an applicable schema or profile.

## SER-018 — Loss Explicitness

Material serialization loss MUST be explicit.

## SER-019 — Fidelity Honesty

Round-trip and preservation guarantees MUST accurately describe actual behavior.

## SER-020 — Determinism Honesty

Determinism claims MUST identify their scope and actual guarantees.

## SER-021 — Canonicalization Explicitness

Canonical serialization MUST define the canonicalization rules.

## SER-022 — Compression Separation

Compression MUST remain distinct from serialization.

## SER-023 — Encryption Separation

Encryption MUST remain distinct from serialization.

## SER-024 — Framing Separation

Framing MUST remain distinct from serialization.

## SER-025 — Validation Separation

Serialization validity MUST remain distinct from semantic validity.

## SER-026 — Provenance Separation

Serialization provenance MUST remain distinct from semantic provenance.

## SER-027 — Authority Separation

Serializer ownership or operation MUST NOT imply semantic authority.

## SER-028 — Provider Independence

Serialization semantics MUST remain independent of a particular provider.

## SER-029 — STC Compatibility

Serialization transitions MUST remain compatible with the Semantic Transition Calculus.

## SER-030 — Reconstruction Validity

Deserialized state MUST be validated before being treated as valid SCR semantic state.

---

# 65. Library Integration

The serialization subdomain belongs beneath:

```text
representation/
```

with the canonical structure:

```text
representation/serialization/
├── README.md
├── 101_definition.md
├── 102_status.yaml
└── 103_library.graph.json
```

Concrete serialization technologies MAY be represented as subdomains where they have sufficient semantic scope:

```text
serialization.json
serialization.cbor
serialization.protobuf
serialization.messagepack
serialization.arrow
serialization.binary
```

Technology-specific subdomains MUST refine rather than redefine the parent serialization semantics.

---

# 66. Relationship to Interchange

The relationship is:

```text
Semantic State
      │
      ▼
Representation
      │
      ▼
Serialization
      │
      ▼
Serialized Representation
      │
      ▼
Interchange
```

However, serialization does not imply interchange.

An interchange representation may use serialization internally, but the interchange profile determines the external semantic mapping.

---

# 67. Relationship to Transport

The relationship is commonly:

```text
Structured Message
      │
      ▼
Serialize
      │
      ▼
Serialized Payload
      │
      ▼
Transport
      │
      ▼
Serialized Payload
      │
      ▼
Deserialize
      │
      ▼
Structured Message
```

Transport moves the serialized payload.

Serialization defines its structural encoding.

---

# 68. Relationship to Persistence

The relationship is commonly:

```text
Semantic State
      │
      ▼
Serialize
      │
      ▼
Serialized Representation
      │
      ▼
Persist
      │
      ▼
Persistent Representation
```

Serialization defines the encoding.

Persistence establishes the lifetime guarantee.

---

# 69. Relationship to Execution

Serialization MAY cross execution boundaries.

For example:

```text
Execution Context A
      │
      ▼
Serialize
      │
      ▼
Transport
      │
      ▼
Deserialize
      │
      ▼
Execution Context B
```

Serialization does not execute the serialized content.

Executable content remains subject to execution and security semantics.

---

# 70. Minimum Viable Serialization

The minimum SCR serialization implementation SHOULD demonstrate:

```text
Structured Value
      │
      ▼
Serialize
      │
      ▼
Encoded Representation
      │
      ▼
Deserialize
      │
      ▼
Structured Value
```

It MUST demonstrate:

* schema identification;
* deterministic behavior or an explicit declaration that determinism is not guaranteed;
* type preservation;
* null/absence handling;
* malformed-input rejection;
* round-trip testing;
* identity/reference behavior;
* loss detection.

---

# 71. Development Sequence

A concrete serialization implementation SHOULD follow:

```text
1. Identify structured input domain
2. Identify semantic owners
3. Define serialization scope
4. Define format
5. Define schema
6. Define version
7. Define type mappings
8. Define collection semantics
9. Define null/absence semantics
10. Define reference semantics
11. Define identity semantics
12. Define cycle semantics
13. Define ordering
14. Define numeric representation
15. Define encoding
16. Define canonicalization
17. Define determinism
18. Define compatibility
19. Define fidelity
20. Define loss
21. Define validation
22. Define security limits
23. Define round-trip guarantees
24. Define conformance tests
25. Formalise critical properties where justified
26. Implement serializer
27. Implement deserializer
28. Validate
29. Verify
30. Update status
31. Update library graph
```

Implementation MUST NOT be allowed to define semantic meaning implicitly.

---

# 72. Development Agent Contract

An agent implementing serialization MUST inspect:

```text
Parent representation specification
Serialization definition
Relevant semantic domain specifications
Identity specification
Reference specification
Hypergraph specification
Schema/profile specification
Interchange specification, where applicable
Persistence specification, where applicable
Transport specification, where applicable
Existing serializers
Provider capabilities
```

The agent MUST distinguish:

```text
Semantic Definition
Serialization Schema
Serialized Representation
Implementation Data Structure
Provider Data Structure
```

These MUST NOT be collapsed.

---

# 73. Required Development Questions

Before implementation, the agent MUST answer:

1. What structured information is being serialized?
2. Who owns its semantics?
3. What structural information is preserved?
4. What information is not representable?
5. What is the schema?
6. What is the format version?
7. What is the schema version?
8. What types are supported?
9. How are null and absence represented?
10. How are references represented?
11. How are identities represented?
12. How are shared references preserved?
13. How are cycles represented?
14. Is ordering significant?
15. What numeric precision is preserved?
16. What is the canonical form?
17. Is serialization deterministic?
18. What are the compatibility guarantees?
19. What are the round-trip guarantees?
20. What information can be lost?
21. How is loss detected?
22. What malformed inputs are rejected?
23. What security limits apply?
24. What properties are formally verified?
25. Which provider capabilities are required?

---

# 74. Final Definition

Serialization is the semantic capability by which structured information is transformed into an encoded representation and subsequently reconstructed under an explicit structural, type, schema, version, and fidelity contract.

The essential relationship is:

```text
Structured Information
        │
        ▼
   Serialization
        │
        ▼
Encoded Representation
        │
        ▼
  Deserialization
        │
        ▼
Structured Information
```

The governing distinctions are:

```text
Meaning
   ≠
Representation
   ≠
Serialization
   ≠
Interchange
   ≠
Transport
   ≠
Persistence
   ≠
Execution
   ≠
Provider
```

And the governing principle is:

> **Serialization encodes structure. Deserialization reconstructs structure. Schemas define structural contracts. Semantic domains define meaning. Interchange defines exchange contracts. Transport moves information. Persistence preserves information across lifetime boundaries. Providers supply the mechanisms.**
