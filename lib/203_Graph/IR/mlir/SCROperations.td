//===- SCROperations.td - SCR Operation Definitions -*- tablegen -*-===//
//
// Operation definitions for the SCR dialect.
// Each operation maps 1:1 to a HyperOp constructor or algebra concept.
// Derived from: SCRFormal/SCR/Algebra.lean
//
//===------------------------------------------------------===//

include "SCRDialect.td"
include "SCRTypes.td"

//===------------------------------------------------------===//
// Common Traits
//===------------------------------------------------------===//

/// All SCR hypergraph mutation operations implement this trait.
def SCR_MutatesHypergraph : NativeOpTrait<"MutatesHypergraph"> {
  let description = [{
    Operation reads and writes !scr.hypergraph state.
    Used for side-effect analysis and scheduling.
  }];
}

/// Operations that advance logical time.
def SCR_AdvancesTime : NativeOpTrait<"AdvancesTime"> {
  let description = [{
    On success, logicalStep is incremented by at least 1.
    On failure, logicalStep is unchanged.
  }];
}

/// Operations that preserve identity on value updates.
def SCR_PreservesIdentity : NativeOpTrait<"PreservesIdentity"> {
  let description = [{
    Entity identity (!scr.entity_id) is not modified by this operation.
    Formal: node_identity_invariant
  }];
}

//===------------------------------------------------------===//
// Hypergraph Operations (ALG-011 → HyperOp)
//===------------------------------------------------------===//

/// Add entity to hypergraph. (ALG-011: addNode)
def SCR_AddNodeOp : SCR_Op<"add_node", [
    SCR_MutatesHypergraph,
    SCR_AdvancesTime,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>,
    AllTypesMatchAt<["result"], ["hypergraph"]>,
    SameOperandsAndResultType
  ]> {
  let summary = "Add a semantic entity to the hypergraph.";
  let description = [{
    Adds an entity to the hypergraph. Fails if entity id already exists.
    On failure, returns the original hypergraph unchanged (rollback).

    Preconditions:
      - entity.id ∉ hypergraph.nodes.id

    Postconditions (success):
      - entity.id ∈ result.nodes.id
      - result.nodes = hypergraph.nodes ++ [entity]
      - result.edges = hypergraph.edges
      - result.logicalStep = hypergraph.logicalStep + 1

    Formal: step (.graphOp (.addNode e)) s c = .ok s' c'
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    SCR_EntityType:$entity
  );

  let results = (outs
    AnyType:$result
  );

  let assemblyFormat = [{
    `(` $hypergraph `,` $entity `)` attr-dict `:` type($hypergraph) `,` type($entity) `->` type($result)
  }];

  let hasVerifier = 1;
}

/// Remove entity from hypergraph. (ALG-011: removeNode)
def SCR_RemoveNodeOp : SCR_Op<"remove_node", [
    SCR_MutatesHypergraph,
    SCR_AdvancesTime,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Remove a semantic entity from the hypergraph.";
  let description = [{
    Removes an entity from the hypergraph. Fails if the entity has
    active incident hyperedges (checkNodeFreeOfEdges).
    On failure, returns the original hypergraph unchanged.

    Preconditions:
      - entity_id ∈ hypergraph.nodes.id
      - no hyperedge in hypergraph.edges has a role targeting entity_id

    Counterexample: CX_03_incident_node_removal_rejected
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    SCR_EntityIdType:$entity_id
  );

  let results = (outs
    AnyType:$result
  );

  let assemblyFormat = [{
    `(` $hypergraph `,` $entity_id `)` attr-dict `:` type($hypergraph) `,` type($entity_id) `->` type($result)
  }];

  let hasVerifier = 1;
}

/// Add hyperedge to hypergraph. (ALG-011: addEdge)
def SCR_AddEdgeOp : SCR_Op<"add_edge", [
    SCR_MutatesHypergraph,
    SCR_AdvancesTime,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Add a typed semantic hyperedge to the hypergraph.";
  let description = [{
    Adds a hyperedge to the hypergraph. Fails if edge id already exists
    or if any role target references a nonexistent entity.

    Preconditions:
      - edge.id ∉ hypergraph.edges.id
      - ∀ role ∈ edge.roles: role.target ∈ hypergraph.nodes.id

    Counterexample: CX_02_dangling_edge_rejected
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    SCR_HyperedgeType:$edge
  );

  let results = (outs
    AnyType:$result
  );

  let assemblyFormat = [{
    `(` $hypergraph `,` $edge `)` attr-dict `:` type($hypergraph) `,` type($edge) `->` type($result)
  }];

  let hasVerifier = 1;
}

/// Remove hyperedge from hypergraph. (ALG-011: removeEdge)
def SCR_RemoveEdgeOp : SCR_Op<"remove_edge", [
    SCR_MutatesHypergraph,
    SCR_AdvancesTime,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Remove a hyperedge from the hypergraph.";
  let description = [{
    Removes a hyperedge by id. Entities are preserved.
    Preconditions:
      - edge_id ∈ hypergraph.edges.id
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    StringAttr:$edge_id
  );

  let results = (outs
    AnyType:$result
  );

  let assemblyFormat = [{
    `(` $hypergraph `,` $edge_id `)` attr-dict `:` type($hypergraph) `,` type($edge_id) `->` type($result)
  }];

  let hasVerifier = 1;
}

/// Update entity value. (ALG-011: updateNodeValue)
def SCR_UpdateNodeValueOp : SCR_Op<"update_node_value", [
    SCR_MutatesHypergraph,
    SCR_AdvancesTime,
    SCR_PreservesIdentity,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Update the value of a semantic entity.";
  let description = [{
    Updates entity value. Identity is preserved (node_identity_invariant).
    Preconditions:
      - entity_id ∈ hypergraph.nodes.id

    Postconditions:
      - result.nodes[entity_id].value = new_value
      - result.nodes[entity_id].id = entity_id (identity preserved)

    Formal: { n with value := v }.id = n.id
    Counterexample: CX_04_conflicting_writes_do_not_commute
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    SCR_EntityIdType:$entity_id,
    SCR_ValueType:$new_value
  );

  let results = (outs
    AnyType:$result
  );

  let assemblyFormat = [{
    `(` $hypergraph `,` $entity_id `,` $new_value `)` attr-dict
    `:` type($hypergraph) `,` type($entity_id) `,` type($new_value) `->` type($result)
  }];

  let hasVerifier = 1;
}

//===------------------------------------------------------===//
// Composition Operations (ALG-020, ALG-021)
//===------------------------------------------------------===//

/// Identity transformation. (ALG-021: noOp)
def SCR_NoOpOp : SCR_Op<"no_op", [
    SCR_MutatesHypergraph,
    SCR_AdvancesTime,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Identity transformation — returns input unchanged, advances time.";
  let description = [{
    The semantic identity element. Returns the hypergraph and context
    unchanged except logicalStep is incremented by 1.

    Formal: step .noOp s c = .ok s { c with logical_step := c.logical_step + 1 }
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    SCR_ContextType:$context
  );

  let results = (outs
    AnyType:$result_graph,
    SCR_ContextType:$result_context
  );

  let assemblyFormat = [{
    `(` $hypergraph `,` $context `)` attr-dict
    `:` type($hypergraph) `,` type($context) `->` type($result_graph) `,` type($result_context)
  }];
}

/// Transactional atomic composition. (ALG-020: atomicTx)
def SCR_AtomicTxOp : SCR_Op<"atomic_tx", [
    SCR_MutatesHypergraph,
    SCR_AdvancesTime,
    SingleBlockImplicitOp<"region">,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Transactionally compose transformations with rollback on failure.";
  let description = [{
    Executes the body region sequentially. On any failure within the
    region, the entire transaction rolls back to the pre-tx state.

    Formal: step (.atomicTx t1 t2) s c
      If step t1 s c = .ok s1 c1 → step t2 s1 c1
      Else .fail s c reason

    Theorems:
      - step_rollback_on_failure: failure preserves state and context
      - step_advances_time: success advances logicalStep
      - step_preserves_time_on_failure: failure preserves logicalStep
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    SCR_ContextType:$context
  );

  let results = (outs
    AnyType:$result_graph,
    SCR_ContextType:$result_context
  );

  let regions = (res AnyRegion:$region);

  let assemblyFormat = [{
    `(` $hypergraph `,` $context `)` attr-dict
    `:` type($hypergraph) `,` type($context) `->` type($result_graph) `,` type($result_context)
    $region
  }];

  let hasVerifier = 1;
}

//===------------------------------------------------------===//
// Observation (ALG-015)
//===------------------------------------------------------===//

/// Pure state query — read entity value. (ALG-015: observeNode)
def SCR_ObserveNodeOp : SCR_Op<"observe_node", [
    Pure,
    SameOperandsAndResultType,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Pure observation — read entity value from hypergraph.";
  let description = [{
    Reads entity value without side effects. No time advancement.
    Formal: observeNode s id
    Theorem: observation_purity (referentially transparent)
  }];

  let arguments = (ins
    AnyType:$hypergraph,
    SCR_EntityIdType:$entity_id
  );

  let results = (outs
    SCR_ValueType:$result
  );

  let assemblyFormat = [{
    `(` $hypergraph `,` $entity_id `)` attr-dict
    `:` type($hypergraph) `,` type($entity_id) `->` type($result)
  }];

  let hasVerifier = 1;
}

//===------------------------------------------------------===//
// State Construction
//===------------------------------------------------------===//

/// Create empty hypergraph.
def SCR_EmptyOp : SCR_Op<"empty", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Create an empty hypergraph (no nodes, no edges, step 0).";
  let description = [{
    Returns the initial empty semantic state.
  }];

  let arguments = (ins);

  let results = (outs
    SCR_HypergraphType:$result
  );

  let assemblyFormat = [{
    attr-dict `->` type($result)
  }];
}

/// Create context.
def SCR_MakeContextOp : SCR_Op<"context", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Create a transition context with logical step and label.";
  let description = [{
    Constructs a !scr.context from a step number and label.
  }];

  let arguments = (ins
    IndexAttr:$logical_step,
    StringAttr:$label
  );

  let results = (outs
    SCR_ContextType:$result
  );

  let assemblyFormat = [{
    $logical_step `,` $label attr-dict `->` type($result)
  }];
}

/// Create entity.
def SCR_MakeEntityOp : SCR_Op<"make_entity", [
    Pure,
    SCR_PreservesIdentity,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Construct a semantic entity from components.";
  let description = [{
    Assembles an entity from identity, type name, value, and properties.
  }];

  let arguments = (ins
    SCR_EntityIdType:$id,
    StringAttr:$type_name,
    SCR_ValueType:$value,
    SCR_DictionaryAttr:$properties
  );

  let results = (outs
    SCR_EntityType:$result
  );

  let assemblyFormat = [{
    `(` $id `,` $type_name `,` $value `,` $properties `)` attr-dict
    `:` type($id) `,` type($type_name) `,` type($value) `,` type($properties) `->` type($result)
  }];
}

/// Create entity id.
def SCR_MakeEntityIdOp : SCR_Op<"entity_id", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Construct a semantic entity identity from a string.";
  let description = [{
    Wraps a string as an opaque !scr.entity_id.
  }];

  let arguments = (ins
    StringAttr:$value
  );

  let results = (outs
    SCR_EntityIdType:$result
  );

  let assemblyFormat = [{
    $value attr-dict `->` type($result)
  }];
}

/// Create value variants.
def SCR_ValueUnitOp : SCR_Op<"value.unit", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Create a unit value.";
  let arguments = (ins);
  let results = (outs SCR_ValueType:$result);
  let assemblyFormat = [{{ attr-dict `->` type($result) }}];
}

def SCR_ValueBoolOp : SCR_Op<"value.bool", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Create a boolean value.";
  let arguments = (ins DefaultValuedParameter<i1, "false">:$value);
  let results = (outs SCR_ValueType:$result);
  let assemblyFormat = [{{ $value attr-dict `->` type($result) }}];
}

def SCR_ValueIntOp : SCR_Op<"value.int", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Create an integer value.";
  let arguments = (ins DefaultValuedParameter<i64, "0">:$value);
  let results = (outs SCR_ValueType:$result);
  let assemblyFormat = [{{ $value attr-dict `->` type($result) }}];
}

def SCR_ValueRealOp : SCR_Op<"value.real", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Create a real (float) value.";
  let arguments = (ins DefaultValuedParameter<f64, "0.0">:$value);
  let results = (outs SCR_ValueType:$result);
  let assemblyFormat = [{{ $value attr-dict `->` type($result) }}];
}

def SCR_ValueTextOp : SCR_Op<"value.text", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Create a text (string) value.";
  let arguments = (ins DefaultValuedParameter<StringAttr, "">:$value);
  let results = (outs SCR_ValueType:$result);
  let assemblyFormat = [{{ $value attr-dict `->` type($result) }}];
}

/// Create hyperedge.
def SCR_MakeHyperedgeOp : SCR_Op<"make_hyperedge", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Construct a typed hyperedge with roles.";
  let description = [{
    Assembles a hyperedge from id, type, roles, and properties.
  }];

  let arguments = (ins
    StringAttr:$id,
    StringAttr:$edge_type,
    ArrayAttr:$roles,
    SCR_DictionaryAttr:$properties
  );

  let results = (outs
    SCR_HyperedgeType:$result
  ];

  let assemblyFormat = [{
    `(` $id `,` $edge_type `,` $roles `,` $properties `)` attr-dict
    `:` type($id) `,` type($edge_type) `,` type($roles) `,` type($properties) `->` type($result)
  }];
}

/// Create role binding.
def SCR_MakeRoleBindingOp : SCR_Op<"make_role", [
    Pure,
    DeclareOpInterfaceMethods<MemoryEffectOpInterface, ["getEffects"]>
  ]> {
  let summary = "Construct a named role binding.";
  let arguments = (ins
    StringAttr:$role,
    SCR_EntityIdType:$target
  );
  let results = (outs SCR_RoleBindingType:$result);
  let assemblyFormat = [{
    `(` $role `,` $target `)` attr-dict `:` type($role) `,` type($target) `->` type($result)
  }];
}

#endif // SCR_OPERATIONS
