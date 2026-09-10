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

/-! ## Exit-criterion 10 (docs/107 §27): conformance relation -/

/--
  DEFINITION (spec §13, §20): `ρ` realizes machine `out` from
  implementation outcomes `OI` when every implementation outcome
  transports to an equivalent machine outcome.
-/
structure Realization {S C T K O OI : Type u}
    [outI : OutcomeOf S C T K OI] [out : OutcomeOf S C T K O]
    [Equiv C O] (ρ : OI → O) : Prop where
  preserves :
    ∀ (τ : T) (s : S) (c : C) (κ : K) (o : OI),
      outI.outcomeOf τ s c κ o →
      ∃ (o' : O), out.outcomeOf τ s c κ o' ∧
        Equiv.equiv c (ρ o) o'

/-! The `tryEvolve` oracle shape used by the Reference Executor and
the root formal model (Milestone 005): apply, check constraint,
succeed-or-fail. Mirrored locally because the root v4.34 project
cannot be imported into v4.19 — this is a SHAPE correspondence
witness, not a cross-project proof. -/
namespace Oracle

abbrev State := Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | add (n : Int)
abbrev Bound := Int
/-- Semantic outcomes (the machine). -/
abbrev Outcome := Int
/-- Executor-shaped outcomes (the implementation). -/
inductive Res where
  | ok (v : Int)
  | fail

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance oCon : Consents State Ctx Op Bound :=
  ⟨fun κ τ s _ => match τ with
    | Op.add n => s + n ≥ κ⟩

/-- The semantic machine: outcome iff admissible, with the value. -/
instance oM : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun τ s _ κ o => match τ with
    | Op.add n => s + n ≥ κ ∧ o = s + n⟩

instance : OutcomeAdmissible State Ctx Op Bound Outcome := ⟨by
  intro τ s _ κ o h
  cases τ with
  | add n =>
    have h' : s + n ≥ κ ∧ o = s + n := h
    exact ⟨trivial, h'.1⟩⟩

/-- The implementation shape: tryEvolve (the RE pattern). -/
def tryEvolve : Bound → Op → State → Res
  | κ, Op.add n, s => if s + n ≥ κ then .ok (s + n) else .fail

/-- The implementation outcome machine. NOT an instance: `OutcomeOf`
keys on (S,C,T,K) and the semantic machine `oM` already occupies it —
the implementation is passed explicitly wherever needed. (FACT: this
is what the outParam design enforces — one semantic machine per
kernel tuple.) -/
def oI : OutcomeOf State Ctx Op Bound Res :=
  ⟨fun τ s _ κ o => ∃ v, tryEvolve κ τ s = .ok v ∧ o = .ok v⟩

/-- The reading map from executor results to semantic values. -/
def ρ : Res → Outcome
  | .ok v => v
  | .fail => 0

instance : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩

/-- FACT: the oracle's successes are exactly the machine outcomes and
its failures are exactly the rejections. -/
theorem oracle_agrees_with_semantics :
    (∀ (n : Int) (s : State) (κ : Bound) (v : Int),
        oM.outcomeOf (Op.add n) s ctx κ v →
        ∃ o, oI.outcomeOf (Op.add n) s ctx κ o) ∧
    (∀ (n : Int) (s : State) (κ : Bound),
        rejected (Op.add n) s ctx κ →
        ¬ ∃ o, oI.outcomeOf (Op.add n) s ctx κ o) := by
  constructor
  · intro n s κ v h
    have hv : s + n ≥ κ ∧ v = s + n := h
    refine ⟨.ok v, ⟨v, ?_, rfl⟩⟩
    simp only [tryEvolve]
    rw [if_pos hv.1, hv.2]
  · intro n s κ hr
    rintro ⟨o, ⟨v, ht, ho⟩⟩
    apply hr
    refine ⟨trivial, ?_⟩
    by_cases hge : s + n ≥ κ
    · exact hge
    · rw [tryEvolve, if_neg hge] at ht
      exact absurd ht (by simp [Res])

/-- FACT: every executor success transports to an equivalent machine
outcome (the field statement, proven directly). -/
theorem realization_field :
    ∀ (τ : Op) (s : State) (c : Ctx) (κ : Bound) (o : Res),
      oI.outcomeOf τ s c κ o →
      ∃ o' : Outcome, oM.outcomeOf τ s c κ o' ∧ ρ o = o' := by
  intro τ s c κ o h
  cases τ with
  | add n =>
  obtain ⟨v, ht, rfl⟩ := h
  by_cases hge : s + n ≥ κ
  · refine ⟨v, ⟨hge, ?_⟩, rfl⟩
    rw [tryEvolve, if_pos hge] at ht
    injection ht with hv
    exact hv.symm
  · exfalso
    rw [tryEvolve, if_neg hge] at ht
    exact absurd ht (by simp [Res])

/-- FACT (docs/107 §27 criterion 10): the executor-shaped machine is
a formal `Realization` of the semantic machine — RE-style witnesses
are conforming realizations: evidence, not authority. -/
theorem tryEvolve_is_realization :
    @Realization State Ctx Op Bound Outcome Res oI oM
      (by infer_instance : Equiv Ctx Outcome) ρ :=
  @Realization.mk State Ctx Op Bound Outcome Res oI oM
    (by infer_instance : Equiv Ctx Outcome) ρ realization_field

end Oracle

end SCR.STC.Laws
