// SCR Dialect Example: Counter Entity Lifecycle
//
// Demonstrates the canonical SCR workflow:
// 1. Create empty state
// 2. Add entities
// 3. Update values
// 4. Observe state
//
// All operations derive from SCRFormal/SCR/Algebra.lean.
// Uses generic syntax (v0.1.0 — no assemblyFormat yet).

// === State Construction ===

%g0 = "scr.empty"() : () -> !scr.hypergraph

%c0 = arith.constant 0 : i64
%id_init = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
%ctx = "scr.make_context"(%c0, %id_init) : (i64, !scr.entity_id) -> !scr.context

// === Entity Creation ===

// Create entity identity
%id_a = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id

// Create value
%val_a = "scr.value_int"(%c0) : (i64) -> !scr.value

// Type name and properties
%tname = "scr.value_text"(%c0) : (i64) -> !scr.value
%props = "scr.value_unit"() : () -> !scr.value

// Assemble entity
%entity_a = "scr.make_entity"(%id_a, %tname, %val_a, %props)
    : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.entity

// Add to hypergraph
%g1 = "scr.add_node"(%g0, %entity_a)
    : (!scr.hypergraph, !scr.entity) -> !scr.hypergraph

// === Value Update ===

%c1 = arith.constant 1 : i64
%new_val = "scr.value_int"(%c1) : (i64) -> !scr.value

%g2 = "scr.update_node_value"(%g1, %id_a, %new_val)
    : (!scr.hypergraph, !scr.entity_id, !scr.value) -> !scr.hypergraph

// === Observation (Pure) ===

%observed = "scr.observe_node"(%g2, %id_a)
    : (!scr.hypergraph, !scr.entity_id) -> !scr.value

// === Identity is Preserved ===

// After update_node_value, entity id is unchanged.
// Formal: { n with value := v }.id = n.id
