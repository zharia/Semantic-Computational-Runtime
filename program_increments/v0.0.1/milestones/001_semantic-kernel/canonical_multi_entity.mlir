/// Multi-Entity Semantic Program — CounterDefinition with Two Entities
///
/// Represents:
///   CounterDefinition
///     Counter c1 (value=5)
///     Counter c2 (value=10)
///     Relationship r1: c1 --LINKS--> c2
///     Transform c1: +3 → c1=8
///     Transform c2: -2 → c2=8
///     Observe c1 → 8
///     Observe c2 → 8
///
/// Representation mapping:
///   Entity Instances → parallel memref<1xi32> allocations
///   Relationships    → module-level metadata attributes
///   Transformations  → independent arith + constraint checks
///   Observations     → return values (non-mutating reads)
///
/// Provenance: This representation is derived from the normative
/// semantic definition at lib/counter/001_definition.md via the
/// semantic model at milestones/001_semantic-kernel/001_semantic-kernel.md
///
/// Verification: mlir-opt --allow-unregistered-dialect --verify-diagnostics

module attributes {
  // Provenance: which semantic definition produced this
  scr.provenance = {
    source = "semantic_kernel_canonical",
    definition = "CounterDefinition",
    milestone = "005",
    normative_source = "lib/counter/001_definition.md"
  },
  // Entity Definition
  scr.entity_definition = {
    type_id = "Counter",
    value_schema = ["value"]
  },
  // Entity Instances (multiple)
  scr.entity_instance = [
    { entity_id = "c1", definition_type = "Counter", initial_value = 5 : i32 },
    { entity_id = "c2", definition_type = "Counter", initial_value = 10 : i32 }
  ],
  // Relationship between entities
  scr.relationship = {
    rel_id = "r1",
    kind = "LINKS",
    source = "c1",
    target = "c2"
  },
  // Constraint
  scr.constraint = {
    kind = "non_negative",
    target_entity = "c1",
    target_property = "value"
  },
  // Context
  scr.context = {
    initial_step = 0 : index,
    label = "golden-path"
  }
} {
  /// Multi-entity semantic transformation program.
  ///
  /// Represents:
  ///   Counter(c1=5), Counter(c2=10)
  ///   → Transform(c1, +3), Transform(c2, -2)
  ///   → Observe(c1)=8, Observe(c2)=8
  func.func @canonical_multi_entity() -> (i32, i32) attributes {
    scr.semantic_program = true
  } {
    // ---- c1 initial = 5 ----
    %c1_init = arith.constant 5 : i32
    %c1_state = memref.alloca() : memref<1xi32>
    %idx0 = arith.constant 0 : index
    memref.store %c1_init, %c1_state[%idx0] : memref<1xi32>

    // ---- c2 initial = 10 ----
    %c2_init = arith.constant 10 : i32
    %c2_state = memref.alloca() : memref<1xi32>
    memref.store %c2_init, %c2_state[%idx0] : memref<1xi32>

    // ---- Transform c1: +3 ----
    %c3 = arith.constant 3 : i32
    %c1_v0 = memref.load %c1_state[%idx0] : memref<1xi32>
    %c1_v1 = arith.addi %c1_v0, %c3 : i32

    // Constraint: c1.value >= 0
    %c0 = arith.constant 0 : i32
    %cmp1 = arith.cmpi sge, %c1_v1, %c0 : i32
    scf.if %cmp1 {
      memref.store %c1_v1, %c1_state[%idx0] : memref<1xi32>
    } else {
      // Constraint violation: keep previous value
      %c1_v0_bad = memref.load %c1_state[%idx0] : memref<1xi32>
      memref.store %c1_v0_bad, %c1_state[%idx0] : memref<1xi32>
    }

    // ---- Transform c2: -2 ----
    %c_neg2 = arith.constant -2 : i32
    %c2_v0 = memref.load %c2_state[%idx0] : memref<1xi32>
    %c2_v1 = arith.addi %c2_v0, %c_neg2 : i32

    // Constraint: c2.value >= 0 (10 - 2 = 8 >= 0, passes)
    %cmp2 = arith.cmpi sge, %c2_v1, %c0 : i32
    scf.if %cmp2 {
      memref.store %c2_v1, %c2_state[%idx0] : memref<1xi32>
    } else {
      %c2_v0_bad = memref.load %c2_state[%idx0] : memref<1xi32>
      memref.store %c2_v0_bad, %c2_state[%idx0] : memref<1xi32>
    }

    // ---- Observe both ----
    %r1 = memref.load %c1_state[%idx0] : memref<1xi32>
    %r2 = memref.load %c2_state[%idx0] : memref<1xi32>
    return %r1, %r2 : i32, i32
  }
}
