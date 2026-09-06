/-
  Semantic Computational Runtime
  Formal Semantic Substrate

  This module is intentionally small.

  The formal SCR hierarchy grows outward from the Semantic Field.
  Concrete semantic structures should be introduced only when they
  are justified by the canonical SCR semantic model.
-/

import Mathlib

namespace SCR

/--
The formal namespace of the Semantic Computational Runtime.

This namespace is deliberately independent of the executable SCR
implementation.
-/
def version : String := "0.1.0"

end SCR
