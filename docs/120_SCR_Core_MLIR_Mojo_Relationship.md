# SCR Core → MLIR ↔ Mojo Relationship

## 1. Three-Layer Architecture

### 1.1 Semantic Definition (Authoritative)
- **Document:** `lib/101_Core/101_definition.md`
- **Purpose:** Normative semantic meaning
- **Authority:** `SCRFormal/SCR/Algebra.lean`
- **Functions:** 24+ conceptual functions (§70-82)

### 1.2 Machine-Readable Definition
- **Artifact:** `lib/203_Graph/IR/mlir/` (MLIR `scr` dialect)
- **Purpose:** Machine-parsable semantic definition
- **Contents:** 21 ops, 7 opaque types, per-op verifiers, `--scr-verify` pass
- **Version:** v0.2.0

### 1.3 Executable Kernel
- **Artifact:** `lib/scr_kernel/` (`.mojo` files)
- **Purpose:** Executable semantic functions on typed values/entities/state
- **Contents:** 11 `.mojo` files, 303 test functions, `SemanticField` orchestrator
- **Version:** v0.0.1

## 2. Function Coverage Matrix (P0 Essential = Fully Mapped)

| # | Function | MLIR Op | Moji Function | Status |
|---|---|---|---|---|
| 1 | `identity.create` | `make_entity_id` | `Entity.__init__` | ✅ |
| 2 | `identity.resolve` | `make_entity_id` value extraction | `Entity.id` access | ✅ |
| 3 | `identity.compare` | `!scr.entity_id` string comparison | `Entity.id` comparison | ✅ |
| 4 | `type.define` | Type system via opaque types | `Value.Variant` definition | ✅ |
| 4 | `type.validate` | Op verifiers on 9 ops | `NonNegativeConstraint.validate()` | ✅ |
| 5 | `value.create` | `value_unit`/`value_int`/`value_bool`/`value_real`/`value_text` | `Value.Variant(...)` constructor | ✅ |
| 6 | `entity.create` | `make_entity` | `Entity.__init__` + `Field.add_entity` | ✅ |
| 7 | `entity.identify` | `make_entity_id` from entity | `Entity.id` access | ✅ |
| 7 | `entity.attribute` | *New MLIR op needed* | `Entity.get(property_name)` | ⚠️ Map needed |
| 8 | `relationship.create` | `make_hyperedge` | `Field.add_definition` / `Field.add_constraint` | ✅ |
| 8 | `relationship.connect` | *New MLIR op needed* | `Field.add_relationship` | ⚠️ Map needed |
| 8 | `relationship.disconnect` | `remove_edge` op exists | `SemanticField.remove_relationship` | ✅ |
| 8 | `relationship.role` | *Via `make_role_binding`* | `SemanticField` role handling | ✅ |
| 9 | `hyperedge.create` | `make_hyperedge` op exists | `Field.add_constraint` | ✅ |
| 9 | `hyperedge.participant` | *Via `make_role_binding`* | N/A | ✅ MLIR |
| 9 | `hyperedge.role` | *Via `make_role_binding`* | N/A | ✅ MLIR |
| 10 | `region.create` | `empty` / `make_context` / `step` / `atomic_tx` | `SemanticField.__init__` | ✅ Both |
| 10 | `region.select` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| 10 | `region.contains` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| 11 | `reference.create` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| 11 | `reference.resolve` | *New MLIR op needed* | N/A | ⚠️ Map needed |
| 12 | `representation.create` | Deferred | N/A | Deferred |
| 12 | `representation.convert` | Deferred | N/A | Deferred |
| 13 | `pattern.create` | Deferred | N/A | Deferred |
| 13 | `pattern.match` | Deferred | N/A | Deferred |
| 14 | `transformation.create` | `Transformation` struct in MLIR | `Transformation.__init__` | ✅ Both |
| 15 | `transformation.apply` | `step`/`atomic_tx` lowering | `Field.execute(INC/EMIT/SET_INT)` | ✅ Both |
| 16 | `operation.define` | 21 ops defined in `SCR.td` | N/A (IR-level) | ✅ MLIR |
| 16 | `operation.execute` | `scr-opt` / `--scr-verify` | N/A (runtime) | ✅ MLIR tool |
| 16 | `operation.validate` | Op `verify()` methods (9 ops) | N/A (compile-time) | ✅ MLIR |
| 17 | `state.create` | `empty` op | `SemanticField.__init__` | ✅ Both |
| 17 | `state.observe` | `observe_node` op | `Field.validate()` | ✅ Both |
| 17 | `state.transition` | `step`/`atomic_tx` ops | `Field.execute(INC/EMIT)` | ✅ Both |
| 18 | `delta.compute` | Deferred | N/A | Deferred |
| 18 | `delta.apply` | Deferred | N/A | Deferred |
| 18 | `delta.compose` | Deferred | N/A | Deferred |
| 19 | `event.create` | *New MLIR op or trace mechanism* | N/A | ⚠️ Map needed |
| 19 | `event.emit` | *New MLIR pass or trace* | N/A | ⚠️ Map needed |
| 20 | `stream.create` | Deferred | N/A | Deferred |
| 20 | `stream.subscribe` | Deferred | N/A | Deferred |
| 20 | `stream.transform` | Deferred | N/A | Deferred |
| 21 | `temporal.compare` | Context `logical_step` comparison | N/A | ✅ MLIR |
| 21 | `temporal.order` | Context `logical_step` ordering | N/A | ✅ MLIR |
| 22 | `causal.link` | Deferred | N/A | Deferred |
| 22 | `causal.predecessors` | Deferred | N/A | Deferred |
| 23 | `provenance.record` | Deferred | N/A | Deferred |
| 23 | `provenance.trace` | Deferred | N/A | Deferred |
| 24 | `constraint.validate` | Op verifiers | `NonNegativeConstraint.validate()` | ✅ Both |
| 25 | `capability.query` | Deferred | N/A | Deferred |
| 25 | `capability.require` | Deferred | N/A | Deferred |
| 25 | `contract.validate` | Deferred | N/A | Deferred |
| 25 | `contract.compose` | Deferred | N/A | Deferred |
| 26 | `equivalence.compare` | Deferred | N/A | Deferred (CX-EQV open) |
| 27 | `query.select` | Deferred | N/A | Deferred |
| 27 | `query.evaluate` | Deferred | N/A | Deferred |
| 28 | `observation.record` | `observe_node` + value ops | N/A | ✅ MLIR |
| 29 | `resource.require` | Deferred | N/A | Deferred |
| 29 | `resource.release` | Deferred | N/A | Deferred |
| 30 | `error.create` | Deferred | N/A | Deferred |
| 30 | `error.classify` | Deferred | N/A | Deferred |

## 3. Abstraction Levels

| Level | Description | Artifact |
|---|---|---|
| **Semantic Definition** | Core meaning (authoritative) | `101_Core.md` |
| **MLIR Representation** | Machine-readable semantic library | `MLIR scr dialect` |
| **Mojo Implementation** | Executable semantic kernel | `Mojo scr_kernel` |
| **Developer Code** | Application-level semantic functions | User code |

## 3. Mapping Rules

### 3.1 MLIR → Moji Mapping Rules
- Every MLIR op with `hasVerifier = 1` has a corresponding Moji function in `scr_kernel/`
- Type mappings: `!scr.entity_id` → `Entity.id`, `!scr.value` → `Value.Variant`, `!scr.entity` → `Entity`
- Verifier mappings: MLIR `emitOpError` → Moji `Error(...)`
- Coverage: P0 essential (8 functions) fully mapped; P1 gap functions under active mapping

### 3.2 Moji → MLIR Mapping Rules
- Every Moji type has a corresponding MLIR opaque type
- Every Moji function has a corresponding MLIR op or lowering
- `SemanticField.execute()` ↔ `step`/`atomic_tx`/`empty` lowering
- `NonNegativeConstraint.validate()` ↔ MLIR op verifier checks

### 3.3 Gap Identification Rules
- Functions present in 101_Core §70 but missing from both MLIR and Moji
- Functions present in one layer but missing from the other
- Functions requiring new MLIR ops or Moji function additions

## 3. Version Synchronization

| Artifact | Current Version | Sync Trigger |
|---|---|---|
| `101_Core.md` | v0.1.0 | On semantic meaning change |
| `MLIR scr dialect` | v0.2.0 | On op/type/function change |
| `Mojo scr_kernel` | v0.0.1 | On function addition/change |
| **Function Coverage Matrix** | v0.2.0 | On any layer change |

## 4. Maintenance Responsibilities

| Layer | Owner | Update Frequency | Gap Identification |
|---|---|---|---|
| **Semantic Definition** | Domain working group | On specification change | Quarterly review |
| **MLIR scr dialect** | MLIR working group | On op/addition | Monthly review + lit test failures |
| **Mojo scr_kernel** | Mojo working group | On function addition | Monthly review + test failures |
| **Function Coverage Matrix** | Documentation working group | On any change | Bi-weekly review |

---

## 5. Open Questions (for future resolution)

1. Which P1/P2 gap functions should be prioritized for MLIR op additions?
2. Should Moji function additions follow MLIR op design, or vice versa?
3. What is the maintenance schedule for keeping the Function Coverage Matrix current?
4. How should version synchronization be enforced across the three layers?
5. Which open questions (1-5 from the 101_Core §66) need immediate resolution?

---