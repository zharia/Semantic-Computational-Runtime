//===- SCRTypes.td - SCR Type Definitions -*- tablegen -*-===//
//
// Type definitions for the SCR dialect.
// Derived from: SCRFormal/SCR/Basic.lean, SCRFormal/SCR/Hypergraph.lean
//
//===------------------------------------------------------===//

include "SCRDialect.td"

//===------------------------------------------------------===//
// EntityId
//===------------------------------------------------------===//

def SCR_EntityIdType : DialectType<
    SCR_Dialect, "entity_id",
    /*isStruct=*/true,
    /*isMutable=*/false> {
  let description = [{
    Opaque semantic identity. Structurally compared by string value.
    Not a pointer — two entity IDs with the same string are identical.
  }];
}

//===------------------------------------------------------===//
// Value (Variant Sum)
//===------------------------------------------------------===//

def SCR_ValueType : DialectType<
    SCR_Dialect, "value",
    /*isStruct=*/true,
    /*isMutable=*/false> {
  let description = [{
    Semantic value — variant sum type with exactly one active constructor.

    Variants:
      unit     — no payload
      bool     — i1
      int      — i64 (arbitrary-precision in semantics)
      real     — f64
      text     — string
      sequence — array of !scr.value (recursive)
  }];

  let parameters = [{
    /// Which variant is active.
    enum Variant { Unit, Bool, Int, Real, Text, Sequence };

    /// The active variant.
    Variant variant;

    /// Payload (type depends on variant).
    /// Unit: none; Bool: IntegerAttr<i1>; Int: IntegerAttr<i64>;
    /// Real: FloatAttr<f64>; Text: StringAttr; Sequence: ArrayAttr<!scr.value>.
    Attribute payload;
  }];

  let methods = [{
    /// Get the active variant.
    Variant getVariant() const { return variant; }

    /// Check if unit.
    bool isUnit() const { return variant == Variant::Unit; }

    /// Check if bool.
    bool isBool() const { return variant == Variant::Bool; }

    /// Check if int.
    bool isInt() const { return variant == Variant::Int; }

    /// Check if real.
    bool isReal() const { return variant == Variant::Real; }

    /// Check if text.
    bool isText() const { return variant == Variant::Text; }

    /// Check if sequence.
    bool isSequence() const { return variant == Variant::Sequence; }
  }];
}

//===------------------------------------------------------===//
// Entity
//===------------------------------------------------------===//

def SCR_EntityType : DialectType<
    SCR_Dialect, "entity",
    /*isStruct=*/true,
    /*isMutable=*/false> {
  let description = [{
    Semantic entity with persistent identity.

    Fields:
      id         — !scr.entity_id (persistent identity)
      typeName   — String (semantic type name)
      value      — !scr.value (typed payload)
      properties — !scr.dictionary (key→value metadata)
  }];

  let parameters = [{
    /// Persistent identity.
    Type id;

    /// Semantic type name.
    StringAttr typeName;

    /// Typed payload.
    Type value;

    /// Key-value properties.
    Attribute properties;
  }];
}

//===------------------------------------------------------===//
// RoleBinding
//===------------------------------------------------------===//

def SCR_RoleBindingType : DialectType<
    SCR_Dialect, "role_binding",
    /*isStruct=*/true,
    /*isMutable=*/false> {
  let description = [{
    Named role binding — a role name pointing to an entity identity.
  }];

  let parameters = [{
    /// Role name (e.g., "source", "target", "owner").
    StringAttr role;

    /// Target entity identity.
    Type target;
  }];
}

//===------------------------------------------------------===//
// Hyperedge
//===------------------------------------------------------===//

def SCR_HyperedgeType : DialectType<
    SCR_Dialect, "hyperedge",
    /*isStruct=*/true,
    /*isMutable=*/false> {
  let description = [{
    Typed semantic hyperedge with named roles.

    Fields:
      id         — String (unique edge identifier)
      edgeType   — String (semantic type name)
      roles      — ArrayAttr<!scr.role_binding> (named role bindings)
      properties — !scr.dictionary (key→value metadata)
  }];

  let parameters = [{
    /// Unique edge identifier.
    StringAttr id;

    /// Semantic type name.
    StringAttr edgeType;

    /// Named role bindings.
    Type roles;

    /// Key-value properties.
    Attribute properties;
  }];
}

//===------------------------------------------------------===//
// Hypergraph (Core State)
//===------------------------------------------------------===//

def SCR_HypergraphType : DialectType<
    SCR_Dialect, "hypergraph",
    /*isStruct=*/true,
    /*isMutable=*/false> {
  let description = [{
    Authoritative semantic state. The primary data type flowing through
    SCR operations.

    Fields:
      nodes       — ArrayAttr<!scr.entity> (semantic entities)
      edges       — ArrayAttr<!scr.hyperedge> (semantic relationships)
      logicalStep — Index (discrete logical time counter)

    Invariant: IncidenceWellFormed
      Every hyperedge's role targets must reference entities in nodes.
  }];

  let parameters = [{
    /// Semantic entities.
    Type nodes;

    /// Semantic relationships.
    Type edges;

    /// Discrete logical time counter.
    IndexType logicalStep;
  }];
}

//===------------------------------------------------------===//
// Context
//===------------------------------------------------------===//

def SCR_ContextType : DialectType<
    SCR_Dialect, "context",
    /*isStruct=*/true,
    /*isMutable=*/false> {
  let description = [{
    Ambient transition metadata. Not modified by failed operations.

    Fields:
      logicalStep — Index (discrete logical time counter)
      label       — String (human-readable transition label)
  }];

  let parameters = [{
    /// Discrete logical time counter.
    IndexType logicalStep;

    /// Human-readable label for this transition.
    StringAttr label;
  }];
}

//===------------------------------------------------------===//
// Dictionary
//===------------------------------------------------------===//

def SCR_DictionaryAttr : DialectAttr<
    SCR_Dialect, "dictionary",
    /*isStruct=*/true> {
  let description = [{
    String→Value dictionary for entity and hyperedge properties.
    Modeled as ArrayAttr of key-value pairs.
  }];

  let parameters = [{
    /// Array of key-value pairs.
    Attribute entries;
  }];
}
