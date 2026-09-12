//===- SCR.td - SCR Dialect Definition -*- tablegen -*-===//
//
// Complete SCR dialect definition.
// Derived from: SCRFormal/SCR/Algebra.lean (closed semantic algebra)
//
//===------------------------------------------------------===//

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

//===------------------------------------------------------===//
// SCR Dialect
//===------------------------------------------------------===//

def SCR_Dialect : Dialect {
  let name = "scr";
  let summary = "SCR Semantic Hypergraph Dialect";
  let description = [{
    MLIR representation of the closed SCR semantic algebra.
  }];
}

//===------------------------------------------------------===//
// Dialect Types (opaque — parsed/printed manually)
//===------------------------------------------------------===//
// Types are registered in C++ via Dialect::initialize().
// Mnemonics: entity_id, value, entity, role_binding,
//            hyperedge, hypergraph, context

//===------------------------------------------------------===//
// Hypergraph Operations
//===------------------------------------------------------===//

def SCR_AddNodeOp : Op<SCR_Dialect, "add_node", [Pure]> {
  let summary = "Add a semantic entity to the hypergraph.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$entity);
  let results = (outs AnyType:$result);
}

def SCR_RemoveNodeOp : Op<SCR_Dialect, "remove_node", [Pure]> {
  let summary = "Remove a semantic entity.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$entity_id);
  let results = (outs AnyType:$result);
}

def SCR_AddEdgeOp : Op<SCR_Dialect, "add_edge", [Pure]> {
  let summary = "Add a typed semantic hyperedge.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$edge);
  let results = (outs AnyType:$result);
}

def SCR_RemoveEdgeOp : Op<SCR_Dialect, "remove_edge", [Pure]> {
  let summary = "Remove a hyperedge by id.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$edge_id);
  let results = (outs AnyType:$result);
}

def SCR_UpdateNodeValueOp : Op<SCR_Dialect, "update_node_value", [Pure]> {
  let summary = "Update entity value. Identity preserved.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$entity_id, AnyType:$new_value);
  let results = (outs AnyType:$result);
}

//===------------------------------------------------------===//
// Composition
//===------------------------------------------------------===//

def SCR_NoOpOp : Op<SCR_Dialect, "no_op", [Pure]> {
  let summary = "Identity transformation. Advances time.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$context);
  let results = (outs AnyType:$result_graph, AnyType:$result_context);
}

def SCR_AtomicTxOp : Op<SCR_Dialect, "atomic_tx", [Pure]> {
  let summary = "Transactional composition with rollback.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$context);
  let results = (outs AnyType:$result_graph, AnyType:$result_context);
  let regions = (region AnyRegion:$body);
}

//===------------------------------------------------------===//
// Observation
//===------------------------------------------------------===//

def SCR_ObserveNodeOp : Op<SCR_Dialect, "observe_node", [Pure]> {
  let summary = "Pure observation - read entity value.";
  let arguments = (ins AnyType:$hypergraph, AnyType:$entity_id);
  let results = (outs AnyType:$result);
}

//===------------------------------------------------------===//
// Constructors
//===------------------------------------------------------===//

def SCR_EmptyOp : Op<SCR_Dialect, "empty", [Pure]> {
  let summary = "Create empty hypergraph.";
  let arguments = (ins);
  let results = (outs AnyType:$result);
}

def SCR_MakeContextOp : Op<SCR_Dialect, "make_context", [Pure]> {
  let summary = "Create transition context.";
  let arguments = (ins AnyType:$logical_step, AnyType:$label);
  let results = (outs AnyType:$result);
}

def SCR_MakeEntityOp : Op<SCR_Dialect, "make_entity", [Pure]> {
  let summary = "Construct semantic entity.";
  let arguments = (ins
    AnyType:$id, AnyType:$type_name,
    AnyType:$value, AnyType:$props);
  let results = (outs AnyType:$result);
}

def SCR_MakeEntityIdOp : Op<SCR_Dialect, "make_entity_id", [Pure]> {
  let summary = "Construct entity identity from string.";
  let arguments = (ins AnyType:$value);
  let results = (outs AnyType:$result);
}

def SCR_ValueUnitOp : Op<SCR_Dialect, "value_unit", [Pure]> {
  let summary = "Construct unit value.";
  let arguments = (ins);
  let results = (outs AnyType:$result);
}

def SCR_ValueBoolOp : Op<SCR_Dialect, "value_bool", [Pure]> {
  let summary = "Construct boolean value.";
  let arguments = (ins AnyType:$value);
  let results = (outs AnyType:$result);
}

def SCR_ValueIntOp : Op<SCR_Dialect, "value_int", [Pure]> {
  let summary = "Construct integer value.";
  let arguments = (ins AnyType:$value);
  let results = (outs AnyType:$result);
}

def SCR_ValueRealOp : Op<SCR_Dialect, "value_real", [Pure]> {
  let summary = "Construct real value.";
  let arguments = (ins AnyType:$value);
  let results = (outs AnyType:$result);
}

def SCR_ValueTextOp : Op<SCR_Dialect, "value_text", [Pure]> {
  let summary = "Construct text value.";
  let arguments = (ins AnyType:$value);
  let results = (outs AnyType:$result);
}

def SCR_MakeHyperedgeOp : Op<SCR_Dialect, "make_hyperedge", [Pure]> {
  let summary = "Construct typed hyperedge with roles.";
  let arguments = (ins
    AnyType:$id, AnyType:$edge_type,
    AnyType:$roles, AnyType:$props);
  let results = (outs AnyType:$result);
}

def SCR_MakeRoleBindingOp : Op<SCR_Dialect, "make_role_binding", [Pure]> {
  let summary = "Construct named role binding.";
  let arguments = (ins AnyType:$role, AnyType:$target);
  let results = (outs AnyType:$result);
}
