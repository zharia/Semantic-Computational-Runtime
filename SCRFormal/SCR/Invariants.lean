import SCR.Transformation

namespace SCR

def Deterministic (step : Transition) : Prop :=
  ∀ s t s₁ s₂,
    step s t = some s₁ →
    step s t = some s₂ →
    s₁ = s₂

theorem deterministic_unique
    {step : Transition}
    (h : Deterministic step)
    {s t s₁ s₂}
    (h₁ : step s t = some s₁)
    (h₂ : step s t = some s₂) :
    s₁ = s₂ :=
  h s t s₁ s₂ h₁ h₂

inductive InvariantId where
  | semanticFieldPrimacy
  | semanticPrimacy
  | identityPersistence
  | representationIndependence
  | contractPreservation
  | constraintPreservation
  | contextPreservation
  | providerNonAuthority
  | abstractionClosure
  | observationalEquivalence
deriving DecidableEq, Repr

end SCR
