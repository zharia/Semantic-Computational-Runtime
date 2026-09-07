# Representation Boundary Analysis

**Document:** SCR-GP-REPRESENTATION-BOUNDARY-0003
**Version:** 0.0.1
**Date:** 2026-09-07
**Status:** ANALYSIS

---

## 1. Purpose

This analysis determines what semantic information must survive from the verified semantic kernel into a computational representation (eventually MLIR). For each kernel concept, we evaluate:

1. What semantic information must survive
2. Whether existing MLIR mechanisms can represent it
3. Whether a custom SCR operation is necessary
4. A recommendation

The analysis covers the verified kernel concepts as implemented across Lean, Mojo Semantic Kernel, and Reference Executor.

---

## 2. Concept-by-Concept Analysis

### 2.1 Identity (EntityId)

**Semantic information that must survive:**
- Entity identity is a unique semantic label (currently `String`)
- Identity must survive representation changes (Lean: `RepresentationChangePreservesIdentity`)
- Identity is independent from memory address, array index, or encoding
- Identity persists across property mutations

**MLIR mechanisms:**
- MLIR identifiers (`mlir::StringAttr`, `mlir::IntegerAttr`) can carry entity identity
- SSA values provide natural uniqueness per value
- Operation results can carry identity metadata via attributes
- `OperationState` supports arbitrary string attributes

**Custom operation needed:** No.

**Recommendation:** Identity can be represented as an MLIR attribute (string or integer) attached to operations and types. No custom operation required. The existing `OperationId` pattern in MLIR provides the right abstraction.

---

### 2.2 EntityDefinition (type_id, value_schema)

**Semantic information that must survive:**
- A definition has a stable `type_id` (semantic type identity)
- A definition specifies a `value_schema`: the set of property names an instance must carry
- Definitions are registered and looked up by `type_id`
- Definitions are independent from instances

**MLIR mechanisms:**
- MLIR types (`mlir::Type`) can represent structured data
- TableGen type definitions allow custom type systems
- `memref`, `tensor` types can represent value schemas as shaped types
- Custom type attributes can carry property schemas
- `mlir::DictionaryAttr` can carry structured metadata

**Custom operation needed:** Possibly — if we want `scr.define_type` as a first-class semantic operation. However, a custom MLIR **type** (not operation) may suffice, using TableGen to define an `EntityType` with a schema attribute.

**Recommendation:** A custom SCR type (via TableGen) appears appropriate. Definitions are structural metadata, not executable operations. They belong in the type system, not as runtime operations. A `scr.EntityType` with a `value_schema` attribute would preserve the semantic contract without requiring a custom operation.

---

### 2.3 EntityInstance (identity, definition_type, values)

**Semantic information that must survive:**
- An instance has a unique identity (SemanticIdentity)
- An instance conforms to a definition (`definition_type`)
- An instance carries runtime values matching its definition's schema
- Conformity can be validated: `instance.conforms(definition)`

**MLIR mechanisms:**
- SSA values naturally represent instances as immutable results
- `memref` can hold mutable instance state in memory
- Operation results can carry type information
- Attributes can carry identity metadata

**Custom operation needed:** Likely — if instance creation is a semantic act. `scr.create_instance(type, id)` could formalize instantiation. However, this might also be representable as a function call with appropriate type annotations.

**Recommendation:** Instance creation and conformity validation may warrant a custom operation (`scr.instantiate`), since it represents a semantic boundary: the moment a definition becomes a living participant in the field. However, the current kernel witnesses suggest this can initially be represented as typed function calls with attribute metadata. Defer custom operation creation until the semantic necessity is demonstrated.

---

### 2.4 Value (Variant type)

**Semantic information that must survive:**
- Values are polymorphic: Int, Float64, Bool, String (kernel witness set)
- Values are carried by entity properties
- Values are observed and returned through observations
- Value type must be preserved through round-trips

**MLIR mechanisms:**
- MLIR has a rich type system: `i32`, `i64`, `f32`, `f64`, `i1`, `string`
- `UnionType` in MLIR can represent variant types
- `IndexType` provides integer-like semantics
- `AnyType` can serve as a catch-all
- Custom type definitions via TableGen are straightforward

**Custom operation needed:** No. Value types map directly to existing MLIR types.

**Recommendation:** Existing MLIR types are sufficient. The kernel witness set (Int, Float64, Bool, String) maps to `i64`, `f64`, `i1`, `!llvm.ptr` (or custom string type). No custom operation needed. If the variant nature needs explicit representation, a custom type attribute or union type can express it.

---

### 2.5 State (entities, relationships, logical_step)

**Semantic information that must survive:**
- State is an authoritative configuration of entities and relationships
- State has a `logical_step` (temporal position)
- State validity requires unique entity IDs and well-formed relationships
- Failed transformations must not partially corrupt state
- Copy-on-write execution model must be preserved

**MLIR mechanisms:**
- `memref` types can represent mutable state in memory
- `scf.for` and `scf.while` can represent temporal loops
- `memref.alloca` / `memref.alloc` can hold state
- Operation side effects can model state mutations
- `func` operations with `memref` arguments can represent stateful computation

**Custom operation needed:** Possibly. State transitions are the core semantic act of SCR. A `scr.step` operation could formalize temporal advancement. However, this might also be representable as a function call with state-passing semantics.

**Recommendation:** State can initially be represented as `memref` holding entity data. Temporal advancement (`logical_step`) can be represented as an `i64` index. The copy-on-write model maps to `memref` allocation + copy + conditional commit. Custom operations may become necessary when we need verification passes over state transitions, but at this stage existing mechanisms appear sufficient.

---

### 2.6 Relationship (id, kind, source, target)

**Semantic information that must survive:**
- Relationships connect entities by identity
- Relationships have a semantic `kind` (e.g., "LINKS", "CONNECTS")
- Source and target must reference existing entities
- Relationships have their own identity
- Relationship endpoints are validated at creation time

**MLIR mechanisms:**
- Operations can reference SSA values (entities) as operands
- Attributes can carry relationship metadata (kind, id)
- `graph.region` in MLIR can represent graph-like structures
- Operation results can carry relationship handles

**Custom operation needed:** Likely — if relationships are first-class semantic constructs. `scr.create_relationship(kind, source, target)` would formalize relationship creation. However, this might be representable as a function call initially.

**Recommendation:** Relationships can initially be represented as operations that take entity references as operands and produce a relationship handle. The `kind` can be an attribute. Custom operation creation is recommended when relationships need to participate in verification passes (e.g., endpoint existence checks), but initially a function call with appropriate attributes may suffice.

---

### 2.7 Transformation (operation, entity_id, property_name, operand)

**Semantic information that must survive:**
- Transformations are semantic acts that change state
- Three kernel witness operations: SET_INT, INCREMENT, EMIT
- Transformations target specific entities and properties
- Transformations may carry operands
- Failed transformations must not partially mutate state
- Determinism: same transformation + same state = same result

**MLIR mechanisms:**
- MLIR operations (`OperationState`) naturally represent transformations
- `func` operations can represent transformations as function calls
- `scf.if` can represent conditional execution
- `scf.for` can represent iterative transformations
- `arith` operations can represent numeric transformations

**Custom operation needed:** Yes, strongly recommended. Transformations are the primary semantic act in SCR. `scr.set`, `scr.increment`, `scr.emit` would provide semantic clarity and enable verification passes. The current kernel witness operations map naturally to custom operations.

**Recommendation:** Custom SCR operations for transformations are the highest-priority recommendation. They represent the core semantic act of the system and benefit most from first-class representation. The three kernel witnesses (SET_INT, INCREMENT, EMIT) map directly to `scr.set`, `scr.increment`, `scr.emit`. Additional operations (e.g., `scr.create_entity`, `scr.create_relationship`) should be added as the kernel expands.

---

### 2.8 Constraint (entity_id, property_name, validate)

**Semantic information that must survive:**
- Constraints are predicates over state
- Constraints reference specific entity properties
- Constraints must be validated after transformations
- Constraint violation rejects the transformation
- Copy-on-write ensures no partial mutation on violation

**MLIR mechanisms:**
- `cf.cond_branch` can represent conditional execution
- `scf.if` can represent constraint-gated regions
- Function arguments can carry constraint metadata
- Custom verification passes can validate constraints at compile time

**Custom operation needed:** Possibly — if constraints need compile-time verification. `scr.constrain` could represent a constraint predicate. However, constraints are more naturally represented as verification rules than as runtime operations.

**Recommendation:** Constraints are better represented as verification metadata than as runtime operations. They can be attached to operations via attributes (`scr.constraint` attribute on transformation operations) and validated by a verification pass. This approach preserves the semantic contract while leveraging MLIR's verification infrastructure.

---

### 2.9 Context (logical_step, label)

**Semantic information that must survive:**
- Context carries temporal position (`logical_step`)
- Context carries a semantic label
- Context propagates through field execution
- Transformations advance context.logical_step
- Context is part of the transformation contract: `F_(t+1) = T(F_t, C_t)`

**MLIR mechanisms:**
- `scf.for` provides natural loop iteration (temporal position)
- `func` arguments can carry context metadata
- `index` type naturally represents loop indices
- Attributes can carry label metadata

**Custom operation needed:** No. Context maps naturally to loop iteration variables and function arguments. The `logical_step` is an index, and the label is an attribute.

**Recommendation:** Context can be represented as loop iteration variables (`index` type) and attributes. The `logical_step` maps to `scf.for` loop induction variables. Custom operations are not needed. Context propagation is naturally handled by SSA value flow through operations.

---

### 2.10 Time (SemanticTime)

**Semantic information that must survive:**
- Time is a semantic dimension with a `step: Int`
- Time advances monotonically (TimeProgresses: after.step >= before.step)
- Observation does not advance time
- Transformations advance time by 1

**MLIR mechanisms:**
- `index` type naturally represents temporal steps
- `scf.for` provides loop induction variables
- `arith.addi` can increment time
- `cf.cond_branch` can enforce monotonicity

**Custom operation needed:** No. Time maps directly to `index` type and loop induction variables. Monotonicity can be enforced by a verification pass.

**Recommendation:** Time can be represented as `index` type values. Temporal advancement is naturally expressed as `arith.addi %step, 1`. Monotonicity is a verification concern, not a representation concern. No custom operation needed.

---

### 2.11 Observation (step, entity_id, property_name, value)

**Semantic information that must survive:**
- Observations record what was seen at a specific step
- Observations reference entity identity and property name
- Observations carry the observed value
- Observations do not mutate state (non-interference)
- Observations do not advance time

**MLIR mechanisms:**
- Operation results can carry observation data
- `memref` can hold observation logs
- `func` return values can carry observations
- Attributes can carry observation metadata

**Custom operation needed:** Possibly — `scr.observe` could formalize observation as a semantic act. However, observation is read-only and might be representable as a function call.

**Recommendation:** Observation can initially be represented as a function call that returns a value without side effects. The `scr.emit` transformation in the current kernel already represents this semantic act. A custom `scr.observe` operation may become valuable when observations need to participate in verification passes, but is not necessary at this stage.

---

### 2.12 SemanticField (state, constraints, observations, definitions, context)

**Semantic information that must survive:**
- The field is the authoritative semantic environment
- The field owns state, constraints, observations, definitions, and context
- The field orchestrates execution
- The field validates state after transformations

**MLIR mechanisms:**
- Module operations can represent the field
- `memref` types can hold field components
- Function arguments can pass field references
- `func` operations can represent field operations

**Custom operation needed:** No. The field is best represented as a module or function scope containing state and operations. It is not a runtime operation but an organizational structure.

**Recommendation:** The field can be represented as an MLIR module containing state (`memref`), operations (transformations), and metadata (attributes). No custom operation needed. The field is the container, not a contained operation.

---

## 3. Summary Matrix

| Concept | Semantic Identity Survives | Type/Definition Survives | Relationships Survive | MLIR Mechanism | Custom Operation Needed |
|---------|---------------------------|--------------------------|----------------------|----------------|------------------------|
| Identity | Yes | No (string attribute) | No | StringAttr | No |
| EntityDefinition | Yes | Yes (custom type) | No | TableGen type | No (custom type) |
| EntityInstance | Yes | Yes (via definition type) | No | SSA value + attributes | No (defer) |
| Value | N/A | Yes (MLIR types) | No | i64/f64/i1/string | No |
| State | N/A | N/A | Yes (entity references) | memref | No |
| Relationship | Yes | Yes (kind attribute) | Yes (entity operands) | Operation + attributes | No (defer) |
| Transformation | N/A | N/A | Yes (entity operands) | Custom operations | **Yes** |
| Constraint | N/A | N/A | Yes (entity references) | Attributes + verification | No (verification) |
| Context | N/A | N/A | No | index + attributes | No |
| Time | N/A | N/A | No | index type | No |
| Observation | N/A | N/A | Yes (entity references) | Function call | No (defer) |
| SemanticField | N/A | N/A | N/A | Module scope | No |

---

## 4. Key Findings

### 4.1 Existing MLIR Mechanisms Are Largely Sufficient

For 10 of 12 concepts, existing MLIR mechanisms (func, memref, arith, index, attributes, scf) provide adequate representation. The semantic kernel maps naturally onto MLIR's computational model without requiring custom infrastructure.

### 4.2 Transformations Are the Primary Custom Operation Candidate

Transformations are the core semantic act of SCR. They represent state changes, are validated against constraints, and carry semantic meaning beyond their computational effect. Custom operations (`scr.set`, `scr.increment`, `scr.emit`) would provide semantic clarity and enable verification passes.

### 4.3 EntityDefinition May Benefit from a Custom Type

Entity definitions are structural metadata that describe entity schemas. A custom MLIR type (`scr.EntityType` via TableGen) would preserve this structural information in the type system, enabling compile-time conformity checks.

### 4.4 Verification Is a Separate Concern

Constraints, identity uniqueness, and state validity are verification concerns, not representation concerns. They can be implemented as MLIR verification passes rather than runtime operations. This separation is architecturally clean.

### 4.5 Context and Time Map Naturally to Loop Constructs

The `F_(t+1) = T(F_t, C_t)` model maps naturally to `scf.for` loops with `index` induction variables. No custom operations needed.

---

## 5. Recommendations

### 5.1 Immediate (Before Next Milestone)

1. **Do not create a custom SCR MLIR dialect yet.** The analysis shows existing mechanisms are sufficient for initial representation.
2. **If creating operations, start with transformations.** `scr.set`, `scr.increment`, `scr.emit` are the highest-value custom operations.
3. **Consider a custom type for EntityDefinition.** TableGen `scr.EntityType` with a `value_schema` attribute.

### 5.2 When MLIR Representation Begins

1. **Start with a minimal operation set.** Only add custom operations when the semantic benefit is demonstrated.
2. **Use attributes for metadata.** Entity identity, relationship kind, and constraint specifications can be attributes on standard operations.
3. **Implement verification passes separately.** Constraint validation, identity uniqueness, and state validity are verification concerns.
4. **Represent state as memref.** Entity data maps to memref holding structured data.
5. **Represent time as index.** Loop induction variables provide natural temporal semantics.

### 5.3 What NOT to Do

1. **Do not create `scr.create_entity`, `scr.create_state`, etc.** These are not semantic operations — they are construction patterns.
2. **Do not create a parallel IR.** MLIR is the canonical representation. Do not build a "Semantic IR" alongside it.
3. **Do not conflate representation with semantics.** The representation must preserve semantics, not redefine them.

---

## 6. Conclusion

The representation boundary analysis yields a clear conclusion:

> **Existing MLIR mechanisms appear sufficient for representing the verified semantic kernel, with one strong recommendation: custom operations for transformations.**

The semantic kernel maps naturally onto MLIR's computational model. The primary gap is the absence of first-class transformation operations, which are the core semantic act of SCR. A minimal set of custom operations (`scr.set`, `scr.increment`, `scr.emit`) would provide significant semantic clarity without requiring extensive custom infrastructure.

The remaining concepts (identity, definitions, instances, values, state, relationships, constraints, context, time, observation) can be represented using existing MLIR mechanisms (attributes, types, memref, scf, index, func) without custom operations.

This is a successful outcome. The analysis demonstrates that the semantic kernel is well-structured enough to survive the representation boundary without losing semantic meaning.
