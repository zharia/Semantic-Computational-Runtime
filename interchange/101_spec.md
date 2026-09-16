# Semantic Computational Runtime

# Interchange Representation

**Document:** `lib/representation/interchange/101_spec.md`
**Semantic ID:** `representation.interchange`
**Version:** `0.1.0`
**Status:** Normative Semantic Specification
**Parent Domain:** `representation`
**Architectural Authority:** `docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`

---

# 1. Purpose

The `representation.interchange` domain defines the semantics of representations intended to exchange semantic information between SCR instances, applications, runtimes, tools, storage systems, and external systems.

Interchange provides a semantic boundary between **SCR meaning** and **external representation formats**.

The fundamental principle is:

> **Interchange represents semantic information for exchange; it does not define the meaning of the information being exchanged.**

SCR semantic domains remain authoritative.

External formats such as glTF, USD, OBJ, PLY, GeoJSON, and other formats are therefore representations of SCR semantic state rather than alternative definitions of SCR semantics.

---

# 2. Scope

This specification defines:

* interchange representations;
* interchange sources and targets;
* representation profiles;
* interchange mappings;
* import;
* export;
* transcoding;
* semantic projection;
* representability;
* fidelity;
* information loss;
* opaque information;
* provenance;
* external references;
* representation identity;
* semantic identity;
* versioning;
* compatibility;
* conflict handling;
* validation;
* conformance;
* interchange lifecycle.

This specification does **not** define the semantics of individual interchange formats.

Individual formats MUST be specified by subdomains.

Examples:

```text
representation.interchange.gltf
representation.interchange.usd
representation.interchange.obj
representation.interchange.ply
```

---

# 3. Semantic Ownership

The `representation.interchange` domain owns the semantics of **interchange as an architectural activity**.

It owns concepts including:

* interchange representation;
* import;
* export;
* transcoding;
* representation mapping;
* interchange profile;
* representability;
* fidelity;
* semantic projection;
* interchange loss;
* opaque preservation;
* interchange provenance;
* interchange compatibility;
* interchange conformance.

It MUST NOT define the semantics of concepts owned by other SCR domains.

For example:

```text
geometry
scene
material
texture
transform
identity
reference
topology
spatial coordinate
spatial partition
authority
ownership
```

remain owned by their respective domains.

Interchange defines how such concepts may be represented and exchanged.

---

# 4. Architectural Principle

The canonical interchange relationship is:

```text
SCR Semantic State
       │
       ▼
Interchange Mapping
       │
       ▼
External Representation
       │
       │ exchange
       ▼
External Representation
       │
       ▼
Interchange Mapping
       │
       ▼
SCR Semantic State
```

The semantic state remains authoritative.

An implementation MAY optimize this process by transforming one representation directly into another, but the resulting operation MUST preserve the semantic guarantees declared by the applicable mappings and profiles.

---

# 5. Interchange Representation

An interchange representation is a representation intended for exchange of semantic information between independently operating systems, processes, applications, runtimes, tools, or storage systems.

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
* `Format` identifies the representation format;
* `FormatVersion` identifies the applicable external format version;
* `Profile` identifies the SCR interpretation contract;
* `Content` is the representation content;
* `Provenance` describes origin and derivation.

---

# 6. Interchange Is Not Transport

Interchange and transport are separate semantic concepts.

An interchange representation MAY be transported by:

* filesystem;
* HTTP;
* AMQP;
* Hyrx;
* object storage;
* database;
* memory;
* removable media;
* direct process communication.

Therefore:

```text
Interchange ≠ Transport
```

For example:

```text
glTF
  ↓
AMQP
```

means that a glTF interchange representation is transported using AMQP.

AMQP does not thereby become the semantic definition of glTF.

---

# 7. Interchange Is Not Persistence

An interchange representation MAY be persistent, but persistence is not required.

An interchange representation MAY exist only long enough to cross a process or system boundary.

Therefore:

```text
Interchange ≠ Persistence
```

Persistence is governed by the appropriate representation/persistence domain.

---

# 8. Interchange Is Not Execution

An interchange format MAY be optimized for runtime consumption.

That does not make it an execution representation.

Therefore:

```text
Interchange ≠ Execution
```

Execution representations remain governed by the execution architecture.

---

# 9. Representation Identity

Every interchange representation SHOULD have an identifiable representation identity.

Conceptually:

```text
RID : Representation → Identity
```

Representation identity MAY be derived from:

* canonical content;
* content hash;
* external identifier;
* persistence identity;
* allocation identity;
* explicit representation identity.

Representation identity MUST remain distinct from semantic identity.

```text
RepresentationIdentity ≠ SemanticIdentity
```

---

# 10. Semantic Identity

The semantic identity of an object is defined by the owning SCR semantic domain.

An external representation identifier MUST NOT automatically become an SCR semantic identifier.

Examples of external identifiers include:

* array indices;
* object names;
* node IDs;
* offsets;
* URIs;
* database IDs;
* provider IDs;
* memory addresses.

These MAY be retained as representation metadata or provenance.

They MUST NOT silently become semantic identity.

---

# 11. Content Identity

Content identity identifies a particular content state.

For example:

```text
CID = Hash(RepresentationContent)
```

Content identity MAY be useful for:

* caching;
* deduplication;
* integrity;
* addressing;
* synchronization.

However:

```text
ContentIdentity ≠ SemanticIdentity
```

---

# 12. Representation Reference

A representation reference identifies something within or relative to a representation.

Examples:

```text
asset.glb
asset.glb#/meshes/4
scene.usd:/World/Robot
buffer.bin[offset,length]
```

A representation reference is not automatically a semantic reference.

Therefore:

```text
RepresentationReference
    ≠
SemanticReference
```

unless an explicit mapping establishes the relationship.

---

# 13. Representation Mapping

An interchange mapping defines how representation structures correspond to SCR semantic structures.

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

A mapping MUST explicitly define:

1. source representation;
2. target semantic domains;
3. interpretation rules;
4. applicability conditions;
5. supported features;
6. unsupported features;
7. fidelity guarantees;
8. loss conditions;
9. provenance behavior;
10. identity behavior;
11. reference behavior.

---

# 14. Representation Profile

An interchange profile defines the contract under which a format is interpreted by SCR.

Conceptually:

```text
Profile =
    <Format,
     Version,
     Features,
     Mappings,
     Fidelity,
     Loss,
     Extensions,
     Provenance,
     Compatibility>
```

A profile MUST be identifiable.

A format name alone MUST NOT determine semantic interpretation.

---

# 15. Format Version and Profile Version

External format version and SCR profile version are distinct.

For example:

```text
External Format:
    glTF 2.0

SCR Profile:
    SCR glTF Core 0.1.0
```

The following MUST remain distinct:

```text
ExternalFormatVersion
≠
InterchangeProfileVersion
≠
ImplementationVersion
≠
SemanticVersion
```

---

# 16. Parsing

Parsing converts external content into a representation structure.

Conceptually:

```text
Bytes
  ↓
Parser
  ↓
Representation
```

Parsing MAY establish:

* syntax;
* structural relationships;
* types;
* references;
* resource boundaries;
* format version.

Parsing MUST NOT by itself establish semantic validity.

Therefore:

```text
ValidRepresentation
≠
ValidSCRState
```

---

# 17. Import

Import maps an interchange representation into SCR semantic state.

The normative pipeline is:

```text
External Content
      ↓
Parse
      ↓
Representation Validation
      ↓
Profile Selection
      ↓
Semantic Mapping
      ↓
SCR Semantic State
      ↓
Semantic Validation
```

Import MUST NOT skip semantic validation.

---

# 18. Representation Validation

The representation MUST first satisfy the requirements of the external format or the explicitly declared recovery mode.

Conceptually:

```text
ValidRepresentation(R)
```

An invalid representation MUST NOT be silently treated as a valid semantic source.

A recovery mode MAY exist.

Recovered information MUST be explicitly classified as recovered or uncertain and MUST NOT silently receive stronger guarantees.

---

# 19. Mapping Validation

After representation validation, the system MUST determine whether the representation can be interpreted under the selected profile.

Conceptually:

```text
Mappable(R,P)
```

A representation MAY be externally valid but not mappable into SCR.

Therefore:

```text
ValidRepresentation(R)
```

does not imply:

```text
Mappable(R,P)
```

---

# 20. Semantic Validation

The semantic result of import MUST satisfy the invariants of its owning SCR domains.

Conceptually:

```text
ValidRepresentation(R)
∧
Mappable(R,P)
→
ValidSCR(Decode(R,P))
```

If semantic validation fails, import MUST NOT claim successful semantic conformance.

---

# 21. Export

Export maps SCR semantic state into an interchange representation.

The normative pipeline is:

```text
SCR Semantic State
      ↓
Representability Analysis
      ↓
Semantic Projection, if required
      ↓
Interchange Mapping
      ↓
Encoding
      ↓
Representation Validation
      ↓
Interchange Representation
```

Export MUST NOT silently discard semantically relevant information.

---

# 22. Representability

A semantic state is representable under profile `P` when the profile provides defined representation semantics for the required information.

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
2. perform an explicit semantic projection;
3. preserve unsupported information opaquely where permitted; or
4. select another profile.

---

# 23. Semantic Projection

A semantic projection reduces a semantic state to a representable semantic subset.

Conceptually:

```text
Projection :
    SemanticState → SemanticSubset
```

Projection MUST be explicit.

For example:

```text
SCR Simulation State
       ↓
Renderable State Projection
       ↓
Interchange Representation
```

The projection MUST identify what semantic information was removed.

---

# 24. Information Loss

Information loss MUST be explicit and attributable.

Conceptually:

```text
Loss =
    <Concept,
     Cause,
     Scope,
     Recoverability>
```

Examples:

```text
PhysicsState
    → target format has no representation

ImplicitVolume
    → explicit surface representation

HighPrecisionValue
    → target precision

ExecutionState
    → excluded from interchange
```

Loss MUST NOT be represented as successful semantic preservation.

---

# 25. Fidelity Classes

An interchange profile MAY provide the following fidelity levels.

## 25.1 Exact

```text
Decode(Encode(S,P),P) ≡ S
```

for the applicable semantic domain.

## 25.2 Equivalent

```text
Decode(Encode(S,P),P) ≈ S
```

under an explicitly defined semantic equivalence relation.

## 25.3 Subset-Preserving

```text
Decode(Encode(S,P),P) ⊑ S
```

where the preserved subset is explicitly defined.

## 25.4 Opaque-Preserving

Information not understood semantically is retained without semantic interpretation.

A profile MUST NOT claim a stronger fidelity level than it provides.

---

# 26. Opaque Information

An implementation MAY preserve unsupported information opaquely.

Opaque information:

* MAY be retained;
* MAY be transported;
* MAY be exported again;
* MAY participate in representation identity;
* MAY participate in provenance.

Opaque information MUST NOT be interpreted as SCR semantics without an applicable mapping.

Therefore:

```text
Opaque ≠ Semantically Understood
```

---

# 27. Extension Handling

Interchange formats MAY provide extensions.

A profile MUST distinguish:

```text
Supported
Recognized but unsupported
Unknown
Invalid
```

Supported extensions MAY be mapped into SCR semantics.

Recognized but unsupported extensions SHOULD be preserved opaquely where possible.

Unknown extensions SHOULD be preserved where the format permits.

Invalid extensions MUST NOT be silently interpreted.

---

# 28. External References

Interchange representations MAY reference external resources.

Examples include:

* textures;
* buffers;
* layers;
* assets;
* remote resources;
* linked documents.

External reference resolution MUST occur within an explicit resolution context.

The context MAY include:

```text
BaseURI
Namespace
Authority
Resolver
SecurityPolicy
VersionConstraints
```

Reference resolution MUST preserve provenance.

---

# 29. Reference Semantics

External references MUST be classified according to their semantic role.

Possible classes include:

```text
RepresentationReference
ResourceReference
SemanticReference
ProvenanceReference
```

The mapping MUST explicitly establish relationships between these classes.

An external URI MUST NOT automatically become an SCR semantic reference.

---

# 30. Provenance

Interchange import MUST preserve provenance sufficient to identify the origin of semantic information where required by the profile.

At minimum, provenance SHOULD identify:

```text
SourceRepresentation
SourceFormat
SourceVersion
Profile
ProfileVersion
SourceReference
ImportOperation
```

Conceptually:

```text
SemanticObject
    │
    └── derivedFrom
          ↓
InterchangeRepresentation
          │
          └── interpretedBy
                ↓
InterchangeProfile
```

---

# 31. Provenance Is Not Identity

Provenance and identity are distinct.

```text
Provenance ≠ Identity
```

A semantic object MAY retain its semantic identity while acquiring new provenance through:

* import;
* export;
* transformation;
* replication;
* migration;
* transcoding.

---

# 32. Export Provenance

When exporting semantic state, an implementation SHOULD preserve relevant provenance where the target representation supports it.

Where the target format cannot represent provenance directly, the provenance MAY be preserved through:

* metadata;
* extension data;
* opaque payloads;
* external provenance records;
* SCR-side provenance.

Material provenance loss MUST be declared.

---

# 33. Transcoding

A transcoder maps one interchange representation to another.

Conceptually:

```text
Representation A
      ↓
Semantic Interpretation
      ↓
Semantic State
      ↓
Semantic Transformation
      ↓
Representation B
```

A direct implementation MAY optimize this pathway.

Where semantic equivalence is claimed:

```text
DecodeB(Transcode(A))
    ≈
DecodeA(A)
```

MUST hold under the declared equivalence relation.

---

# 34. Transcoding Without Semantic Materialization

An implementation MAY perform direct representation-to-representation transformation.

This is an optimization, not a new semantic primitive.

The implementation MUST preserve the guarantees of the equivalent semantic pathway.

If the implementation cannot establish those guarantees, it MUST NOT claim semantic-equivalent transcoding.

---

# 35. Representation Equivalence

The following concepts MUST remain distinct:

```text
ByteEqual
StructuralEqual
RepresentationEquivalent
SemanticEquivalent
```

Two representations MAY be semantically equivalent while being byte-different.

Conceptually:

```text
RepEquivalent(R1,R2,P)
```

means that `R1` and `R2` are equivalent under profile `P`.

---

# 36. Round-Trip Semantics

Interchange profiles MUST explicitly declare their round-trip guarantees.

Possible guarantees include:

### Byte round trip

```text
Encode(Decode(R,P),P) = R
```

### Structural round trip

```text
Structure(Encode(Decode(R,P),P))
    ≡
Structure(R)
```

### Representation-equivalent round trip

```text
Encode(Decode(R,P),P)
    ≈
R
```

### Semantic round trip

```text
Decode(Encode(S,P),P)
    ≡
S
```

A bidirectional mapping MUST NOT imply lossless round-trip behavior unless explicitly declared.

---

# 37. Import and Export Are Not Necessarily Inverses

SCR semantics may be strictly more expressive than an interchange format.

Therefore:

```text
SCR Semantic Space
    ⊇
Representable Interchange Space
```

may be true.

An import operation may therefore produce semantic state containing information that cannot subsequently be exported losslessly.

This is expected behavior and MUST be expressed through fidelity and loss semantics.

---

# 38. Interchange Conflicts

When multiple representations provide conflicting information about the same semantic object, the implementation MUST NOT silently select one.

Possible conflict policies include:

```text
Reject
Prefer authoritative source
Prefer explicitly selected version
Merge
Create conflict state
Resolve through authority
```

The selected policy MUST be explicit.

---

# 39. Authority

Representation ownership does not imply semantic authority.

Therefore:

```text
RepresentationOwner ≠ SemanticOwner
RepresentationOwner ≠ SemanticAuthority
Exporter ≠ SemanticAuthority
LatestRepresentation ≠ AutomaticallyAuthoritative
```

Authority MUST be established by the governing SCR authority and identity model.

---

# 40. Interchange Mutation

Mutation of a representation MUST NOT automatically mutate the corresponding semantic object.

Likewise, semantic mutation MUST NOT automatically mutate an external representation.

An explicit transition MUST establish the relationship.

Therefore:

```text
RepresentationMutation ≠ SemanticMutation
```

unless an explicit semantic transition defines the operation.

---

# 41. Interchange Deletion

Deleting an interchange representation MUST NOT imply semantic deletion.

For example:

```text
delete(asset.glb)
```

does not imply:

```text
delete(SID(mesh))
```

unless the semantic lifecycle explicitly defines the representation as authoritative and deletion as a semantic transition.

Historical representations MAY remain after semantic deletion for:

* audit;
* provenance;
* archival;
* reproducibility;
* recovery.

---

# 42. Representation Aliasing

Multiple interchange representations MAY encode the same semantic object.

For example:

```text
Representation A ──┐
Representation B ──┼──→ Semantic Object S
Representation C ──┘
```

This MUST NOT automatically create multiple semantic identities.

Identity resolution MUST be governed by the semantic identity model.

---

# 43. Representation Merging

Multiple interchange representations MAY be merged into one semantic state.

The merge MUST define:

* identity resolution;
* reference resolution;
* authority;
* ownership;
* precedence;
* conflict handling;
* provenance;
* version compatibility.

No implicit precedence rule is permitted.

---

# 44. Canonicalization

A profile MAY define a canonical representation.

Canonicalization MAY support:

* deterministic hashing;
* content identity;
* deduplication;
* comparison;
* caching;
* reproducibility.

Canonicalization MUST preserve the semantic guarantees declared by the profile.

Canonical representation does not become semantic authority merely because it is canonical.

---

# 45. Determinism

Determinism claims MUST identify their scope.

Possible claims include:

```text
ByteDeterministic
StructuralDeterministic
ContentDeterministic
SemanticDeterministic
```

Semantic determinism MUST NOT be confused with byte determinism.

---

# 46. Interchange and Hypergraphs

Interchange representations MAY encode SCR hypergraphs.

The external representation's graph structure MUST NOT automatically redefine SCR hypergraph semantics.

If an external format supports only lower-arity relations while SCR supports higher-arity relations, the mapping MUST explicitly encode or reject the unsupported semantics.

Nullary relations, reference semantics, deletion semantics, and hyperedge identity MUST follow their governing SCR specifications.

---

# 47. Nullary Relations

If an interchange format can represent a nullary relation, the mapping MUST preserve its semantics according to the SCR hypergraph specification.

If it cannot represent a nullary relation:

1. the mapping MUST declare the limitation;
2. the relation SHOULD be preserved opaquely where possible; or
3. semantic loss MUST be explicitly declared.

A nullary relation MUST NOT be silently transformed into another arity merely for convenience.

---

# 48. Deletion Semantics

External deletion markers, tombstones, missing objects, and absent references MUST NOT automatically imply SCR semantic deletion.

Deletion MUST be interpreted according to the target semantic domain.

If an interchange format has no explicit deletion semantics, deletion MUST NOT be inferred merely from absence.

---

# 49. Spatial Semantics

Interchange coordinate systems MUST be mapped into the appropriate SCR spatial domain.

An external coordinate system MUST NOT become the universal SCR coordinate system.

Where applicable, mappings SHOULD identify:

```text
axis convention
unit system
handedness
origin
reference frame
transform convention
precision
```

The following distinction remains mandatory:

```text
ExternalCoordinateSystem
    ≠
SCRCoordinateSystem
```

---

# 50. Spatial Partitioning

An external representation MAY contain spatial partitioning.

Such partitioning MUST NOT automatically become SCR computational partition identity.

For example:

```text
ExternalTile ≠ SCRPartition
```

unless an explicit mapping establishes that relationship.

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

# 51. Authority and Ownership

External metadata concerning ownership, authorship, or access MUST NOT automatically establish SCR ownership or authority.

The mapping MUST distinguish:

```text
ExternalOwnership
RepresentationOwnership
SemanticOwnership
SemanticAuthority
```

These are independent concepts.

---

# 52. Security Boundary

Interchange representations MUST be treated as untrusted input unless explicitly trusted.

The following implication MUST NOT be assumed:

```text
ValidRepresentation
→
SafeExecution
```

Import MUST establish semantic validity before execution.

External references MUST NOT automatically grant access to external resources.

Resource resolution MUST obey the applicable security and authority context.

---

# 53. Error Semantics

Interchange failures SHOULD distinguish at least:

```text
ParseError
FormatValidationError
ProfileError
UnsupportedFeature
MappingError
ReferenceResolutionError
SemanticValidationError
RepresentabilityError
FidelityViolation
ConflictError
VersionCompatibilityError
SecurityError
```

Concrete implementations MAY use different error structures, but these semantic distinctions MUST remain observable where applicable.

---

# 54. STC Integration

Interchange operations are semantic transitions and MUST be compatible with the Semantic Transition Calculus.

Examples include:

```text
τimport
τexport
τtranscode
τproject
τmaterialize
τdematerialize
```

The operation remains subject to the STC admissibility model:

```text
Applicable(τ,S,C)
Consents(τ,S,C,K)
```

Representation validity, authority, resource availability, security constraints, and provider capabilities MAY contribute to context and constraint environments.

Interchange MUST NOT introduce a new fundamental transition kernel primitive merely to represent interchange operations.

---

# 55. Transition Consequences

The consequences of interchange operations SHOULD be carried through the STC transition edge.

Possible consequence descriptions include:

```text
RepresentationCreated
RepresentationUpdated
RepresentationInvalidated
RepresentationImported
RepresentationExported
RepresentationTranscoded
RepresentationProjected
RepresentationLost
ProvenanceAdded
```

These are domain-level consequence descriptions.

They do not replace the GMKernel transition model.

---

# 56. Materialization

Materialization creates a representation of semantic state.

```text
Semantic State
      ↓
Materialize
      ↓
Interchange Representation
```

Materialization MUST NOT change semantic identity solely because a representation was created.

---

# 57. Dematerialization

Dematerialization removes a materialized representation while preserving semantic state where the semantic state remains independently valid.

```text
Interchange Representation
      ↓
Dematerialize
      ↓
Semantic State
```

Dematerialization MUST NOT be interpreted as semantic deletion.

---

# 58. Formal Model

The interchange domain MAY be described as:

```text
Interchange =
    <F,V,P,R,M,E,D,Q,L,O,C>
```

where:

```text
F = formats
V = format versions
P = profiles
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
    Representation × Profile × Context
        →
    SemanticState
```

An encoder:

```text
E :
    SemanticState × Profile × Context
        →
    Representation
```

Representation validity:

```text
ValidR :
    Representation × Profile → Prop
```

Representability:

```text
Representable :
    SemanticState × Profile → Prop
```

Representation equivalence:

```text
RepEquivalent :
    Representation × Representation × Profile → Prop
```

---

# 59. Semantic Preservation

A profile MAY claim preservation of a semantic property.

Conceptually:

```text
Preserves(P,Q)
```

where `Q` is a semantic property.

For example:

```text
Preserves(P,GeometryTopology)
Preserves(P,TransformHierarchy)
Preserves(P,MaterialParameters)
```

Preservation claims MUST be supported by validation, formal proof, or another declared conformance mechanism appropriate to the assurance level.

---

# 60. Lean Formalisation

Lean formalisation SHOULD be used where interchange semantics have high semantic centrality or high risk.

Priority areas include:

* identity mapping;
* reference semantics;
* deletion semantics;
* semantic preservation;
* representation equivalence;
* round-trip guarantees;
* projection correctness;
* provenance;
* canonicalization.

Lean MUST NOT silently redefine this specification.

If the Lean model and this specification disagree, the discrepancy MUST be resolved explicitly.

---

# 61. Formalisation Maturity

Interchange subdomains MAY use:

```text
none
described
axiomatized
modeled
proved
verified
```

Not every interchange format requires complete formalisation.

Formalisation effort SHOULD be proportional to:

* semantic centrality;
* risk;
* complexity;
* interoperability importance;
* consequences of incorrect interpretation.

---

# 62. Conformance

An interchange implementation conforms to this specification when:

1. its mappings are explicit;
2. its profile is identifiable;
3. semantic ownership remains outside the interchange domain;
4. identity distinctions are preserved;
5. representation validity is distinguished from semantic validity;
6. representability is evaluated;
7. loss is explicit;
8. opaque information is handled according to profile;
9. provenance is preserved as required;
10. references are explicit;
11. deletion semantics are explicit;
12. version compatibility is explicit;
13. round-trip guarantees are honest;
14. declared fidelity is satisfied;
15. negative cases are handled;
16. provider mechanisms do not redefine semantics.

---

# 63. Conformance Evidence

Conformance SHOULD include:

```text
Positive Tests
Negative Tests
Malformed Input Tests
Unsupported Feature Tests
Extension Tests
Identity Tests
Reference Tests
Deletion Tests
Provenance Tests
Loss Tests
Round-Trip Tests
Equivalence Tests
Version Tests
Security Tests
```

Formal proofs SHOULD be included where the profile claims formally established guarantees.

---

# 64. Domain Structure

The interchange domain follows the library structure defined by the SCR domain/subdomain model.

Canonical structure:

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

Concrete formats MUST be represented as subdomains where they have sufficient semantic scope to justify independent specifications.

---

# 65. Subdomain Requirements

A concrete interchange subdomain MUST define at least:

```text
Format
FormatVersion
SCRProfile
SupportedFeatures
UnsupportedFeatures
Mappings
IdentityRules
ReferenceRules
DeletionRules
ProvenanceRules
Fidelity
Loss
Extensions
Validation
Conformance
```

Where appropriate it SHOULD additionally define:

```text
LeanFormalisation
RoundTripGuarantees
Canonicalisation
Transcoding
Migration
SecurityRequirements
```

---

# 66. glTF as First Concrete Interchange Subdomain

The first major interchange subdomain SHOULD be:

```text
lib/representation/interchange/gltf/
```

The glTF specification SHOULD map, where applicable:

```text
glTF mesh
    → SCR geometry.mesh

glTF primitive
    → SCR geometry primitive

glTF accessor
    → SCR data view

glTF buffer
    → SCR data representation

glTF node
    → SCR scene node

glTF transform
    → SCR transform

glTF material
    → SCR material

glTF texture
    → SCR image/texture
```

These are mappings and MUST NOT be treated as identity equivalences.

The SCR glTF specification MUST also explicitly address glTF extensions, external resources, identity, provenance, reference semantics, fidelity, loss, and round-trip behavior.

---

# 67. Development Sequence

A new interchange integration SHOULD follow:

```text
1. Identify external format
2. Identify external version
3. Identify SCR semantic domains
4. Identify semantic owners
5. Define profile
6. Define import mappings
7. Define export mappings
8. Define identity semantics
9. Define reference semantics
10. Define deletion semantics
11. Define provenance
12. Define extension handling
13. Define fidelity
14. Define loss
15. Define representability
16. Define round-trip guarantees
17. Define validation
18. Define conformance tests
19. Formalise critical properties where justified
20. Implement parser
21. Implement mapper
22. Implement encoder
23. Validate
24. Verify
25. Update status
26. Update library graph
```

Implementation MUST NOT define semantic meaning by accident.

---

# 68. Development Agent Contract

An agent implementing an interchange subdomain MUST inspect:

```text
Parent representation specification
Interchange specification
Relevant semantic domain specifications
Identity specification
Reference specification
Deletion semantics
Provenance semantics
Library graph
Existing adapters
Provider capabilities
```

The agent MUST NOT infer SCR semantics from:

* parser object models;
* external class hierarchies;
* provider data structures;
* file layouts;
* database schemas;
* memory layouts.

External formats provide structures to be mapped, not semantic authority.

---

# 69. Required Questions Before Implementation

Before implementing an interchange format, the agent MUST be able to answer:

1. What SCR semantic concepts does the format represent?
2. Who owns each concept?
3. Which external structures map to each concept?
4. Which external structures have no SCR semantic equivalent?
5. Which SCR concepts cannot be represented?
6. What information is lost?
7. What information is preserved opaquely?
8. How are identities established?
9. How are references established?
10. What happens when references become invalid?
11. What happens when objects are deleted?
12. What provenance is created?
13. What versions are supported?
14. What extensions are supported?
15. What are the round-trip guarantees?
16. What equivalence relation is used?
17. What conflicts can occur?
18. What authority resolves conflicts?
19. What properties are formally established?
20. What provider mechanisms are required?

---

# 70. Normative Invariants

## INT-001 — Semantic Independence

Interchange MUST NOT define the semantic meaning of the objects it represents.

## INT-002 — Explicit Mapping

Every semantic interpretation MUST occur through an identifiable mapping.

## INT-003 — Profile Identification

Semantic interchange MUST occur under an identifiable profile.

## INT-004 — Identity Separation

Representation identity MUST remain distinct from semantic identity.

## INT-005 — Content Identity Separation

Content identity MUST remain distinct from semantic identity.

## INT-006 — Reference Separation

Representation references MUST remain distinct from semantic references unless explicitly mapped.

## INT-007 — Format Validation

Representation validity MUST be distinguished from semantic validity.

## INT-008 — Semantic Validation

Imported semantic state MUST satisfy the invariants of its owning domains.

## INT-009 — No Silent Loss

Material semantic loss MUST NOT be silently discarded.

## INT-010 — Explicit Projection

Lossy semantic projection MUST be explicit.

## INT-011 — Opaque Preservation

Information declared for opaque preservation MUST NOT be silently discarded.

## INT-012 — Provenance Preservation

Required provenance MUST be preserved.

## INT-013 — Provenance Separation

Provenance MUST NOT redefine identity.

## INT-014 — Version Separation

Format, profile, semantic, and implementation versions MUST remain distinct.

## INT-015 — Round-Trip Honesty

Round-trip guarantees MUST accurately reflect actual behavior.

## INT-016 — Equivalence Explicitness

Byte equality MUST NOT be substituted for semantic equivalence.

## INT-017 — Provider Independence

Interchange semantics MUST NOT depend on a specific provider.

## INT-018 — Parser Separation

Parsing MUST remain distinct from semantic interpretation.

## INT-019 — Export Representability

Export MUST establish representability or perform explicit projection.

## INT-020 — Conflict Explicitness

Conflicting representations MUST NOT be silently reconciled.

## INT-021 — Authority Separation

Representation ownership MUST NOT imply semantic authority.

## INT-022 — Deletion Separation

Representation deletion MUST NOT imply semantic deletion.

## INT-023 — Reference Lifecycle

Representation reference lifecycle MUST remain distinct from semantic object lifecycle.

## INT-024 — Extension Honesty

Unsupported extensions MUST NOT be silently interpreted.

## INT-025 — Semantic Ownership

Interchange MUST NOT redefine concepts owned by other semantic domains.

## INT-026 — Formalisation Integrity

Formalisation MUST NOT silently redefine the normative semantics.

## INT-027 — Provenance Traceability

Imported semantic objects MUST be traceable to their source representation where required by profile.

## INT-028 — Loss Traceability

Declared semantic loss MUST have an identifiable cause.

## INT-029 — Compatibility Explicitness

External format compatibility MUST NOT imply SCR semantic compatibility.

## INT-030 — Semantic Round-Trip

Where semantic round-trip is claimed, the declared semantic equivalence MUST be preserved.

---

# 71. Summary

The `representation.interchange` domain establishes the following model:

```text
                 SCR SEMANTICS
                       │
                       ▼
               INTERCHANGE MAPPING
                       │
                       ▼
                PROFILE CONTRACT
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
        glTF          USD          PLY
          │            │            │
          └────────────┼────────────┘
                       ▼
                 REPRESENTATION
                       │
                       ▼
                EXCHANGE / SYSTEM
```

The semantic object remains authoritative.

The interchange representation is an encoding of that meaning.

The mapping defines how the encoding is interpreted.

The profile defines the guarantees.

The provider supplies the mechanism.

---

# 72. Final Principle

The purpose of interchange is interoperability without semantic surrender.

Therefore:

> **SCR does not become compatible with an external format by adopting that format's ontology. SCR becomes compatible by defining an explicit, validated mapping between the external representation and SCR semantics.**

The governing relationship is:

```text
Semantic Domain
      ↓
Interchange Mapping
      ↓
Representation
      ↓
Exchange
      ↓
Representation
      ↓
Interchange Mapping
      ↓
Semantic Domain
```

The final rule is:

> **Representations describe. Mappings interpret. Semantic domains define. Providers realize. Interchange connects.**
