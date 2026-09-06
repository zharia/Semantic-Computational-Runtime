import SCR.Basic
import SCR.Relationship

namespace SCR

structure State where
  entities : List Entity
  relationships : List Relationship
deriving Repr

def EntityIdsUnique (s : State) : Prop :=
  (s.entities.map Entity.id).Nodup

def RelationshipsWellFormed (s : State) : Prop :=
  ∀ r ∈ s.relationships,
    r.source ∈ s.entities.map Entity.id ∧
    r.target ∈ s.entities.map Entity.id

def ValidState (s : State) : Prop :=
  EntityIdsUnique s ∧ RelationshipsWellFormed s

end SCR
