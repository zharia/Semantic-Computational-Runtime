





































/-!
# Semantic Transition Calculus — Kernel (STC-001)

Formalization of the Semantic Transition Calculus over the EXISTING SCR
ontology. No parallel state/transition/equivalence ontology is created
(spec §4, §9, §21).

Reuse map (full table in `crosswalk.md`):
- concrete machines instantiate `S := SCR.State`-based state domains,
  `C := SCR.Context`, `T := SCR.Transformation`-like domains;
- the kernel ⟨S, C, T, K, O, ≡⟩ of docs/106 §3 is treated as a
  HYPOTHESIS (spec §3) and formalized by the kernel classes below
  (`Applicable`, `Consents`, `OutcomeOf`, `Equiv`, `EquivSetoid`,
  `IsFailure`), with derived judgements layered on top.

Outcome semantics are set-valued (`M(δ) ⊆ O`, docs/106 §10) — this is
deliberately relational, not a partial function; the insufficiency of
the functional alias `SCR.Transition` for nondeterminism is proven in
`STCCounterexamples.lean` (CX-NDet).

Classification discipline (spec §34): every nontrivial statement is
labelled DEFINITION / DERIVED / ASSUMPTION / GAP.

## Kernel falsification findings (summary)

- GAP G1 (ResultState): composition (docs/107 §9) is not expressible
  from ⟨S,C,T,K,O,≡⟩ alone — outcomes carry no state. Counterexample
  CX-RESULT.
- GAP G2 (independence): semantic independence (docs/106 §12) is not a
  function of outcome data. Counterexample CX-IND (two machines,
  identical outcome data, opposite commutation). The published kernel
  is therefore NOT sufficient for concurrency; a footprint structure
  is the minimal refinement.
- Observation of outcomes is DERIVED from ≡ (probe form); no new
  primitive is required. (Resolves spec §12 primitivity question for
  the outcome level.)
- `Admissible ⇒ Applicable` (docs/106 §8) becomes a theorem by
  definition of `admissible`, with both conjuncts independently
  falsifiable (STCExamples) — the distinction is real, the implication
  is structural.
-/

namespace SCR.STC
universe u v
/-! ## Kernel domains and judgements -/
/-- DEFINITION (docs/107 §3). `applicable τ s c` — τ is meaningful for
s in c. Structural domain condition; not capability, not consent. -/
class Applicable (S C T : Type u) where
  applicable : T → S → C → Prop
/-- DEFINITION (docs/106 §8). `consents κ τ s c` — the constraint
environment κ permits τ at s under c.
ASSUMPTION (spec §8): kept separate from `applicable` because the two
are independently falsifiable (STCExamples: applicable-but-refused,
and domain-mismatch cases). -/
class Consents (S C T K : Type u) where
  consents : K → T → S → C → Prop
/-- DEFINITION (docs/106 §10). The outcome relation `o ∈ M(δ)` for the
instantiation δ = (τ, s, c, κ). Set-valued by design. -/
class OutcomeOf (S C T K : Type u) (O : outParam (Type u)) where
  outcomeOf : T → S → C → K → O → Prop
/-- DEFINITION (docs/106 §16). Context-indexed semantic equivalence on
outcomes. REFINES `SCR.Equivalence` (bare equality): see CX-EQV. -/
class Equiv (C : Type u) (O : outParam (Type u)) where
  equiv : C → O → O → Prop
/-- ASSUMPTION (kernel): ≡ is a setoid per context. Bundled as a
structure taking the relation explicitly (avoids TC-stuck parent
projections; the laws are the assumption a machine must witness). -/
structure EquivLaws (C : Type u) (O : outParam (Type u)) (e : Equiv C O) where
  refl  : ∀ (c : C) (o : O), e.equiv c o o
  symm  : ∀ (c : C) {o₁ o₂}, e.equiv c o₁ o₂ → e.equiv c o₂ o₁
  trans : ∀ (c : C) {o₁ o₂ o₃},
    e.equiv c o₁ o₂ → e.equiv c o₂ o₃ → e.equiv c o₁ o₃
/-- DEFINITION (docs/106 §11.2). `isFailure o` — a semantic failure
OUTCOME (admissible transition, defined failure). Contrasted with
rejection, which yields no outcome at all. Realization/physical
failure (docs/106 §11.3–4) are inexpressible in the kernel BY DESIGN
(spec §19, §26): the classes live in provider/EGS layers. -/
class IsFailure (O : Type u) where
  isFailure : O → Prop
/-! ## Derived notions -/
variable {S C T K O : Type u} {P : Type u}
/-- DERIVED (docs/106 §9, spec §9). A semantic transition is an
instantiation tuple — derived, not a new primitive. No `STCTransition`
ontology is introduced; this is just the kernel's own product. -/
abbrev Transition (S C T K : Type u) : Type u := T × S × C × K
/-- DERIVED: instantiation judgement (docs/107 §5) as a function. -/
def instantiate (τ : T) (s : S) (c : C) (κ : K) :
    Transition S C T K :=
  (τ, s, c, κ)
/-- DERIVED (docs/107 §4). Admissible = applicable ∧ consented.
The published implication `Admissible ⇒ Applicable` (docs/106 §8) is
THEOREM `admissible_imp_applicable` below: a structural consequence of
the definition, whose semantic content lies in the independence of the
conjuncts (demonstrated by machine examples). -/
def admissible [Applicable S C T] [Consents S C T K]
    (τ : T) (s : S) (c : C) (κ : K) : Prop :=
  Applicable.applicable τ s c ∧ Consents.consents κ τ s c
/-- PROVEN: the SMM implication. -/
theorem admissible_imp_applicable [Applicable S C T]
    [Consents S C T K]
    (τ : T) (s : S) (c : C) (κ : K)
    (h : admissible τ s c κ) :
    Applicable.applicable τ s c := h.1
/-- DERIVED (docs/106 §11.1). Semantic rejection = not admissible.
Rejection instantiates no transition with outcomes; see
`rejected_no_outcome`. -/
def rejected [Applicable S C T] [Consents S C T K]
    (τ : T) (s : S) (c : C) (κ : K) : Prop :=
  ¬ admissible τ s c κ
/-- ASSUMPTION (machine well-formedness, docs/107 §3–§5): outcomes
exist only for admissible instantiations. Without it, rejection and
admissible-but-partial collapse and the §11 taxonomy is
inexpressible. Proven for each concrete machine; it is a law machines
must satisfy, not a consequence of the tuple. -/
class OutcomeAdmissible (S C T K O : Type u)
    [ap : Applicable S C T] [co : Consents S C T K]
    [out : OutcomeOf S C T K O] where
  outcome_only_admissible :
    ∀ (τ : T) (s : S) (c : C) (κ : K) (o : O),
      out.outcomeOf τ s c κ o → admissible τ s c κ
/-- DERIVED: rejection admits no outcome. PROVEN from the class law. -/
theorem rejected_no_outcome [Applicable S C T] [Consents S C T K]
    [OutcomeOf S C T K O] [hM : OutcomeAdmissible S C T K O]
    (τ : T) (s : S) (c : C) (κ : K)
    (h : rejected τ s c κ) (o : O) :
    ¬ OutcomeOf.outcomeOf τ s c κ o :=
  fun ho => h (hM.outcome_only_admissible τ s c κ o ho)
/-- DERIVED: the outcome set M(δ). -/
def outcomes [OutcomeOf S C T K O]
    (δ : Transition S C T K) (o : O) : Prop :=
  let (τ, s, c, κ) := δ
  OutcomeOf.outcomeOf τ s c κ o
/-- DERIVED (docs/106 §10): deterministic — all outcomes equivalent in
the transition's own context. -/
def deterministic [OutcomeOf S C T K O] [Equiv C O]
    (δ : Transition S C T K) : Prop :=
  ∀ (o₁ o₂ : O), outcomes δ o₁ → outcomes δ o₂ →
    Equiv.equiv δ.2.2.1 o₁ o₂
/-- DERIVED (docs/107 §6): nondeterministic — two context-distinct
outcomes. `|M(δ)| > 1` in the equivalence quotient. -/
def nondeterministic [OutcomeOf S C T K O] [Equiv C O]
    (δ : Transition S C T K) : Prop :=
  ∃ (o₁ o₂ : O), outcomes δ o₁ ∧ outcomes δ o₂ ∧
    ¬ Equiv.equiv δ.2.2.1 o₁ o₂
/-- PROVEN: nondeterministic defeats determinism. -/
theorem nondeterministic_not_deterministic [OutcomeOf S C T K O]
    [Equiv C O] (δ : Transition S C T K)
    (h : nondeterministic δ) : ¬ deterministic δ := by
  intro hd
  obtain ⟨o₁, o₂, h₁, h₂, hn⟩ := h
  refine hn ?_
  exact hd o₁ o₂ h₁ h₂
/-- DERIVED (spec §10, Partiality): a transition is partial when it is
admissible yet instantiates no outcome. Distinguished from rejection
(no admissibility) and from failure (an outcome exists). -/
def partialTransition [Applicable S C T] [Consents S C T K]
    [OutcomeOf S C T K O] (δ : Transition S C T K) : Prop :=
  let (τ, s, c, κ) := δ
  admissible τ s c κ ∧ ¬ ∃ (o : O), outcomes δ o
/-- PROVEN: a rejected transition is not partial — the two taxonomy
classes are disjoint on the admissibility axis (spec §11). -/
theorem rejected_not_partial [Applicable S C T] [Consents S C T K]
    [OutcomeOf S C T K O] (τ : T) (s : S) (c : C) (κ : K)
    (h : rejected τ s c κ) :
    ¬ partialTransition (instantiate τ s c κ) := by
  intro hp
  exact h hp.1
/-! ## GAP G1 — composition needs outcome-to-state structure -/
/-- GAP G1 (spec §14). Sequential composition of transitions is not
expressible from ⟨S,C,T,K,O,≡⟩ alone: an outcome carries no state for
the next transformation's applicability. Counterexample: CX-RESULT.
Minimal refinement: a relational result extractor. Kept multi-valued:
several implementation result states may realize one semantic outcome
(docs/106 §10 "multiple permitted realizations"). -/
class ResultState (S C T K : Type u) (O : outParam (Type u)) where
  result : T → S → C → K → O → S → Prop
/-- DEFINITION (docs/107 §9). Sequential composition over transitions
plus their second transformation: the composite outcome o₂ exists iff
some o₁ ∈ M(δ₁) result-states into s₂ with o₂ ∈ M(τ₂, s₂, c, κ). -/
def composeOutcome [OutcomeOf S C T K O] [ResultState S C T K O]
    (δ₁ : Transition S C T K) (τ₂ : T) (c : C) (κ : K)
    (o₂ : O) : Prop :=
  let (τ₁, s₁, c₁, κ₁) := δ₁
  ∃ (o₁ : O) (s₂ : S),
    outcomes δ₁ o₁ ∧ ResultState.result τ₁ s₁ c₁ κ₁ o₁ s₂ ∧
    OutcomeOf.outcomeOf τ₂ s₂ c κ o₂
/-! ## GAP G2 — observation (resolved: derived) -/

/--
  DERIVED (spec §12, resolves GAP G2): states are semantically
  distinguished when SOME probe transition produces at s an outcome
  that NO outcome of the same instantiation at s' is equivalent to.
  Observation needs no new kernel primitive — it is read through the
  outcome relation and ≡. (Whether observation is "semantic state"
  itself: no — it is a relation between states and outcomes.)
-/
def probeDistinction [out : OutcomeOf S C T K O] [eq : Equiv C O]
    (s s' : S) : Prop :=
  ∃ (τ : T) (c : C) (κ : K) (o : O),
    out.outcomeOf τ s c κ o ∧
    ¬ ∃ (o' : O), out.outcomeOf τ s' c κ o' ∧ eq.equiv c o o'

/-! ## GAP G3 — independence needs footprint structure -/
/-- GAP G3 (spec §15). `δ₁ ⊥ δ₂` cannot be a function of outcome data:
CX-IND exhibits two machines with identical outcome relations where
the same transitions commute in one and conflict in the other.
Minimal refinement: a footprint domain P (`touches`/`Footprint`) plus
an overlap relation on P (`Overlap`). The commutation property is then
a machine soundness law
(`FootprintsSound`), proven per concrete machine — NOT assumed
vacuously: CX-IND shows no kernel-only definition can replace it. -/
class Footprint (T : Type u) (P : outParam (Type u)) where
  touches : T → P → Prop
/-- Overlap on footprint domains: when two footprint points share
semantic state. -/
class Overlap (P : Type u) where
  overlaps : P → P → Prop
/-- DERIVED: independence = no pair of touched footprints overlaps. -/
def independent [Footprint T P] [Overlap P] (τ₁ τ₂ : T) : Prop :=
  ∀ (p₁ p₂ : P), Footprint.touches τ₁ p₁ →
    Footprint.touches τ₂ p₂ → ¬ Overlap.overlaps p₁ p₂
/-- ASSUMPTION (machine soundness, spec §15, docs/106 §12):
independence, when it holds, must support reordering of the realized
outcome sequences. Stated structurally here; discharged per machine
(see `commutes_pair` in STCExamples.lean). Full generality requires a
composed-outcome equivalence — deferred to STC-002 and recorded as
OPEN O-1, not hidden in a trivially-satisfied schema. -/
class FootprintsSound (S C T K O P : Type u)
    [out : OutcomeOf S C T K O] [res : ResultState S C T K O]
    [fp : Footprint T P] [ov : Overlap P] where
  commute_of_independent :
    ∀ (τ₁ τ₂ : T) (s : S) (c : C) (κ : K) (o₁ : O) (s₁ : S),
      out.outcomeOf τ₁ s c κ o₁ →
      res.result τ₁ s c κ o₁ s₁ →
      independent τ₁ τ₂ →
      ∃ (o₂ : O) (s₂ : S),
        out.outcomeOf τ₂ s c κ o₂ ∧
        res.result τ₂ s c κ o₂ s₂ ∧
        ∃ (o₁' : O), out.outcomeOf τ₁ s₂ c κ o₁'
end SCR.STC