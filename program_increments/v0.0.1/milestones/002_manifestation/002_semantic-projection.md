# SCR IMPLEMENTATION DIRECTIVE

## Semantic Projection, Affordance, Transformation, Manifestation & Reconciliation

You are implementing an architectural evolution of the **Semantic Computational Runtime (SCR)** repository.

Repository:

`https://github.com/zharia/Semantic-Computational-Runtime`

The implementation must be treated as an **architectural extension of SCR**, not as an isolated feature.

The foundational engineering principle remains:

> **Computation is transformation of semantic structure within a Semantic Field, and the runtime is the mechanism by which semantic topology becomes physical reality.**

The repository's existing Semantic Field, Seed, numeric semantics, execution semantics, and `lib` architecture are authoritative starting points. Do not introduce competing abstractions where an existing SCR abstraction can be extended.

---

# 1. PRIMARY OBJECTIVE

Extend SCR so that it explicitly models the following lifecycle:

```text
SUBSTRATE
    │
    ▼
SEMANTIC PROJECTION
    │
    ▼
SEMANTIC OBSERVATION
    │
    ▼
SEMANTIC FIELD
    │
    ├── identity
    ├── topology
    ├── state
    ├── context
    ├── relationships
    └── affordances
    │
    ▼
SEMANTIC TRANSFORMATION
    │
    ▼
CONSTRAINT EVALUATION
    │
    ▼
MANIFESTATION
    │
    ▼
RECONCILIATION
    │
    └──────────────► SEMANTIC FIELD
```

This lifecycle must become an explicit part of SCR's architecture.

Do NOT implement this merely as an AI-agent loop.

An LLM, planner, controller, compiler, deterministic rule engine, simulation engine, human operator, or another runtime may eventually produce transformations.

The semantic runtime must remain independent of any particular intelligence/planning mechanism.

---

# 2. IMPORTANT CONCEPTUAL DISTINCTION

Do not treat LUMOS as a dependency.

The relevant paper is:

**LUMOS: A Semantic Operating-System Layer for Accessibility-Grounded AI Agents**

`https://arxiv.org/html/2606.30697v1`

Use it as an architectural reference and validation case.

LUMOS demonstrates that systems such as accessibility trees, DOMs and OS automation interfaces already expose substantial semantic structure.

SCR must generalise this observation.

The correct abstraction is:

> **Semantic Projection**

not:

> "UI integration"

and not:

> "LUMOS integration."

UI accessibility is merely one possible manifestation/projection domain.

The same architecture must eventually accommodate:

* UI
* DOM
* accessibility APIs
* databases
* filesystems
* network protocols
* sensors
* simulations
* graphics
* hardware
* distributed systems
* other semantic substrates

---

# 3. ARCHITECTURAL PRINCIPLE: SEMANTIC PROJECTION

Introduce a first-class semantic concept:

## Semantic Projection

A Semantic Projection maps semantic information exposed by an external substrate or manifestation into canonical SCR semantic structures.

Conceptually:

```text
External Substrate
       │
       ▼
Observation
       │
       ▼
Projection
       │
       ▼
Canonical Semantic Structure
       │
       ▼
Semantic Field
```

The projection MUST preserve as much semantic fidelity as the substrate exposes.

Establish the following ordering:

```text
native semantics
      ↓
structured semantics
      ↓
derived semantics
      ↓
visual/spatial inference
      ↓
raw physical representation
```

SCR should prefer the highest-fidelity semantic source available.

Do not reconstruct semantics from pixels when the substrate already exposes the semantics directly.

---

# 4. SEMANTIC PROJECTION CONTRACT

Define a clear abstraction/protocol for projections.

A projection should conceptually support:

```text
observe(substrate)
    → semantic observation

project(observation)
    → semantic structure

resolve(semantic identity)
    → substrate manifestation/reference

manifest(semantic transformation)
    → substrate operation

reconcile(manifestation result)
    → updated semantic observation
```

Exact APIs should follow the repository's existing naming, typing and architectural conventions.

Do not blindly copy the above function names if SCR already has an appropriate abstraction.

The important invariant is the semantic responsibility.

A projection:

* knows how to observe a substrate;
* knows how to normalise substrate semantics;
* knows how semantic identities correspond to manifestations;
* knows how semantic transformations become substrate operations;
* does NOT define the Semantic Field itself;
* does NOT redefine universal ontology;
* does NOT become an application-specific command system.

---

# 5. SEMANTIC OBSERVATION

Introduce or strengthen the concept of a **Semantic Observation**.

An observation is not necessarily the entire Semantic Field.

It is a bounded representation of what a substrate currently exposes or what is relevant under a particular context.

Conceptually:

```text
Semantic Field
      │
      ▼
Observation Policy
      │
      ▼
Contextual Semantic Observation
```

An observation should be capable of expressing, where available:

* identity
* type/role
* state
* value
* relationships
* context
* spatial manifestation
* temporal information
* affordances
* provenance
* confidence where semantics are inferred
* source/substrate
* observation timestamp/version

Do not make every field mandatory if the source cannot provide it.

Distinguish clearly between:

1. known semantics;
2. inferred semantics;
3. unavailable semantics.

Do not silently convert unavailable information into invented values.

---

# 6. SEMANTIC IDENTITY

Strengthen SCR's identity model.

The architecture MUST distinguish semantic identity from manifestation identity.

For example:

```text
Semantic Entity
      │
      ├── semantic identity
      │
      ├── UI identity
      ├── DOM identity
      ├── filesystem identity
      ├── database identity
      ├── spatial manifestation
      └── observation identity
```

Do not use:

* memory addresses,
* screen coordinates,
* DOM paths,
* filesystem paths,
* database row numbers,
* accessibility node positions

as universal semantic identity.

These may be **manifestation references**.

The semantic identity must persist across legitimate changes in manifestation.

Implement explicit invariants for:

* identity persistence;
* identity equivalence;
* manifestation replacement;
* entity creation;
* entity destruction;
* entity mutation;
* observation continuity.

If the repository already contains Identity Persistence invariants, extend them rather than duplicating them.

---

# 7. SEMANTIC AFFORDANCES

Promote **Affordance** to a first-class semantic concept.

An affordance represents a transformation that is validly applicable to an entity or semantic structure under a particular context.

Conceptually:

```text
Entity
 ├── identity
 ├── type
 ├── state
 ├── value
 ├── relationships
 ├── context
 └── affordances
```

An affordance should conceptually contain:

```text
Affordance
 ├── target
 ├── transformation
 ├── parameters
 ├── preconditions
 ├── constraints
 ├── authority requirements
 ├── expected effects
 ├── reversibility
 └── provenance
```

Examples:

```text
activate(button)
set_value(field, value)
append(document, content)
focus(control)
select(entity)
create(entity)
delete(entity)
move(entity, destination)
```

Do not make these UI commands.

`click`, `keypress`, pointer events, DOM mutation, SQL UPDATE, filesystem writes, etc. are possible **manifestations of semantic transformations**.

---

# 8. SEMANTIC TRANSFORMATION ALGEBRA

Strengthen the existing transformation/execution model so that semantic transformations become explicit.

The fundamental abstraction is:

```text
Transformation(
    subject,
    operation,
    parameters,
    context,
    constraints
)
```

The transformation operates on semantic structure.

The manifestation layer determines how that transformation is physically realised.

For example:

```text
activate(save_button)
```

may manifest as:

```text
mouse click
keyboard activation
accessibility API invocation
DOM event
```

Likewise:

```text
set_value(input, "hello")
```

could manifest as:

```text
keyboard input
DOM property mutation
accessibility API
native widget API
```

The semantic transformation MUST NOT depend on one manifestation mechanism.

---

# 9. PRECONDITIONS, POSTCONDITIONS AND INVARIANTS

Every executable semantic transformation should have a mechanism for expressing:

### Preconditions

What must already be true.

```text
field.editable == true
```

### Constraints

What may not be violated.

```text
authority >= required_authority
```

### Expected effects

What semantic changes should result.

```text
document.content' = document.content + appended_content
```

### Postconditions

What must be true after execution.

```text
document.version > previous_version
```

### Invariants

What must remain true throughout execution.

Existing SCR invariant mechanisms should be reused.

Do not create an independent validation framework if the repository already contains suitable invariant/constraint machinery.

---

# 10. MANIFESTATION

Formalise **Manifestation** as the mechanism by which a semantic transformation becomes physical/substrate state.

The distinction must be explicit:

```text
Semantic Transformation
        ≠
Manifestation Operation
```

Example:

```text
Semantic:
    set_value(field, "hello")

Manifestation:
    send keyboard events
```

or:

```text
Semantic:
    update(record, field=value)

Manifestation:
    SQL UPDATE
```

or:

```text
Semantic:
    move(entity, destination)

Manifestation:
    update spatial coordinates
```

The manifestation layer must never redefine semantic meaning.

---

# 11. RECONCILIATION

Introduce or strengthen **Semantic Reconciliation**.

After manifestation, the runtime MUST NOT assume that the requested transformation succeeded merely because the substrate operation returned successfully.

The runtime should support:

```text
before_state
     │
     ▼
semantic transformation
     │
     ▼
manifestation
     │
     ▼
new observation
     │
     ▼
reconciliation
     │
     ▼
updated semantic state
```

Reconciliation must be capable of detecting:

* success;
* partial success;
* semantic divergence;
* stale observation;
* external mutation;
* manifestation failure;
* unexpected state;
* identity replacement;
* constraint violation.

The runtime should prefer observed semantic state over assumed state.

---

# 12. CONTEXTUAL PROJECTION

A projection MUST be able to produce bounded semantic views rather than requiring the entire Semantic Field to be serialised or exposed.

Introduce a conceptual mechanism for:

```text
Field
  ↓
Scope
  ↓
Context
  ↓
Relevance
  ↓
Resolution
  ↓
Semantic Observation
```

This must support future requirements such as:

* local semantic neighbourhoods;
* focused entities;
* task-relevant projections;
* hierarchical resolution;
* semantic summarisation;
* incremental observations;
* subscriptions/deltas.

Do not prematurely implement an enormous context engine.

Establish the correct abstraction and invariants first.

---

# 13. SPATIAL PROJECTION

Explicitly recognise that physical space is a projection of semantic structure.

For example:

```text
(x, y)
  ↓
spatial projection
  ↓
semantic entity
```

Coordinates MUST NOT themselves constitute semantic identity.

Support mappings such as:

```text
semantic entity
      │
      ├── spatial location
      ├── bounding region
      ├── coordinate system
      ├── viewport
      └── manifestation
```

This should be general enough for:

* UI
* 2D graphics
* 3D graphics
* simulation
* GIS
* robotics
* physical environments

Do not implement a UI-only coordinate model.

---

# 14. THE SEED

Revisit the Seed architecture in light of these concepts.

The Seed MUST remain separate from `lib`.

Do NOT turn the Seed into a parallel ontology.

Its role is to establish the foundational semantic vocabulary, distinctions, normalization rules and external references required to make `lib` definitions coherent.

The Seed should support concepts such as:

```text
identity
entity
state
relationship
context
observation
projection
affordance
transformation
constraint
manifestation
reconciliation
space
time
value
provenance
```

Where external standards provide authoritative definitions, reference them.

Particularly investigate relevant standards and technical vocabularies for:

* accessibility semantics;
* WAI-ARIA;
* accessibility APIs;
* DOM semantics;
* UI automation;
* graph/data models;
* schema systems;
* spatial semantics;
* provenance;
* identity.

Do not duplicate external standards unnecessarily.

The Seed should explain how external semantic vocabularies map into SCR's canonical semantic concepts.

---

# 15. LUMOS AS A REFERENCE CASE

Do NOT add LUMOS as an SCR dependency.

Instead, create documentation describing LUMOS as a **reference validation case**.

Document the mapping:

```text
LUMOS Concept
      ↓
SCR Concept
```

At minimum analyse:

```text
semantic blueprint → semantic observation/projection
stable element ID → semantic identity / manifestation identity
role → semantic type/role
state → semantic state
value → semantic value
bounds → spatial manifestation
affordance → semantic affordance
observe → semantic observation
plan → transformation selection
validate → constraint evaluation
act → manifestation
re-observe → reconciliation
```

Also explicitly document where LUMOS is narrower than SCR.

LUMOS is an example implementation domain, not the definition of SCR.

---

# 16. REPOSITORY STRUCTURE

Inspect the existing repository before modifying it.

Do NOT blindly create directories.

First determine:

* current `lib` structure;
* existing semantic primitives;
* existing field implementation;
* identity implementation;
* transformation/execution implementation;
* numeric semantics;
* execution semantics;
* invariant/validation mechanisms;
* Seed location;
* documentation architecture;
* testing architecture.

Then integrate the new concepts into the existing structure.

Prefer extending existing modules over creating parallel frameworks.

If new modules are justified, their names and locations must follow repository conventions.

---

# 17. DOCUMENTATION

Update the repository's semantic documentation comprehensively.

At minimum, ensure the documentation addresses:

### Semantic Projection

Definition, purpose, lifecycle, invariants.

### Semantic Observation

What constitutes an observation and how observations differ from the Field.

### Semantic Identity

Persistence, manifestation references, identity reconciliation.

### Affordance

Definition, structure, preconditions, authority, expected effects.

### Semantic Transformation

Definition and relationship to manifestation.

### Manifestation

How semantic transformations become substrate operations.

### Reconciliation

How manifested state becomes semantic state again.

### Contextual Projection

Scope, relevance, resolution and bounded observations.

### Spatial Projection

Mapping between semantic and physical/spatial structures.

### External Semantic Systems

How external semantic representations are normalised.

Documentation should clearly explain the architectural direction:

```text
Manifestation
    ↓
Projection
    ↓
Semantic Field
    ↓
Transformation
    ↓
Manifestation
```

---

# 18. TESTING REQUIREMENTS

This is an architectural change and therefore requires substantive tests.

Do not merely test that classes instantiate.

Test semantic invariants.

At minimum implement tests for:

## Projection

* substrate observation produces canonical semantic representation;
* semantic fidelity is preserved;
* unavailable values are not fabricated;
* provenance is retained;
* projection is deterministic where the substrate is deterministic.

## Identity

* semantic identity persists across manifestation changes;
* manifestation identifiers do not become semantic identities;
* replacement can be distinguished from mutation;
* identity reconciliation works across observations.

## Affordances

* affordances are derived from valid semantic state;
* invalid affordances are rejected;
* preconditions are evaluated;
* constraints are evaluated;
* authority requirements are respected.

## Transformations

* semantic transformations are substrate-independent;
* parameters are semantically validated;
* invalid transformations are rejected before manifestation;
* expected effects can be represented.

## Manifestation

* semantic transformations map to substrate operations;
* manifestation failures propagate correctly;
* substrate-specific errors do not corrupt semantic state.

## Reconciliation

* successful transformations reconcile correctly;
* partial failures are detected;
* stale observations are detected;
* external mutations are detected;
* unexpected state is not silently accepted.

## Spatial Projection

* coordinates can resolve to semantic entities;
* spatial manifestations do not determine identity;
* multiple coordinate systems can be represented without semantic corruption.

## Contextual Projection

* projections can be scoped;
* irrelevant entities can be omitted;
* omitted entities are not interpreted as nonexistent;
* projection resolution is explicit.

---

# 19. PROPERTY-BASED / INVARIANT TESTING

Where practical, add property-based tests for the following:

```text
project(manifestation)
→ semantic structure

manifest(semantic transformation)
→ manifestation

reconcile(observe(manifestation))
→ semantic structure
```

Test round-trip properties.

Where a reversible transformation exists:

```text
S
 ↓ transform
S'
 ↓ inverse
S
```

should recover semantic equivalence, subject to explicitly documented lossiness.

For lossy projections, define an explicit equivalence relation rather than expecting byte-for-byte equality.

This is important.

**Semantic equivalence is not necessarily representational equality.**

---

# 20. NUMERIC SEMANTICS

Do not bypass the existing numeric-semantic architecture.

Spatial values, bounds, coordinates, measurements, probabilities, confidence values, timestamps, ranges and other quantitative information MUST use the existing SCR numeric semantics where applicable.

Do not introduce ad-hoc:

```text
float
int
tuple[x, y]
```

representations merely because they are convenient.

Review the existing numeric semantics documentation and ensure the new projection/manif­estation model respects:

* numeric meaning;
* units;
* precision;
* uncertainty;
* range;
* conversion;
* execution semantics.

---

# 21. ERROR MODEL

Extend the existing SCR error model rather than creating unrelated exceptions.

The implementation must be capable of distinguishing at least conceptually:

```text
ProjectionError
ObservationError
IdentityResolutionError
InvalidAffordance
PreconditionFailure
ConstraintViolation
TransformationError
ManifestationError
ReconciliationError
StaleObservation
SemanticDivergence
```

Use repository conventions for actual types/names.

Errors should preserve semantic provenance and relevant context where appropriate.

---

# 22. DETERMINISM

Where SCR semantics require deterministic behaviour, ensure:

```text
same semantic input
+
same context
+
same transformation
+
same constraints
=
same semantic result
```

unless nondeterminism is explicitly part of the domain semantics.

Do not introduce hidden nondeterminism through:

* unordered collections;
* unstable identifiers;
* timestamps;
* random spatial resolution;
* implicit external state.

Where nondeterminism is unavoidable, make it explicit in the semantic model.

---

# 23. NO AI DEPENDENCY

Do not introduce:

* LLM dependencies;
* agent frameworks;
* prompt orchestration;
* model-specific abstractions;

as part of this architectural change.

The architecture must remain fully usable without AI.

An AI planner may eventually consume:

```text
Semantic Observation
```

and produce:

```text
Semantic Transformation
```

but SCR itself must not depend upon how that transformation was selected.

---

# 24. NO UI COUPLING

Do not introduce browser-, desktop-, or accessibility-specific abstractions into foundational semantic modules.

Bad:

```text
SemanticFieldButton
WindowsButton
DOMSemanticNode
```

Good:

```text
SemanticEntity
SemanticRole
Affordance
Transformation
Manifestation
Projection
```

UI implementations belong at the projection/manifestation boundary.

---

# 25. EXTERNAL REFERENCE DOCUMENTATION

Where appropriate, document external standards and systems that provide semantic infrastructure.

At minimum investigate:

* LUMOS paper;
* WAI-ARIA;
* accessibility tree concepts;
* relevant OS accessibility APIs;
* DOM;
* UI Automation;
* AT-SPI;
* platform semantic representations.

The purpose is not to implement all of them.

The purpose is to establish that SCR can normalise heterogeneous semantic representations into a common Semantic Field.

---

# 26. IMPLEMENTATION SEQUENCE

Follow this sequence.

### Phase 1 — Repository reconnaissance

Inspect the entire relevant architecture.

Identify existing abstractions and invariants.

Do not modify code yet.

### Phase 2 — Semantic model

Define the conceptual relationships among:

```text
Field
Observation
Projection
Identity
Affordance
Transformation
Constraint
Manifestation
Reconciliation
Context
Spatial Projection
```

Resolve naming conflicts with existing SCR concepts.

### Phase 3 — Seed

Update Seed definitions and external references.

Ensure terminology is canonical.

### Phase 4 — `lib`

Implement the minimal foundational primitives required.

Avoid premature substrate-specific implementations.

### Phase 5 — Execution

Integrate transformations, constraints, manifestation and reconciliation into the runtime execution model.

### Phase 6 — Reference projection

Implement a minimal synthetic/in-memory projection.

This should be the first concrete projection.

It must not depend upon an operating system or browser.

Use it to validate the entire lifecycle.

### Phase 7 — Tests

Implement unit, integration, invariant and property-based tests.

### Phase 8 — Documentation

Update architecture and semantic documentation.

### Phase 9 — Full validation

Run all project checks.

---

# 27. REQUIRED REFERENCE IMPLEMENTATION

Create a minimal **in-memory semantic substrate** or equivalent test substrate if the repository does not already possess one.

It should support:

```text
entities
identity
roles/types
state
values
relationships
affordances
spatial manifestation
transformations
mutation
observation
reconciliation
```

Demonstrate:

```text
create entity
      ↓
observe
      ↓
derive affordance
      ↓
select transformation
      ↓
validate
      ↓
manifest
      ↓
observe again
      ↓
reconcile
      ↓
updated Field
```

This reference implementation is important because it validates the architecture without introducing external platform dependencies.

---

# 28. ACCEPTANCE CRITERIA

The implementation is NOT complete until all of the following are true.

### Architecture

* [ ] Semantic Projection is a first-class concept.
* [ ] Semantic Observation is explicitly represented.
* [ ] Semantic Identity is distinct from manifestation identity.
* [ ] Affordance is explicitly represented.
* [ ] Semantic Transformation is distinct from manifestation.
* [ ] Manifestation is explicitly represented.
* [ ] Reconciliation is explicitly represented.
* [ ] Contextual Projection is represented.
* [ ] Spatial Projection is represented.

### Semantics

* [ ] Existing Semantic Field remains foundational.
* [ ] Existing Seed remains authoritative for canonical terminology.
* [ ] No competing ontology has been created.
* [ ] Existing numeric semantics are respected.
* [ ] Existing execution semantics are respected.
* [ ] Existing invariants are reused wherever possible.

### Generality

* [ ] No foundational module depends on UI.
* [ ] No foundational module depends on LUMOS.
* [ ] No foundational module depends on an LLM.
* [ ] Architecture applies beyond UI.

### Execution

* [ ] Semantic transformations can be validated before manifestation.
* [ ] Constraints are evaluated before execution.
* [ ] Manifestation errors are represented.
* [ ] Post-execution observation is possible.
* [ ] Reconciliation detects semantic divergence.

### Identity

* [ ] Semantic identity persists across manifestation changes.
* [ ] Manifestation identifiers remain subordinate to semantic identity.
* [ ] Identity replacement/mutation can be distinguished.

### Testing

* [ ] Unit tests pass.
* [ ] Integration tests pass.
* [ ] Invariant tests pass.
* [ ] Property-based tests are added where appropriate.
* [ ] Round-trip/equivalence tests exist.
* [ ] No existing tests regress.

### Documentation

* [ ] Architecture documentation updated.
* [ ] Seed documentation updated.
* [ ] Relevant `lib` documentation updated.
* [ ] Execution documentation updated.
* [ ] LUMOS is documented as a reference/validation case.
* [ ] External semantic standards are referenced where appropriate.

---

# 29. VALIDATION COMMANDS

Determine the repository's canonical validation commands first.

Then run all applicable checks, including at minimum:

```text
dependency/environment synchronization
formatter
linter
type checker
unit tests
integration tests
property-based tests
documentation validation
package/build validation
```

For Python, inspect the project's actual tooling before assuming commands.

If the repository uses `uv`, use the project's prescribed `uv` workflow.

Do not merely run a subset of tests.

Run the complete available validation suite.

---

# 30. FINAL ARCHITECTURAL REVIEW

After implementation, perform a second-pass architectural review.

Ask:

### Semantic Field

Does the Field remain the source of semantic truth?

### Projection

Can heterogeneous substrates project into it without changing its ontology?

### Identity

Can semantic identity survive changing manifestations?

### Affordance

Are affordances semantic possibilities rather than UI commands?

### Transformation

Can a transformation exist independently of its physical implementation?

### Manifestation

Can different substrates realise the same semantic transformation?

### Reconciliation

Can SCR detect when physical reality diverges from intended semantic state?

### Context

Can the runtime expose bounded semantic views without pretending omitted information does not exist?

### Spatial semantics

Can spatial representations be treated as manifestations rather than identities?

### Generality

Could the exact same machinery plausibly support:

```text
UI
database
filesystem
simulation
network
robotics
graphics
hardware
distributed state
```

without redesigning the foundational semantic model?

If not, revisit the abstraction boundary.

---

# 31. CRITICAL DESIGN TEST

Before considering the work complete, test this proposition:

> **SCR should be capable of representing the semantic lifecycle demonstrated by LUMOS without knowing that LUMOS exists.**

If SCR requires a LUMOS-specific concept to accomplish this, the abstraction is probably at the wrong level.

Conversely:

> **LUMOS-like systems should be implementable as projections/manif­estations on top of SCR's semantic machinery.**

That is the architectural test.

---

# 32. DO NOT OVERENGINEER

This directive is an architectural evolution, not permission to build every conceivable subsystem.

Do not prematurely implement:

* distributed semantic consensus;
* full ontology reasoning;
* universal agent planning;
* complete accessibility integrations;
* browser automation;
* OS automation;
* multimodal perception;
* autonomous planners.

Establish the correct **semantic primitives, contracts, invariants and execution boundaries** first.

A small, rigorous semantic calculus is preferable to a giant collection of vaguely related classes.

---

# 33. REQUIRED FINAL REPORT

When implementation is complete, report:

1. **Repository changes**

   * files added;
   * files modified;
   * files removed, if any.

2. **Architectural changes**

   * how Projection was integrated;
   * how Observation was integrated;
   * how Identity was strengthened;
   * how Affordance was implemented;
   * how Transformation was integrated;
   * how Manifestation was represented;
   * how Reconciliation works.

3. **Seed changes**

   * new canonical terms;
   * external references added;
   * normalization rules added.

4. **Tests**

   * test categories;
   * number of tests;
   * failures;
   * property/invariant coverage.

5. **Documentation**

   * documents created/updated.

6. **Validation**

   * exact commands executed;
   * results.

7. **Architectural risks**

   * unresolved ambiguities;
   * technical debt;
   * areas requiring future work.

8. **LUMOS comparison**

   * what SCR now represents that corresponds to LUMOS;
   * where SCR deliberately generalises beyond LUMOS;
   * any concepts from LUMOS intentionally rejected.

Do not claim completion if validation fails.

Do not hide failures.

Do not silently weaken tests to make the implementation pass.

---

# FINAL DIRECTIVE

Treat this work as an evolution of the **Semantic Computational Runtime's foundational execution model**.

The objective is not:

> "add support for AI agents."

The objective is:

> **Make the transition between semantic reality and manifested reality a first-class computational operation.**

The canonical loop should ultimately be expressible as:

```text
        ┌───────────────────────┐
        │    SEMANTIC FIELD     │
        └───────────┬───────────┘
                    │
                 observe
                    │
                    ▼
        ┌───────────────────────┐
        │ SEMANTIC OBSERVATION  │
        └───────────┬───────────┘
                    │
              transformation
                    │
                    ▼
        ┌───────────────────────┐
        │     CONSTRAINTS       │
        └───────────┬───────────┘
                    │
               manifestation
                    │
                    ▼
        ┌───────────────────────┐
        │      SUBSTRATE        │
        └───────────┬───────────┘
                    │
                 observe
                    │
                    ▼
        ┌───────────────────────┐
        │    RECONCILIATION     │
        └───────────┬───────────┘
                    │
                    └──────────────► SEMANTIC FIELD
```

This loop is not an "agent architecture."

It is a candidate **core execution pattern of SCR itself**.

Implement accordingly.
