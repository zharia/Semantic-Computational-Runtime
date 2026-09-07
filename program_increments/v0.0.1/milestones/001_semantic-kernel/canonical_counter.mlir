/// Canonical Semantic Entity Compilation — Representation Analysis
///
/// This MLIR module represents the canonical Counter semantic program
/// using standard MLIR dialects. No custom SCR dialect is introduced.
///
/// Semantic Program:
///   1. Entity Definition: Counter (value_schema=["value"])
///   2. Entity Instance: c1, Counter, initial value=0
///   3. Constraint: value >= 0
///   4. Context: step=0, label="golden-path"
///   5. Transformation: increment value by 5, then by 3, then by 2
///   6. Observation: read final value
///
/// Representation mapping:
///   Entity Definition  → module attributes (metadata)
///   Entity Instance    → memref<1xi32> (state container)
///   Identity           → function name + entity_id attribute
///   Value              → i32 (semantic integer value)
///   State              → memref<1xi32> (authoritative state)
///   Transformation     → arith.addi + memref.store/load
///   Constraint         → scf.if guard (verified at transform time)
///   Context            → module attributes (logical_step, label)
///   Time               → index (semantic step counter)
///   Observation        → return value (non-mutating read)
///
/// Verification: mlir-opt --verify-diagnostics

// ---------------------------------------------------------------
// Entity Definition metadata (attributes, not executable)
// ---------------------------------------------------------------
// These attributes encode semantic information that must survive
// representation. They are not lowered — they are metadata.

// ---------------------------------------------------------------
// Canonical Counter Transformation
// ---------------------------------------------------------------

// Module with semantic metadata attributes
module attributes {
  // Entity Definition
  scr.entity_definition = {
    type_id = "Counter",
    value_schema = ["value"]
  },
  // Entity Instance
  scr.entity_instance = {
    entity_id = "c1",
    definition_type = "Counter",
    initial_value = 0 : i32
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

  /// Canonical semantic transformation program.
  ///
  /// Represents: CounterInstance → Transform(+5,+3,+2) → Observe
  ///
  /// The function body encodes the exact same computation as the
  /// Mojo kernel and Reference Executor canonical programs.
  func.func @canonical_counter() -> i32 attributes {
    // This function IS the canonical semantic program.
    // Its return value is the observation result.
    scr.semantic_program = true,
    scr.entity = "c1",
    scr.entity_type = "Counter"
  } {
    // Initial state: value = 0
    %init = arith.constant 0 : i32

    // Allocate authoritative state (memref = semantic state container)
    %state = memref.alloca() : memref<1xi32>
    %idx0 = arith.constant 0 : index
    memref.store %init, %state[%idx0] : memref<1xi32>

    // Context: logical step = 0
    %step0 = arith.constant 0 : index

    // ---- Transformation 1: increment by 5 ----
    %c5 = arith.constant 5 : i32
    %v0 = memref.load %state[%idx0] : memref<1xi32>
    %v1 = arith.addi %v0, %c5 : i32

    // Constraint guard: check value >= 0
    // (For positive increments this always holds; guard is structural)
    %c0 = arith.constant 0 : i32
    %cmp1 = arith.cmpi sge, %v1, %c0 : i32
    scf.if %cmp1 {
      memref.store %v1, %state[%idx0] : memref<1xi32>
    }

    // ---- Transformation 2: increment by 3 ----
    %c3 = arith.constant 3 : i32
    %v2 = memref.load %state[%idx0] : memref<1xi32>
    %v3 = arith.addi %v2, %c3 : i32

    %cmp2 = arith.cmpi sge, %v3, %c0 : i32
    scf.if %cmp2 {
      memref.store %v3, %state[%idx0] : memref<1xi32>
    }

    // ---- Transformation 3: increment by 2 ----
    %c2 = arith.constant 2 : i32
    %v4 = memref.load %state[%idx0] : memref<1xi32>
    %v5 = arith.addi %v4, %c2 : i32

    %cmp3 = arith.cmpi sge, %v5, %c0 : i32
    scf.if %cmp3 {
      memref.store %v5, %state[%idx0] : memref<1xi32>
    }

    // ---- Observation: read final value (non-mutating) ----
    %result = memref.load %state[%idx0] : memref<1xi32>
    return %result : i32
  }
}
