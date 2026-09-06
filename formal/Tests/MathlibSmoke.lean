import Mathlib

namespace SCR.Tests

/--
Basic theorem proving that the SCR formal layer can consume Mathlib.
-/
example : (1 : Nat) + 1 = 2 := by
  norm_num

/--
Basic algebraic theorem.
-/
example {α : Type} [AddMonoid α] (x : α) : 0 + x = x := by
  exact zero_add x

end SCR.Tests
