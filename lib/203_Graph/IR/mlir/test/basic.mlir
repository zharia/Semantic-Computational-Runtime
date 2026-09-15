// RUN: tools/scr-opt %s | FileCheck %s

// === Positive tests ===

func.func @test_empty_hypergraph() -> !scr.hypergraph {
  // CHECK: scr.empty
  %g = "scr.empty"() : () -> !scr.hypergraph
  return %g : !scr.hypergraph
}

func.func @test_add_node() -> !scr.hypergraph {
  %g = "scr.empty"() : () -> !scr.hypergraph
  %c0 = arith.constant 0 : i64
  %id = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
  %val = "scr.value_int"(%c0) : (i64) -> !scr.value
  %tname = "scr.value_text"(%c0) : (i64) -> !scr.value
  %props = "scr.value_unit"() : () -> !scr.value
  %entity = "scr.make_entity"(%id, %tname, %val, %props) : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.entity
  // CHECK: scr.add_node
  %g1 = "scr.add_node"(%g, %entity) : (!scr.hypergraph, !scr.entity) -> !scr.hypergraph
  return %g1 : !scr.hypergraph
}

func.func @test_observe_node() -> !scr.value {
  %g = "scr.empty"() : () -> !scr.hypergraph
  %c0 = arith.constant 0 : i64
  %id = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
  %val = "scr.value_int"(%c0) : (i64) -> !scr.value
  %tname = "scr.value_text"(%c0) : (i64) -> !scr.value
  %props = "scr.value_unit"() : () -> !scr.value
  %entity = "scr.make_entity"(%id, %tname, %val, %props) : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.entity
  %g1 = "scr.add_node"(%g, %entity) : (!scr.hypergraph, !scr.entity) -> !scr.hypergraph
  // CHECK: scr.observe_node
  %result = "scr.observe_node"(%g1, %id) : (!scr.hypergraph, !scr.entity_id) -> !scr.value
  return %result : !scr.value
}

func.func @test_step() -> (!scr.hypergraph, !scr.context) {
  %g = "scr.empty"() : () -> !scr.hypergraph
  %c0 = arith.constant 0 : i64
  %id = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
  %ctx = "scr.make_context"(%c0, %id) : (i64, !scr.entity_id) -> !scr.context
  // CHECK: scr.step
  %g1, %ctx1 = "scr.step"(%g, %ctx) ({
    %val = "scr.value_int"(%c0) : (i64) -> !scr.value
    %tname = "scr.value_text"(%c0) : (i64) -> !scr.value
    %props = "scr.value_unit"() : () -> !scr.value
    %entity = "scr.make_entity"(%id, %tname, %val, %props) : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.entity
    %g_inner = "scr.add_node"(%g, %entity) : (!scr.hypergraph, !scr.entity) -> !scr.hypergraph
    "scr.return"(%g_inner, %ctx) : (!scr.hypergraph, !scr.context) -> ()
  }) : (!scr.hypergraph, !scr.context) -> (!scr.hypergraph, !scr.context)
  return %g1, %ctx1 : !scr.hypergraph, !scr.context
}

func.func @test_remove_node() -> !scr.hypergraph {
  %g = "scr.empty"() : () -> !scr.hypergraph
  %c0 = arith.constant 0 : i64
  %id = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
  %val = "scr.value_int"(%c0) : (i64) -> !scr.value
  %tname = "scr.value_text"(%c0) : (i64) -> !scr.value
  %props = "scr.value_unit"() : () -> !scr.value
  %entity = "scr.make_entity"(%id, %tname, %val, %props) : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.entity
  %g1 = "scr.add_node"(%g, %entity) : (!scr.hypergraph, !scr.entity) -> !scr.hypergraph
  // CHECK: scr.remove_node
  %g2 = "scr.remove_node"(%g1, %id) : (!scr.hypergraph, !scr.entity_id) -> !scr.hypergraph
  return %g2 : !scr.hypergraph
}

func.func @test_update_node_value() -> !scr.hypergraph {
  %g = "scr.empty"() : () -> !scr.hypergraph
  %c0 = arith.constant 0 : i64
  %c1 = arith.constant 1 : i64
  %id = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
  %val = "scr.value_int"(%c0) : (i64) -> !scr.value
  %tname = "scr.value_text"(%c0) : (i64) -> !scr.value
  %props = "scr.value_unit"() : () -> !scr.value
  %entity = "scr.make_entity"(%id, %tname, %val, %props) : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.entity
  %g1 = "scr.add_node"(%g, %entity) : (!scr.hypergraph, !scr.entity) -> !scr.hypergraph
  %new_val = "scr.value_int"(%c1) : (i64) -> !scr.value
  // CHECK: scr.update_node_value
  %g2 = "scr.update_node_value"(%g1, %id, %new_val) : (!scr.hypergraph, !scr.entity_id, !scr.value) -> !scr.hypergraph
  return %g2 : !scr.hypergraph
}
