# SCR IMPLEMENTATION DIRECTIVE

## Manifestation Semantics, Representation Independence, and LVGL-Informed Architectural Refinement

You are implementing a semantic architectural refinement of the Semantic Computational Runtime (SCR) repository.

Repository:

`https://github.com/zharia/Semantic-Computational-Runtime`

Reference workload:

`https://github.com/lvgl/lvgl`

Your task is **not** to integrate LVGL into SCR.

Your task is to use LVGL as a concrete architectural validation case to strengthen SCR's existing semantic model around:

* semantic structure
* morphology
* topology
* geometry
* state
* perception
* streams
* interfaces
* transformations
* lowering
* providers
* rendering
* manifestation
* representation independence

The implementation MUST preserve SCR's governing architectural principle:

> **Semantic meaning is authoritative; representation, implementation, execution substrate, provider, backend, storage mechanism, and physical manifestation are not.**

The repository is a semantic system first and a software repository second.

---

# 1. PRIMARY OBJECTIVE

Refine the SCR semantic library so that a system analogous to LVGL can be represented naturally as an instance of the existing SCR architecture without introducing LVGL-specific concepts into the semantic core.

The resulting architecture MUST support the conceptual pipeline:

```text
                         SEMANTIC FIELD
                              │
                              ▼
                     Semantic Structure
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
           Topology        Morphology         State
              │               │               │
              └───────────────┼───────────────┘
                              ▼
                        Transformation
                              │
                              ▼
                         Representation
                              │
                              ▼
                           Lowering
                              │
                              ▼
                           Provider
                              │
                              ▼
                          Execution
                              │
                              ▼
                        Manifestation
```

The reverse direction MUST also be expressible:

```text
Physical / external world
          │
          ▼
      Observation
          │
          ▼
      Perception
          │
          ▼
    Semantic Event
          │
          ▼
    State Transition
          │
          ▼
      Semantic Field
```

The architecture therefore becomes a bidirectional semantic cycle:

```text
                 ┌─────────────────────┐
                 │    SEMANTIC FIELD   │
                 └──────────┬──────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
         PERCEPTION                 MANIFESTATION
              │                           │
              ▼                           ▼
       observations                  projections
              │                           │
              └─────────────┬─────────────┘
                            ▼
                     WORLD INTERFACE
```

Do NOT introduce this model by creating a new LVGL subsystem.

Do NOT make LVGL a dependency.

Do NOT make GUI concepts foundational.

Do NOT make rendering synonymous with manifestation.

Do NOT make a widget tree synonymous with semantic topology.

Do NOT make geometry synonymous with semantic structure.

---

# 2. MANDATORY FIRST STEP: RECONNAISSANCE

Before modifying anything, inspect the repository comprehensively enough to understand the current state.

At minimum inspect:

```text
lib/README.md
lib/000_meta/
lib/101_Core/
lib/201_Data/
lib/202_Math/
lib/203_Graph/
lib/301_Field/
lib/302_Geometry/
lib/303_Topology/
lib/401_Morphology/
lib/603_Perception/
lib/604_Control/
lib/802_Stream/
lib/902_Interfaces/
lib/903_Lowering/
lib/904_Providers/
lib/905_Transforms/
lib/A01_Render/
```

Also inspect:

* repository root instructions
* existing tests
* validation scripts
* status files
* generated graph machinery
* implementation directories
* existing MLIR material
* current numeric/semantic definitions
* any existing manifestation/projection terminology

Do not assume the current directory names imply inheritance.

The repository explicitly distinguishes semantic hierarchy from filesystem hierarchy.

Before editing, identify:

1. existing definitions that already express part of Manifestation
2. existing definitions of Representation
3. existing definitions of Projection
4. existing definitions of Rendering
5. existing `Renderable` contracts
6. existing transformation contracts
7. existing provider contracts
8. existing lowering contracts
9. existing observation/perception semantics
10. existing stream/delta/event semantics
11. existing morphology/topology semantics
12. existing validation infrastructure

If the current architecture already contains equivalent concepts, **refine them rather than duplicating them**.

---

# 3. SOURCE-OF-TRUTH RULES

Preserve the existing SCR control-plane hierarchy.

The following distinctions MUST remain intact:

```text
Specification ≠ Implementation
Status ≠ Specification
Graph ≠ Source of Truth
Provider ≠ Semantic Authority
Backend ≠ Semantic Meaning
Representation ≠ Concept
Transformation ≠ Lowering
Domain ≠ Implementation
Filesystem Hierarchy ≠ Semantic Hierarchy
```

The normative semantic definition is authoritative.

Status files record engineering state.

The aggregate library graph is derived.

Do NOT manually edit a generated graph merely to make it match implementation.

If a generated artifact must change, update the authoritative source and regenerate it.

---

# 4. MANIFESTATION

Introduce or formalise **Manifestation** as a cross-domain semantic concept.

First determine whether Manifestation already exists in an adequate form.

If it does:

* strengthen it
* clarify its boundaries
* remove ambiguity
* integrate it with the existing semantic model

If it does not, introduce it at the lowest semantic scope justified by the existing architecture.

Do NOT automatically create a new top-level numbered domain.

The intended semantic definition is approximately:

> **Manifestation is the realization of semantic structure as an observable, actionable, or physically consequential representation within a target domain.**

Manifestation MUST be distinguished from:

```text
Semantic Entity
Semantic Structure
Representation
Transformation
Lowering
Provider
Execution
Observation
Rendering
```

The model MUST support:

```text
Semantic Structure
       ↓
Representation
       ↓
Transformation / Lowering
       ↓
Provider
       ↓
Execution
       ↓
Manifestation
```

Manifestation is therefore an outcome/process of realization, not the semantic identity of the thing being realized.

---

# 5. REPRESENTATION INDEPENDENCE

Formalise and reinforce the principle that one semantic entity may have multiple representations.

For example:

```text
Semantic Entity
 ├── semantic representation
 ├── morphological representation
 ├── geometric representation
 ├── render representation
 ├── storage representation
 ├── wire representation
 └── execution representation
```

None of these becomes semantic authority merely because it is used by the implementation.

The definition MUST explicitly prohibit semantic authority from migrating into:

* buffers
* tensors
* meshes
* scene graphs
* widget trees
* DOM trees
* draw lists
* GPU resources
* LVGL objects
* serialized objects
* MLIR implementation details
* provider-specific objects

A provider representation may be authoritative for its own execution domain without becoming authoritative for SCR semantics.

---

# 6. MORPHOLOGY REFINEMENT

Review `401_Morphology`.

Strengthen its definition where necessary so that morphology clearly covers:

* form
* structure
* organization
* differentiation
* composition
* parts and wholes
* structural role
* pattern
* shape
* growth
* deformation
* emergence
* structural transformation
* representation-independent structural organization

Explicitly establish that morphology is not restricted to:

* meshes
* physical bodies
* visual shapes
* rendering
* geometry

A hierarchical UI structure is a valid *example* of morphology.

It is not the definition of morphology.

The definition should support structures such as:

```text
Organism
 ├── tissue
 ├── organ
 └── subsystem
```

```text
UI
 ├── container
 ├── control
 └── label
```

```text
Distributed computation
 ├── kernel
 ├── channel
 └── execution region
```

without making any of these examples foundational.

Preserve the existing bidirectional relationship:

```text
Pattern
   ↕
Morphological Interpretation
   ↕
Morphological Structure
   ↕
Structural Analysis
   ↕
Pattern
```

Do not weaken this existing principle.

---

# 7. TOPOLOGY REFINEMENT

Review `303_Topology`.

Ensure that topology is not reduced to parent/child trees.

The semantic model MUST support richer relationships such as:

```text
contains
part_of
adjacent_to
connected_to
aligned_with
controls
observes
renders
derived_from
associated_with
```

and higher-order relationships where pairwise reduction would lose meaning.

A tree such as:

```text
Parent
 ├── Child
 ├── Child
 └── Child
```

must be representable as a topological relation, not treated as the fundamental semantic model.

LVGL's object tree is a validation case for this requirement.

Do NOT introduce:

```text
parent_id
child_id
widget_tree
```

as foundational SCR concepts merely because LVGL uses them.

---

# 8. GEOMETRY REFINEMENT

Review `302_Geometry`.

Ensure that geometry remains distinct from:

* topology
* morphology
* spatial computation
* rendering

Clarify that geometry may be:

1. intrinsic semantic information
2. derived from topology/morphology/constraints
3. a representation of semantic structure

The distinction MUST be explicit.

Support concepts relevant to layout systems, including:

* extent
* position
* bounds
* alignment
* coordinate systems
* reference frames
* constraints
* layout
* spatial relationships
* derived geometry

LVGL-style Flex/Grid layout MUST be understood as a validation example of constraint-driven geometric derivation, not as the semantic definition of layout.

---

# 9. STREAM REFINEMENT

Review `802_Stream`.

Explicitly account for semantic streams carrying:

* events
* signals
* messages
* observations
* state changes
* deltas
* invalidations
* manifestation updates
* render updates
* telemetry
* graph changes

Do not define streams merely as transport mechanisms.

The architecture should support:

```text
semantic state
      ↓
state delta
      ↓
invalidation
      ↓
transformation
      ↓
manifestation update
```

and:

```text
observation
      ↓
event
      ↓
semantic transition
      ↓
state delta
      ↓
manifestation update
```

The LVGL event/update model is a validation case.

---

# 10. PERCEPTION REFINEMENT

Review `603_Perception`.

Ensure that perception can describe the acquisition and semantic interpretation of observations, rather than being restricted to computer vision or neural perception.

The conceptual pipeline should permit:

```text
Input
 ↓
Observation
 ↓
Perceptual interpretation
 ↓
Semantic event
 ↓
State transition
```

LVGL-style:

```text
touch
 ↓
input state
 ↓
event
 ↓
object transition
```

must be representable as a special case.

Do not make GUI input a foundational concept.

---

# 11. CONTROL REFINEMENT

Review `604_Control` where necessary.

Separate:

```text
Observation
```

from:

```text
Control decision
```

and:

```text
State transition
```

A system should be able to express:

```text
observation
   ↓
interpretation
   ↓
decision
   ↓
action
   ↓
state change
```

without conflating event handling with control semantics.

---

# 12. INTERFACES

Review `902_Interfaces`.

Clarify capability semantics for concepts including:

```text
Renderable
Observable
Controllable
Stateful
Transformable
Streamable
Serializable
Composable
Deterministic
Temporal
```

Determine whether `Manifestable` is actually required.

Do not introduce it merely because the word is attractive.

If the existing capability system already expresses manifestation adequately, extend the existing contract instead.

If a new capability is necessary, define:

* semantic meaning
* preconditions
* postconditions
* invariants
* inputs
* outputs
* failure semantics
* observability
* provider implications
* implementation independence

A capability MUST describe what an entity can participate in, not prescribe how the capability is implemented.

---

# 13. RENDERING

Review `A01_Render`.

The rendering domain MUST describe **visual manifestation semantics**, not UI semantics.

Do NOT introduce GUI widgets as render primitives.

Potential semantic concepts to evaluate include:

```text
Renderable
RenderTarget
RenderContext
RenderState
RenderOperation
RenderGraph
RenderPass
Visibility
Clipping
Compositing
Presentation
Invalidation
IncrementalRender
```

Only introduce concepts justified by the existing architecture.

Rendering MUST be defined as one possible manifestation mechanism.

The architecture should conceptually permit:

```text
Semantic Entity
      │
      ▼
Renderable capability
      │
      ├── LVGL
      ├── SVG
      ├── Canvas
      ├── WebGPU
      ├── Vulkan
      ├── framebuffer
      └── other providers
```

Do not make any renderer semantically authoritative.

---

# 14. RENDERING ≠ MANIFESTATION

This distinction is mandatory.

The semantic relationship should be:

```text
Manifestation
    ├── visual
    │     └── rendering
    ├── auditory
    ├── haptic
    ├── network
    ├── storage
    ├── telemetry
    ├── physical
    └── other domain manifestations
```

Do not create all of these domains merely to satisfy the diagram.

Instead, ensure that the semantic definition of Manifestation does not accidentally imply that visual rendering is the only form.

The architecture must remain open to future manifestation domains.

---

# 15. TRANSFORMS

Review `905_Transforms`.

Explicitly distinguish:

```text
semantic transformation
```

from:

```text
lowering
```

and:

```text
provider adaptation
```

For example:

```text
semantic structure
      ↓
morphological transformation
      ↓
geometric derivation
      ↓
render representation
      ↓
provider-specific lowering
```

These are not one operation.

A transformation preserves/changes semantic structure according to an explicitly defined contract.

A lowering changes representation toward a lower execution abstraction.

A provider adapts execution to a particular implementation substrate.

Preserve this distinction throughout documentation and implementation.

---

# 16. LOWERING

Review `903_Lowering`.

Make sure the model can express:

```text
Semantic IR
    ↓
Domain/Intermediate Representation
    ↓
Provider-compatible representation
    ↓
Executable representation
```

Do not encode LVGL-specific objects into the semantic IR.

If an LVGL lowering is eventually required, it belongs downstream of the semantic representation.

The semantic IR must remain independent of LVGL.

---

# 17. PROVIDERS

Review `904_Providers`.

Strengthen provider semantics around capability-driven selection.

A provider should conceptually expose:

```text
Capabilities
Constraints
Supported Representations
Execution Characteristics
Resource Requirements
Availability
Failure Modes
```

Provider selection should conceptually be:

```text
Semantic Requirement
+
Target Constraints
+
Provider Capabilities
+
Execution Conditions
        ↓
Provider Selection
```

The provider must never become semantic authority.

LVGL is a potential provider/reference implementation.

It must not become a mandatory SCR dependency.

---

# 18. LVGL AS A VALIDATION CASE ONLY

Use LVGL to validate the architecture.

Map concepts approximately as follows:

```text
LVGL Object
    → Core semantic entity + Morphology

LVGL Object Hierarchy
    → Topology + Morphology

LVGL Position/Size
    → Geometry

LVGL Layout
    → Geometry + Constraints + Transforms

LVGL State
    → Core State

LVGL Event
    → Stream/Event semantics

LVGL Input
    → Perception

LVGL Event Handling
    → Control / Transformation

LVGL Rendering
    → Render / Manifestation

LVGL Backend
    → Provider

LVGL generated/executable representation
    → Lowering

LVGL incremental rendering
    → Stream + Transform + Render
```

This mapping is a **validation matrix**, not an implementation dependency.

Do not add LVGL to `lib/`.

Do not add an `LVGL/` semantic domain.

Do not create LVGL-specific semantic primitives.

Do not modify SCR semantics merely to imitate LVGL.

If LVGL conflicts with SCR semantics, SCR semantics win.

---

# 19. REQUIRED DOCUMENTATION

For every semantic domain materially changed, update its normative definition.

At minimum evaluate:

```text
101_Core
302_Geometry
303_Topology
401_Morphology
603_Perception
604_Control
802_Stream
902_Interfaces
903_Lowering
904_Providers
905_Transforms
A01_Render
```

Do not mechanically edit all of them.

Only modify domains where the architectural refinement genuinely requires clarification or new normative semantics.

Every changed `101_definition.md` MUST contain, as applicable:

* purpose
* scope
* semantic model
* terminology
* invariants
* relationships
* composition
* state
* transformations
* inputs
* outputs
* errors
* observability
* representation independence
* implementation independence
* MLIR implications
* runtime implications
* validation requirements
* testing requirements
* completeness criteria

---

# 20. MANIFESTATION DEFINITION REQUIREMENTS

The Manifestation definition, wherever placed, MUST explicitly define:

### Identity

Manifestation identity MUST NOT be confused with semantic identity.

### Subject

What semantic structure is being manifested?

### Target

Where/in what domain does manifestation occur?

### Representation

Which representation is being used?

### Provider

Which implementation realizes the manifestation?

### Execution

How is it executed?

### Observability

How can successful manifestation be observed?

### Failure

What happens when manifestation cannot occur?

### Fidelity

What semantic properties are preserved?

### Loss

Which information may legitimately be omitted?

### Adaptation

How may manifestation adapt to target constraints?

### Reversibility

Is manifestation reversible?

If not, what information is lost?

### Incrementality

Can manifestation be updated from semantic deltas rather than rebuilt?

### Determinism

Under what conditions is manifestation deterministic?

### Provenance

Can a manifestation be traced back to the semantic source and transformation chain?

---

# 21. SEMANTIC FIDELITY

Introduce explicit language for semantic fidelity.

A manifestation MUST NOT silently claim to preserve semantics that it discards.

The model should distinguish:

```text
semantic equivalence
semantic preservation
semantic approximation
semantic projection
semantic reduction
lossy manifestation
```

For example:

```text
Full semantic object
        ↓
visual manifestation
        ↓
pixels
```

does not preserve all semantic information.

The pixels are therefore a projection/manifestation, not the semantic object itself.

This distinction must be reflected in normative language.

---

# 22. DELTA / INCREMENTAL SEMANTICS

Where appropriate, define how semantic deltas propagate into manifestations.

At minimum support the conceptual form:

```text
S₀
 ↓
ΔS
 ↓
Transformation(ΔS)
 ↓
ΔR
 ↓
Provider update
 ↓
ΔM
```

where:

* `S` = semantic state
* `R` = representation
* `M` = manifestation

Do not require all providers to support incremental updates.

Instead define capability semantics so a provider can declare whether incremental manifestation is supported.

This is important for embedded and real-time systems and is strongly validated by LVGL-style partial rendering.

---

# 23. ADAPTIVE EXECUTION

Ensure the resulting semantics are compatible with SCR's adaptive runtime.

The same semantic state MUST be capable of producing different manifestations depending upon:

* target hardware
* resource availability
* latency constraints
* precision requirements
* resolution
* acceleration
* memory
* bandwidth
* provider capabilities
* runtime conditions

The semantic structure must remain invariant while the realization strategy changes.

Conceptually:

```text
                    SAME SEMANTIC STATE
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
           Desktop       MCU          GPU
              │            │            │
            Provider     Provider     Provider
              │            │            │
              ▼            ▼            ▼
        Manifestation  Manifestation  Manifestation
```

---

# 24. MLIR REQUIREMENTS

Do not prematurely invent dialects or operations.

First establish semantic contracts.

Then inspect whether existing MLIR abstractions can represent the required semantics.

Only introduce new MLIR constructs where the semantic contract genuinely requires them.

The implementation MUST maintain:

```text
Semantic definition
        ↓
semantic IR contract
        ↓
MLIR representation
```

not:

```text
existing MLIR operation
        ↓
retroactive semantic definition
```

If a concept cannot yet be cleanly represented in MLIR, document the gap rather than distorting the semantic model.

---

# 25. TESTING STRATEGY

Testing MUST operate at several levels.

## 25.1 Semantic tests

Verify that definitions are internally coherent.

Test:

* terminology
* invariants
* relationships
* identity
* representation independence
* provider independence
* manifestation semantics
* transformation semantics

## 25.2 Structural tests

Verify:

* expected directories exist
* required definition files exist
* references resolve
* no forbidden duplicate concepts were introduced
* naming conventions remain valid

## 25.3 Contract tests

Verify interfaces such as:

```text
Renderable
Observable
Stateful
Transformable
Streamable
```

where implemented.

## 25.4 Representation tests

Demonstrate that the same semantic concept can have multiple representations without changing semantic identity.

## 25.5 Provider tests

Verify that provider-specific representations do not leak into semantic definitions.

## 25.6 Transformation tests

Verify:

```text
semantic → representation
representation → lower representation
lower representation → provider
```

remain distinct stages.

## 25.7 Runtime tests

Where runtime implementation exists, test:

* state transitions
* event propagation
* delta propagation
* manifestation
* failure
* provider selection
* incremental update
* observability

## 25.8 Regression tests

Run the entire existing test suite.

No existing semantic contract may regress.

---

# 26. REQUIRED NEGATIVE TESTS

Add explicit tests or validation checks preventing the following architectural failures:

### Provider leakage

A semantic definition MUST NOT contain LVGL-specific semantic types.

### Backend leakage

A semantic definition MUST NOT require a rendering backend.

### Representation authority

A representation MUST NOT become the canonical semantic source.

### Tree reduction

A higher-order topology MUST NOT be forced into a tree when meaning would be lost.

### Rendering conflation

Rendering MUST NOT be defined as equivalent to manifestation.

### Geometry conflation

Geometry MUST NOT become the universal representation of morphology.

### Transformation/lowering conflation

Transformation MUST NOT be treated as synonymous with lowering.

### Status contamination

Status files MUST NOT redefine semantic meaning.

### Graph contamination

Generated graph files MUST NOT become semantic authority.

### Filesystem semantics

Directory placement MUST NOT be treated as proof of semantic inheritance.

---

# 27. LVGL VALIDATION MATRIX

Create a validation artifact documenting how an LVGL-like system maps into SCR.

The artifact should demonstrate at least:

```text
Screen
Container
Button
Label
Style
State
Event
Input
Layout
Geometry
Rendering
Invalidation
Partial Update
Backend
```

For each, document:

```text
LVGL concept
SCR semantic concept
SCR domain
Representation
Transformation
Provider
Manifestation
```

The artifact MUST explicitly identify where LVGL concepts are merely implementation-specific.

The purpose is to prove that SCR can model the semantics without importing LVGL ontology.

---

# 28. EXAMPLE END-TO-END SCENARIO

Construct at least one end-to-end conceptual validation scenario.

Example:

```text
Semantic Entity:
    "Control"

Morphology:
    role = interactive_control
    relation = contained_by(Screen)

Geometry:
    derived from layout constraints

State:
    enabled = true
    active = false

Observation:
    pointer/touch input

Perception:
    identifies interaction with Control

Event:
    activate(Control)

Transformation:
    active := true

State Delta:
    active: false → true

Manifestation:
    visual appearance changes

Representation:
    provider-specific render representation

Provider:
    LVGL-like renderer

Output:
    visual presentation
```

The test MUST demonstrate that the semantic `Control` exists independently of its LVGL representation.

Do not create a semantic `LVGLButton`.

---

# 29. DOCUMENTATION QUALITY REQUIREMENTS

Definitions must use normative language consistently.

Use:

* MUST
* MUST NOT
* SHOULD
* SHOULD NOT
* MAY

where appropriate.

Avoid implementation-driven wording such as:

> "This is implemented using..."

inside normative semantic definitions unless describing a non-authoritative implementation note.

Prefer:

> "The semantic domain requires..."

and:

> "A provider may implement..."

---

# 30. DO NOT OVER-ARCHITECT

Do not introduce new top-level domains merely because a concept can be named.

Before adding anything, ask:

1. Does an existing domain already own this semantic?
2. Is this a cross-cutting mechanism?
3. Is this merely a representation?
4. Is this merely a provider?
5. Is this merely an implementation technique?
6. Is this genuinely a new semantic domain?

Prefer refinement and composition over proliferation.

---

# 31. DO NOT IMPLEMENT LVGL

Unless an existing SCR implementation explicitly requires a rendering provider, do not:

* add LVGL as a dependency
* vendor LVGL
* create LVGL bindings
* create LVGL adapters
* compile LVGL
* reproduce LVGL internals
* reproduce LVGL widget APIs

The purpose of this work is architectural generalisation.

An actual LVGL provider can be a later implementation increment.

---

# 32. VALIDATION COMMANDS

Discover the repository's canonical validation commands before running them.

Do not invent commands if the repository already defines canonical commands.

At minimum, after implementation:

1. validate semantic definitions
2. validate repository structure
3. validate references
4. regenerate derived artifacts where required
5. run unit tests
6. run integration tests
7. run static analysis
8. run formatting checks
9. run type checks where applicable
10. run build checks
11. run repository-specific semantic validation
12. inspect generated graph/status artifacts
13. verify working tree for unintended modifications

If a command fails because the repository is incomplete, distinguish:

```text
implementation failure
```

from:

```text
pre-existing repository failure
```

Do not conceal either.

---

# 33. STATUS UPDATES

After implementation, update status artifacts only with facts supported by evidence.

For each changed domain record:

* implementation state
* tests
* validation state
* known gaps
* dependencies
* provider availability
* lowering availability
* unresolved semantic questions

Do not mark a domain complete merely because its documentation exists.

A semantic definition may be complete while implementation remains partial.

Represent those as separate states.

---

# 34. DERIVED GRAPH

If `103_library.graph.json` or equivalent derived graph artifacts exist:

1. update authoritative definitions first
2. update implementation/status evidence
3. regenerate the graph using the repository's canonical mechanism
4. validate graph consistency
5. never hand-edit graph semantics

The graph must remain a derived view.

---

# 35. COMPLETENESS CRITERIA

This task is complete only when all of the following are true.

### Semantic completeness

* Manifestation has a precise definition.
* Representation is distinct from semantic identity.
* Manifestation is distinct from rendering.
* Rendering is understood as visual manifestation.
* Morphology can represent structured entities beyond physical geometry.
* Topology is richer than parent/child trees.
* Geometry is distinct from morphology and topology.
* Perception can model semantic interpretation of observations.
* Streams can carry semantic events, state changes and deltas.
* Transformations remain distinct from lowering.
* Providers remain distinct from semantics.
* Provider selection can be capability/constraint driven.

### Architectural completeness

* No LVGL-specific semantic primitive has been introduced.
* No provider has become semantic authority.
* No renderer has become semantically authoritative.
* No representation has become canonical by implementation accident.
* No unnecessary top-level domain has been added.
* Existing domain boundaries remain coherent.

### Documentation completeness

* All materially affected definitions are updated.
* Cross-domain relationships are documented.
* Invariants are documented.
* Validation requirements are documented.
* Implementation independence is explicit.
* MLIR implications are documented where relevant.

### Testing completeness

* Existing tests pass.
* New semantic validation passes.
* New structural validation passes.
* Negative architectural checks pass.
* Provider/representation independence is tested.
* LVGL mapping validation passes.

### Repository completeness

* Status reflects actual implementation state.
* Derived graph is regenerated correctly.
* No generated files were manually corrupted.
* No unrelated files were modified.
* Formatting/lint/build/type checks pass where applicable.
* Working tree contains only intentional changes.

---

# 36. FINAL AGENT REPORT

When finished, provide a concise implementation report containing:

## Changed

List every file/directory materially changed.

## Semantic changes

Explain what semantic contracts changed.

## Architectural changes

Explain how Manifestation, Representation, Morphology, Topology, Rendering, Streams, Providers, Transforms and Lowering now relate.

## Validation

List every validation command executed and its result.

## Tests

List new and existing tests executed.

## LVGL validation

Explain how the LVGL reference workload validates the new architecture without becoming a dependency.

## Remaining gaps

List every known incomplete area.

## Architectural questions

List only genuinely unresolved semantic questions.

Do not conceal uncertainty.

---

# 37. FINAL ARCHITECTURAL TEST

Before declaring the work complete, answer this question explicitly:

> **Can SCR represent the following without making LVGL part of its semantic ontology?**

```text
A semantic interactive entity exists.

It has a morphological structure.

It participates in a topology.

Its geometry is derived from structural and spatial constraints.

An external observation is perceived.

A semantic event occurs.

The entity's state changes.

A semantic delta propagates.

A transformation derives a representation.

A provider is selected according to capabilities and constraints.

The representation is lowered for that provider.

The provider executes.

The result becomes a visual manifestation.

The manifestation may be incrementally updated.

A different provider may produce a different manifestation from the same semantic state.

The original semantic identity remains unchanged throughout.
```

If the answer is **yes**, the architecture has passed the central validation criterion.

If the answer is **no**, do not patch around the failure with provider-specific concepts.

Identify which semantic abstraction is missing and refine the appropriate authoritative definition.

---

# 38. GOVERNING PRINCIPLE

The final implementation must preserve this conceptual ordering:

```text
                     MEANING
                        │
                        ▼
                 SEMANTIC FIELD
                        │
                        ▼
               SEMANTIC STRUCTURE
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
       TOPOLOGY      MORPHOLOGY      STATE
          │             │             │
          └─────────────┼─────────────┘
                        ▼
                  TRANSFORMATION
                        │
                        ▼
                   REPRESENTATION
                        │
                        ▼
                    LOWERING
                        │
                        ▼
                    PROVIDER
                        │
                        ▼
                    EXECUTION
                        │
                        ▼
                  MANIFESTATION
                        │
                        ▼
                    OBSERVATION
                        │
                        ▼
                   PERCEPTION
                        │
                        ▼
                 SEMANTIC CHANGE
                        │
                        └──────────────► FIELD
```

The runtime is the mechanism by which semantic topology becomes physical reality.

The semantic field remains the source of meaning.

**Do not invert this architecture.**

A renderer must not define the thing being rendered.

A provider must not define the semantics it provides.

A representation must not define the concept it represents.

A tree must not define a topology richer than itself.

An implementation must not define the specification.

And an external technology such as LVGL must remain what it is:

> **a concrete manifestation technology and architectural reference case, not the ontology of SCR.**
