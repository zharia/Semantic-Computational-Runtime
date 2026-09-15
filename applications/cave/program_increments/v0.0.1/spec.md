# Cave v0.0.1

## Information Gathering, Capability Mapping and Gap Analysis

**Path:** `applications/cave/program_increments/v0.0.1/spec.md`

**Status:** Draft

**Program Increment:** CAVE-000

**Primary objective:** Establish an evidence-based capability map between the current Semantic Computational Runtime (SCR) implementation and the requirements of the Cave application, identifying semantic, runtime, provider, and application gaps before significant Cave implementation begins.

---

# 1. Purpose

Cave is an applied reference application for the Semantic Computational Runtime (SCR).

The purpose of Cave is not merely to produce a spatial desktop. Cave is intended to exercise SCR against a substantial real-world workload and thereby determine:

1. what SCR already expresses;
2. what existing SCR primitives can be reused;
3. what existing primitives can be composed to express Cave requirements;
4. where SCR semantics are incomplete;
5. where SCR runtime/EGS capabilities are incomplete;
6. where provider capabilities are missing;
7. where Cave requires application-specific composition;
8. which apparent gaps are actually modelling errors;
9. which new semantic primitives, if any, are genuinely justified.

This program increment therefore **must not begin by implementing Cave-specific semantic abstractions**.

The first objective is to understand the current system.

---

# 2. Governing Principle

The following principle is normative:

> Cave shall reuse SCR semantic primitives wherever they can express the required concept without semantic distortion.

Cave shall not create a parallel semantic model merely because an existing SCR abstraction is inconvenient to use.

When a requirement cannot currently be expressed, it shall first be analysed to determine whether the problem is:

* an existing primitive that is insufficient;
* a missing composition or relation;
* a missing runtime capability;
* a missing provider capability;
* an application-specific concern;
* or a genuinely missing general semantic primitive.

Only after this classification may implementation proceed.

---

# 3. Scope

This increment covers:

* repository inspection;
* SCR library inspection;
* runtime inspection;
* EGS inspection;
* provider architecture inspection;
* existing documentation inspection;
* test and validation infrastructure inspection;
* Cave requirement identification;
* semantic capability mapping;
* provider capability mapping;
* runtime capability mapping;
* gap identification;
* gap classification;
* evidence collection;
* proposed remediation;
* implementation sequencing.

This increment does **not** primarily implement:

* the Cave desktop;
* the OGRE provider;
* the Louvre provider;
* Wayland integration;
* GPU resource bridging;
* the Cave spatial environment.

Those are subsequent increments unless a minimal proof is required to establish an information-gathering result.

---

# 4. Definitions

## 4.1 SCR primitive

A semantic concept explicitly represented by the SCR semantic library.

Examples may include concepts related to:

* identity;
* entity;
* graph;
* space;
* topology;
* geometry;
* transform;
* dynamics;
* rendering;
* streams;
* systems.

The actual inventory must be determined from the repository rather than assumed from this document.

## 4.2 Composition

A meaningful combination of existing SCR primitives that expresses a higher-level concept without requiring a new primitive.

Example:

```text
position + orientation + scale
        ↓
      transform
```

if that composition is already supported by SCR semantics.

A composition must not automatically become a new primitive.

## 4.3 Semantic gap

A requirement that cannot be represented correctly using the current SCR semantic model.

## 4.4 Runtime gap

A requirement that is semantically representable but cannot currently be executed, scheduled, communicated, instantiated, or managed by the SCR runtime/EGS.

## 4.5 Provider gap

A capability that is semantically and architecturally valid but is not currently supplied by the required external provider.

Examples:

* OGRE capability;
* Louvre capability;
* GPU interop;
* Wayland resource handling.

## 4.6 Application composition

A Cave-specific arrangement of existing SCR concepts that does not justify extending SCR.

## 4.7 Semantic distortion

A situation where an existing primitive can technically be made to represent a concept but its meaning, invariants, lifecycle, or relationships are changed sufficiently that the representation becomes misleading or architecturally incorrect.

---

# 5. Architectural Context

The target architecture is:

```text
                    Cave Application
                          │
                          ▼
                  SCR Semantic Graph
                          │
              ┌───────────┴───────────┐
              │                       │
             EGS              SCR Runtime
              │                       │
        Provider bindings              │
              │                       │
        ┌─────┴─────┐                 │
        │           │                 │
      OGRE        Louvre              │
        │           │                 │
        ▼           ▼                 ▼
    rendering    Wayland/KMS       execution
```

The fundamental architectural separation is:

```text
SCR semantic ontology
        ≠
SCR runtime
        ≠
provider
        ≠
manifestation
        ≠
Cave application composition
```

In particular:

> OGRE is a rendering provider, not Cave's semantic model.

> Louvre is a compositor/system provider, not Cave's semantic model.

> The OGRE scene graph is a manifestation of SCR state, not the authoritative state.

---

# 6. Required Investigation

The development agent shall perform an evidence-based inspection of the current repository before proposing implementation.

The investigation shall cover at minimum:

## 6.1 Repository structure

Inspect:

```text
applications/
lib/
runtime/
tests/
docs/
build configuration
dependency configuration
```

and any other relevant SCR directories.

Determine the repository's current conventions for:

* applications;
* libraries;
* providers;
* runtime components;
* specifications;
* status files;
* graph metadata;
* tests;
* program increments.

Do not assume directory names from this specification are already correct.

---

# 7. SCR Semantic Library Inventory

Produce an authoritative inventory of the current SCR semantic library.

For every relevant library/domain identify:

```text
domain
path
purpose
existing primitives
interfaces
relationships
dependencies
providers
tests
specification status
implementation status
```

The inventory must be based on the actual repository.

The agent shall distinguish:

1. implemented;
2. partially implemented;
3. specified but unimplemented;
4. referenced but unspecified;
5. experimental;
6. deprecated;
7. unknown.

No concept may be classified as implemented merely because documentation describes it.

---

# 8. Cave Requirement Model

Before mapping requirements to SCR, construct a preliminary Cave capability model.

The initial requirement categories shall include:

## Identity

* application identity;
* surface identity;
* semantic object identity;
* provider identity;
* resource identity;
* version/content identity.

## Graph

* entities;
* relationships;
* parent/child;
* containment;
* references;
* dependency;
* lifecycle relationships.

## Spatial

* world;
* space;
* position;
* orientation;
* scale;
* transform;
* hierarchy;
* bounds;
* coordinates;
* local/global transformation.

## Geometry

* shape;
* surface;
* mesh;
* bounds;
* intersection;
* ray;
* coordinate conversion.

## Rendering

* scene;
* renderable;
* camera;
* material;
* texture;
* shader;
* light;
* render target;
* frame;
* damage/update state.

## Resource

* external resource;
* native handle;
* ownership;
* lifetime;
* synchronization;
* format;
* dimensions;
* version/serial.

## Stream and Event

* input event;
* output event;
* lifecycle event;
* frame event;
* damage event;
* resource update;
* client event.

## System

* process/application;
* session;
* client;
* output;
* device;
* compositor;
* execution environment.

## Dynamics

* movement;
* navigation;
* animation;
* temporal state;
* transitions.

## Interaction

* pointer;
* keyboard;
* touch;
* ray casting;
* hit/intersection;
* focus;
* local-coordinate conversion.

These are **requirements to investigate**, not declarations that SCR must contain primitives with these names.

---

# 9. Capability Traceability Matrix

Create a machine-readable and human-readable traceability matrix.

Each Cave requirement shall contain at minimum:

| Field                   | Meaning                                               |
| ----------------------- | ----------------------------------------------------- |
| Requirement ID          | Stable identifier                                     |
| Cave requirement        | What Cave needs                                       |
| Semantic meaning        | What the requirement actually means                   |
| Existing SCR capability | Relevant SCR primitive/composition                    |
| SCR location            | Repository path                                       |
| Evidence                | Source/spec/test evidence                             |
| Reusable                | Yes/No                                                |
| Semantic distortion     | None/Low/High                                         |
| Runtime support         | Yes/Partial/No                                        |
| Provider support        | Yes/Partial/No                                        |
| Classification          | Reuse/Compose/Extend/New/Runtime/Provider/Application |
| Gap                     | Description if applicable                             |
| Proposed action         | Recommended remediation                               |
| Confidence              | High/Medium/Low                                       |

Example identifiers:

```text
CAVE-REQ-IDENTITY-001
CAVE-REQ-SPATIAL-001
CAVE-REQ-RENDER-001
CAVE-REQ-RESOURCE-001
CAVE-REQ-INPUT-001
```

The exact numbering scheme may be refined if repository conventions already exist.

---

# 10. Evidence Rules

Every capability classification must be supported by evidence.

Acceptable evidence includes:

* source code;
* existing SCR specification;
* tests;
* interfaces;
* provider implementation;
* runtime implementation;
* generated metadata;
* build configuration.

Documentation alone is insufficient to classify an unimplemented capability as implemented.

The agent must explicitly distinguish:

```text
FACT
```

from:

```text
INFERENCE
```

and:

```text
PROPOSED DESIGN
```

Where evidence is unavailable, mark the capability:

```text
UNKNOWN
```

rather than guessing.

---

# 11. Gap Classification

Every discovered gap shall be assigned exactly one primary classification.

## GAP-A — Semantic Primitive

The concept is general to SCR and cannot be represented without semantic distortion using existing primitives or compositions.

Potential action:

```text
extend SCR semantic library
```

## GAP-B — Semantic Composition

The required concept can be expressed by composing existing primitives, but that composition is not currently formalised.

Potential action:

```text
define relation/composition
```

Do not create a primitive unless analysis proves the composition is insufficient.

## GAP-C — Runtime

The semantic concept exists but SCR cannot currently execute or manage it.

Potential action:

```text
extend runtime / EGS
```

## GAP-D — Provider

SCR can express the concept, but OGRE, Louvre, or another provider lacks the implementation.

Potential action:

```text
extend provider
```

## GAP-E — Application Composition

The requirement is specific to Cave and does not justify changing SCR.

Potential action:

```text
implement in Cave
```

## GAP-F — Representation Error

The requirement appears to be missing only because the current proposed model is incorrect.

Potential action:

```text
reformulate requirement/model
```

This classification is important because it prevents every implementation problem from becoming a new SCR primitive.

---

# 12. Semantic Primitive Reuse Test

Before proposing any new SCR primitive, the agent must answer:

1. Does an existing primitive already represent this concept?
2. Can existing primitives represent it through composition?
3. Does an existing interface already provide the required behaviour?
4. Is the apparent gap actually a provider limitation?
5. Is the apparent gap actually a runtime limitation?
6. Is the requirement genuinely general beyond Cave?
7. Would introducing a primitive reduce semantic distortion?
8. What invariant would the new primitive establish?
9. What existing primitive cannot establish that invariant?
10. Can the proposed primitive be independently tested outside Cave?

A new primitive must not be proposed solely because it makes Cave implementation easier.

---

# 13. Provider Mapping

Produce a separate provider capability matrix.

At minimum:

```text
Provider: OGRE

Semantic capability
SCR representation
OGRE manifestation
Provider status
Missing implementation
Ownership model
Lifecycle
Synchronization
```

and:

```text
Provider: Louvre

Semantic capability
SCR representation
Louvre manifestation
Provider status
Missing implementation
Ownership model
Lifecycle
Synchronization
```

The provider analysis must preserve the semantic/provider boundary.

For example:

```text
SCR external resource
        ↓
provider binding
        ↓
Louvre LTexture / native GPU resource
```

is preferred to:

```text
SCR OgreTexture
SCR LouvreTexture
```

unless there is a compelling semantic reason otherwise.

---

# 14. External GPU Resource Analysis

Specifically investigate whether current SCR semantics can represent an externally owned GPU resource.

The investigation must consider:

* resource identity;
* native handle;
* provider;
* ownership;
* borrowed versus owned resources;
* lifetime;
* synchronization;
* format;
* dimensions;
* version/serial;
* resource invalidation;
* resource replacement.

The analysis must determine whether this belongs in:

```text
render
resource
system
stream
```

or an existing composition.

Do not create a Cave-specific GPU-resource abstraction before this analysis.

---

# 15. Input and Spatial Inversion Analysis

Determine whether existing SCR semantics can represent the mapping:

```text
screen coordinate
        ↓
camera
        ↓
ray
        ↓
intersection
        ↓
spatial object
        ↓
inverse transform
        ↓
local coordinate
        ↓
input target
```

The analysis must determine whether the required concepts already exist across:

* spatial;
* geometry;
* topology;
* math;
* render;
* stream/system.

If they exist independently but lack a formal composition, classify this as a semantic composition gap rather than immediately creating a new primitive.

---

# 16. Required Deliverables

CAVE-000 is complete only when the following artefacts exist.

## D-001 — Repository Inventory

A structured inventory of relevant SCR components.

## D-002 — Semantic Library Inventory

A capability map of the current semantic library.

## D-003 — Cave Requirement Catalogue

A structured list of Cave requirements.

## D-004 — Cave/SCR Traceability Matrix

Every requirement mapped to SCR capability or classified as a gap.

## D-005 — Provider Capability Matrix

OGRE and Louvre capabilities mapped to SCR semantics.

## D-006 — Gap Register

Every gap classified as:

```text
semantic primitive
semantic composition
runtime
provider
application
representation error
```

## D-007 — Proposed SCR Extensions

Only genuinely justified semantic extensions.

Each proposed extension must include:

* rationale;
* semantic definition;
* invariant;
* relationship to existing primitives;
* alternatives rejected;
* tests required;
* Cave requirement(s) motivating it.

## D-008 — CAVE-001 Implementation Plan

Only after the preceding analysis is complete.

The next increment must be derived from the evidence rather than predetermined.

---

# 17. Completion Criteria

CAVE-000 shall not be considered complete merely because documentation has been produced.

It is complete when:

* the repository has been inspected;
* the current semantic library has been inventoried;
* Cave requirements have been catalogued;
* requirements have been mapped to existing SCR capabilities;
* evidence has been recorded;
* unknowns have been explicitly identified;
* gaps have been classified;
* OGRE provider requirements have been identified;
* Louvre provider requirements have been identified;
* runtime/EGS requirements have been identified;
* proposed new primitives have been justified;
* implementation priorities have been derived from the analysis.

The output must make it possible for a subsequent developer to answer:

> **"What must actually be implemented next, and why?"**

without repeating the entire investigation.

---

# 18. Non-Goals

This increment shall not:

* implement the complete Cave desktop;
* redesign SCR without evidence;
* duplicate SCR semantics inside Cave;
* create OGRE-specific semantic primitives merely for convenience;
* create Louvre-specific semantic primitives merely for convenience;
* prematurely optimise GPU paths;
* prematurely solve multi-output rendering;
* replace niri;
* establish production desktop stability;
* assume that a proposed semantic abstraction is correct without testing it against SCR's existing ontology.

---

# 19. Development Method

The implementation process shall follow:

```text
Describe
   ↓
Inspect
   ↓
Map
   ↓
Analyse
   ↓
Classify
   ↓
Specify
   ↓
Test
   ↓
Validate
   ↓
Implement
```

The agent must not reverse this sequence by implementing first and rationalising the semantics afterwards.

---

# 20. Full Development Agent Instruction Prompt

The following prompt is normative for the development agent executing CAVE-000.

---

## DEVELOPMENT AGENT PROMPT — CAVE-000

You are implementing **CAVE-000** for the Semantic Computational Runtime repository.

The target project is **Cave**, a spatial Wayland desktop that will ultimately use SCR semantic primitives with OGRE as a rendering provider and Louvre as a Wayland/compositor provider.

However, **do not begin by implementing Cave**.

The purpose of this program increment is to determine what the current SCR implementation already provides and what is genuinely missing.

### Mission

Perform an evidence-based audit of the current SCR repository and produce a complete:

1. repository inventory;
2. SCR semantic-library capability inventory;
3. Cave requirement catalogue;
4. Cave → SCR capability traceability matrix;
5. OGRE provider capability matrix;
6. Louvre provider capability matrix;
7. runtime/EGS capability matrix;
8. semantic gap register;
9. proposed SCR extension register;
10. CAVE-001 implementation plan.

The primary question is:

> **How much of Cave can be expressed using the SCR capabilities that already exist?**

The secondary question is:

> **Where SCR cannot express something, what is the smallest correct architectural extension required?**

Do not optimise for the shortest path to a working Cave prototype.

Optimise for discovering the actual state and capability of SCR.

---

### 1. Repository inspection

Begin by inspecting the complete repository structure relevant to:

```text
lib/
runtime/
applications/
tests/
docs/
providers/
build configuration
dependency configuration
```

Do not assume these paths exist exactly as written.

Identify the repository's actual conventions.

Determine:

* where semantic libraries live;
* where specifications live;
* where status metadata lives;
* where graph metadata lives;
* where applications live;
* where providers live;
* where EGS lives;
* where runtime interfaces live;
* how tests are structured;
* how builds are performed;
* how validation is performed.

Record findings.

Do not modify architecture merely to fit this specification.

---

### 2. Inspect the SCR semantic library

Inventory the current semantic domains and primitives.

For each relevant domain identify:

```text
domain
path
specification
implementation
interfaces
dependencies
tests
providers
status
```

Determine whether each capability is:

```text
IMPLEMENTED
PARTIAL
SPECIFIED_ONLY
EXPERIMENTAL
REFERENCED_ONLY
DEPRECATED
UNKNOWN
```

Do not infer implementation status from names.

Inspect actual source and tests.

---

### 3. Search broadly before proposing anything new

For every Cave requirement search the entire SCR repository for existing representations.

Search by:

* terminology;
* type names;
* interfaces;
* graph relationships;
* mathematical representations;
* tests;
* provider abstractions;
* runtime abstractions.

Do not assume that a concept must exist under the expected English name.

For example, if Cave needs a transform, search for equivalent mathematical, geometric, spatial, or graph representations before proposing a new transform primitive.

---

### 4. Construct the Cave requirement model

Create a structured catalogue of the requirements necessary for the eventual Cave application.

At minimum analyse:

```text
identity
entity
graph
relationship
space
position
orientation
scale
transform
hierarchy
geometry
surface
mesh
bounds
ray
intersection
camera
renderable
material
texture
shader
light
render target
frame
damage
resource
external resource
ownership
lifetime
synchronization
stream
event
input
pointer
keyboard
touch
focus
application
client
session
output
process
navigation
movement
animation
persistence
```

These are requirements to investigate.

Do not assume each requires a separate SCR primitive.

---

### 5. Map requirements to SCR

For each requirement determine:

```text
existing primitive?
existing composition?
existing interface?
runtime support?
provider support?
```

Record exact repository evidence.

Use the following classification:

```text
REUSE
COMPOSE
SEMANTIC_EXTENSION
RUNTIME_EXTENSION
PROVIDER_EXTENSION
CAVE_COMPOSITION
REPRESENTATION_ERROR
UNKNOWN
```

Do not classify something as `SEMANTIC_EXTENSION` until the reuse and composition possibilities have been investigated.

---

### 6. Semantic extension discipline

For every proposed new SCR primitive answer all of these:

1. What is its semantic definition?
2. Why is it not already represented?
3. Why can existing primitives not express it?
4. What invariant does it establish?
5. Is that invariant general to SCR?
6. Is the concept independent of Cave?
7. Could it be expressed as a relation?
8. Could it be expressed as a composition?
9. Could it instead belong to a provider?
10. Could it instead belong to runtime/EGS?
11. What tests would prove its correctness?

If these questions cannot be answered, do not propose the primitive.

---

### 7. Do not contaminate SCR with provider concepts

Do not introduce semantic concepts whose only purpose is to mirror:

```text
Ogre::SceneNode
Ogre::Item
Ogre::Texture
Ogre::Camera
Ogre::SceneManager
Louvre::LTexture
Louvre-specific objects
OpenGL-specific handles
```

Instead determine the general semantic concept first.

Provider-specific objects belong behind provider boundaries.

The desired direction is:

```text
SCR semantic concept
        ↓
provider binding
        ↓
OGRE/Louvre implementation
```

not:

```text
Cave
  ↓
OGRE/Louvre object model
  ↓
SCR
```

---

### 8. Analyse external GPU resources

Explicitly investigate whether SCR already has a suitable abstraction for:

* external GPU resources;
* native handles;
* resource ownership;
* borrowed resources;
* lifetime;
* synchronization;
* resource versions/serials;
* format;
* dimensions.

The eventual Cave architecture will likely need to represent a Louvre-owned GPU resource that OGRE can borrow.

Do not implement that mechanism during CAVE-000 unless a tiny experimental probe is required to establish feasibility.

The objective here is semantic and architectural classification.

---

### 9. Analyse spatial input

Determine whether SCR can represent:

```text
screen
→ camera
→ ray
→ intersection
→ spatial object
→ inverse transform
→ local coordinate
→ input event
```

Search across:

```text
math
geometry
spatial
topology
render
stream
system
```

Determine whether this is:

* already supported;
* composable;
* a semantic gap;
* a runtime gap;
* or a provider gap.

---

### 10. Analyse OGRE as a provider

Do not design Cave directly around OGRE.

Determine what the OGRE provider would need to manifest from SCR.

At minimum investigate:

```text
world/scene
spatial object
transform
geometry
camera
material
texture
render target
external GPU resource
frame/render lifecycle
```

Distinguish:

```text
SCR semantic requirement
```

from:

```text
OGRE implementation requirement
```

---

### 11. Analyse Louvre as a provider

Determine what Louvre needs to provide to SCR.

At minimum investigate:

```text
Wayland client lifecycle
surface
buffer
DMA-BUF
GPU resource
synchronization
input
output
presentation
damage
session
KMS
```

Again, distinguish:

```text
semantic concept
```

from:

```text
Louvre mechanism
```

---

### 12. Inspect EGS/runtime

Determine whether EGS/runtime can currently support the eventual Cave application model.

Investigate:

* application registration;
* semantic graph loading;
* provider discovery;
* provider binding;
* lifecycle;
* messaging;
* events;
* streams;
* execution;
* resource management;
* identity;
* versioning;
* shutdown/restart.

Classify each requirement independently.

Do not automatically classify runtime limitations as semantic limitations.

---

### 13. Create the gap register

Every gap must have:

```text
GAP-ID
Requirement-ID
Description
Evidence
Classification
Severity
Generality
Existing alternatives
Recommended action
Dependencies
Validation method
```

Severity should distinguish at least:

```text
BLOCKING
HIGH
MEDIUM
LOW
INFORMATIONAL
```

A gap is `BLOCKING` only if it prevents the next meaningful Cave milestone.

---

### 14. Distinguish facts from proposals

In all documentation explicitly distinguish:

```text
FACT
```

from:

```text
INFERENCE
```

from:

```text
PROPOSED DESIGN
```

from:

```text
UNKNOWN
```

Never present a proposed abstraction as though it already exists.

Never infer implementation status from documentation alone.

---

### 15. Tests and validation

For every proposed semantic extension identify the test required to prove it.

Follow SCR's established principle:

```text
describe
→ spec
→ test
→ validate
```

Do not create implementation without a corresponding validation strategy.

Where existing SCR capabilities are reused, identify the existing tests that prove their validity.

Where tests do not exist, record that as a validation gap.

---

### 16. Avoid premature implementation

Do not implement:

* the full Cave desktop;
* OGRE integration;
* Louvre integration;
* Wayland handling;
* GPU resource bridging;
* navigation;
* input routing;

during this increment unless a narrowly scoped experiment is required to answer an otherwise unresolved architectural question.

If such an experiment is necessary:

1. state the question;
2. define the smallest experiment;
3. execute it;
4. record the result;
5. remove experimental code if it does not belong in the final architecture.

---

### 17. Required output files

Create the appropriate documentation using existing repository conventions.

At minimum produce:

```text
CAVE-000 repository inventory
CAVE-000 SCR capability inventory
CAVE-000 Cave requirement catalogue
CAVE-000 Cave/SCR traceability matrix
CAVE-000 provider capability matrix
CAVE-000 runtime/EGS capability matrix
CAVE-000 semantic gap register
CAVE-000 proposed SCR extension register
CAVE-000 CAVE-001 implementation plan
```

Do not invent an alternative documentation structure if the repository already has an established convention.

If the repository requires:

```text
101_spec.md
102_status.yaml
103_library.graph.json
```

or equivalent metadata, follow that convention.

---

### 18. Validation

Before declaring CAVE-000 complete:

* run the relevant repository validation;
* run documentation/schema validation where available;
* run relevant existing tests;
* ensure all referenced paths actually exist;
* ensure all claimed capabilities have evidence;
* ensure all proposed gaps have classifications;
* ensure no proposed primitive duplicates an existing capability;
* ensure provider concepts have not leaked into SCR semantics;
* ensure unknowns are explicitly marked;
* ensure the next implementation increment follows from the analysis.

---

### 19. Final report

End with a concise executive summary containing:

```text
SCR capabilities already sufficient for Cave
SCR capabilities requiring composition
SCR semantic gaps
SCR runtime/EGS gaps
OGRE provider gaps
Louvre provider gaps
Cave-specific composition
blocking issues
recommended next milestone
```

The most important conclusion must answer:

> **What is the minimum set of changes required before CAVE-001 can begin?**

Do not answer this from assumptions.

Derive it from the repository evidence.

---

### 20. Final architectural constraint

The ultimate Cave architecture is expected to be:

```text
                    CAVE
                      │
                      ▼
              SCR semantic graph
                      │
                      ▼
                     EGS
                      │
          ┌───────────┴───────────┐
          │                       │
     OGRE provider          Louvre provider
          │                       │
          ▼                       ▼
      Rendering              Wayland/KMS
          │                       │
          └───────────┬───────────┘
                      ▼
                     GPU
```

Cave itself should remain a **consumer of SCR**, not a second implementation of SCR.

If Cave discovers that SCR cannot express something fundamental, fix SCR where appropriate.

If OGRE cannot manifest an SCR concept, fix the provider.

If Louvre cannot provide an infrastructure capability, fix the provider.

If the concept is merely a Cave-specific arrangement, keep it in Cave.

If the problem is caused by an incorrect semantic model, correct the model rather than adding another primitive.

The objective of this program increment is therefore not to maximize code produced.

It is to maximize **architectural knowledge with evidence** and establish the smallest correct implementation path for the next increment.

---

# End of CAVE-000 Specification
