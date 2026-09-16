# Semantic Computational Runtime

# Interchange

**Document:** `lib/representation/interchange/101_spec.md`
**Version:** `0.1.0`
**Status:** Normative Semantic Specification
**Domain:** `representation.interchange`
**Parent Specification:** `lib/representation/101_spec.md`
**Architectural Authority:** `docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`

---

# 1. Purpose

This specification defines the semantic model for **interchange representations** within the Semantic Computational Runtime (SCR).

Interchange concerns the representation of semantic state for communication, exchange, import, export, migration, archival transfer, or interoperability between SCR and external systems.

The fundamental principle is:

> **An interchange representation encodes semantic information for exchange; it does not define the meaning of that information.**

SCR semantics remain authoritative.

An interchange format is therefore an external representation of SCR meaning rather than an alternative semantic ontology.

---

# 2. Scope

This specification defines:

1. interchange representations;
2. interchange sources and targets;
3. representation profiles;
4. interchange mappings;
5. import;
6. export;
7. transcoding;
8. semantic projection;
9. fidelity;
10. information loss;
11. opaque information;
12. provenance;
13. external references;
14. representation identity;
15. semantic identity;
16. interchange validation;
17. interchange conflicts;
18. versioning;
19. compatibility;
20. conformance;
21. interchange lifecycle;
22. interchange-specific invariants.

This specification does not define any particular interchange format.

Specific formats MUST be defined by subdomains.

Examples include:

```text
representation.interchange.gltf
representation.interchange.usd
representation.interchange.obj
representation.interchange.ply
```

---

# 3. Architectural Position

Interchange is a subdomain of representation.

The relationship is:

```text
SCR Semantic Domain
        │
        ▼
Representation
        │
        ▼
Interchange
        │
        ├── glTF
        ├── USD
        ├── OBJ
        ├── PLY
        └── other formats
```

The interchange domain MUST NOT become the semantic owner of concepts belonging to other domains.

For example:

```text
geometry
scene
material
texture
transform
spatial.coordinate
identity
provenance
```

remain owned by their respective semantic domains.

Interchange defines how those semantics may be represented and exchanged.

---

# 4. Fundamental Principle

The canonical interchange relationship is:

```text
External Representation
        │
        ▼
Representation Interpretation
        │
        ▼
SCR Semantic State
        │
        ▼
Semantic Transformation
        │
        ▼
Representation Encoding
        │
        ▼
External Representation
```

The semantic state is the authoritative middle layer.

An implementation MAY optimize this process by performing direct representation-to-representation transformations, but such optimizations MUST preserve the semantic guarantees declared by the applicable interchange profiles.

---

# 5. Interchange Representation

An interchange representation is a representation intended to communicate semantic information between independently operating systems, tools, runtimes, processes, storage systems, or applications.

Conceptually:

```text
InterchangeRepresentation =
    <RID,
     Format,
     FormatVersion,
     Profile,
     Content,
     Provenance>
```

where:

* `RID` is representation identity;
* `Format` identifies the external representation format;
* `FormatVersion` identifies the applicable format version;
* `Profile` identifies the SCR interpretation contract;
* `Content` contains the representation;
* `Provenance` describes its origin and derivation.

---

# 6. Interchange Does Not Imply Transport

An interchange representation MAY be transported by:

* filesystem;
* HTTP;
* AMQP;
* Hyrx;
* object storage;
* removable media;
* database;
* memory;
* direct process communication.

Transport and interchange are distinct.

Therefore:

```text
Interchange
≠
Transport
```

A glTF asset transported through AMQP remains a glTF interchange representation carried by an AMQP transport.

An AMQP message carrying semantic information does not thereby become an interchange format.

---

# 7. Interchange Does Not Imply Persistence

An interchange representation MAY be persistent, but persistence is not required.

For example:

```text
Semantic State
    ↓
Encode
    ↓
glTF representation
    ↓
Transmit
    ↓
Decode
```

The glTF representation may exist only transiently.

Therefore:

```text
Interchange
≠
Persistence
```

---

# 8. Interchange Does Not Imply Execution

An interchange representation MAY be optimized for runtime consumption.

This does not make it an execution representation.

For example, glTF is designed for efficient runtime asset delivery, but the semantic meaning of the represented scene remains distinct from the runtime mechanisms used to render or execute it.

Therefore:

```text
Interchange
≠
Execution
```

---

# 9. Semantic Ownership

The interchange domain owns concepts concerning:

* exchange;
* import;
* export;
* mapping;
* profiles;
* representability;
* interchange fidelity;
* interchange loss;
* interchange provenance;
* external references;
* interchange compatibility.

It MUST NOT redefine concepts owned by other SCR domains.

---

# 10. Interchange Mapping

An interchange mapping defines how a representation is interpreted as SCR semantic state.

Conceptually:

```text
InterchangeMapping =
    <SourceFormat,
     SourceVersion,
     Profile,
     TargetDomains,
     Rules,
     Preconditions,
     Preservation,
     Loss,
     Provenance>
```

A mapping MUST be identifiable and versioned.

A mapping MUST NOT be inferred solely from the name of a file format.

---

# 11. Mapping Direction

An interchange mapping MAY be:

```text
Import
Export
Bidirectional
Transcoding
```

### Import

```text
Representation → SCR Semantic State
```

### Export

```text
SCR Semantic State → Representation
```

### Bidirectional

Both mappings are explicitly defined.

Bidirectionality MUST NOT imply lossless round-trip behavior.

### Transcoding

```text
Representation A → Representation B
```

A transcoder MUST declare whether its result is:

* byte-equivalent;
* structurally equivalent;
* representation-equivalent;
* semantically equivalent;
* lossy.

---

# 12. Import

Import is the process of interpreting an interchange representation as SCR semantic state.

The normative conceptual pipeline is:

```text
External Bytes
      ↓
Parse
      ↓
Representation
      ↓
Representation Validation
      ↓
Profile Selection
      ↓
Mapping
      ↓
SCR Semantic Objects
      ↓
Semantic Validation
```

Each stage has a distinct responsibility.

---

# 13. Parse

Parsing establishes the structural representation.

Parsing MAY establish:

```text
syntax
structure
types
references
resource boundaries
format version
```

Parsing MUST NOT be treated as semantic interpretation.

Therefore:

```text
Parse(R)
```

does not imply:

```text
ValidSCR(Parse(R))
```

---

# 14. Representation Validation

The representation MUST be validated against the applicable external format before semantic interpretation is claimed.

Conceptually:

```text
ValidRepresentation(R)
```

A representation failing external format validation MUST NOT be silently treated as valid SCR semantic input.

A recovery mode MAY exist, but recovered information MUST be explicitly classified as recovered, uncertain, or implementation-defined.

---

# 15. Profile Selection

Import MUST occur under an identifiable interchange profile.

Conceptually:

```text
Profile(R, Context) → P
```

The profile determines:

* supported features;
* semantic mappings;
* unsupported features;
* loss behavior;
* opaque preservation;
* identity handling;
* provenance handling;
* version compatibility.

If no applicable profile exists, semantic import MUST fail rather than silently guessing.

---

# 16. Semantic Mapping

Mapping interprets representation structures as SCR semantic structures.

For example:

```text
External Node
    ↓
SCR Scene Node

External Mesh
    ↓
SCR Geometry Mesh

External Material
    ↓
SCR Material
```

A mapping MUST identify the semantic owner of each interpreted concept.

It MUST NOT create duplicate semantic definitions inside the interchange domain.

---

# 17. Export

Export converts SCR semantic state into an external interchange representation.

The normative conceptual pipeline is:

```text
SCR Semantic State
      ↓
Representability Analysis
      ↓
Semantic Projection, if required
      ↓
Representation Mapping
      ↓
Encoding
      ↓
Representation Validation
      ↓
Interchange Representation
```

Export MUST NOT silently discard semantic information when that information falls outside the declared fidelity of the export.

---

# 18. Representability

A semantic state is representable under an interchange profile if the profile provides a defined representation for the required semantic information.

Conceptually:

```text
Representable(S,P)
```

If:

```text
¬Representable(S,P)
```

the implementation MUST:

1. reject the export;
2. explicitly project to a representable subset;
3. preserve the unsupported information through an allowed opaque mechanism; or
4. select another representation profile.

Silent semantic truncation is prohibited.

---

# 19. Semantic Projection

A projection maps a semantic state to a semantically weaker or smaller state that is representable by the target interchange format.

Conceptually:

```text
Projection :
    SemanticState → SemanticSubset
```

For example:

```text
Full SCR Scene
    ↓
Renderable Scene Projection
    ↓
glTF
```

Projection MUST identify what semantic information has been removed.

Projection MUST NOT be presented as lossless interchange.

---

# 20. Information Loss

Information loss MUST be explicit.

Conceptually:

```text
Loss =
    <Concept,
     Cause,
     Scope,
     Recoverability>
```

Examples include:

```text
simulation state
    → no target representation

implicit geometry
    → explicit mesh approximation

higher precision
    → target-format quantization

execution state
    → omitted from interchange
```

The absence of information from an interchange representation MUST NOT automatically be interpreted as semantic absence in SCR.

---

# 21. Opaque Information

An interchange implementation MAY preserve information that SCR does not understand.

Such information MUST be represented as opaque information.

Opaque information:

* MAY be stored;
* MAY be transported;
* MAY be returned during export;
* MAY contribute to representation identity;
* MAY contribute to provenance.

Opaque information MUST NOT be interpreted as semantic information without an applicable mapping.

Therefore:

```text
Opaque
≠
Unknown semantic meaning inferred by implementation
```

---

# 22. Extension Semantics

Interchange formats MAY define extensions.

An interchange profile MUST distinguish:

```text
Supported
Recognized but unsupported
Unknown
Invalid
```

Supported extensions MAY be semantically mapped.

Recognized but unsupported extensions SHOULD be preserved opaquely where possible.

Unknown extensions SHOULD be preserved where the representation permits.

Invalid extensions MUST NOT be silently interpreted as valid semantic information.

---

# 23. External References

Interchange representations MAY contain references to resources outside the primary representation.

Examples:

```text
texture URI
buffer URI
asset reference
external layer
external archive
remote object
```

External references MUST be interpreted relative to an explicit resolution context.

The context MAY include:

```text
base URI
namespace
authority
credentials
network policy
resource resolver
version constraints
```

Resolution MUST NOT silently change semantic identity.

---

# 24. Reference Identity

An external reference is a representation-level relationship.

For example:

```text
asset.glb#/meshes/4
```

is a representation reference.

It is not automatically:

```text
SID(mesh)
```

A mapping MUST explicitly establish the relationship between external reference and SCR identity.

---

# 25. Representation Identity

Every imported or exported representation SHOULD have an identifiable representation identity.

Representation identity MAY be content-derived.

For example:

```text
RID = Hash(CanonicalRepresentation)
```

However:

```text
RID ≠ SID
```

must remain invariant.

---

# 26. Semantic Identity Preservation

Import SHOULD preserve semantic identity where the source representation contains sufficient identity/provenance information.

Where the external representation contains no authoritative SCR identity, the importer MAY establish a new SCR identity according to the applicable identity specification.

External array positions, object names, or memory addresses MUST NOT automatically become authoritative semantic identity.

---

# 27. Provenance

Import MUST establish provenance sufficient to identify:

* source representation;
* source format;
* format version;
* mapping profile;
* mapping version;
* source reference;
* import operation;
* relevant transformation context.

Conceptually:

```text
SCRObject
    └── derivedFrom
          └── InterchangeRepresentation
                └── interpretedBy
                      └── MappingProfile
```

Provenance is not semantic identity.

---

# 28. Provenance Preservation Through Export

When exporting a semantic object with existing provenance, the exporter SHOULD preserve provenance where the target format allows it.

If the target format cannot represent provenance semantically, provenance MAY be stored in:

* metadata;
* opaque extension data;
* external provenance records;
* SCR-side provenance graph.

Loss of provenance MUST be declared where material.

---

# 29. Versioning

Interchange has at least three independent version dimensions:

```text
External Format Version
SCR Interchange Profile Version
Implementation Version
```

These MUST NOT be conflated.

For example:

```text
glTF 2.0
SCR glTF Profile 0.1.0
Importer Implementation 0.4.3
```

represent three distinct version identities.

---

# 30. Compatibility

Compatibility MUST be evaluated explicitly.

An implementation MAY support:

```text
exact version
compatible minor version
compatible feature subset
profile-specific compatibility
```

Compatibility MUST NOT be inferred solely from a version string.

The profile MUST define the compatibility conditions.

---

# 31. Semantic Compatibility

Two representations MAY be externally compatible while being semantically incompatible with SCR.

Therefore:

```text
FormatCompatible
```

does not imply:

```text
SCRSemanticallyCompatible
```

A representation MUST satisfy both the external format requirements and the applicable SCR mapping requirements before semantic import is considered valid.

---

# 32. Representation Equivalence

Two interchange representations MAY be equivalent under a profile without being byte-identical.

The following hierarchy MUST remain distinct:

```text
ByteEqual
    ↓
StructurallyEqual
    ↓
RepresentationEquivalent
    ↓
SemanticallyEquivalent
```

The implications are not generally reversible.

A profile MUST define which equivalence relation applies to a claimed interoperability guarantee.

---

# 33. Round-Trip Semantics

Interchange profiles MUST state their round-trip guarantees.

Possible guarantees include:

### Byte round trip

```text
Encode(Decode(R)) = R
```

### Structural round trip

```text
Structure(Encode(Decode(R)))
    ≡
Structure(R)
```

### Representation-equivalent round trip

```text
Encode(Decode(R))
    ≈
R
```

### Semantic round trip

```text
Decode(Encode(S))
    ≡
S
```

A profile MUST NOT claim a stronger guarantee than its mapping actually establishes.

---

# 34. Import/Export Asymmetry

Import and export are not required to be inverses.

For example:

```text
External Representation
    ↓
Import
    ↓
SCR State
```

may preserve more information than:

```text
SCR State
    ↓
Export
    ↓
External Representation
```

because SCR may represent concepts outside the target format.

Therefore:

```text
Decode(Encode(S)) ≡ S
```

MUST NOT be assumed merely because:

```text
Encode(Decode(R))
```

is supported.

---

# 35. Transcoding

A direct transcoder MAY map:

```text
Representation A → Representation B
```

without constructing the complete semantic state.

However, the transcoder MUST have semantic guarantees equivalent to an accepted semantic pathway.

Where applicable:

```text
DecodeB(Transcode(A))
    ≈
DecodeA(A)
```

The equivalence relation MUST be identified.

---

# 36. Interchange Conflicts

When multiple representations describe the same semantic object but disagree, the implementation MUST NOT silently select one.

Possible conflict policies include:

```text
Reject
Prefer authoritative source
Prefer newest version
Merge
Create conflict state
Resolve through explicit authority
```

The selected policy MUST be explicit.

---

# 37. Authority

Ownership of an interchange representation does not establish authority over the represented semantic object.

For example:

```text
File Owner
    ≠
Semantic Owner

Exporter
    ≠
Semantic Authority

Latest File
    ≠
Authoritative Semantic State
```

Authority MUST be established according to the SCR authority and identity models.

---

# 38. Interchange Mutation

Modifying an interchange representation does not necessarily mutate the corresponding SCR semantic object.

Likewise, modifying an SCR semantic object does not modify an external representation unless an explicit export or synchronization transition occurs.

Therefore:

```text
Representation Mutation
≠
Semantic Mutation
```

unless an explicit semantic transition establishes that relationship.

---

# 39. Interchange Deletion

Deleting an interchange representation MUST NOT imply semantic deletion.

For example:

```text
delete(asset.glb)
```

does not imply:

```text
delete(SID(mesh))
```

unless the semantic lifecycle explicitly defines the representation as authoritative and its deletion as a semantic transition.

Likewise, semantic deletion does not automatically require deletion of all historical representations.

Historical representations MAY remain as provenance or archival artifacts.

---

# 40. Interchange History

An SCR implementation MAY retain previous interchange representations.

Historical representations MAY be used for:

* provenance;
* audit;
* rollback;
* reproducibility;
* comparison;
* migration;
* verification.

Historical representation retention MUST NOT be confused with current semantic state.

---

# 41. Canonicalization

A profile MAY define a canonical representation form.

Canonicalization MAY support:

* deterministic hashing;
* comparison;
* caching;
* reproducibility;
* deduplication;
* content addressing.

Canonicalization MUST NOT change semantic meaning.

Where canonicalization changes representation structure while preserving semantics, the profile MUST define the applicable equivalence relation.

---

# 42. Determinism

Where deterministic export is claimed, the implementation MUST define the scope of determinism.

Possible scopes include:

```text
byte deterministic
structurally deterministic
content deterministic
semantic deterministic
```

A semantic equivalence guarantee MUST NOT be confused with byte determinism.

---

# 43. Validation Model

Interchange validation has at least four stages:

```text
1. Format Validity
2. Mapping Validity
3. Semantic Validity
4. Conformance Validity
```

Conceptually:

```text
ValidFormat(R)
    ∧
Mappable(R,P)
    ∧
ValidSCR(Decode(R,P))
    ∧
Conforms(Adapter,P)
```

Only the complete chain establishes conformant semantic interchange.

---

# 44. Negative Semantics

The interchange specification MUST define failure conditions.

Examples:

```text
unsupported required feature
invalid external reference
unresolvable resource
semantic ambiguity
invalid identity mapping
incompatible version
lossless export impossible
invalid extension
conflicting representations
```

Failure MUST NOT silently produce a representation that is claimed to satisfy stronger guarantees.

---

# 45. Error Classification

Interchange errors SHOULD distinguish:

```text
ParseError
FormatValidationError
UnsupportedFeature
MappingError
ReferenceResolutionError
SemanticValidationError
RepresentabilityError
FidelityViolation
ConflictError
SecurityError
VersionCompatibilityError
```

An implementation MAY use different concrete error types, but the semantic distinction MUST remain observable.

---

# 46. Security Boundary

External interchange representations MUST be treated as untrusted input unless explicitly trusted.

An implementation MUST NOT assume:

```text
ValidFormat(R)
→
SafeExecution(R)
```

Import MUST establish semantic validity before execution.

Resource resolution MUST respect the applicable security and authority context.

External references MUST NOT automatically grant access to resources.

---

# 47. Resource Resolution

Resource resolution is an execution/service concern supporting interchange.

The interchange semantics require only that resolution be:

* explicit;
* attributable;
* context-dependent where required;
* failure-aware;
* provenance-preserving.

The actual resolver MAY be implemented by:

* filesystem provider;
* HTTP provider;
* object-store provider;
* database provider;
* SCR application;
* custom provider.

---

# 48. Interchange and Hypergraphs

Interchange representations MAY encode hypergraphs.

However, the external representation's graph model MUST NOT automatically replace SCR's hypergraph semantics.

If a format supports only binary edges while SCR requires higher-arity relationships, the mapping MUST explicitly encode the corresponding semantic relationship.

Likewise, nullary relations, deletion semantics, and reference semantics MUST follow the governing SCR hypergraph specification rather than assumptions inherited from an external file format.

---

# 49. Interchange and Nullary Relations

If an external representation can encode a relation with zero endpoints, its mapping MUST preserve the SCR nullary relation policy where the target semantic domain supports such relations.

If the external format cannot represent the relation:

1. the mapping MUST declare the limitation;
2. the relation MUST be preserved opaquely where possible; or
3. the mapping MUST explicitly declare semantic loss.

A nullary relation MUST NOT be silently converted into a unary or binary relation merely for representational convenience.

---

# 50. Interchange and Deletion Semantics

External deletion markers, tombstones, missing objects, or absent references MUST NOT automatically imply SCR semantic deletion.

Deletion MUST be interpreted according to the target semantic domain.

An interchange format that lacks explicit deletion semantics MUST NOT be treated as having them by inference.

---

# 51. Interchange and References

External references MUST be classified as:

```text
representation reference
semantic reference
resource reference
provenance reference
```

The mapping MUST identify which category applies.

A representation reference MUST NOT silently become a semantic relationship.

---

# 52. Interchange and Spatial Semantics

Interchange coordinates MUST be mapped into the SCR coordinate domain.

An external coordinate system MUST NOT become the universal SCR coordinate system.

A mapping SHOULD explicitly identify:

```text
axis convention
unit system
origin convention
handedness
transform convention
precision
reference frame
```

The distinction remains:

```text
External Coordinate System
    ≠
SCR Coordinate Semantics
```

---

# 53. Interchange and Spatial Partitioning

An interchange representation MAY encode spatial partitioning.

Such partitioning MUST NOT automatically become SCR computational partition identity.

For example:

```text
External tile
    ≠
SCR Partition
```

unless an explicit semantic mapping establishes the relationship.

The distinctions defined by the spatial architecture remain:

```text
Coordinate
≠
Partition
≠
State
≠
Execution Resource
```

---

# 54. Interchange and Authority

An external interchange document MAY contain authorship, ownership, or access metadata.

Such metadata MUST NOT automatically establish SCR authority.

The mapping MUST distinguish:

```text
external ownership metadata
semantic ownership
semantic authority
representation ownership
```

These concepts remain separate.

---

# 55. Interchange and Formalisation

Interchange mappings MAY be formally specified.

Formalisation SHOULD focus on:

* identity preservation;
* reference correctness;
* semantic preservation;
* loss characterization;
* round-trip properties;
* provenance;
* equivalence;
* canonicalization;
* conflict resolution.

Formalisation MUST remain subordinate to the normative semantic specification.

---

# 56. Formal Model

The interchange domain can be abstracted as:

```text
Interchange =
    <F,V,P,R,M,E,D,Q,L,O,C>
```

where:

```text
F = external formats
V = format versions
P = SCR interchange profiles
R = representations
M = mappings
E = encoders
D = decoders
Q = equivalence relations
L = loss/projection relations
O = provenance relations
C = compatibility relations
```

A mapping is conceptually:

```text
M :
    R × P × Context
      →
    SemanticState
```

An encoder is:

```text
E :
    SemanticState × P × Context
      →
    R
```

A validity predicate is:

```text
Valid :
    R × P → Prop
```

A representability predicate is:

```text
Representable :
    SemanticState × P → Prop
```

---

# 57. Formal Preservation

For a semantic property `Q`, an interchange profile MAY claim:

```text
Preserves(P,Q)
```

A lossless claim requires an appropriate proof or conformance argument that:

```text
Q(S)
→
Q(Decode(Encode(S,P)))
```

For full semantic equivalence:

```text
Decode(Encode(S,P))
    ≡
S
```

for the declared domain and equivalence relation.

---

# 58. Formalisation Levels

Interchange subdomains SHOULD use the following maturity model:

```text
none
described
axiomatized
modeled
proved
verified
```

Foundational interchange semantics SHOULD preferentially receive formal treatment.

Individual format adapters MAY remain at lower formalisation levels when the semantic risk is low.

---

# 59. Conformance

An interchange implementation conforms to this specification when:

1. its semantic mappings are explicit;
2. identity distinctions are preserved;
3. representation and semantic validity are separated;
4. fidelity claims are declared;
5. loss is explicit;
6. unsupported information is handled according to profile;
7. provenance requirements are satisfied;
8. reference semantics are explicit;
9. deletion semantics are explicit;
10. version compatibility is explicit;
11. declared round-trip guarantees are satisfied;
12. negative cases are tested;
13. semantic ownership remains with the appropriate SCR domains.

---

# 60. Conformance Evidence

Conformance SHOULD include:

```text
positive examples
negative examples
malformed representations
unsupported features
extension handling
identity tests
reference tests
deletion tests
provenance tests
loss tests
round-trip tests
equivalence tests
version compatibility tests
security tests
```

Where formalisation exists, proof artifacts SHOULD accompany the specification.

---

# 61. Library Integration

An interchange subdomain MUST follow the structure defined by `118_LIBRARY_DOMAIN_AND_SUBDOMAIN_MODEL`.

For example:

```text
lib/representation/interchange/
├── README.md
├── 101_spec.md
├── 102_status.yaml
├── 103_library.graph.json
│
├── gltf/
├── usd/
├── obj/
└── ply/
```

Each concrete format subdomain MUST define its own specification.

---

# 62. glTF as a Concrete Subdomain

glTF SHOULD be represented as:

```text
lib/representation/interchange/gltf/
```

Its specification MUST define:

* supported glTF versions;
* supported extensions;
* mapping to SCR geometry;
* mapping to SCR scene;
* mapping to SCR materials;
* mapping to SCR textures;
* mapping to transforms;
* mapping to animation;
* mapping to cameras;
* identity mapping;
* reference mapping;
* provenance;
* unsupported features;
* opaque extension preservation;
* fidelity;
* loss;
* round-trip guarantees;
* conformance tests.

The glTF specification itself remains external authority for glTF format semantics. The SCR glTF specification defines only the mapping into SCR semantics.

---

# 63. Development Sequence

A new interchange integration MUST follow:

```text
1. Identify external format
2. Identify external format version
3. Identify SCR semantic domains
4. Identify semantic owners
5. Define representation profile
6. Define import mappings
7. Define export mappings
8. Define reference semantics
9. Define identity semantics
10. Define deletion semantics
11. Define provenance
12. Define extension handling
13. Define fidelity
14. Define loss
15. Define round-trip guarantees
16. Define validation
17. Define conformance corpus
18. Formalise critical properties where justified
19. Implement parser
20. Implement mapper
21. Implement encoder
22. Validate
23. Verify
24. Update status and library graph
```

Implementation MUST NOT precede semantic definition of the mapping.

---

# 64. Agent Contract

An implementation agent working on an interchange subdomain MUST first inspect:

```text
parent 101_spec.md
relevant semantic domain specifications
103_library.graph.json
identity specification
reference semantics
deletion semantics
provenance semantics
representation specification
existing adapters
existing provider capabilities
```

The agent MUST NOT infer semantic definitions from:

* external file structures;
* parser APIs;
* existing implementation classes;
* provider data structures;
* database schemas;
* memory layouts.

The external format is evidence for a mapping, not authority over SCR semantics.

---

# 65. Required Development Questions

Before implementing an interchange format, the agent MUST be able to answer:

1. What SCR semantic concepts does the format represent?
2. Who owns those concepts semantically?
3. Which external structures map to those concepts?
4. Which external structures have no SCR semantic equivalent?
5. Which SCR concepts cannot be represented?
6. What information is lost?
7. What information is preserved opaquely?
8. How are identities established?
9. How are references established?
10. What happens when references break?
11. What happens when objects are deleted?
12. What provenance is created?
13. What versions are supported?
14. What extensions are supported?
15. What are the round-trip guarantees?
16. What equivalence relation is used?
17. What conflicts can occur?
18. What authority governs conflicting representations?
19. What properties are formally proven?
20. What provider mechanisms are required?

---

# 66. Normative Invariants

## INT-001 — Interchange Semantic Independence

Interchange representations MUST NOT define SCR semantic meaning.

## INT-002 — Explicit Mapping

Every semantic interpretation MUST occur through an identifiable mapping.

## INT-003 — Profile Identification

Every semantic interchange operation MUST identify its applicable profile.

## INT-004 — Identity Separation

Representation identity MUST remain distinct from semantic identity.

## INT-005 — Reference Separation

External representation references MUST remain distinct from semantic references unless explicitly mapped.

## INT-006 — Format Validation

External representation validity MUST be established before claiming semantic validity.

## INT-007 — Semantic Validation

Mapped semantic state MUST satisfy the invariants of its owning SCR domains.

## INT-008 — No Silent Loss

Material semantic loss MUST NOT be silently discarded.

## INT-009 — Explicit Projection

Lossy semantic projection MUST be explicit.

## INT-010 — Opaque Preservation

Information declared for opaque preservation MUST NOT be silently discarded.

## INT-011 — Provenance

Required interchange provenance MUST be preserved.

## INT-012 — Provenance Separation

Provenance MUST NOT redefine semantic identity.

## INT-013 — Version Separation

Format, profile, semantic, and implementation versions MUST remain distinct.

## INT-014 — Round-Trip Honesty

Round-trip claims MUST accurately reflect implementation guarantees.

## INT-015 — Equivalence Explicitness

Byte equality MUST NOT be substituted for semantic equivalence.

## INT-016 — Provider Independence

Interchange semantics MUST NOT depend on a particular provider.

## INT-017 — Parser Separation

Parsing MUST remain distinct from semantic interpretation.

## INT-018 — Export Representability

Export MUST establish representability or explicitly perform semantic projection.

## INT-019 — Conflict Explicitness

Conflicting representations MUST NOT be silently reconciled.

## INT-020 — Authority Separation

Representation ownership MUST NOT imply semantic authority.

## INT-021 — Deletion Separation

Representation deletion MUST NOT imply semantic deletion.

## INT-022 — Reference Lifecycle

Representation reference lifecycle MUST be distinct from semantic object lifecycle.

## INT-023 — Extension Honesty

Unsupported extensions MUST NOT be silently interpreted.

## INT-024 — Semantic Ownership

Interchange MUST NOT duplicate or redefine concepts owned by other semantic domains.

## INT-025 — Formalisation Integrity

Formal models MUST NOT silently redefine the normative specification.

## INT-026 — Provenance Traceability

Every imported semantic object MUST be traceable to its source representation when provenance is required by the profile.

## INT-027 — Loss Traceability

Declared information loss MUST be attributable to a defined mapping limitation or projection.

## INT-028 — Compatibility Explicitness

Format compatibility MUST NOT be inferred to imply SCR semantic compatibility.

## INT-029 — Determinism Honesty

Determinism claims MUST identify their scope.

## INT-030 — Semantic Round-Trip

Where semantic round-trip is claimed, the declared semantic equivalence MUST be preserved.

---

# 67. Summary Model

The interchange domain can be reduced to the following model:

```text
                    SCR SEMANTICS
                         │
                         │
                 ┌───────▼───────┐
                 │    MAPPING    │
                 └───────┬───────┘
                         │
                 ┌───────▼───────┐
                 │    PROFILE    │
                 └───────┬───────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
             glTF       USD        PLY
              │          │          │
              └──────────┼──────────┘
                         │
                    REPRESENTATION
                         │
                 ┌───────▼───────┐
                 │   TRANSPORT   │
                 │ / PERSISTENCE │
                 └───────────────┘
```

The semantic object remains authoritative throughout.

---

# 68. Final Principle

The interchange domain exists to make SCR interoperable without surrendering semantic authority.

Therefore:

> **SCR does not become compatible with an external format by adopting that format's ontology. SCR becomes compatible by defining an explicit, validated mapping between the external representation and SCR semantics.**

An external format may be widespread, efficient, mature, or highly expressive.

None of those properties make it the semantic authority for SCR.

The governing rule is:

> **Representations describe. Mappings interpret. Semantic domains define. Providers realize.**

And for interchange specifically:

> **Exchange the representation; preserve the meaning.**
