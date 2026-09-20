# Development Agent Instruction

## SCR Semantic Correction, Reconciliation and Conformance

**File:** `program_increments/v0.0.3/agent-objectives/002_semantic-correction-and-conformance.md`

**Repository:** `zharia/Semantic-Computational-Runtime`

**Program Increment:** `v0.0.3`

**Objective:** Correct, reconcile, formalize, test, and validate the outstanding semantic issues identified during the review of the O3DE/AzFramework assessment and associated v0.0.3 milestone work.

---

# 1. Mission

The purpose of this objective is to bring the affected portions of the Semantic Computational Runtime (SCR) from **assessment/draft state toward internally coherent, formally specified, and evidence-backed semantic definitions**.

The preceding assessment identified several areas where the current work risks:

* duplicating existing SCR concepts rather than extending them;
* confusing SCR semantics with provider-specific semantics;
* asserting mathematical properties without sufficient definitions or proofs;
* conflating identity, scope, ownership, authority, manifestation, replication, and projection;
* treating provider implementation details as universal semantic rules;
* imposing lifecycle or materialization structures that are too restrictive;
* making physics claims that are not generally valid;
* claiming semantic guarantees without specifying the conditions under which they hold;
* confusing documented, specified, implemented, tested, and validated status.

This objective must correct those issues.

The governing principle is:

> **Align → integrate → project → adapt → execute.**

Do **not**:

> invent → replace → centralize.

SCR is a semantic integration and execution framework. It must preserve the authority of established standards, mathematical definitions, domain models, and external providers while defining the contracts necessary for composition, integration, identity, transformation, execution, and verification.

---

# 2. Primary Rule: Inspect Before Changing

Before creating, modifying, renaming, or deleting any specification:

1. Inspect the current repository.
2. Identify the existing canonical SCR definition/specification for the concept.
3. Identify whether the relevant document is:

   * canonical;
   * provisional;
   * draft;
   * placeholder;
   * provider-specific;
   * implementation documentation;
   * test documentation;
   * generated material.
4. Trace references and dependencies.
5. Determine whether the issue can be resolved by:

   * correcting an existing definition;
   * extending an existing definition;
   * adding a constraint;
   * adding a profile;
   * adding a mapping;
   * adding a provider adapter;
   * adding a proof/test;
   * or genuinely defining a new semantic construct.

**Do not create a new parallel ontology merely because an existing concept is incomplete.**

Where an existing SCR definition already covers the concept, amend or extend it rather than creating a competing definition.

---

# 3. Evidence Discipline

Every substantive conclusion produced by this objective must be classified.

Use the following evidence ladder:

### 3.1 Proposed

A design proposal with rationale but without sufficient canonical specification or validation.

### 3.2 Documented

A canonical repository definition/specification exists and records the semantic rule and its provenance.

### 3.3 Formally Specified

The rule has explicit:

* inputs;
* outputs;
* preconditions;
* postconditions;
* invariants;
* assumptions;
* failure conditions;
* applicable domain/profile.

### 3.4 Formally Verified

A machine-checkable proof or equivalent formal verification artifact exists, together with its assumptions and verification environment.

### 3.5 Implemented

The semantics have an executable implementation or provider mapping.

### 3.6 Tested

A reproducible automated or manual test demonstrates the specified behavior.

### 3.7 Validated

Conformance has been demonstrated against an external standard, provider, mathematical reference, or independently defined expected behavior.

Do not use a stronger status merely because a weaker status exists.

For example:

> documented ≠ implemented
> implemented ≠ tested
> tested ≠ validated
> specified ≠ formally verified

Every modified objective/status document must preserve this distinction.

---

# 4. Scope of Work

This correction sprint MUST address all of the following areas:

1. coordinate-system semantics;
2. transform mathematics;
3. lifecycle semantics;
4. entity/component semantics;
5. context/scope semantics;
6. identity semantics;
7. ownership and authority semantics;
8. manifestation, projection, replication, cloning, and migration semantics;
9. materialization/lowering semantics;
10. physics semantics;
11. distributed state semantics;
12. evidence/status/conformance reporting.

These areas are coupled and must be reconciled rather than fixed independently where their definitions intersect.

---

# 5. Coordinate-System Semantics

## 5.1 Identify the canonical SCR convention

Determine whether SCR already defines:

* handedness;
* up axis;
* forward axis;
* right axis;
* coordinate units;
* world/local frame semantics;
* orientation conventions.

Do not assume that a convention found in the O3DE assessment is canonical SCR.

If no canonical convention exists, document the gap before proposing one.

If one exists, treat it as authoritative unless there is explicit evidence that it must be changed.

---

## 5.2 Resolve all contradictory axis claims

The reviewed material contains conflicting descriptions involving:

* SCR axes;
* O3DE axes;
* forward/up/right conventions.

Resolve this explicitly.

Produce a mathematically precise mapping between coordinate frames.

The mapping MUST specify:

* source basis;
* destination basis;
* handedness;
* axis permutation;
* axis sign changes;
* unit conversion;
* origin relationship where applicable;
* point transformation;
* vector transformation;
* normal transformation;
* orientation transformation;
* matrix representation;
* quaternion representation.

Do not describe an axis permutation informally and consider the problem solved.

---

## 5.3 Define transformation semantics

For each transformation type establish:

```text
source frame
destination frame
transformation
inverse transformation
composition rule
identity transformation
```

The specification must make clear whether transformations are:

* active or passive;
* local-to-parent or parent-to-local;
* point transforms or vector transforms;
* row-major or column-major where relevant;
* left- or right-multiplied;
* quaternion convention and multiplication order.

These conventions must be explicit.

---

## 5.4 Unit semantics

Define the relationship between:

* SCR units;
* provider units;
* asset units;
* simulation units;
* rendering units.

Unit conversion must not be hidden inside an unexplained coordinate mapping.

Where dimensional analysis is applicable, establish the invariant:

> physical quantities must preserve dimensional meaning across representation/provider boundaries.

---

# 6. Transform Algebra

The reviewed work conflates pose and general transformation.

Correct this.

## 6.1 Distinguish:

At minimum distinguish:

* position;
* orientation;
* pose;
* scale;
* rigid transform;
* similarity transform;
* affine transform;
* general linear transform.

Do not call every position/orientation/scale tuple a "pose."

---

## 6.2 Define the supported transformation class

Determine which transformation class SCR actually requires.

For example:

```text
Rigid transform
T = (R, t)

Similarity transform
T = (sR, t)

Affine transform
T = (A, t)
```

Do not introduce these merely as mathematical decoration. Select the smallest model that is actually required by SCR.

---

## 6.3 Address scale and rotation correctly

Explicitly investigate the interaction between:

* non-uniform scale;
* rotation;
* composition;
* shear.

If SCR represents transforms as:

```text
translation + rotation + scale
```

demonstrate the conditions under which that representation is closed under composition.

If it is not generally closed, state the limitation explicitly and determine whether SCR:

* restricts the supported transform class;
* adds shear/general affine representation;
* decomposes only under specified conditions;
* or treats certain representations as provider-specific.

Do not assert group properties that the representation does not satisfy.

---

## 6.4 Required mathematical properties

For every supported transformation class, define and test where applicable:

* identity;
* inverse;
* associativity;
* closure;
* composition;
* frame conversion;
* round-trip conversion.

Where a mathematical structure genuinely forms a group, monoid, group action, etc., state the exact structure and prove the relevant properties.

Where it does not, do not force it into that abstraction.

---

## 6.5 Required validation

Create tests for:

1. identity;
2. inverse;
3. composition;
4. round-trip provider conversion;
5. axis conversion;
6. unit conversion;
7. orientation conversion;
8. point transformation;
9. vector transformation;
10. normal transformation where relevant;
11. scale composition;
12. non-uniform-scale edge cases.

Include numerical tolerances explicitly.

---

# 7. Lifecycle Semantics

The existing assessment defines a lifecycle resembling:

```text
Instantiated
    ↓
Initialized
    ↓
Active
    ↕
Deactivated
    ↓
Destroyed
```

Do not automatically elevate this provider/runtime pattern into a universal SCR entity law.

---

## 7.1 Separate semantic lifecycle from execution lifecycle

Determine which lifecycle semantics belong to:

* all semantic entities;
* executable entities;
* components;
* provider manifestations;
* runtime hosts;
* resources;
* graph nodes;
* remote references.

A declarative semantic object does not necessarily have the same lifecycle as an executable runtime object.

---

## 7.2 Define lifecycle as a profile where necessary

If the O3DE-style lifecycle is useful, express it as an applicable profile or executable entity lifecycle rather than assuming it applies universally.

Define:

* states;
* legal transitions;
* transition preconditions;
* postconditions;
* failure states;
* destruction semantics;
* ownership implications;
* provider-specific extensions.

---

## 7.3 Activation ordering

Do not impose a global total order unless SCR actually requires one.

Where dependency ordering exists, define it as a graph constraint.

Distinguish:

* dependency ordering;
* initialization ordering;
* activation ordering;
* execution scheduling;
* semantic composition.

A DAG may be an implementation mechanism or a semantic dependency relation; determine which.

---

# 8. Entity and Component Semantics

The O3DE model must not be copied wholesale into SCR.

Determine which properties are genuinely semantic and which are O3DE implementation choices.

---

## 8.1 Entity semantics

Define an SCR entity in terms of its semantic role.

Do not assume:

> entity = runtime object with behavior.

An entity may be:

* declarative;
* executable;
* persistent;
* remote;
* projected;
* replicated;
* simulated;
* purely referential.

If SCR requires a common abstraction, define the minimum shared semantics.

---

## 8.2 Component semantics

Separate:

* component as semantic composition;
* component as executable implementation;
* component as provider adapter;
* component as capability provider;
* component as implementation object.

Do not assume:

> one component of a given type per entity.

If cardinality constraints exist, define them explicitly.

Examples of possible cardinality semantics:

```text
exactly one
zero or one
one or more
zero or more
provider-defined
profile-defined
```

---

## 8.3 Component identity

Do not automatically assert that components have no identity.

Determine whether identity is:

* unnecessary;
* inherited from entity membership;
* independently addressable;
* required for distributed execution;
* required for provider mapping.

If O3DE components lack independent semantic identity, document that as an O3DE mapping property rather than an SCR universal rule unless independently justified.

---

# 9. Context, Scope, Identity, Ownership and Authority

These concepts MUST be separated.

At minimum define independently:

```text
SID
scope membership
context
ownership
authority
provider manifestation
replica
projection
clone
snapshot
```

---

## 9.1 Identity

SCR SID remains the identity authority.

Document:

* identity uniqueness domain;
* authority;
* persistence;
* derivation;
* verification;
* hierarchy;
* provider mapping.

Do not equate:

```text
SID
EntityId
USD prim path
network identifier
memory address
database key
```

These may be mappings or manifestations.

---

## 9.2 Scope

Define scope independently from identity.

A scope answers questions such as:

> where/within which semantic domain does this reference participate?

Do not use scope membership as an implicit identity mechanism.

---

## 9.3 Context

Define whether context means:

* execution context;
* semantic context;
* ownership scope;
* provider runtime;
* dependency environment;
* spatial context.

If multiple meanings are necessary, use explicit terminology rather than overloading "context."

---

## 9.4 Ownership

Define ownership independently from authority.

Ownership may describe:

* resource responsibility;
* lifecycle responsibility;
* administrative control;
* simulation ownership;
* data ownership.

Do not assume ownership and authority are identical.

---

## 9.5 Authority

Define authority in terms of which actor/provider/domain is authoritative for a particular semantic state or operation.

A server may be authoritative for a state variable without being the semantic owner of the entity itself.

Authority MUST be scoped to something explicit.

---

# 10. Manifestation, Projection, Replication, Clone and Migration

These operations must be distinct.

Define the semantics of:

### Manifestation

Mapping a semantic object into a provider/runtime representation.

### Projection

Representing some semantic state or subset in another representation/domain.

### Replication

Maintaining multiple instances of state under a specified synchronization relationship.

### Clone

Creating a new semantic identity derived from an existing object.

### Snapshot

Capturing state at a specified time/version.

### Provider migration

Moving or re-instantiating a manifestation between providers while preserving the specified semantic invariants.

### Scope transfer

Changing scope membership without implying identity change.

These operations must not be treated as synonyms.

---

## 10.1 SID preservation

Explicitly specify which operations preserve SID.

For example, determine whether:

```text
manifestation      → same SID
projection         → same or derived SID?
replica             → same or distinct SID?
clone               → distinct SID
snapshot            → same identity + versioned state
migration           → same SID
scope transfer      → same SID
```

Do not assume the answer; derive it from the canonical SCR identity model.

---

# 11. Materialization and Lowering

The existing materialization work contains useful concepts but risks imposing a fixed universal pipeline.

Do not assume every SCR artifact passes through one mandatory sequence.

---

## 11.1 Replace fixed pipeline assumptions with contracts

If the architecture supports stages such as:

```text
Source
Semantic
Intermediate
Deployable
Runtime
Observed
```

treat these as representations/profiles in a transformation graph unless the repository establishes them as universal stages.

Define:

* input representation;
* output representation;
* semantic preservation requirements;
* allowed loss;
* approximation;
* provenance;
* dependencies;
* reproducibility;
* failure;
* invalidation.

---

## 11.2 Source authority

Do not assert universally:

> source representation is semantic authority.

Distinguish:

* representation authority;
* semantic authority;
* schema authority;
* provider authority;
* execution authority.

USD, O3DE, SCR, physics engines, asset systems, etc. may have authority over different aspects.

---

## 11.3 Determinism

Separate:

1. semantic determinism;
2. reproducible transformation;
3. deterministic artifact generation;
4. bitwise reproducibility.

These are not equivalent.

Document the scope and assumptions for any determinism guarantee.

---

## 11.4 Rematerialization

Do not define arbitrary rematerialization as lossless reconstruction unless this is actually guaranteed.

If runtime state can diverge from source state, define:

* provenance;
* dirty state;
* invalidation;
* mutation authority;
* snapshot requirements;
* reconstruction limits;
* irreversible transformations.

A runtime representation must not silently imply that the original source can always be reconstructed.

---

# 12. Physics Semantic Corrections

Review all physics definitions against:

* existing SCR Physics definitions;
* existing Dynamics definitions;
* existing Simulation definitions;
* established physics terminology;
* the semantics actually exposed by providers.

Do not create a parallel physics ontology.

---

## 12.1 Static body

Do not define static body as necessarily meaning:

> permanent fixed landscape.

Static means provider/domain-specific immobility constraints as defined by the applicable physics model.

Insertion/removal and lifecycle remain separate questions.

---

## 12.2 Kinematic body

Do not define kinematic body as universally:

> infinite mass.

Define the actual behavioral property.

Distinguish:

* dynamic;
* kinematic;
* static;
* constrained;
* scripted;
* externally driven.

---

## 12.3 Character controllers

Do not automatically model a character controller as a subtype of kinematic rigid body.

Determine whether the semantic model should represent:

* controller;
* body;
* collision representation;
* locomotion system;
* constraints;

as separate concepts.

---

## 12.4 Contact semantics

Do not elevate provider-internal collision phases into SCR semantics unless externally observable and required.

Possible phases such as:

```text
broad phase
narrow phase
contact generation
solver
integration
```

are generally implementation details unless SCR explicitly exposes them.

Define only observable semantic events/state transitions.

---

## 12.5 Conservation laws

Do not assert universal energy conservation for practical collision systems.

Account for:

* restitution;
* friction;
* damping;
* motors;
* external work;
* numerical integration;
* constraints;
* intentionally dissipative systems.

If an invariant is intended, specify the model under which it applies.

---

## 12.6 Degrees of freedom

Do not assign universal DOF values to joints without defining:

* coordinate frames;
* constraint model;
* axis conventions;
* limits;
* locked/unlocked axes;
* translational/rotational assumptions.

---

## 12.7 Physics validation

Where feasible, create minimal reference tests for:

* rigid body state;
* static/kinematic/dynamic distinctions;
* transformation;
* velocity;
* acceleration;
* force;
* impulse;
* constraints;
* contact;
* restitution;
* friction;
* conservation assumptions.

Each test must state its physical assumptions.

---

# 13. Distributed State Semantics

The distributed runtime model must explicitly distinguish:

```text
authority
ownership
replication
observation
prediction
reconciliation
transport
consistency
```

---

## 13.1 Authority

Define exactly what state or operation an authority controls.

Examples:

```text
entity state
component state
individual field
simulation result
command acceptance
resource
```

Avoid an undifferentiated concept of "server authority."

---

## 13.2 Replication

Define:

* source state;
* replica state;
* synchronization relationship;
* update model;
* versioning;
* ordering;
* loss handling;
* recovery;
* conflict behavior.

Do not state that SCR replication automatically guarantees consistency without specifying the consistency model.

---

## 13.3 Delta transmission

If delta encoding is used, distinguish:

> representation optimization

from:

> semantic replication guarantee.

A delta is an encoding of a state transition. It does not itself establish correctness, ordering, durability, or convergence.

---

## 13.4 Prediction

Define prediction as speculative state derived from incomplete/future assumptions.

Specify:

* prediction input;
* authoritative state;
* prediction horizon;
* correction;
* rollback;
* replay;
* divergence detection.

---

## 13.5 Reconciliation

Define reconciliation explicitly.

At minimum determine:

```text
authoritative state
predicted state
divergence criterion
correction mechanism
rollback requirement
replay requirement
conflict policy
```

Do not treat reconciliation as merely "replace local state."

---

## 13.6 Observation

An observation may be:

* delayed;
* partial;
* sampled;
* quantized;
* filtered;
* projected.

Therefore observation semantics must not imply exact instantaneous state equivalence.

---

## 13.7 Transport

Separate transport guarantees from application consistency.

Transport may define:

* ordering;
* delivery;
* duplication;
* loss;
* retransmission;
* framing;
* flow control.

SCR semantic consistency must define what these properties mean at the application/state layer.

---

# 14. Provider Boundary

Throughout this objective, maintain strict separation between:

### SCR semantic authority

The semantic contract and invariants defined by SCR.

### External standard authority

For example:

* USD semantics;
* AMQP semantics;
* mathematical standards;
* established physics definitions.

### Provider authority

For example:

* O3DE;
* Bullet;
* PhysX;
* OpenVDB;
* H3;
* Ogre3D.

### Representation authority

The schema/format governing a particular representation.

### Implementation behavior

Specific behavior of a software implementation.

A provider must not become semantic authority merely because SCR currently uses it.

---

# 15. O3DE/AzFramework Mapping

Revisit the original O3DE/AzFramework assessment after correcting the SCR semantics.

For every O3DE concept classify it as one of:

```text
SCR canonical semantic
SCR extension
SCR profile
provider mapping
provider implementation
representation
adapter concern
not applicable
research/open issue
```

Examples to investigate include:

* EntityId;
* Entity;
* Component;
* ComponentDescriptor;
* RuntimeHost;
* Transform;
* lifecycle;
* ownership;
* networking;
* replication;
* prediction;
* reconciliation;
* physics;
* assets;
* SceneAPI;
* USD;
* runtime manifestation.

Do not import O3DE restrictions into SCR merely because they are present in O3DE.

---

# 16. Canonical Definition Reconciliation

For each affected concept produce a reconciliation record:

```text
Concept:
Existing SCR definition:
Location:
Canonical status:
External authority:
Problem identified:
Required correction:
Provider-specific aspects:
New invariant:
Proof required:
Test required:
Validation required:
Affected dependencies:
```

Where multiple definitions exist, identify the canonical one and document the others as mappings, historical drafts, profiles, or deprecated material as appropriate.

Do not silently leave contradictory definitions in the repository.

---

# 17. Formalization Requirements

For mathematically meaningful concepts, provide explicit formal definitions.

At minimum use:

* sets;
* functions;
* relations;
* state transitions;
* predicates;
* invariants;
* composition laws;

where appropriate.

Avoid formal notation where it adds no useful precision.

---

## 17.1 Lean

Where the repository already uses Lean/mathlib and the concept is suitable for formal verification:

1. express the core mathematical definition;
2. state the invariant;
3. prove the invariant where feasible;
4. record assumptions;
5. link the proof to the specification.

Do not require Lean proofs for concepts that are primarily empirical, provider-specific, or operational.

---

# 18. Testing Strategy

Tests must correspond to semantic claims.

Do not create tests merely to increase test count.

At minimum develop focused tests for:

### Coordinates

* basis conversion;
* handedness;
* round-trip;
* units.

### Transforms

* identity;
* inverse;
* composition;
* round-trip;
* scale edge cases.

### Identity

* uniqueness;
* mapping;
* clone;
* replication;
* migration.

### Lifecycle

* valid transitions;
* invalid transitions;
* profile-specific behavior.

### Context/scope

* membership;
* transfer;
* manifestation;
* multiple manifestations.

### Materialization

* transformation;
* provenance;
* invalidation;
* deterministic/reproducible behavior.

### Physics

* explicitly modelled invariants.

### Distributed state

* authority;
* prediction;
* reconciliation;
* versioning;
* replica divergence.

Every test must identify the semantic claim being tested.

---

# 19. Negative Testing

The correction sprint MUST include adversarial tests.

Specifically attempt to falsify:

* coordinate conversion assumptions;
* transform group assumptions;
* lifecycle universality;
* identity equivalence;
* ownership/authority equivalence;
* replica identity assumptions;
* materialization reversibility;
* determinism claims;
* conservation claims;
* replication consistency claims.

A failed invariant is useful information.

Do not modify the invariant simply to make the test pass.

First determine whether:

1. the implementation is wrong;
2. the specification is wrong;
3. the assumption is incomplete;
4. the invariant is too strong.

---

# 20. Documentation Structure

Use the repository's existing documentation structure.

Do not create duplicate top-level documentation trees merely to accommodate this work.

Where the repository convention requires:

```text
101_definition.md
101_spec.md
102_status.yaml
103_library.graph.json
```

preserve that convention.

Update the appropriate canonical files rather than creating parallel versions.

Every new specification must contain, where applicable:

```text
Purpose
Scope
Terminology
Semantic Definition
Mathematical Model
Invariants
Preconditions
Postconditions
Failure Conditions
Mappings
Provider Considerations
Provenance
Implementation Status
Testing Status
Validation Status
Open Questions
```

---

# 21. Provenance

Every definition derived from an external technology or standard must record its provenance.

At minimum record:

```text
Source
Version/date where relevant
Relevant concept
What SCR adopts
What SCR changes
What remains provider-specific
```

Do not imply that SCR owns semantics originating elsewhere.

---

# 22. Status Updates

Update status only from evidence generated during this objective.

Do not mark an item:

* implemented without implementation evidence;
* tested without test evidence;
* validated without conformance evidence;
* formally verified without a proof artifact.

Where an issue remains unresolved, explicitly mark:

```text
UNRESOLVED
```

and explain why.

---

# 23. Required Deliverables

The development agent MUST produce the following.

## Deliverable A — Repository Reconciliation Report

Create or update the appropriate v0.0.3 milestone report containing:

* repository state inspected;
* affected canonical documents;
* contradictions found;
* corrections applied;
* unresolved issues;
* provenance;
* implementation status;
* testing status;
* validation status.

---

## Deliverable B — Corrected Semantic Specifications

Update the canonical SCR specifications for:

1. coordinates;
2. transformations;
3. lifecycle;
4. entity/component composition;
5. context/scope;
6. identity;
7. ownership/authority;
8. manifestation/projection/replication/clone/migration;
9. materialization/lowering;
10. physics;
11. distributed state.

Only create new files where an actual structural gap exists.

---

## Deliverable C — Formal Artifacts

Where appropriate:

* Lean definitions;
* Lean proofs;
* mathematical derivations;
* executable reference models.

Link every formal artifact to the relevant specification.

---

## Deliverable D — Tests

Add focused tests for the semantic invariants.

Tests must be reproducible.

Record:

* command;
* environment;
* result;
* expected result;
* actual result.

---

## Deliverable E — Provider Mapping

Produce a corrected O3DE/AzFramework mapping showing:

```text
SCR concept
O3DE concept
relationship
conversion/mapping
semantic authority
provider limitation
validation status
```

---

## Deliverable F — Status

Update:

```text
102_status.yaml
```

or the repository's equivalent status artifact with evidence-backed statuses.

Do not fabricate completion.

---

# 24. Acceptance Criteria

The objective is complete only when all of the following are satisfied.

### AC-01 — No known coordinate contradiction

All conflicting axis/frame/unit claims have been reconciled.

### AC-02 — Transform model is mathematically coherent

The supported transformation class is explicitly defined and its composition/inverse behavior is correct for the claimed domain.

### AC-03 — Pose is not conflated with general transform

Position, orientation, pose, scale, and affine/general transforms are explicitly distinguished.

### AC-04 — Lifecycle is appropriately scoped

The O3DE-style lifecycle is not incorrectly imposed on all SCR semantic entities.

### AC-05 — Identity is separated from scope

SID, context, scope, manifestation, and provider IDs are not conflated.

### AC-06 — Ownership and authority are distinct

The specifications explicitly distinguish ownership from authority.

### AC-07 — Replication semantics are explicit

Replication, observation, prediction, reconciliation, and transport are separately defined.

### AC-08 — Materialization is contract-driven

Materialization/lowering does not assume universal fixed stages or unconditional reversibility.

### AC-09 — Physics claims are physically defensible

Definitions do not contain universal claims that depend on provider-specific or model-specific assumptions.

### AC-10 — Provider semantics remain provider semantics

O3DE/AzFramework behavior is mapped rather than silently promoted to SCR law.

### AC-11 — Evidence statuses are truthful

Documented, specified, verified, implemented, tested, and validated are not conflated.

### AC-12 — Negative tests exist

Important invariants have been actively challenged.

### AC-13 — Existing SCR architecture is preserved

The correction does not unnecessarily introduce a second ontology, second identity model, second lifecycle model, or second transformation model.

### AC-14 — Formal claims have formal evidence

Mathematical claims that require proof have corresponding formal artifacts or are explicitly marked unverified.

### AC-15 — Remaining uncertainty is visible

Anything not established is explicitly recorded as unresolved/open research rather than silently assumed.

---

# 25. Explicit Prohibitions

The development agent MUST NOT:

1. invent repository definitions that have not been inspected;
2. assume a report's proposed definition is already canonical;
3. duplicate an existing SCR concept;
4. copy O3DE semantics wholesale into SCR;
5. promote provider implementation details to universal semantics;
6. claim mathematical properties without checking them;
7. claim physics invariants outside their assumptions;
8. conflate identity with manifestation;
9. conflate ownership with authority;
10. conflate transport guarantees with consistency guarantees;
11. assume replication implies identical state;
12. assume rematerialization is lossless;
13. assume source representation is always semantic authority;
14. mark work validated without evidence;
15. modify an invariant solely because an implementation fails it;
16. expand ontology where correction of an existing definition is sufficient;
17. introduce unnecessary dependencies;
18. perform broad unrelated refactoring;
19. rewrite functioning subsystems merely for stylistic consistency;
20. delete contradictory material without preserving its provenance or explaining the reconciliation.

---

# 26. Working Method

Use the following sequence.

## Phase 1 — Archaeology

Inspect the repository and map existing definitions.

Output:

```text
concept → canonical location → status → dependencies → evidence
```

---

## Phase 2 — Contradiction Detection

Identify contradictions across:

* SCR definitions;
* milestone reports;
* provider mappings;
* implementation;
* tests;
* formal models.

---

## Phase 3 — Semantic Reconciliation

For every contradiction determine:

```text
canonical definition
provider-specific definition
representation-specific definition
incorrect claim
unresolved question
```

---

## Phase 4 — Mathematical Correction

Resolve:

* coordinate frames;
* transformations;
* identity algebra;
* relevant state transition models.

Produce formal derivations/proofs where appropriate.

---

## Phase 5 — Semantic Correction

Correct:

* lifecycle;
* entity/component;
* context/scope;
* identity;
* ownership;
* authority;
* materialization;
* physics;
* distributed state.

---

## Phase 6 — Provider Mapping

Re-evaluate the O3DE/AzFramework relationship against the corrected SCR model.

---

## Phase 7 — Implementation

Only implement changes necessary to support the corrected semantics.

Avoid speculative implementation.

---

## Phase 8 — Verification

Run:

* unit tests;
* property tests;
* negative tests;
* formal verification where applicable;
* provider conformance tests where applicable.

---

## Phase 9 — Documentation

Update canonical specifications and status artifacts.

---

## Phase 10 — Final Audit

Perform a final repository-wide search for the old contradictory definitions.

The agent MUST specifically search for:

* old axis conventions;
* old transform claims;
* old lifecycle universality;
* old identity/ownership conflation;
* old physics claims;
* old replication guarantees.

Do not declare completion until obsolete contradictions have either been removed, corrected, or explicitly marked as historical/provider-specific.

---

# 27. Final Report Format

The final report MUST contain:

```text
# SCR Semantic Correction and Conformance Report

## 1. Executive Summary

## 2. Repository State Before Changes

## 3. Canonical Definitions Identified

## 4. Contradictions Found

## 5. Corrections Applied

### 5.1 Coordinates
### 5.2 Transform Algebra
### 5.3 Lifecycle
### 5.4 Entity/Component
### 5.5 Context/Scope
### 5.6 Identity
### 5.7 Ownership/Authority
### 5.8 Manifestation/Replication
### 5.9 Materialization
### 5.10 Physics
### 5.11 Distributed State

## 6. O3DE/AzFramework Mapping

## 7. Formal Verification

## 8. Tests

## 9. Validation

## 10. Evidence Matrix

## 11. Remaining Unresolved Questions

## 12. Files Changed

## 13. Commands Executed

## 14. Final Assessment
```

The evidence matrix should use:

| Concept | Documented | Formally Specified | Formally Verified | Implemented | Tested | Validated |
| ------- | ---------- | ------------------ | ----------------- | ----------- | ------ | --------- |

Use `true`, `false`, or an explicit evidence reference.

---

# 28. Definition of Done

This objective is **not** complete when documentation has merely been rewritten.

It is complete when:

> the affected SCR semantics are internally coherent, canonical definitions have been reconciled, provider semantics are correctly separated from SCR semantics, mathematical claims are supported by mathematics, executable claims are supported by tests, external mappings are evidenced, and remaining uncertainty is explicitly visible.

The final state should allow a subsequent development agent to work from:

> **describe → specify → prove/test → validate → implement**

rather than from:

> **describe → assume → implement**.

---

# 29. Governing Principle

The final architecture must preserve the fundamental SCR direction:

> **SCR defines the semantic contracts necessary to compose computational meaning.**

It does not need to own every implementation.

External systems remain valuable authorities within their domains.

The desired result is therefore not an SCR replacement for O3DE, USD, physics engines, spatial libraries, networking systems, or other providers.

The desired result is a rigorously defined semantic layer capable of:

```text
semantic definition
        ↓
formal model
        ↓
provider mapping
        ↓
materialization
        ↓
execution
        ↓
observation
        ↓
verification
```

with identity, provenance, state, transformation, and authority preserved across those boundaries.

**Do not expand the ontology until the existing ontology is coherent.**

**Correct first. Prove where possible. Test what can execute. Validate what can be compared. Record everything that remains uncertain.**
