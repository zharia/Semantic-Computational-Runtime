import SCR.Identity
import SCR.State
import SCR.STC
import SCR.Basic

/-!
# STC-001 Concrete Machines

Executable witnesses for the kernel (`STC.lean`). Each machine is a
SEMANTIC machine only — no scheduler, storage, provider, or VM notion
(spec §26, §41). Every `OutcomeAdmissible` law is PROVEN from the
machine's own outcome definition (discharged, not assumed).

Machines: Counter (applicability vs consent, composition),
Div (semantic failure AS outcome), Choice (nondeterminism),
Loop (partiality), Pair (footprint independence + commutation).
-/

namespace SCR.STC.Examples

open SCR.STC

/-! ## Machine 1: Counter — Int states, lower-bound constraint envs -/

namespace Counter

abbrev State := Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | inc (n : Int)
  | dec (n : Int)
  | dbl
abbrev Bound := Int
abbrev Outcome := Int

def cval : Op → State → Int
  | .inc n, s => s + n
  | .dec n, s => s - n
  | .dbl,   s => 2 * s

/-- DEFINITION: applicability — `dbl` meaningful only on even states
(structural domain); `inc`/`dec` everywhere. -/
instance cApp : Applicable State Ctx Op where
  applicable τ s _ := match τ with
    | .dbl => ∃ k : Int, s = 2 * k
    | _    => True

/-- DEFINITION: consent — result respects the bound. -/
instance cCon : Consents State Ctx Op Bound where
  consents κ τ s _ := cval τ s ≥ κ

/-- DEFINITION: outcome exists exactly when admissible, with the
computed value — well-formedness law holds BY CONSTRUCTION. -/
instance ctrOut : OutcomeOf State Ctx Op Bound Outcome where
  outcomeOf τ s _ κ o :=
    Applicable.applicable τ s ctx ∧ cval τ s ≥ κ ∧ o = cval τ s

instance : OutcomeAdmissible State Ctx Op Bound Outcome where
  outcome_only_admissible _ _ _ _ _ h := ⟨h.1, h.2.1⟩

def cEquiv : Equiv Ctx Outcome :=
  { equiv := fun _ o₁ o₂ => o₁ = o₂ }

/-- Witness: value equality is a lawful equivalence. -/
theorem equiv_laws : EquivLaws Ctx Outcome cEquiv :=
  { refl := fun _ _ => rfl
    symm := fun _ _ _ h => Eq.symm h
    trans := fun _ _ _ _ h₁ h₂ => Eq.trans h₁ h₂ }

instance : Equiv Ctx Outcome := cEquiv

/-- DEFINITION: outcome realizes itself as state. -/
instance cRes : ResultState State Ctx Op Bound Outcome where
  result _ _ _ _ o s' := s' = o

instance : IsFailure Outcome where
  isFailure _ := False

/-- FACT (spec §7–§8): `dec 10` at 5, bound 0: applicable but NOT
admissible — constraint rejection, distinct from domain refusal. -/
theorem applicable_not_admissible :
    Applicable.applicable (Op.dec 10) (5 : State) ctx ∧
    ¬ admissible (Op.dec 10) (5 : State) ctx (0 : Bound) := by
  constructor
  · exact trivial
  · rintro ⟨_, h⟩
    simp only [admissible, cApp, cCon, cval] at h
    omega

/-- FACT (spec §7 Q1): `dbl` at odd 3 is not even APPLICABLE. -/
theorem dbl_not_applicable :
    ¬ Applicable.applicable (Op.dbl) (3 : State) ctx := by
  intro h
  have h2 : ∃ k : Int, (3 : Int) = 2 * k := h
  rcases h2 with ⟨k, hk⟩
  omega

/-- FACT (spec §11 row 1): rejection → NO outcome. -/
theorem rejected_has_no_outcome :
    ∀ o : Outcome,
      ¬ outcomes (instantiate (Op.dec 10) (5 : State) ctx (0 : Bound)) o := by
  intro o h
  simp [outcomes, instantiate, cApp, cCon, ctrOut, cval] at h

/-- FACT: admissible successful runs are deterministic. -/
theorem inc_deterministic :
    deterministic (instantiate (Op.inc 3) (4 : State) ctx (0 : Bound)) := by
  intro o₁ o₂ h₁ h₂
  exact h₁.2.2.trans h₂.2.2.symm

/-- FACT (spec §14): inc 3 from 4 gives 7 (admissible), but the
continuation `dbl` is REFUSED at odd 7: no composite outcome 14.
Applicability of the continuation is a genuine semantic condition of
composition (docs/107 §9), not an execution artifact. -/
theorem compose_refused_odd_middle :
    ¬ composeOutcome (instantiate (Op.inc 3) (4 : State) ctx (0 : Bound))
        Op.dbl ctx (0 : Bound) 14 := by
  rintro ⟨o₁, s₂, h₁, h₂, h₃⟩
  have h₁' : o₁ = cval (Op.inc 3) 4 := h₁.2.2
  have h₁'' : o₁ = (7 : Int) := by simpa [cval] using h₁'
  have h₂' : s₂ = o₁ := h₂
  rcases h₃ with ⟨happ₃, _, _⟩
  have h₃' : ∃ k : Int, s₂ = 2 * k := happ₃
  rcases h₃' with ⟨k, hk⟩
  have hchain : (7 : Int) = 2 * k := by
    calc (7 : Int) = o₁ := h₁''.symm
      _ = s₂ := h₂'.symm
      _ = 2 * k := hk
  omega

/-- FACT: the SAME two transitions from 5 compose (even middle 8):
inc 3 → 8, dbl → 16. -/
theorem compose_success :
    composeOutcome (instantiate (Op.inc 3) (5 : State) ctx (0 : Bound))
        Op.dbl ctx (0 : Bound) 16 :=
  ⟨8, 8, ⟨trivial, by simp [cval], rfl⟩, rfl,
    ⟨⟨4, rfl⟩, by simp [cval], rfl⟩⟩

end Counter

/-! ## Machine 2: Div — semantic failure IS an outcome (row 2) -/

namespace Div

abbrev State := Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | divBy (d : Int)
abbrev Bound := Int
inductive Outcome where
  | ok  (n : Int)
  | fail

/-- Division is meaningful everywhere (unlike Counter.dbl): the zero
case is SEMANTIC FAILURE, not rejection. -/
instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩

instance dOut : OutcomeOf State Ctx Op Bound Outcome where
  outcomeOf := fun τ _ _ _ o => match τ with
    | .divBy d => o = if d = 0 then .fail else .ok 0

instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩

instance : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance : ResultState State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ o s' => o = .ok s'⟩

instance dIsF : IsFailure Outcome where
  isFailure := fun o => match o with
    | .fail => True
    | .ok _ => False

/-- FACT (spec §10–§11): div-by-zero is admissible, HAS an outcome,
and it is a semantic failure. Contrasted with
`rejected_has_no_outcome` (row 1). -/
theorem div_zero_is_semantic_failure :
    admissible (Op.divBy 0) (6 : State) ctx (0 : Bound) ∧
    outcomes (instantiate (Op.divBy 0) (6 : State) ctx (0 : Bound))
      Outcome.fail ∧
    IsFailure.isFailure (Outcome.fail : Outcome) :=
  ⟨⟨trivial, trivial⟩, by simp [outcomes, instantiate, dOut], trivial⟩

/-- FACT: a successful division is NOT a failure. -/
theorem div_ok_not_failure :
    outcomes (instantiate (Op.divBy 2) (6 : State) ctx (0 : Bound))
      (Outcome.ok 0) ∧
    ¬ IsFailure.isFailure (Outcome.ok 0 : Outcome) :=
  ⟨by simp [outcomes, instantiate, dOut], by simp [dIsF]⟩

end Div

/-! ## Machine 3: Choice — nondeterministic outcomes -/

namespace Choice

abbrev State := Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | toss
abbrev Bound := Int
abbrev Outcome := Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩
instance cOut : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ o => o = (0 : Outcome) ∨ o = 1⟩
instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance choiceEq : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩

/-- FACT (docs/106 §10): |M(δ)| > 1 — relational M REQUIRED (CX-NDet
refutes functional models). -/
theorem toss_nondeterministic :
    nondeterministic (instantiate Op.toss (0 : State) ctx (0 : Bound)) :=
  ⟨0, 1, by simp [outcomes, instantiate, cOut],
    by simp [outcomes, instantiate, cOut], by simp [choiceEq]⟩

end Choice

/-! ## Machine 4: Loop — partiality (admissible, outcome-less) -/

namespace Loop

abbrev State := Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | run
abbrev Bound := Int
abbrev Outcome := Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩
instance : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ => False⟩
instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ h => absurd h False.elim⟩

/-- FACT (spec §10 Partiality): admissible yet NO outcome. No new
primitive needed — a definitional consequence of the kernel. -/
theorem run_partial :
    partialTransition (instantiate Op.run (0 : State) ctx (0 : Bound)) :=
  ⟨⟨trivial, trivial⟩, fun ⟨_, h⟩ => absurd h False.elim⟩

end Loop

/-! ## Machine 5: Pair — footprint independence + commutation -/

namespace Pair

abbrev State := Int × Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | incL | incR
abbrev Bound := Int
abbrev Outcome := Int × Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩
instance out : OutcomeOf State Ctx Op Bound Outcome where
  outcomeOf := fun τ st _ _ o => match τ, st with
    | .incL, (a, b) => o = (a + 1, b)
    | .incR, (a, b) => o = (a, b + 1)
instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance res : ResultState State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ o s' => s' = o⟩

/-- Footprint cells: 0 = left, 1 = right. -/
abbrev Cell := Int

instance fp : Footprint Op Cell where
  touches := fun τ p => match τ with
    | .incL => p = 0
    | .incR => p = 1

/-- Cells overlap only with themselves. -/
instance ov : Overlap Cell where
  overlaps := fun p q => p = q

/-- FACT (spec §15): incrementing different cells is semantically
independent. -/
theorem independent_witness :
    @independent Op Cell fp ov Op.incL Op.incR := by
  intro p q h₁ h₂ hov
  simp only [fp] at h₁ h₂
  subst h₁; subst h₂
  exact (by decide : ¬ ((0 : Cell) = 1)) hov

/-- FACT: independent transitions commute — both orders from (a,b)
reach one common composite outcome. This machine DISCHARGES the
`FootprintsSound`-style commutation law for its own footprint. -/
theorem pair_commutes (a b : Int) :
    ∃ o : Outcome,
      composeOutcome (instantiate Op.incL (a, b) ctx (0 : Bound))
        Op.incR ctx (0 : Bound) o ∧
      composeOutcome (instantiate Op.incR (a, b) ctx (0 : Bound))
        Op.incL ctx (0 : Bound) o :=
  ⟨(a + 1, b + 1),
    ⟨(a + 1, b), (a + 1, b), rfl, rfl, rfl⟩,
    ⟨(a, b + 1), (a, b + 1), rfl, rfl, rfl⟩⟩

end Pair

/-! ## Machine 6: Prov — provider indexed by context; realization
failure observable as PARTIALITY, never rejection
(docs/106 §11.3, spec §11; docs/107 §19: Valid ⇏ Realizable) -/

namespace Prov

abbrev State := Int
/-- Provider identity elevated into the field as semantic context data
(legal per spec §19). -/
inductive Ctx where
  | up | down
inductive Op where
  | put (n : Int)
abbrev Bound := Int
abbrev Outcome := Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
/-- Semantic admissibility is INDEPENDENT of provider availability —
the firewall: an unavailable provider must not make a transformation
semantically invalid. -/
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩

/-- Availability gates the OUTCOME, not admissibility. -/
instance pvOut : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun τ _ c _ o =>
    (match τ with | .put n => o = n) ∧
    (match c with | .up => True | .down => False)⟩

instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance pvEq : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩

/-- FACT (docs/107 §27 criterion 4): realization failure manifests as
`partialTransition` — admissible, no outcome — formally disjoint from
rejection (`¬ admissible`). The classes cannot be conflated here. -/
theorem realization_down_is_partial_not_rejected :
    partialTransition
      (instantiate (Op.put 5) (0 : State) Ctx.down (0 : Bound)) ∧
    ¬ rejected (Op.put 5) (0 : State) Ctx.down (0 : Bound) := by
  constructor
  · refine ⟨⟨trivial, trivial⟩, ?_⟩
    rintro ⟨o, h⟩
    exact h.2
  · intro hr
    exact hr ⟨trivial, trivial⟩

/-- FACT (spec §13 provider substitution): where BOTH providers are
available they produce equal — hence equivalent — outcomes; replacing
one by the other preserves semantic meaning. -/
theorem provider_substitution :
    ∀ (c₁ c₂ : Ctx) (o₁ o₂ : Outcome),
      outcomes (instantiate (Op.put 5) (0 : State) c₁ (0 : Bound)) o₁ →
      outcomes (instantiate (Op.put 5) (0 : State) c₂ (0 : Bound)) o₂ →
      Equiv.equiv c₁ o₁ o₂ := by
  intro c₁ c₂ o₁ o₂ h₁ h₂
  exact h₁.1.trans h₂.1.symm

end Prov

/-! ## Machine 7: IFO — causal dependence WITH order-sensitive
composition (companion to `Pair`; docs/107 §27 criterion 7) -/

namespace IFO

abbrev State := Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | dbl | inc
abbrev Bound := Int
abbrev Outcome := Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩
instance ifOut : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun τ s _ _ o => match τ with
    | .dbl => o = 2 * s
    | .inc => o = s + 1⟩
instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance ifRes : ResultState State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ o s' => s' = o⟩

/-- Single shared cell: both write it. -/
abbrev Cell := Int
instance ifFp : Footprint Op Cell where
  touches := fun _ p => p = 0
instance ifOv : Overlap Cell := ⟨fun p q => p = q⟩

/-- FACT: causally dependent (overlapping footprints) AND order-
sensitive (8 ≠ 7). The constrained counterpart of `Pair`: temporal
order here IS causally load-bearing. -/
theorem ifo_causal_and_order_sensitive :
    causallyDependent (T := Op) (P := Cell) Op.dbl Op.inc ∧
    ¬ ∃ o : Outcome,
      composeOutcome (instantiate Op.inc (3 : State) ctx (0 : Bound))
        Op.dbl ctx (0 : Bound) o ∧
      composeOutcome (instantiate Op.dbl (3 : State) ctx (0 : Bound))
        Op.inc ctx (0 : Bound) o := by
  constructor
  · intro h
    exact h 0 0 rfl rfl rfl
  · rintro ⟨o, ⟨o₁, s₁, h₁, h₂, h₃⟩, ⟨o₂, s₂, h₄, h₅, h₆⟩⟩
    have h₇ : o = 8 := by
      have e₁ : o₁ = (3 : Int) + 1 := h₁
      have e₂ : s₁ = o₁ := h₂
      have e₃ : o = 2 * s₁ := h₃
      simp only [Outcome, State] at e₁ e₂ e₃ ⊢
      omega
    have h₈ : o = 7 := by
      have e₁ : o₂ = 2 * (3 : Int) := h₄
      have e₂ : s₂ = o₂ := h₅
      have e₃ : o = s₂ + 1 := h₆
      simp only [Outcome, State] at e₁ e₂ e₃ ⊢
      omega
    simp only [Outcome, State] at h₇ h₈ ⊢
    omega

end IFO

/-! ## Machine 8: Switch — context dependence WITHOUT state change
(spec §7 Q4–Q6) -/

namespace Switch

abbrev State := Int
inductive Ctx where
  | left | two | off
  deriving DecidableEq
inductive Op where
  | run
abbrev Bound := Int
abbrev Outcome := Int

/-- Applicability depends on the CONTEXT, not the state (Q4, Q6). -/
instance swApp : Applicable State Ctx Op where
  applicable _ _ c := c = Ctx.left ∨ c = Ctx.two

instance swCon : Consents State Ctx Op Bound :=
  ⟨fun _ _ _ _ => True⟩

/-- Interpretation differs by context: the same state transforms to
DIFFERENT outcomes in the two admissible contexts (Q5); the third
context admits nothing. -/
instance swOut : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun _ s c _ o =>
    (c = Ctx.left ∧ o = 2 * s) ∨ (c = Ctx.two ∧ o = s + 1)⟩

instance : OutcomeAdmissible State Ctx Op Bound Outcome where
  outcome_only_admissible _ _ _ _ _ h := by
    rcases h with ⟨h1, _⟩ | ⟨h1, _⟩
    · exact ⟨Or.inl h1, trivial⟩
    · exact ⟨Or.inr h1, trivial⟩

instance swEq : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩

/-- FACT (Q6): admissible in `left`, REJECTED in `off` — no state
change between the two judgements: applicability is a context
property, not a state property. -/
theorem context_changes_admissibility_no_state_change :
    admissible (Op.run) (4 : State) Ctx.left (0 : Bound) ∧
    rejected (Op.run) (4 : State) Ctx.off (0 : Bound) := by
  constructor
  · exact ⟨Or.inl rfl, trivial⟩
  · rintro ⟨h, _⟩
    rcases h with hh | hh
    · cases hh
    · cases hh

/-- FACT (Q5): same state, same transformation — outcome 8 under
`left`, outcome 5 under `two`: the two contexts interpret the state
DIFFERENTLY, and those outcomes are not equivalent. -/
theorem left_doubles :
    outcomes (instantiate (Op.run) (4 : State) Ctx.left (0 : Bound)) 8 :=
  Or.inl ⟨rfl, by simp⟩

theorem two_increments :
    outcomes (instantiate (Op.run) (4 : State) Ctx.two (0 : Bound)) 5 :=
  Or.inr ⟨rfl, by simp⟩

theorem contexts_disagree :
    ¬ swEq.equiv Ctx.left 8 (5 : Outcome) := by
  simp [swEq]

end Switch

/-! ## Machine 9: Repr — representation substitution preserves
semantics (spec §13) -/

namespace Repr

abbrev State := Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
inductive Op where
  | succ
abbrev Bound := Int
abbrev Outcome := Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩
instance rpOut : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun (.succ) s _ _ o => o = s + 1⟩
instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩

/-- Alternative representation of the SAME semantic values. -/
inductive Tagged where
  | tag (n : Int)

abbrev Outcome2 := Tagged
instance rpOut2 : OutcomeOf State Ctx Op Bound Outcome2 :=
  ⟨fun (.succ) s _ _ o => o = Tagged.tag (s + 1)⟩

/-- The representation bridge. -/
def ρ : Outcome → Outcome2
  | n => Tagged.tag n

/-- FACT (spec §13 representation substitution): every canonical
outcome transports to the tagged machine via ρ — bitwise identity of
representations is NOT required, only transported semantic equality. -/
theorem repr_substitution (s : State) (o : Outcome)
    (h : outcomes (instantiate Op.succ s ctx (0 : Bound)) o) :
    ∃ o2 : Outcome2,
      @OutcomeOf.outcomeOf State Ctx Op Bound Outcome2 rpOut2
        Op.succ s ctx (0 : Bound) o2 ∧
      ρ o = o2 := by
  have h' : o = s + 1 := h
  exact ⟨ρ o, congrArg ρ h', rfl⟩

end Repr

/-! ## Machine 10: Probe — state observation via designated probes
(spec §12; GAP G2 resolution: no new primitive) -/

namespace Probe

abbrev State := Int × Int
inductive Ctx where
  | base
def ctx : Ctx := Ctx.base
/-- The field's only probe: read the first component. -/
inductive Op where
  | fst
abbrev Bound := Int
abbrev Outcome := Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩
instance pbOut : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun _ (a, _) _ _ o => o = a⟩
instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance pbEq : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩

/-- FACT (spec §12): states agreeing on ALL probes are NOT
probe-distinguishable — the field observes no more than its probes;
unobservable differences have no semantic weight. -/
theorem probe_indistinguishable :
    ¬ @probeDistinction State Ctx Op Bound Outcome pbOut pbEq
        (1, 2) (1, 3) := by
  rintro ⟨τ, c, κ, o, h₁, h₂⟩
  cases τ with
  | fst =>
    apply h₂
    exact ⟨o, h₁, rfl⟩

/-- FACT: states differing on a probe ARE distinguished — observation
separates exactly what the field can see. -/
theorem probe_distinguish :
    @probeDistinction State Ctx Op Bound Outcome pbOut pbEq
      (1, 2) (2, 3) :=
  ⟨Op.fst, ctx, (0 : Bound), 1, rfl, by
    rintro ⟨o', h, he⟩
    have h2 : o' = 2 := h
    have h1 : (1 : Int) = o' := he
    simp only [Outcome] at h1 h2 ⊢
    omega⟩

end Probe

/-! ## Machine 11: Persist — persistence / migration / replication as
TRANSFORMATIONS with semantic effects, not subsystems (spec §18;
docs/106 §23) -/

namespace Persist

abbrev State := Int
/-- Locations as semantic context data (the field MODELS location —
legal per spec §19; NOT a machine subsystem). -/
inductive Ctx where
  | hot | cold
def ctx : Ctx := Ctx.hot
inductive Op where
  | persist | restore | replicate
abbrev Bound := Int
abbrev Outcome := Int

instance : Applicable State Ctx Op := ⟨fun _ _ _ => True⟩
instance : Consents State Ctx Op Bound := ⟨fun _ _ _ _ => True⟩

/-- Persistence preserves the value; restore re-yields it;
replication yields a copy — an explicitly EQUIVALENCE-preserving
relation, not a bitwise duplication claim (docs/106 §23). -/
instance psOut : OutcomeOf State Ctx Op Bound Outcome :=
  ⟨fun τ s _ _ o => match τ with
    | .persist   => o = s
    | .restore   => o = s
    | .replicate => o = s⟩
instance : OutcomeAdmissible State Ctx Op Bound Outcome :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance psEq : Equiv Ctx Outcome := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance psRes : ResultState State Ctx Op Bound Outcome :=
  ⟨fun _ s _ _ o s' => o = s ∧ s' = s⟩

/-- FACT: persistence round-trip: Restore(S_t) → S′ with S′ ≡ S_t
(docs/106 §23). -/
theorem persist_roundtrip (s : State) :
    ∀ o₁ o₂ : Outcome,
      outcomes (instantiate Op.persist s ctx (0 : Bound)) o₁ →
      outcomes (instantiate Op.restore s ctx (0 : Bound)) o₂ →
      Equiv.equiv ctx o₁ o₂ := by
  intro o₁ o₂ h₁ h₂
  exact h₁.trans h₂.symm

/-- FACT: migration across (semantic) contexts preserves the required
value: (S, C₁) → (S, C₂) with S ≡ S (docs/106 §23). -/
theorem migration_preserves (s : State) :
    outcomes (instantiate Op.persist s Ctx.hot (0 : Bound)) s →
    outcomes (instantiate Op.restore s Ctx.cold (0 : Bound)) s :=
  fun h => h

/-- FACT: replication yields an outcome equivalent to the source —
the explicit equivalence model, no bitwise assumption. -/
theorem replication_equiv (s : State) :
    outcomes (instantiate Op.replicate s ctx (0 : Bound)) s ∧
    Equiv.equiv ctx s s :=
  ⟨rfl, rfl⟩

end Persist

/-! ## Machine 12: Witness — the canonical multi-entity golden-path
witness (Milestone 005) described ENTIRELY in STC terms over the
COMMITTED ontology (`SCR.State`, `SCR.Entity`, `SCR.Relationship`,
`SCR.SameIdentity`) — docs/107 §27 criterion 11. -/

namespace Witness

open SCR

/-- States are the committed `SCR.State`. Contexts trivial here. -/
abbrev Ctx : Type := Unit
def ctx : Ctx := ()

/-- Transformations: add an integer to the value of a named entity. -/
inductive WOp where
  | add (e : EntityId) (n : Int)

abbrev Bound := Int

/-- Semantic value of an entity. -/
def valueOf (e : Entity) : Option Int :=
  match e.value with
  | .int n => some n
  | _ => none

/-- Field lookup over the entity list. -/
def getValL : List Entity → EntityId → Option Int
  | [], _ => none
  | a :: r, e => if a.id = e then valueOf a else getValL r e

def getVal (s : State) (e : EntityId) : Option Int :=
  getValL s.entities e

/-- Field update, replacing the value of the named entity. -/
def setValL : List Entity → EntityId → Int → List Entity
  | [], _, _ => []
  | a :: r, e, v =>
    (if a.id = e then { a with value := Value.int v } else a)
      :: setValL r e v

def upd (s : State) (e : EntityId) (v : Int) : State :=
  { s with entities := setValL s.entities e v }

/-- The result value of an operation, if its target exists. -/
def resultVal : WOp → State → Option Int
  | .add e n, s => match getVal s e with
    | some v => some (v + n)
    | none => none

/-- DEFINITION (machine): applicability — the target entity exists.
STRUCTURAL, not consent: constraint (the bound) is separate. -/
instance wApp : Applicable State Ctx WOp :=
  ⟨fun τ s _ => ∃ v, resultVal τ s = some v⟩

/-- DEFINITION (machine): consent — the resulting value respects the
bound. -/
instance wCon : Consents State Ctx WOp Bound :=
  ⟨fun κ τ s _ => ∀ v, resultVal τ s = some v → v ≥ κ⟩

/-- DEFINITION (machine): outcome — the full successor state when the
addition is in domain and respects the bound. -/
instance wOut : OutcomeOf State Ctx WOp Bound State where
  outcomeOf τ s _ κ o := match τ with
    | .add e n => ∃ v, resultVal (.add e n) s = some v ∧ v ≥ κ
        ∧ o = upd s e v

/-- PROVEN: outcomes only for admissible instantiations — discharged
from the machine's own definitions. -/
instance : OutcomeAdmissible State Ctx WOp Bound State := ⟨by
  intro τ s _ κ o h
  cases τ with
  | add e n =>
    rcases h with ⟨v, hr, hge, _⟩
    refine ⟨⟨v, hr⟩, ?_⟩
    intro w hw
    have hvw : some w = some v := by rw [← hw, hr]
    have hwv : w = v := Option.some.inj hvw
    exact hwv ▸ hge⟩

/-- DEFINITION: composition support — the outcome state is the result
state. -/
instance wRes : ResultState State Ctx WOp Bound State :=
  ⟨fun _ _ _ _ o s' => s' = o⟩

/-- DEFINITION (machine): outcome equivalence is equality of semantic
field states (values and relationships pointwise). NOTE: this is the
witness's choice of observation granularity; CX-EQV shows bare
equality is NOT the general solution. -/
instance wEq : Equiv Ctx State := ⟨fun _ s₁ s₂ => s₁ = s₂⟩

/-! ### The canonical field: c1 = 5, c2 = 10, c1 —LINKS→ c2 -/

def c1 : Entity :=
  { id := ⟨"c1"⟩, typeName := "Counter", value := .int 5
    , properties := [] }

def c2 : Entity :=
  { id := ⟨"c2"⟩, typeName := "Counter", value := .int 10
    , properties := [] }

def link : Relationship :=
  { source := ⟨"c1"⟩, target := ⟨"c2"⟩
    kind := RelationKind.typed "LINKS", properties := [] }

def s0 : State :=
  { entities := [c1, c2], relationships := [link] }

/-- FACT: the canonical initial field is VALID per the committed
`SCR.ValidState` (entity ids unique, relationships well-formed). -/
theorem s0_valid : ValidState s0 := by
  constructor
  · simp [EntityIdsUnique, s0, c1, c2]
  · simp [RelationshipsWellFormed, s0, link, c1, c2]

/-! ### The pipeline in STC judgements -/

/-- STEP 1 of the witness: `add c1 3` is admissible at bound 0. -/
theorem step1_admissible :
    admissible (WOp.add ⟨"c1"⟩ 3) s0 ctx (0 : Bound) :=
  ⟨⟨8, by simp [resultVal, getVal, getValL, valueOf, s0, c1, c2]⟩,
   fun w hw => by
    have h8 : resultVal (WOp.add ⟨"c1"⟩ 3) s0 = some (8 : Int) :=
      by simp [resultVal, getVal, getValL, valueOf, s0, c1, c2]
    have h8w : some w = some (8 : Int) := by rw [← hw, h8]
    have : w = 8 := Option.some.inj h8w
    subst this; omega⟩

/-- STEP 2: the transition has outcome state s₁ where c1 = 8,
c2 = 10 (unchanged). -/
theorem step2_outcome :
    outcomes (instantiate (WOp.add ⟨"c1"⟩ 3) s0 ctx (0 : Bound))
      (upd s0 ⟨"c1"⟩ 8) :=
  ⟨8, by simp [resultVal, getVal, getValL, valueOf, s0, c1, c2],
    by simp, rfl⟩

/-! STEP 3: the outcome state remains VALID — state invariants are
preserved across the semantic transition (spec §23 Transition
validity). -/

/-- Entity ids are invariant under value update. -/
theorem ids_setValL (l : List Entity) (e : EntityId) (v : Int) :
    (setValL l e v).map (fun x => x.id) = l.map (fun x => x.id) := by
  induction l with
  | nil => rfl
  | cons a r ih =>
    simp only [setValL, List.map_cons, ih]
    split <;> simp

theorem ids_upd (s : State) (e : EntityId) (v : Int) :
    (upd s e v).entities.map (fun x => x.id) =
      s.entities.map (fun x => x.id) :=
  ids_setValL s.entities e v

/-- FACT: validity is preserved. -/
theorem step3_valid (s₁ : State)
    (h : outcomes (instantiate (WOp.add ⟨"c1"⟩ 3) s0 ctx (0 : Bound)) s₁)
    (h0 : ValidState s0) : ValidState s₁ := by
  obtain ⟨v, hr, hge, ho⟩ := h
  subst ho
  obtain ⟨hn, hrf⟩ := h0
  refine ⟨?_, ?_⟩
  · rw [EntityIdsUnique, ids_upd]; exact hn
  · rw [RelationshipsWellFormed] at hrf ⊢
    intro r hr'
    specialize hrf r hr'
    simp only [upd, ids_upd] at hrf ⊢
    exact hrf

/-- STEP 4: composition — `add c1 3` then `add c2 (−2)` reaches the
observed end state (c1 = 8, c2 = 8). This reproduces the canonical
witness values `Observe: c1=8, c2=8`. -/
theorem step4_compose :
    composeOutcome (instantiate (WOp.add ⟨"c1"⟩ 3) s0 ctx (0 : Bound))
      (WOp.add ⟨"c2"⟩ (-2)) ctx (0 : Bound) (upd (upd s0 ⟨"c1"⟩ 8) ⟨"c2"⟩ 8) := by
  refine ⟨upd s0 ⟨"c1"⟩ 8, upd s0 ⟨"c1"⟩ 8, ?_, rfl, ?_⟩
  · exact ⟨8, by simp [resultVal, getVal, getValL, valueOf, s0, c1, c2],
      by simp, rfl⟩
  · refine ⟨8, ?_, by simp, rfl⟩
    simp [resultVal, getVal, getValL, valueOf, upd, setValL, s0, c1, c2]

/-- STEP 5: observation — the final values are exactly the canonical
witness observations (c1 = 8, c2 = 8). -/
theorem step5_observe :
    getVal (upd (upd s0 ⟨"c1"⟩ 8) ⟨"c2"⟩ 8) ⟨"c1"⟩ = some 8 ∧
    getVal (upd (upd s0 ⟨"c1"⟩ 8) ⟨"c2"⟩ 8) ⟨"c2"⟩ = some 8 := by
  constructor
  · simp [getVal, getValL, valueOf, upd, setValL, s0, c1, c2]
  · simp [getVal, getValL, valueOf, upd, setValL, s0, c1, c2]

/-- Value updates never change entity ids. -/
theorem mem_setValL : ∀ (l : List Entity) (e : EntityId) (v : Int)
    (x : Entity), x ∈ l →
    ∃ y, y ∈ setValL l e v ∧ y.id = x.id := by
  intro l
  induction l with
  | nil => intro e v x hx; simp at hx
  | cons a r ih =>
    intro e v x hx
    simp only [List.mem_cons] at hx
    rcases hx with hxa | hx
    · cases hxa
      by_cases h : a.id = e
      · exact ⟨{ a with value := Value.int v },
          by simp [setValL, h], by simp⟩
      · exact ⟨a, by simp [setValL, h], rfl⟩
    · obtain ⟨y, hy, hyy⟩ := ih e v x hx
      exact ⟨y, by simp [setValL]; exact Or.inr hy, hyy⟩

/-- STEP 6: identity obligations — entity identities persist across
the transitions (docs/107 §16): the updated field still contains
entities with the original ids (`SCR.SameIdentity`). -/
theorem step6_identity (s₁ : State)
    (h : outcomes (instantiate (WOp.add ⟨"c1"⟩ 3) s0 ctx (0 : Bound)) s₁) :
    ∃ e₁ e₂ : Entity, e₁ ∈ s₁.entities ∧ e₂ ∈ s₁.entities ∧
      SameIdentity e₁ c1 ∧ SameIdentity e₂ c2 := by
  obtain ⟨v, _, _, ho⟩ := h
  subst ho
  have hm1 : (c1 : Entity) ∈ s0.entities := by
    simp [s0, List.mem_cons]
  have hm2 : (c2 : Entity) ∈ s0.entities := by
    simp [s0, List.mem_cons]
  obtain ⟨y₁, hy₁, hy₁id⟩ := mem_setValL s0.entities ⟨"c1"⟩ v c1 hm1
  obtain ⟨y₂, hy₂, hy₂id⟩ := mem_setValL s0.entities ⟨"c1"⟩ v c2 hm2
  exact ⟨y₁, y₂, hy₁, hy₂, hy₁id, hy₂id⟩

end Witness


end SCR.STC.Examples
