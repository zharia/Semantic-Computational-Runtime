import SCR.Field

namespace SCR

/--
The formal Seed kernel is deliberately small. Broader Seed vocabulary is
mapped into this kernel or into domain-specific formal modules as those
semantics become stable enough to formalize.
-/
structure SeedConcept where
  id : String
  label : String
  definition : String
deriving Repr

def seedConcepts : List SeedConcept :=
  [ { id := "scr:entity", label := "Entity",
      definition := "A semantically identifiable participant in the Semantic Field." }
  , { id := "scr:identity", label := "Identity",
      definition := "The semantic property by which an entity remains identifiable." }
  , { id := "scr:state", label := "State",
      definition := "A semantically meaningful configuration of a field or entity." }
  , { id := "scr:transformation", label := "Transformation",
      definition := "A semantic mapping that changes or derives semantic structure." }
  ]

end SCR
