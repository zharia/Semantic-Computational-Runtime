import Mathlib

namespace SCR

structure EntityId where
  value : String
deriving DecidableEq, Repr

inductive Value where
  | unit
  | bool : Bool → Value
  | int : Int → Value
  | real : Float → Value
  | text : String → Value
  | sequence : List Value → Value
deriving Repr

structure Entity where
  id : EntityId
  typeName : String
  value : Value
  properties : List (String × Value)
deriving Repr

end SCR
