import SCR.Basic

namespace SCR

def SameIdentity (a b : Entity) : Prop :=
  a.id = b.id

structure Representation where
  entity : EntityId
  encoding : String
deriving Repr

def RepresentationChangePreservesIdentity
    (before after : Representation) : Prop :=
  before.entity = after.entity

theorem representation_change_preserves_identity
    {before after : Representation}
    (h : RepresentationChangePreservesIdentity before after) :
    before.entity = after.entity :=
  h

end SCR
