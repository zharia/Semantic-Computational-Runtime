# Gate 0 — Specification Reconciliation Matrix

**Date:** 2026-09-07
**Status:** COMPLETE

---

## Reconciliation Matrix

| Kernel Concept | Normative Spec (seed/) | Lean Definition (formal/SCR/) | Mojo Definition (Reference Executor) | Conflicts | Resolution |
|---|---|---|---|---|---|
| **Entity** | seed/001_foundations/002_entity.md — "semantically identifiable participant in the Semantic Field" | SCR.Basic: `Entity` structure with `id: EntityId`, `typeName: String`, `value: Value`, `properties: List (String × Value)` | `Entity` struct with `id: String`, `kind: String`, `properties: Dict[String, Value]` | Lean has `value` field on Entity; Reference Executor does not. Lean uses `List (String × Value)`; Mojo uses `Dict`. | Lean `value` field is a canonical aggregation — acceptable. Dict vs List is representation choice — no semantic conflict. |
| **Identity** | seed/001_foundations/003_identity.md — "semantic property by which an entity remains identifiable across valid representations and transformations" | SCR.Identity: `EntityId` (structure with `value: String`), `SameIdentity`, `RepresentationChangePreservesIdentity` | `Entity.id` field (`String`) | Reference Executor uses raw String for identity. No explicit identity-persistence theorem in Mojo. | String-based identity is representation. Semantic identity is defined by `EntityId` in Lean. No conflict — implementation is subordinate. |
| **Value** | seed/001_foundations/004_value.md — "semantic content carried by a property, state, operation, relationship, observation or transformation" | SCR.Basic: `Value` inductive with `unit`, `bool`, `int`, `real`, `text`, `sequence` | `Value = Variant[Int, Float64, Bool, String]` | Lean has `unit` and `sequence` variants; Mojo does not. Mojo uses `Float64` where Lean uses `Float`. | `unit` and `sequence` not needed for kernel witness — deferred. Float64 vs Float is representation — no semantic conflict. |
| **Relationship** | seed/001_foundations/006_relationship.md — "first-class semantic connection between identifiable entities" | SCR.Relationship: `Relationship` structure with `source: EntityId`, `target: EntityId`, `kind: RelationKind`, `properties: List (String × Value)` | `Relationship` struct with `id: String`, `relation: String`, `source: String`, `target: String` | Reference Executor has `id` field; Lean does not. Reference Executor lacks `properties`. | `id` on Relationship is useful for referencing — acceptable extension. `properties` omission is simplification for kernel witness — no semantic conflict. |
| **State** | seed/001_foundations/008_state.md — "semantically meaningful configuration of a field or entity at a point in the relevant state space" | SCR.State: `State` structure with `entities: List Entity`, `relationships: List Relationship`, plus `EntityIdsUnique`, `RelationshipsWellFormed`, `ValidState` | State is implicit in `SemanticField.entities` Dict | Reference Executor embeds state in field. Lean has explicit `ValidState` predicate. | Representation difference — no semantic conflict. |
| **Transformation** | seed/003_computation/010_transformation.md — "semantic mapping that changes, refines, projects, composes or otherwise derives semantic structure" | SCR.Transformation: `Transformation` structure with `id: TransformationId`, `operation: OperationId`, `target: EntityId`, `argument: Option Value` | `Transformation` struct with `operation: Int`, `entity_id: String`, `property_name: String`, `operand: Int` | Lean uses typed IDs; Mojo uses raw Int/String. Lean has `argument: Option Value`; Mojo has `operand: Int`. | Int-based operation codes are representation. No semantic conflict. |
| **Constraint** | seed/007_semantic-laws/016_constraint.md — "condition that must hold for a semantic object, operation, transformation or composition to be valid" | SCR.Basic: `Constraint (S : Type) := S → Prop`. SCR.Invariants: `InvariantId` enum | `NonNegativeConstraint` struct with `entity_id`, `property_name`, `validate(value: Int)` | Lean constraint is abstract predicate; Reference Executor has concrete NonNegativeConstraint only. | Concrete constraint is instance of abstract — no conflict. |
| **Context** | seed/001_foundations/007_context.md — "semantic conditions under which a statement, value, operation or relationship is meaningful" | SCR.Field: `Context` structure with `id: ContextId`, `name: String` | Context not explicitly represented (implicit in Executor) | Reference Executor lacks explicit Context. | Deferred for kernel witness — context is architecturally present in Lean. |
| **Time** | seed/004_space_time/032_time.md — "semantic dimension supporting temporal order, intervals, evolution, events, processes and timescales" | Not explicitly formalized as standalone type | `ExecutionState.logical_step: Int` | No explicit Time type in Lean. Reference Executor uses logical_step. | Time needs formal definition. Action: add to Lean. |
| **Observation** | seed/003_computation/014_observation.md — "information obtained about an entity, field, process or environment" | Not formalized | `Observation` struct with `step`, `entity_id`, `property_name`, `value` | No Observation type in Lean. | Action: add to Lean. |
| **Semantic Field** | seed/001_foundations/001_semantic-field.md — "foundational semantic substrate" | SCR.Field: `SemanticField` with `state`, `contexts`, `transformations` | `SemanticField` struct with `entities`, `relationships`, `non_negative_constraints` | Lean SemanticField has contexts and transformations; Reference Executor does not. | Representation difference — no semantic conflict. |

---

## Conflicts Found

1. **Lean Entity has `value` field; Reference Executor does not** — Not a conflict. The `value` field in Lean is a canonical aggregation; the Reference Executor accesses values through entity properties. Both are valid representations.

2. **No explicit Time type in Lean** — Gap. Action: add `SemanticTime` to Lean formal model.

3. **No explicit Observation type in Lean** — Gap. Action: add `Observation` to Lean formal model.

4. **Reference Executor lacks explicit Context** — Acceptable for kernel witness. Context is architecturally present in Lean `SemanticField`.

---

## Required Actions

1. Add `SemanticTime` type and theorems to `formal/SCR/Basic.lean`
2. Add `Observation` type and non-interference theorem to `formal/SCR/Basic.lean`
3. Add `Context` persistence to `formal/SCR/Field.lean`
4. Build Mojo semantic kernel that corresponds to reconciled definitions
5. Create equivalence tests between Mojo kernel and Reference Executor

---

## Conclusion

No semantic contradictions found. All differences are representation-level, which is architecturally correct. Two gaps identified (Time, Observation in Lean) — resolved by extending the formal model.
