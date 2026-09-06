import SCR.Invariants

namespace SCR

structure ContextId where
  value : String
deriving DecidableEq, Repr

structure Context where
  id : ContextId
  name : String
deriving Repr

structure SemanticField where
  state : State
  contexts : List Context
  transformations : List Transformation
deriving Repr

def FieldValid (f : SemanticField) : Prop :=
  ValidState f.state

end SCR
