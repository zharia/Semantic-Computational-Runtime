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

end SCR.STC.Examples
