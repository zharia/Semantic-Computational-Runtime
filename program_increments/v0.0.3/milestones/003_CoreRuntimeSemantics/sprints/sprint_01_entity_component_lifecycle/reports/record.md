# Sprint 001 Record: Entity, Component & Lifecycle

## 1. Objective

Define/extend SCR semantic definitions for Entity, Component, composition, attachment, lifecycle, and dependency. Produce definitions grounded in existing SCR library and informed by Milestone 002 O3DE assessment. Preserve SCR authority model: SID is authoritative identity; no provider terminology promoted to semantic authority.

## 2. Existing SCR Library Assessment

### 2.1 Domains With Substantive Definitions

| Domain | Path | Status | Relevance |
|--------|------|--------|-----------|
| **Identity** | `lib/101_Core/Identity/101_definition.md` | Operational (0.1.0) | Authoritative. SID is coordinate identity. 9-layer authority hierarchy. 17 invariants (IAM-I001–IAM-I017). IAM-I014 (Manifestation Separation) and IAM-I015 (Binding Separation) directly relevant to entity/component identity model. |
| **Core** | `lib/101_Core/101_definition.md` | Draft (0.1.0) | Defines Entity, Object, State, State Transition, Composition, Constraint, Capability, Contract, Relationship, Role as foundational concepts. Sections 10, 21, 22, 32, 29, 30, 31 are the normative basis. |

### 2.2 Domains That Are Placeholder Stubs

All of the following contain only structural boilerplate — no semantic definitions:

| Domain | Path | Implication |
|--------|------|-------------|
| **Types** | `lib/101_Core/Types/101_definition.md` | No type system definition yet. Core §8 defines Type conceptually. |
| **State** | `lib/101_Core/State/101_definition.md` | No state semantics. Core §21–22 defines State and State Transition. Lifecycle states must extend Core. |
| **Composition** | `lib/101_Core/Composition/101_definition.md` | No composition rules. Core §32 defines composition generically. Entity-component composition needs explicit definition. |
| **Constraints** | `lib/101_Core/Constraints/101_definition.md` | No constraint semantics. Core §29 defines Constraint conceptually. Service contracts are a specific constraint form. |
| **Concepts** | `lib/101_Core/Concepts/101_definition.md` | No concept definitions. |
| **Capabilities** | `lib/101_Core/Capabilities/101_definition.md` | No capability definitions. Core §30 defines Capability. |
| **Properties** | `lib/101_Core/Properties/101_definition.md` | No property definitions. |
| **Relations** | `lib/101_Core/Relations/101_definition.md` | No relation definitions. Core §12–13 defines Relationships and Roles. |
| **Interfaces** | `lib/101_Core/Interfaces/101_definition.md` | No interface definitions. |
| **Operations** | `lib/101_Core/Operations/101_definition.md` | No operation definitions. Core §20 defines Operations. |
| **Contracts** | `lib/101_Core/Contracts/101_definition.md` | No contract definitions. Core §31 defines Contracts. |

### 2.3 Assessment Summary

The SCR library has a comprehensive **Core** specification (§10, §21–22, §29–32) that defines Entity, State, State Transition, Constraint, Capability, Contract, and Composition conceptually. The **Identity** domain is fully specified with invariants. Everything else is placeholder.

**Critical gap:** Core defines *what* these concepts mean abstractly, but provides no operational semantics for entity-component composition, lifecycle state machines, or service contracts. M003 must fill this gap.

## 3. Entity Definition

### 3.1 SCR Entity (Normative)

**Concept:** `Entity`
**Source:** Core §10 (Entities and Objects)
**Status:** extend-existing — Core defines entity abstractly; sprint defines operational semantics

An Entity in SCR is a **semantically addressable, composable computational unit** possessing:

- **Identity** — SID coordinate (authoritative, per `lib/101_Core/Identity`)
- **Type** — semantic type classification
- **State** — lifecycle state machine (defined below)
- **Components** — zero or more attached Component instances
- **Dependencies** — declared and resolved through service contracts

An Entity has **no behavior of its own**. All behavior emerges from the composition of its attached Components. This is the fundamental principle of entity-component architecture.

### 3.2 Entity vs Object Distinction

Core §10 defines both Entity and Object. SCR distinguishes:

| Concept | Meaning | Identity Boundary |
|---------|---------|-------------------|
| **Entity** | Composable unit with lifecycle. Component container. Identity boundary. | SID coordinate |
| **Object** | Generic semantically addressable construct. May or may not have components. | May have identity, may not |

Entity is a specialization of Object that adds component composition and lifecycle management.

### 3.3 Identity Authority (Preserved from M002)

```
SCR SID (authoritative identity)
    ↓ Manifestation Layer
Provider EntityId (provider-local runtime handle)
    ↓ Provider Mapping
Provider Entity (runtime instance)
```

- SID is never derived from a provider identifier
- Provider entity handles are manifestation-layer ephemeral references
- Multiple provider handles may reference the same SID across different contexts

### 3.4 Provenance

```yaml
concept: Entity
source: O3DE
source_terminology: AZ::Entity
scr_interpretation: Semantically addressable composable unit with SID identity, component slots, lifecycle state machine, and dependency resolution
differences: No behavior of own (same as O3DE). Identity via SID not EntityId. No 32-bit active-state bitmask. Lifecycle states simplified.
```

## 4. Component Definition

### 4.1 SCR Component (Normative)

**Concept:** `Component`
**Source:** Core §30 (Capabilities), §31 (Contracts), §32 (Composition)
**Status:** define-new — no existing SCR component definition

A Component is a **composable unit of semantic behavior** attached to an Entity. A Component:

- Has **no independent identity** — it exists only within the scope of its owning Entity
- Has a **lifecycle** tied to its owning Entity's lifecycle
- Declares a **service contract** (provided/required/dependent/incompatible services)
- Can **provide services** to other components
- Can **require services** from other components
- Has **no standalone execution** — activation occurs only as part of Entity activation

### 4.2 Component vs Capability Distinction

| Concept | Meaning | Scope |
|---------|---------|-------|
| **Capability** | Abstract property of a semantic object (e.g., Composable, Deterministic) | Core §30 — universal |
| **Component** | Concrete composable behavior unit attached to an Entity | M003 — entity-scoped |

A Component *declares* capabilities through its service contract. A Capability is an abstract property; a Component is a concrete attachment.

### 4.3 Service Contract

**Concept:** `ServiceContract`
**Source:** O3DE ComponentDescriptor service declarations
**Status:** define-new

A ServiceContract declares four relations between a Component type and other Component types:

| Relation | Meaning | Activation Implication |
|----------|---------|----------------------|
| **provides** | This component offers this service | After activation, this service is available |
| **requires** | This component needs this service to function | Service provider must be present and activated first |
| **depends-on** | This component prefers this service; if present, activates after it | Soft ordering preference |
| **incompatible-with** | This component cannot coexist with this service | Validation error if both present on same Entity |

Service contracts are the mechanism by which component composition is validated and dependency ordering is computed.

### 4.4 Provenance

```yaml
concept: Component
source: O3DE
source_terminology: AZ::Component
scr_interpretation: Composable behavior unit with no independent identity, service contract, lifecycle tied to owning entity
differences: No independent identity (same as O3DE). Service contract formalized as four explicit relations. No ComponentApplication coupling.
```

```yaml
concept: ServiceContract
source: O3DE
source_terminology: ComponentDescriptor (GetProvidedServices, GetRequiredServices, GetDependentServices, GetIncompatibleServices)
scr_interpretation: Formal four-relation service declaration used for dependency ordering and composition validation
differences: SCR formalizes as explicit semantic contract, not a C++ descriptor API. Provider-agnostic.
```

## 5. Lifecycle State Machine

### 5.1 Entity Lifecycle States (Normative)

**Concept:** `LifecycleState`
**Source:** O3DE AZ::Entity::State, Core §21–22 (State, State Transition)
**Status:** define-new

```
                    ┌──────────────┐
                    │ Instantiated │
                    └──────┬───────┘
                           │ initialize()
                           ▼
                    ┌──────────────┐
                    │  Initialized │
                    └──────┬───────┘
                           │ activate()
                           ▼
                    ┌──────────────┐
                    │    Active    │◄──────────┐
                    └──────┬───────┘           │
                           │ deactivate()      │ reactivate()
                           ▼                   │
                    ┌──────────────┐           │
                    │  Deactivated │───────────┘
                    └──────┬───────┘
                           │ destroy()
                           ▼
                    ┌──────────────┐
                    │  Destroyed   │
                    └──────────────┘
```

### 5.2 State Semantics

| State | Meaning | Component Behavior |
|-------|---------|-------------------|
| **Instantiated** | Entity created. Components exist but uninitialized. No services available. | Components constructed. |
| **Initialized** | Entity initialization complete. Components have run Init. Services declared but not yet active. | Components initialized once. |
| **Active** | Entity fully operational. All components activated in dependency order. Services available. | Components activated in topological order by service dependencies. |
| **Deactivated** | Entity suspended. Components deactivated in reverse dependency order. Services unavailable. Entity may reactivate. | Components deactivated in reverse order. |
| **Destroyed** | Terminal state. Entity and all components permanently destroyed. No recovery. | Components destroyed. No further operations valid. |

### 5.3 Transition Rules

| From | To | Trigger | Preconditions |
|------|----|---------|---------------|
| Instantiated | Initialized | `initialize()` | Entity created. Components attached. |
| Initialized | Active | `activate()` | All required services resolvable. No cyclic dependencies. No incompatible components. |
| Active | Deactivated | `deactivate()` | None additional. |
| Deactivated | Active | `reactivate()` | Entity not destroyed. |
| Deactivated | Destroyed | `destroy()` | None additional. |
| Active | Destroyed | `destroy()` | Direct destruction from active state. |

**Invalid transitions:**
- Instantiated → Active (must initialize first)
- Initialized → Deactivated (must activate first)
- Destroyed → any (terminal state)

### 5.4 Component Lifecycle Ordering

When an Entity transitions:

**Activation** (Instantiated → Initialized → Active):
1. Components sorted topologically by service dependencies (requires before provides)
2. Components activated in sorted order
3. Each component's Init runs once (on first initialization)
4. Each component's Activate runs on each activation

**Deactivation** (Active → Deactivated):
1. Components deactivated in **reverse** topological order
2. Required services withdrawn in safe order

**Destruction** (Deactivated/Active → Destroyed):
1. Components destroyed in **reverse** topological order

### 5.5 Provenance

```yaml
concept: LifecycleState
source: O3DE
source_terminology: AZ::Entity::State (Constructed → Initializing → Init → Activating → Active → Deactivating → Destroying → Destroyed)
scr_interpretation: Five-state lifecycle: Instantiated → Initialized → Active → Deactivated → Destroyed
differences: Simplified from O3DE's 8 states. No Initializing/Activating/Deactivating/Destroying intermediate states (those are implementation transitions). No 32-bit active-state bitmask. Reactivation is explicit transition from Deactivated to Active.
```

## 6. Composition Rules

### 6.1 Entity-Component Attachment

**Concept:** `Composition`
**Source:** Core §32, O3DE entity-component model
**Status:** extend-existing — Core defines composition abstractly

**Rules:**

1. **One-to-many:** One Entity may have zero or more Components.
2. **No independent identity:** Components have no SID of their own. Their identity is scoped to the owning Entity.
3. **Single ownership:** A Component instance belongs to exactly one Entity. No sharing across Entities.
4. **Explicit attachment:** Components are explicitly attached to Entities at construction or initialization time. No implicit composition.
5. **Type uniqueness:** At most one Component of a given service-providing type per Entity (enforced by incompatible-with checks).

### 6.2 Dependency Ordering

**Concept:** `DependencyOrdering`
**Source:** O3DE DependencySort
**Status:** define-new (within Composition domain)

**Algorithm:**

1. Build directed graph: edge from Component A to Component B if A requires a service B provides.
2. Topological sort of the graph.
3. If cycle detected → composition validation error.
4. Activation order: topological order.
5. Deactivation order: reverse topological order.

**Validation rules:**
- All `requires` services must be satisfied by some Component on the same Entity
- All `incompatible-with` relations must not conflict with any Component on the same Entity
- Dependency graph must be acyclic

### 6.3 Composition Validation

Before activation, the Entity must validate:

1. All required services are provided by at least one Component
2. No incompatible services are both present
3. Dependency graph is acyclic
4. Topological ordering exists

If validation fails, activation is rejected with diagnostic information.

### 6.4 Provenance

```yaml
concept: DependencyOrdering
source: O3DE
source_terminology: AZ::Entity::DependencySort
scr_interpretation: Topological sort of composable units by service dependencies. Acyclic graph required. Activation in topological order, deactivation in reverse.
differences: SCR formalizes as semantic constraint on composition, not a C++ sort routine. Ordering is a property of the composition, not an algorithm detail.
```

## 7. Gap Analysis

### 7.1 Classification of SCR Needs

| Concept | Current SCR Status | Action | Classification |
|---------|-------------------|--------|----------------|
| **Entity** | Core §10 defines abstractly. No operational semantics. | **extend-existing** | Needs operational definition with lifecycle, composition |
| **Component** | No definition anywhere in SCR library | **define-new** | New semantic concept |
| **LifecycleState** | Core §21–22 defines State/Transition abstractly. `lib/101_Core/State/` is stub. | **define-new** | New specific state machine |
| **ServiceContract** | `lib/101_Core/Contracts/` is stub. Core §31 defines Contract abstractly. | **define-new** | New specific contract form |
| **Composition (entity-component)** | Core §32 defines composition abstractly. `lib/101_Core/Composition/` is stub. | **extend-existing** | Needs entity-component specific rules |
| **DependencyOrdering** | No definition. `203_Graph` has algorithms but no semantic. | **define-new** | New composition constraint |
| **EntityContext** | `lib/101_Core/Context/` is stub | **define-new** | Ownership scope for entity hierarchies |
| **EntityTemplate** | No definition | **define-new** | Reusable entity hierarchy specification |
| **EntitySpawn** | No definition | **define-new** | Runtime instantiation from template |
| **ComponentDescriptor** | No definition | **define-new** | Component type metadata |
| **RuntimeHost** | No definition | **define-new** | Application-level component management |

### 7.2 Concepts Requiring Clarity

| Concept | Question | Recommended Resolution |
|---------|----------|----------------------|
| **Tick** | Semantic (per-frame step) or implementation? | Semantic. Defer to dedicated sprint — interacts with temporal semantics. |
| **EntityTemplate vs Prefab** | Are these distinct concepts? | EntityTemplate is the semantic concept. Prefab/O3DE is one serialization format. |
| **Context scope** | Should EntityContext be a Core concept or a higher-level domain? | Core. Entity ownership scope is fundamental. |
| **Component identity** | Can a component ever have independent identity? | No. Component identity is always scoped to Entity. If a component needs independent identity, it should be an Entity. |

### 7.3 Concepts Already Adequately Defined

| Concept | Where Defined |
|---------|---------------|
| SID Identity | `lib/101_Core/Identity/101_definition.md` — complete |
| Entity (abstract) | Core §10 — adequate as foundation |
| State (abstract) | Core §21–22 — adequate as foundation |
| Contract (abstract) | Core §31 — adequate as foundation |
| Capability (abstract) | Core §30 — adequate as foundation |
| Relationship | Core §12–13 — adequate as foundation |

## 8. Derived Definitions for Semantic Library

The following definitions should be added to the SCR semantic library. Each is classified per M003 exit criteria.

### 8.1 Recommended File Structure

```
lib/101_Core/
├── Identity/           (existing — operational)
├── Concepts/           (needs: Entity, Component definitions)
├── State/              (needs: LifecycleState definition)
├── Composition/        (needs: Composition rules, DependencyOrdering)
├── Contracts/          (needs: ServiceContract definition)
├── Context/            (needs: EntityContext definition)
├── Relations/          (needs: ParentChildRelation — deferred to Sprint 02)
└── ...other domains...
```

### 8.2 Classification Summary

| Classification | Count | Concepts |
|----------------|-------|----------|
| **already-defined** | 6 | SID Identity, Entity (abstract), State (abstract), Contract (abstract), Capability (abstract), Relationship |
| **needs-extension** | 2 | Entity (operational), Composition (entity-component rules) |
| **define-new** | 7 | Component, LifecycleState, ServiceContract, DependencyOrdering, EntityContext, EntityTemplate, EntitySpawn |
| **needs-clarity** | 1 | Tick (deferred) |

## 9. Exit Criteria Check

- [x] Entity definition distinguishes semantic entity from provider entity (Section 3)
- [x] Component definition distinguishes semantic capability from implementation component (Section 4)
- [x] Lifecycle states and transitions documented (Section 5)
- [x] Composition rules documented (Section 6)
- [x] Gap analysis from M002 addressed (Section 7)
- [x] Provenance documented for all O3DE-derived concepts (Sections 3.4, 4.4, 5.5, 6.4)
- [x] Each concept classified: already-defined / needs-extension / define-new / needs-clarity (Section 7.1)

## 10. Deferred to Subsequent Sprints

| Concept | Sprint | Reason |
|---------|--------|--------|
| ParentChildRelation | Sprint 02 (Spatial Hierarchy) | Spatial semantics; entity hierarchy lives in Transform domain |
| Transform Inheritance | Sprint 02 | Extend existing `101_Core/Transforms` |
| Tick | Sprint 03+ | Interacts with temporal semantics; needs dedicated analysis |
| EntityTemplate / EntitySpawn | Sprint 04 (Asset/Resource/Materialization) | Tied to serialization and instantiation pipelines |
| RuntimeHost | Deferred | Application-level; may belong to provider specification |
