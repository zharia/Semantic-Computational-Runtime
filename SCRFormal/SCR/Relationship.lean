import SCR.Basic

namespace SCR

inductive RelationKind where
  | typed (name : String)
deriving DecidableEq, Repr

structure Relationship where
  source : EntityId
  target : EntityId
  kind : RelationKind
  properties : List (String × Value)
deriving Repr

end SCR
