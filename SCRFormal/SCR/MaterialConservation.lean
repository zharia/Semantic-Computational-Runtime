-- SCR Material Conservation Formal Specification
namespace SCR.Material

/-- Discrete material constitutive state with integer mass units (e.g. grams or milligrams) -/
structure MaterialState where
  name : String
  densityKgM3 : Nat
  volumeMilli : Nat
  temperatureK : Nat
deriving Repr, DecidableEq

def MaterialState.massGrams (m : MaterialState) : Nat :=
  m.densityKgM3 * m.volumeMilli

/-- Semantic Transition Calculus reaction definition -/
structure Reaction where
  name : String
  reactants : List MaterialState
  products : List MaterialState

def totalMass (ms : List MaterialState) : Nat :=
  ms.foldl (fun acc m => acc + m.massGrams) 0

def ConservesMass (r : Reaction) : Prop :=
  totalMass r.reactants = totalMass r.products

/-- Single reactant mass equivalence theorem -/
theorem single_reactant_mass (m : MaterialState) :
    totalMass [m] = m.massGrams := by
  simp [totalMass]

/-- Binary phase transition conservation law -/
theorem binary_phase_conservation (r : Reaction) (m1 m2 : MaterialState)
    (h_react : r.reactants = [m1])
    (h_prod : r.products = [m2])
    (h_eq : m1.massGrams = m2.massGrams) :
    ConservesMass r := by
  simp [ConservesMass, totalMass, h_react, h_prod, h_eq]

/-- General multi-phase conservation theorem -/
theorem reaction_conservation_congruence (r : Reaction)
    (h : totalMass r.reactants = totalMass r.products) :
    ConservesMass r := h

end SCR.Material
