import SCR.STC

/-!
# STC-001 Abstract Laws

Theorems that hold for ANY well-formed machine, from explicit
hypotheses only (spec §32). Where an "obvious" law cannot be proven
from the published kernel, the failure is recorded as an OPEN
question with the exact missing structure — not hidden behind a
purpose-built assumption class that conjoins the conclusion.
Classification per spec §34.
-/

namespace SCR.STC.Laws

open SCR.STC

variable {S C T K O : Type u}

/-- PROVEN: outcome-less transitions are vacuously deterministic.
SEMANTIC WARNING: `deterministic` cannot certify existence; partiality
must be a separate taxonomy predicate (`partialTransition`) —
confirming docs/106 §10 needs the outcome SET, not a functional
behaviour reading (spec §10 Partiality). -/
theorem deterministic_of_empty [OutcomeOf S C T K O] [Equiv C O]
    (δ : Transition S C T K) (h : ∀ o : O, ¬ outcomes δ o) :
    deterministic δ :=
  fun _ _ h₁ => absurd h₁ (h _)

/-- PROVEN (spec §11): rejection annihilates composition. -/
theorem rejected_compose_none [Applicable S C T] [Consents S C T K]
    [OutcomeOf S C T K O] [ResultState S C T K O]
    [hM : OutcomeAdmissible S C T K O]
    (τ₁ : T) (s : S) (c : C) (κ : K) (τ₂ : T) (o₂ : O)
    (h : rejected τ₁ s c κ) :
    ¬ composeOutcome (instantiate τ₁ s c κ) τ₂ c κ o₂ := by
  rintro ⟨o₁, s₂, ho, _, _⟩
  exact rejected_no_outcome τ₁ s c κ h o₁ ho

/-- PROVEN (spec §14, existence form): a successful step followed by
a successful continuation composes. -/
theorem compose_exists [OutcomeOf S C T K O] [ResultState S C T K O]
    (δ₁ : Transition S C T K) (τ₂ : T) (c : C) (κ : K)
    (o₁ : O) (s₂ : S) (o₂ : O)
    (h₁ : outcomes δ₁ o₁)
    (hr : ResultState.result δ₁.1 δ₁.2.1 δ₁.2.2.1 δ₁.2.2.2 o₁ s₂)
    (h₂ : OutcomeOf.outcomeOf τ₂ s₂ c κ o₂) :
    composeOutcome δ₁ τ₂ c κ o₂ :=
  ⟨o₁, s₂, h₁, hr, h₂⟩

/-- PROVEN (docs/106 §12): nondeterministic transitions are
distinguishable — nondeterminism is not definitional noise. -/
theorem nondet_witness_distinguish [OutcomeOf S C T K O]
    [Equiv C O]
    (δ : Transition S C T K) (h : nondeterministic δ) :
    ∃ o₁ o₂ : O, outcomes δ o₁ ∧ outcomes δ o₂ ∧
      ¬ Equiv.equiv δ.2.2.1 o₁ o₂ := h

/-- PROVEN: with a subsingleton outcome domain (all outcomes
semantically equal), a nonempty outcome set is a singleton. Honest
degenerate corollary connecting `outcomes` with quotienting. -/
theorem singleton_outcomes_of_subsingleton [OutcomeOf S C T K O]
    [Subsingleton O] (δ : Transition S C T K)
    (h : ∃ o : O, outcomes δ o) :
    ∃ o : O, outcomes δ o ∧ ∀ o' : O, outcomes δ o' → o = o' := by
  obtain ⟨o, ho⟩ := h
  exact ⟨o, ho, fun o' _ => Subsingleton.elim o o'⟩

/-! ## OPEN O-2 / GAP G4 — what could NOT be proven, and why

ATTEMPT (recorded honestly, spec §25/§32): composition preserves
determinism:

```text
deterministic δ₁ ∧ (∀ reachable s₂, τ₂ deterministic at s₂)
  ⇒ any two composite outcomes are ≡
```

STATUS: UNPROVABLE from the published kernel.

EXACT MISSING STRUCTURE (analysis):
1. The kernel carries ≡ only on OUTCOMES. docs/106 §16 lists
   state/transition/implementation equivalence too — the kernel tuple
   under-specifies the DOMAIN of ≡. Composition must transport
   continuations across equivalent intermediate outcomes: this needs
   ≡ on STATES plus congruence laws (applicable, consents, outcomeOf,
   result are ≡-respecting).
2. None of those congruences is derivable from ⟨S,C,T,K,O,≡⟩; they
   are genuine semantic conditions of well-formed machines
   (docs/107 §9 "composition must preserve context; constraints;
   provenance; identity obligations" names exactly this family).

DECISION: do NOT add a `CongruentComposition` class whose field is
the theorem — that is conclusion-laundering (spec §32). The
congruence/setoid package is the subject of STC-002 per the
trajectory (spec §43).

FACT (supporting evidence for the gap being real, not notational):
the failed attempt requires writing `Equiv.equiv c s₂ s₂'` for
STATES — a proposition that does not typecheck in the kernel at all.
Type-level absence IS the gap. -/

end SCR.STC.Laws
