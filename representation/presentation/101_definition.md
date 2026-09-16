# Semantic Computational Runtime

# Presentation — Definition

**Document:** `lib/representation/presentation/101_definition.md`
**Semantic ID:** `representation.presentation`
**Version:** `0.1.0`
**Status:** Normative Semantic Definition
**Parent Domain:** `representation`
**Related Domains:** `representation.serialization`, `representation.interchange`, `representation.transport`, `representation.persistence`, `render`

---

# 1. Purpose

The `representation.presentation` subdomain defines the semantics by which structured or semantic information is transformed into a form intended for **human perception, external observation, interaction, or presentation to another perceptual system**.

Presentation answers:

> **How should information be made perceptible or inspectable without changing the semantic identity of what is being presented?**

Presentation may produce:

* visual output;
* auditory output;
* textual output;
* tactile output;
* multimodal output;
* interactive views;
* dashboards;
* diagrams;
* spatial scenes;
* accessibility representations.

The governing principle is:

> **Presentation exposes meaning; it does not become the meaning.**

---

# 2. Scope

This definition establishes semantics for:

* presentation;
* presentation views;
* presentation contexts;
* perceptual modalities;
* presentation mappings;
* visualisation;
* textual presentation;
* auditory presentation;
* tactile presentation;
* multimodal presentation;
* layout;
* styling;
* annotation;
* abstraction;
* filtering;
* aggregation;
* projection;
* viewpoint;
* camera semantics;
* interaction;
* presentation state;
* presentation identity;
* presentation provenance;
* accessibility;
* presentation fidelity;
* semantic highlighting;
* presentation transformations;
* presentation validation.

Concrete technologies such as:

* OGRE;
* Vulkan;
* OpenGL;
* Wayland;
* HTML/CSS;
* terminal interfaces;
* audio engines;
* accessibility APIs;

are mechanisms or providers.

They do not define SCR presentation semantics.

---

# 3. Architectural Position

Presentation is a representation of semantic or structured information intended for perception.

Conceptually:

```text
SCR Semantic State
        │
        ▼
Semantic / Representation Mapping
        │
        ▼
Presentation Model
        │
        ▼
Presentation Representation
        │
        ▼
Rendering / Perceptual Provider
        │
        ▼
Human / External Observer
```

The reverse direction may occur through interaction:

```text
Observer
   │
   ▼
Interaction
   │
   ▼
Presentation Context
   │
   ▼
Semantic Operation
   │
   ▼
SCR Semantic State
```

The fundamental distinction is:

```text
Semantic Meaning
    ≠
Presentation
    ≠
Rendering
    ≠
Execution
```

---

# 4. Presentation Is Not Semantic Meaning

A presentation communicates information about a semantic object.

It does not become the semantic object.

For example:

```text
Semantic Object: Graph G
        │
        ├── textual presentation
        ├── 2D graph presentation
        ├── 3D graph presentation
        └── auditory presentation
```

All presentations MAY refer to the same semantic object.

Therefore:

```text
PresentationIdentity ≠ SemanticIdentity
```

---

# 5. Presentation Is Not Rendering

Rendering is a mechanism for producing perceptual output from a presentation or scene.

Presentation defines what is to be presented.

Rendering determines how a concrete rendering mechanism produces output.

Therefore:

```text
Presentation ≠ Rendering
```

For example:

```text
Semantic Geometry
      ↓
Presentation Model
      ↓
Scene
      ↓
OGRE
      ↓
GPU
      ↓
Pixels
```

OGRE does not define what the geometry means.

---

# 6. Presentation Is Not Visualization

Visualization is a class of presentation concerned primarily with representing information through visual structures.

Therefore:

```text
Visualization ⊂ Presentation
```

Not all presentation is visualization.

Examples of non-visual presentation include:

* audio;
* speech;
* haptic feedback;
* machine-readable accessibility output.

---

# 7. Presentation Is Not Interchange

A presentation MAY be exported or exchanged, but presentation itself does not imply interchange.

For example:

```text
Semantic State
      ↓
Presentation
      ↓
Display
```

is not necessarily an interchange operation.

Conversely, an interchange representation MAY contain presentation metadata without becoming a presentation system.

Therefore:

```text
Presentation ≠ Interchange
```

---

# 8. Presentation Is Not Serialization

Presentation MAY be serialized.

Serialization defines how the presentation state is encoded.

Presentation defines what is being presented.

Therefore:

```text
Presentation ≠ Serialization
```

For example:

```text
Presentation Model
      ↓
Serialize
      ↓
JSON
```

The JSON is a serialization of the presentation model, not the presentation semantics themselves.

---

# 9. Presentation Is Not Persistence

A presentation MAY be persisted.

Persistence defines lifetime and durability.

Presentation defines perceptual representation.

Therefore:

```text
Presentation ≠ Persistence
```

---

# 10. Presentation Context

A presentation occurs within a context.

Conceptually:

```text
PresentationContext =
    <Observer,
     Modality,
     View,
     Scale,
     Permissions,
     InteractionState,
     Accessibility,
     Constraints>
```

The same semantic state MAY have different valid presentations under different contexts.

---

# 11. Observer

An observer is an entity or system for which presentation is produced.

An observer MAY be:

* a human;
* a group of humans;
* an accessibility system;
* a monitoring system;
* another computational system;
* an autonomous agent.

Presentation MUST NOT assume that every observer has the same perceptual capabilities.

---

# 12. Perceptual Modality

A presentation MAY use one or more modalities:

```text
Visual
Auditory
Textual
Tactile
Spatial
Multimodal
```

A modality is a presentation mechanism, not a semantic domain.

The same semantic information MAY be mapped into multiple modalities.

---

# 13. Presentation View

A presentation view defines the subset, projection, arrangement, or interpretation of semantic information exposed to an observer.

A view MAY define:

* visible objects;
* hidden objects;
* ordering;
* grouping;
* filtering;
* aggregation;
* viewpoint;
* scale;
* detail;
* annotations.

A view MUST NOT silently modify the underlying semantic state merely because the view excludes or transforms information.

---

# 14. Presentation Mapping

A presentation mapping defines how semantic information becomes perceptually representable.

Conceptually:

```text
PresentationMap :
    SemanticState × Context
        →
    PresentationState
```

A mapping MUST define where relevant:

* source semantics;
* target modality;
* transformations;
* projections;
* filtering;
* aggregation;
* abstraction;
* fidelity;
* loss;
* interaction behavior.

---

# 15. Presentation State

Presentation state contains information required to realize a particular presentation.

It MAY include:

```text
Objects
Geometry
Layout
Style
Visibility
Viewpoint
Camera
Annotations
Interaction State
Selection
Highlighting
Accessibility State
```

Presentation state MUST remain distinct from semantic state.

---

# 16. Semantic State and Presentation State

The distinction is:

```text
Semantic State
    = what exists and what it means

Presentation State
    = how that meaning is exposed
```

For example:

```text
Semantic Graph
    Nodes A, B, C

Presentation
    A visible
    B hidden
    C highlighted
```

The visibility state does not imply that B ceased to exist semantically.

---

# 17. Projection

Presentation commonly applies projection.

Projection MAY:

* select;
* aggregate;
* simplify;
* transform;
* spatialize;
* collapse;
* expand;
* annotate.

Projection MUST be explicit where information is removed or transformed.

---

# 18. Filtering

Filtering determines which semantic information is presented.

For example:

```text
Semantic State
    ├── A
    ├── B
    ├── C
    └── D

Filter
    ↓

Presentation
    ├── A
    └── C
```

Filtering does not imply semantic deletion.

Therefore:

```text
PresentationFiltering ≠ SemanticDeletion
```

---

# 19. Aggregation

Presentation MAY aggregate multiple semantic objects.

For example:

```text
1,000 individual events
        ↓
Presentation aggregation
        ↓
"1,000 events"
```

Aggregation MUST preserve the distinction between:

```text
Individual Semantic Objects
    ≠
Presentation Aggregate
```

unless the semantic model explicitly defines the aggregate as a semantic object.

---

# 20. Abstraction

Presentation MAY deliberately reduce detail.

Examples include:

```text
Detailed Geometry
        ↓
Simplified Geometry

Large Graph
        ↓
Clustered Graph

Simulation
        ↓
Summary View
```

Abstraction MUST declare its fidelity where omitted information could affect interpretation.

---

# 21. Level of Detail

Presentation MAY use multiple levels of detail.

For example:

```text
LOD 0 → Overview
LOD 1 → Regional structure
LOD 2 → Object structure
LOD 3 → Component detail
LOD 4 → Full detail
```

Level of detail is a presentation property.

It MUST NOT imply that lower-detail representations are different semantic objects.

---

# 22. Layout

Layout determines the arrangement of presentation elements.

Layout MAY be:

* spatial;
* hierarchical;
* tabular;
* radial;
* graph-based;
* temporal;
* textual;
* auditory.

Layout MUST NOT silently redefine semantic relationships.

For example:

```text
Visual proximity
    ≠
Semantic relationship
```

unless the presentation specification explicitly establishes that correspondence.

---

# 23. Spatial Presentation

A semantic object MAY be presented spatially.

For example:

```text
Semantic Graph
      ↓
3D Layout
      ↓
Spatial Presentation
```

Spatial position is presentation state unless explicitly mapped to semantic spatial coordinates.

Therefore:

```text
PresentationPosition ≠ SemanticPosition
```

---

# 24. Camera and Viewpoint

A camera or viewpoint determines the observer's spatial perspective.

Camera state MAY include:

* position;
* orientation;
* projection;
* field of view;
* clipping;
* focus;
* scale.

Camera state is presentation state unless explicitly associated with semantic spatial state.

---

# 25. Style

Presentation style MAY include:

* colour;
* typography;
* line width;
* shape;
* texture;
* opacity;
* sound;
* animation;
* emphasis.

Style is not semantic meaning by default.

However, where style communicates a semantic property, the mapping MUST explicitly establish that relationship.

---

# 26. Semantic Encoding Through Presentation

Presentation MAY intentionally encode semantic properties.

For example:

```text
Red    → error
Blue   → informational
Large  → magnitude
Brightness → activity
Motion → change
```

Such mappings MUST be explicit.

A viewer MUST NOT be required to infer semantic meaning from arbitrary stylistic choices.

---

# 27. Accessibility

Presentation SHOULD provide equivalent or materially informative representations for supported observer modalities.

For example:

```text
Visual Graph
     ↕
Textual Graph Description
     ↕
Auditory Graph Description
```

Accessibility presentation MUST preserve the relevant semantic information required by the accessibility contract.

Accessibility does not require identical representation.

It requires appropriate semantic access.

---

# 28. Presentation Fidelity

Presentation MAY be:

```text
Exact
Equivalent
Approximate
Projected
Aggregated
Abstracted
Lossy
```

The fidelity claim MUST be explicit.

A presentation MUST NOT claim to expose information that it has discarded.

---

# 29. Information Loss

Presentation may intentionally omit information.

Examples:

```text
Hidden objects
Collapsed nodes
Simplified geometry
Aggregated values
Filtered events
```

Loss MUST NOT be confused with semantic deletion.

The underlying semantic state remains unchanged unless a separate semantic operation occurs.

---

# 30. Presentation Identity

A presentation instance MAY have its own identity.

The identities MUST remain distinct:

```text
SID
PresentationID
RepresentationID
ContentID
```

A new presentation view of the same semantic object does not necessarily create a new semantic object.

---

# 31. Presentation Reference

A presentation MAY reference semantic objects.

For example:

```text
Presentation Element P
        │
        └── represents → Semantic Object S
```

The presentation reference MUST NOT be treated as the semantic object's identity.

---

# 32. Selection

Presentation MAY contain a selection state.

For example:

```text
Selected = {A, C, F}
```

Selection is normally presentation state.

It MAY trigger a semantic operation when explicitly connected to interaction semantics.

---

# 33. Highlighting

Highlighting is a presentation mechanism that emphasizes information.

Examples include:

* colour;
* animation;
* outline;
* sound;
* magnification;
* spatial displacement.

Highlighting MUST NOT modify semantic state unless explicitly defined as an interaction operation.

---

# 34. Animation

Presentation MAY represent temporal change through animation.

Animation MAY expose:

```text
Semantic Time
Simulation Time
Presentation Time
Real Time
```

These MUST remain distinct.

In particular:

```text
Presentation Time ≠ Semantic Time
```

unless explicitly mapped.

---

# 35. Temporal Presentation

A presentation MAY expose a sequence of semantic states.

Conceptually:

```text
S₀ → S₁ → S₂ → S₃
          │
          ▼
      Presentation
          │
          ▼
       Animation
```

Presentation playback does not itself execute the semantic transitions.

---

# 36. Interaction

Presentation MAY provide interaction mechanisms.

Examples include:

* selection;
* navigation;
* dragging;
* zooming;
* editing;
* activation;
* inspection;
* manipulation.

Interaction MUST distinguish:

```text
Presentation Operation
    ≠
Semantic Operation
```

A presentation interaction MAY request a semantic transition, but it does not automatically constitute one.

---

# 37. Interaction Mapping

An interaction mapping defines how observer actions correspond to semantic operations.

Conceptually:

```text
ObserverAction
      ↓
PresentationInteraction
      ↓
SemanticTransitionRequest
      ↓
Authorization / Applicability
      ↓
Semantic Transition
```

The semantic transition remains governed by SCR transition semantics.

---

# 38. Authority

Viewing does not imply authority.

Therefore:

```text
PresentationAccess
    ≠
SemanticAuthority
```

A user MAY be able to see an object without being permitted to modify it.

Likewise, a presentation MAY expose an object without exposing all of its underlying state.

---

# 39. Ownership

Presentation ownership does not imply semantic ownership.

Therefore:

```text
PresentationOwner
    ≠
SemanticOwner
```

A rendering process may own the presentation resources while another actor owns the semantic state.

---

# 40. Security

Presentation MUST respect applicable security and authorization constraints.

Presentation MUST NOT reveal information that the observer is not authorized to observe.

Security filtering SHOULD occur before information is exposed through the presentation pipeline.

The following implication is invalid:

```text
SemanticStateExists
    →
ObserverMaySeeIt
```

---

# 41. Privacy

Presentation MAY require redaction or aggregation to prevent disclosure of sensitive information.

Possible transformations include:

* masking;
* aggregation;
* anonymization;
* suppression;
* spatial coarsening;
* temporal coarsening.

Privacy transformations MUST be explicit where they alter fidelity.

---

# 42. Provenance

Presentation SHOULD preserve provenance for information where required.

Possible provenance includes:

```text
Source Semantic Object
Presentation Mapping
View
Profile
Observer Context
Timestamp
Presentation Version
Provider
```

Presentation provenance MUST remain distinct from semantic provenance.

---

# 43. Presentation History

A presentation system MAY maintain history such as:

```text
Previous View
Previous Selection
Camera Path
Interaction History
Playback Position
```

Presentation history MUST NOT automatically become semantic history.

Semantic history remains governed by the semantic lifecycle and transition specifications.

---

# 44. Presentation Mutation

Changing presentation state does not normally mutate semantic state.

For example:

```text
Zoom In
Pan
Rotate Camera
Change Colour Scheme
Hide Node
```

are normally presentation operations.

Operations such as:

```text
Edit Node
Delete Object
Move Semantic Object
Change Property
```

may request semantic transitions.

The boundary MUST be explicit.

---

# 45. Presentation Deletion

Deleting a presentation element does not imply deleting the semantic object.

For example:

```text
Delete View Element
        ≠
Delete Semantic Object
```

Presentation lifecycle and semantic lifecycle MUST remain distinct.

---

# 46. Persistence of Presentation State

Presentation state MAY be persisted.

Examples include:

* saved layouts;
* camera positions;
* user preferences;
* dashboards;
* view configurations.

Persistence of presentation state does not imply persistence of the underlying semantic state.

---

# 47. Serialization of Presentation State

Presentation state MAY be serialized.

For example:

```text
Presentation State
      ↓
Serialization
      ↓
JSON / Binary
```

The serialized form remains an encoding of presentation state.

It does not become the semantic model.

---

# 48. Interchange of Presentation

Presentation state MAY be exchanged between systems.

For example:

```text
Presentation Profile
      ↓
Interchange Representation
      ↓
Another Presentation System
```

Interchange fidelity MUST be explicitly defined.

---

# 49. Rendering Boundary

The rendering boundary is:

```text
Presentation Model
      ↓
Rendering Provider
      ↓
Physical / Perceptual Output
```

The rendering provider MAY implement:

* rasterization;
* vectorization;
* text layout;
* audio synthesis;
* haptic output;
* GPU execution.

The provider MUST NOT silently redefine presentation semantics.

---

# 50. GPU Presentation

GPU resources MAY realize presentation.

Examples include:

```text
Vertex Buffers
Index Buffers
Textures
Shaders
Framebuffers
Command Buffers
```

GPU addresses and handles are implementation resources.

They MUST NOT become semantic identity.

---

# 51. OGRE Integration

OGRE MAY serve as a rendering provider for SCR presentation.

The relationship is:

```text
SCR Semantic Model
        ↓
SCR Presentation Model
        ↓
OGRE Provider
        ↓
GPU
        ↓
Pixels
```

OGRE MAY provide:

* scene management;
* rendering;
* materials;
* cameras;
* meshes;
* animation;
* GPU integration.

OGRE MUST remain below the presentation semantic boundary.

---

# 52. Wayland Integration

Wayland MAY provide an external display/compositor mechanism.

The relationship is:

```text
Presentation
      ↓
Rendering
      ↓
Wayland Surface
      ↓
Compositor
      ↓
Display
```

Wayland does not define SCR presentation semantics.

---

# 53. Presentation and Spatial Semantics

A presentation MAY expose semantic spatial information.

Where semantic coordinates are presented directly:

```text
SemanticCoordinate
        ↓
PresentationCoordinate
```

the mapping MUST be explicit.

A display coordinate is not automatically a semantic coordinate.

Therefore:

```text
DisplayPosition ≠ SemanticPosition
```

---

# 54. Presentation and Spatial Partitioning

A presentation MAY expose computational partitions.

For example:

```text
Partition P1 → region A
Partition P2 → region B
Partition P3 → region C
```

The visual arrangement is presentation state.

Partition identity remains governed by spatial partition semantics.

Therefore:

```text
VisualRegion ≠ ComputationalPartition
```

unless explicitly mapped.

---

# 55. Presentation and Distributed Execution

Presentation MAY observe distributed computation.

For example:

```text
Partition A ──┐
Partition B ──┼──→ Presentation
Partition C ──┘
```

Presentation aggregation MUST NOT imply that the underlying partitions have been merged.

---

# 56. Presentation and Streaming

Presentation MAY consume streamed semantic or representation data.

For example:

```text
Transport
    ↓
Serialized Data
    ↓
Deserialize
    ↓
Presentation Mapping
    ↓
Rendering
```

Transport and serialization remain separate semantic layers.

---

# 57. Presentation and STC

Presentation operations MAY participate in the Semantic Transition Calculus.

Examples include:

```text
τview
τfilter
τproject
τselect
τhighlight
τlayout
τnavigate
τinteract
```

These operations MUST use the existing GMKernel transition model.

Presentation MUST NOT introduce an independent execution calculus.

---

# 58. Presentation Consequences

Presentation transitions MAY produce consequences such as:

```text
ViewChanged
SelectionChanged
PresentationUpdated
PresentationInvalidated
InteractionReceived
PresentationFiltered
PresentationProjected
```

These are consequences of presentation operations.

They MUST remain represented through the existing relational transition model.

---

# 59. Formal Model

The presentation domain MAY be modeled as:

```text
Presentation =
    <S,P,V,O,M,L,F,A,I,Q>
```

where:

```text
S = semantic sources
P = presentation states
V = views
O = observers
M = modalities
L = layouts
F = fidelity / projection rules
A = accessibility rules
I = interaction mappings
Q = presentation equivalence
```

Presentation mapping:

```text
Present :
    SemanticState × View × Context
        →
    PresentationState
```

Rendering:

```text
Render :
    PresentationState × ProviderContext
        →
    PerceptualOutput
```

Interaction:

```text
Interact :
    ObserverAction × PresentationContext
        →
    SemanticTransitionRequest
```

---

# 60. Presentation Equivalence

Two presentation states MAY be equivalent under a presentation profile.

Conceptually:

```text
PresentationEquivalent(P1,P2,C)
```

This does not imply:

```text
P1 = P2
```

nor:

```text
SemanticState(P1) = SemanticState(P2)
```

Equivalence MUST be defined relative to observer needs and declared fidelity.

---

# 61. Semantic Preservation

A presentation mapping SHOULD preserve all semantic properties required by its declared purpose.

For example, a graph presentation claiming to expose connectivity MUST preserve connectivity.

A visualization claiming to encode magnitude MUST preserve the relevant magnitude relationship.

Preservation claims MUST be testable.

---

# 62. Formalisation

Lean formalisation SHOULD be considered for:

* presentation mapping correctness;
* filtering semantics;
* projection semantics;
* aggregation properties;
* semantic preservation;
* accessibility equivalence;
* interaction mapping;
* identity preservation;
* presentation/semantic separation.

Lean MUST formalize the normative presentation semantics rather than redefining them.

---

# 63. Conformance

A presentation implementation conforms to this definition when:

1. presentation is distinct from semantic meaning;
2. presentation is distinct from rendering;
3. presentation is distinct from serialization;
4. presentation is distinct from interchange;
5. presentation is distinct from persistence;
6. presentation state is explicit;
7. observer context is explicit;
8. presentation mappings are explicit;
9. filtering and projection are explicit;
10. information loss is explicit;
11. semantic identity is preserved;
12. presentation position is not silently treated as semantic position;
13. presentation interaction is distinct from semantic transition;
14. authority is respected;
15. accessibility semantics are explicit where claimed;
16. provider mechanisms do not redefine presentation semantics.

---

# 64. Normative Invariants

## PRE-001 — Semantic Independence

Presentation MUST NOT redefine the semantic meaning of presented information.

## PRE-002 — Rendering Separation

Presentation MUST remain distinct from rendering.

## PRE-003 — Serialization Separation

Presentation MUST remain distinct from serialization.

## PRE-004 — Interchange Separation

Presentation MUST remain distinct from interchange.

## PRE-005 — Persistence Separation

Presentation MUST remain distinct from persistence.

## PRE-006 — Execution Separation

Presentation MUST remain distinct from execution.

## PRE-007 — View Explicitness

A presentation view MUST explicitly define its selection, projection, aggregation, or abstraction behavior where applicable.

## PRE-008 — Observer Explicitness

Presentation context MUST identify or characterize the observer requirements relevant to the presentation.

## PRE-009 — Modality Explicitness

The perceptual modality MUST be explicit.

## PRE-010 — Projection Explicitness

Information projection MUST NOT be silently interpreted as semantic deletion.

## PRE-011 — Filtering Separation

Presentation filtering MUST remain distinct from semantic deletion.

## PRE-012 — Aggregation Separation

Presentation aggregation MUST remain distinct from semantic aggregation unless explicitly mapped.

## PRE-013 — Spatial Separation

Presentation coordinates MUST remain distinct from semantic coordinates unless explicitly mapped.

## PRE-014 — Partition Separation

Presentation regions MUST remain distinct from semantic computational partitions unless explicitly mapped.

## PRE-015 — Identity Separation

Presentation identity MUST remain distinct from semantic identity.

## PRE-016 — Reference Separation

Presentation references MUST remain distinct from semantic references unless explicitly mapped.

## PRE-017 — Style Separation

Presentation style MUST NOT acquire semantic meaning unless explicitly declared by the presentation mapping.

## PRE-018 — Fidelity Honesty

Presentation fidelity claims MUST accurately describe information preserved and lost.

## PRE-019 — Accessibility Integrity

Accessibility mappings MUST preserve the semantic information required by their declared accessibility purpose.

## PRE-020 — Interaction Separation

Presentation interaction MUST remain distinct from semantic transition.

## PRE-021 — Authority Separation

Presentation access MUST NOT imply semantic authority.

## PRE-022 — Ownership Separation

Presentation ownership MUST NOT imply semantic ownership.

## PRE-023 — Security Integrity

Presentation MUST enforce applicable observation and disclosure constraints.

## PRE-024 — Provenance Separation

Presentation provenance MUST remain distinct from semantic provenance.

## PRE-025 — Lifecycle Separation

Presentation lifecycle MUST remain distinct from semantic lifecycle.

## PRE-026 — History Separation

Presentation history MUST remain distinct from semantic history.

## PRE-027 — Temporal Separation

Presentation time MUST remain distinct from semantic time unless explicitly mapped.

## PRE-028 — Provider Independence

Presentation semantics MUST remain independent of a particular rendering or display provider.

## PRE-029 — STC Compatibility

Presentation transitions MUST remain compatible with the Semantic Transition Calculus.

## PRE-030 — Validation Integrity

A presentation MUST NOT claim semantic preservation that has not been validated under its declared mapping and fidelity contract.

---

# 65. Library Integration

The presentation subdomain belongs beneath:

```text
lib/representation/
```

with the canonical structure:

```text
lib/representation/presentation/
├── README.md
├── 101_definition.md
├── 102_status.yaml
└── 103_library.graph.json
```

Potential technology-independent subdomains include:

```text
presentation.visual
presentation.audio
presentation.text
presentation.tactile
presentation.spatial
presentation.multimodal
presentation.accessibility
presentation.interaction
presentation.layout
```

Technology-specific providers belong beneath the appropriate provider boundary rather than becoming semantic authorities.

---

# 66. Relationship to Render

The relationship is:

```text
Semantic State
      ↓
Presentation Model
      ↓
Render Model
      ↓
Rendering Provider
      ↓
Perceptual Output
```

`presentation` answers:

> What should be exposed and how should it be perceptually represented?

`render` answers:

> How is that presentation physically produced?

Therefore:

```text
Presentation ≠ Render
```

---

# 67. Relationship to Serialization

Presentation state MAY be serialized:

```text
PresentationState
      ↓
Serialization
      ↓
Serialized Presentation
```

Serialization preserves or encodes presentation structure.

It does not determine the perceptual meaning of that structure.

---

# 68. Relationship to Interchange

Presentation MAY participate in interchange:

```text
Presentation Model
      ↓
Interchange Mapping
      ↓
External Presentation Representation
```

Interchange defines how the presentation representation crosses system boundaries.

---

# 69. Relationship to Transport

Presentation data MAY be transported:

```text
Presentation State
      ↓
Serialization
      ↓
Transport
      ↓
Remote Presentation Context
```

Transport moves the representation.

It does not define presentation semantics.

---

# 70. Relationship to Persistence

Presentation configuration MAY be persisted:

```text
View Configuration
      ↓
Serialization
      ↓
Persistence
```

Persistence establishes its lifetime.

It does not define the presentation semantics.

---

# 71. Minimum Viable Presentation

The minimum SCR presentation implementation SHOULD demonstrate:

```text
Semantic State
      ↓
Presentation Mapping
      ↓
Presentation State
      ↓
Rendering Provider
      ↓
Observable Output
```

It MUST demonstrate:

* semantic-to-presentation mapping;
* presentation identity separation;
* explicit view state;
* at least one modality;
* filtering or projection;
* semantic reference preservation;
* presentation/semantic coordinate separation where spatial presentation is used;
* validation of declared fidelity;
* provider separation.

---

# 72. Development Sequence

A concrete presentation implementation SHOULD follow:

```text
1. Identify semantic source domain
2. Identify semantic owners
3. Define observer/context
4. Define modality
5. Define presentation purpose
6. Define presentation mapping
7. Define view model
8. Define filtering
9. Define projection
10. Define aggregation
11. Define layout
12. Define style
13. Define fidelity
14. Define identity/reference mapping
15. Define spatial mapping where applicable
16. Define temporal mapping where applicable
17. Define accessibility requirements
18. Define interaction semantics
19. Define authority/security constraints
20. Define provenance
21. Define validation
22. Formalise critical properties where justified
23. Implement provider adapter
24. Render
25. Validate semantic preservation
26. Verify
27. Update status
28. Update library graph
```

---

# 73. Development Agent Contract

An implementation agent MUST inspect:

```text
Parent representation specification
Presentation definition
Relevant semantic domain specifications
Identity specification
Reference specification
Spatial semantics
Spatial partitioning semantics
Authority/ownership semantics
STC
Render specification
Relevant provider capabilities
```

The agent MUST distinguish:

```text
Semantic Object
Presentation Object
Presentation View
Rendering Object
Provider Object
Physical Resource
```

These MUST NOT be collapsed.

---

# 74. Required Development Questions

Before implementation, the agent MUST answer:

1. What semantic information is being presented?
2. Who owns that semantic information?
3. Who is the observer?
4. What modality is being used?
5. What presentation mapping is applied?
6. What information is filtered?
7. What information is projected?
8. What information is aggregated?
9. What information is lost?
10. What fidelity is guaranteed?
11. How is semantic identity preserved?
12. How are semantic references represented?
13. Are spatial positions semantic or presentational?
14. Are temporal values semantic or presentational?
15. What does visual style communicate?
16. What accessibility representation is required?
17. What interactions exist?
18. Which interactions request semantic transitions?
19. What authority checks apply?
20. What security constraints apply?
21. What provenance is preserved?
22. Which rendering provider is used?
23. Which provider capabilities are required?
24. Which properties can be formally verified?
25. What evidence establishes semantic preservation?

---

# 75. Final Definition

Presentation is the semantic capability by which information is selected, transformed, arranged, and exposed through one or more perceptual modalities for an observer.

The fundamental relationship is:

```text
Semantic Meaning
       │
       ▼
Presentation Mapping
       │
       ▼
Presentation State
       │
       ▼
Rendering / Perceptual Mechanism
       │
       ▼
Observer
```

Presentation may change:

* viewpoint;
* layout;
* style;
* scale;
* level of detail;
* modality;
* filtering;
* aggregation;
* abstraction.

It MUST NOT silently change:

* semantic identity;
* semantic ownership;
* semantic authority;
* semantic existence;
* semantic references;
* semantic lifecycle.

The governing distinctions are:

```text
Meaning
   ≠
Presentation
   ≠
Rendering
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

The governing principle is:

> **Presentation makes meaning perceptible. Rendering makes presentation physical. Neither becomes the meaning itself.**
