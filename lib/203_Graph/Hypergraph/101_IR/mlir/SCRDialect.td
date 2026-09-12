//===- SCRDialect.td - SCR Dialect Definition -*- tablegen -*-===//
//
// Dialect definition for the Semantic Computational Runtime.
// Derived from: SCRFormal/SCR/Algebra.lean (closed semantic algebra)
//
//===------------------------------------------------------===//

#ifndef SCR_DIALECT
#define SCR_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/IR/SideEffectInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/VerifiedConstantInterface.td"

//===------------------------------------------------------===//
// SCR Dialect
//===------------------------------------------------------===//

def SCR_Dialect : Dialect {
  let name = "scr";
  let summary = "SCR Semantic Hypergraph Dialect";
  let description = [{
    MLIR representation of the closed SCR semantic algebra.
    Operations transform authoritative semantic hypergraph state.
    All operations verify algebraic invariants (incidence well-formedness,
    time monotonicity, rollback, identity preservation).
  }];
  let useFoldAPI = kMustFold;

  let useFoldAPI = kAllocLikeFold;

  let version = "0.1.0";

  let extraClassDeclaration = [{
    /// Get the SCR dialect namespace.
    static mlir::StringRef getDialectNamespace() { return "scr"; }
  }];
}

//===------------------------------------------------------===//
// Types
//===------------------------------------------------------===//

/// Semantic identity — string-compared, opaque.
def SCR_EntityIdType : DialectType<SCR_Dialect, "entity_id",
    "Semantic identity type. Opaque, string-compared.">;

/// Variant sum type: unit | bool | int | real | text | sequence.
def SCR_ValueType : DialectType<SCR_Dialect, "value",
    "Semantic value — variant sum with exactly one active constructor.">;

/// Semantic entity — persistent identity + typed payload.
def SCR_EntityType : DialectType<SCR_Dialect, "entity",
    "Semantic entity with persistent identity.">;

/// Named role pointing to an entity.
def SCR_RoleBindingType : DialectType<SCR_Dialect, "role_binding",
    "Named role binding (role name → entity identity).">;

/// Typed semantic relationship.
def SCR_HyperedgeType : DialectType<SCR_Dialect, "hyperedge",
    "Typed semantic hyperedge with named roles.">;

/// Authoritative semantic state — nodes + edges + logical step.
def SCR_HypergraphType : DialectType<SCR_Dialect, "hypergraph",
    "Authoritative semantic state (hypergraph). Primary data type.">;

/// Ambient transition metadata.
def SCR_ContextType : DialectType<SCR_Dialect, "context",
    "Ambient transition context (logical step, label).">;

//===------------------------------------------------------===//
// Attributes
//===------------------------------------------------------===//

/// Dictionary attribute for entity/hyperedge properties.
def SCR_DictionaryAttr : DialectAttr<SCR_Dialect, "dictionary",
    "String→Value dictionary for properties.">;

#endif // SCR_DIALECT
