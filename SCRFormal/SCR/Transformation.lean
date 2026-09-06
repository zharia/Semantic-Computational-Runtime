import SCR.State

namespace SCR

structure OperationId where
  value : String
deriving DecidableEq, Repr

structure TransformationId where
  value : String
deriving DecidableEq, Repr

structure Operation where
  id : OperationId
  name : String
deriving Repr

structure Transformation where
  id : TransformationId
  operation : OperationId
  target : EntityId
  argument : Option Value
deriving Repr

def Transition := State → Transformation → Option State

def ValidTransition
    (s s' : State)
    (_t : Transformation)
    (_step : Transition s _t = some s') : Prop :=
  ValidState s ∧ ValidState s'

end SCR
