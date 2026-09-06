import SCR.State

namespace SCR

def StateEquivalent (a b : State) : Prop :=
  a = b

def Equivalent (a b : State) : Prop :=
  StateEquivalent a b

theorem equivalent_refl (a : State) : Equivalent a a :=
  rfl

theorem equivalent_symm {a b : State} (h : Equivalent a b) :
    Equivalent b a :=
  h.symm

theorem equivalent_trans {a b c : State}
    (hab : Equivalent a b)
    (hbc : Equivalent b c) :
    Equivalent a c :=
  hab.trans hbc

end SCR
