// RUN: scr-opt %s | FileCheck %s

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

func.func @test_no_op() -> (!scr.hypergraph, !scr.context) {
  %g = "scr.empty"() : () -> !scr.hypergraph
  %c0 = arith.constant 0 : i64
  %id = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
  %ctx = "scr.make_context"(%c0, %id) : (i64, !scr.entity_id) -> !scr.context
  // CHECK: scr.no_op
  %g1, %ctx1 = "scr.no_op"(%g, %ctx) : (!scr.hypergraph, !scr.context) -> (!scr.hypergraph, !scr.context)
  return %g1, %ctx1 : !scr.hypergraph, !scr.context
}

func.func @test_make_hyperedge() -> !scr.hyperedge {
  %c0 = arith.constant 0 : i64
  %id = "scr.make_entity_id"(%c0) : (i64) -> !scr.entity_id
  %roles = "scr.value_unit"() : () -> !scr.value
  %props = "scr.value_unit"() : () -> !scr.value
  %tname = "scr.value_text"(%c0) : (i64) -> !scr.value
  // CHECK: scr.make_hyperedge
  %edge = "scr.make_hyperedge"(%id, %tname, %roles, %props) : (!scr.entity_id, !scr.value, !scr.value, !scr.value) -> !scr.hyperedge
  return %edge : !scr.hyperedge
}
