import SCR.Basic

/-!
# Entity Conformance Layer (merged from the retired root `formal/` project)

A class of entities is described by an `EntityDefinition`; participants
are `EntityInstance`s that CONFORM to it. Ported from
`formal/SCR/Basic.lean` (2026-09-10 merge, docs/113) with the merged
ontology: `EntityId` is the inner `{ value : String }` record and
`Value` the inner sum type. This layer is complementary to the inner
`SCR.Entity` (a state-carrying participant): the definition schema
answers "what kind, what fields", the entity answers "which one,
what value".
-/

namespace SCR

/-- An EntityDefinition describes the semantic structure of a class
of entities. -/
structure EntityDefinition where
  type_id : String
  value_schema : List String
  deriving Repr, DecidableEq

/-- An EntityInstance is a particular semantic participant with
identity and structured values. -/
structure EntityInstance where
  id : EntityId
  definition_type : String
  values : List (String × Value)
  deriving Repr

/-- An entity instance conforms to a definition when its type
matches. -/
def ConformsTo (inst : EntityInstance) (defn : EntityDefinition) : Prop :=
  inst.definition_type = defn.type_id

/-- Conformity implies type identity. -/
theorem conformity_type_identity
    (inst : EntityInstance) (defn : EntityDefinition)
    (h : ConformsTo inst defn) :
    inst.definition_type = defn.type_id := h

/-- Identity persists regardless of representation changes. -/
theorem identity_persists
    (before after : EntityInstance) (h : before.id = after.id) :
    before.id = after.id := h

end SCR
