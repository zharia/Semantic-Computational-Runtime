import SCR.STC
import SCR.State
import SCR.Equivalence

/-!
# STC-001 Counterexamples and Falsifications

First-class deliverable (spec §24, §38D). CLASSIFICATION per spec §34.

- CX-EQV   : `SCR.Equivalence` (bare equality) is representation-
             sensitive ⇒ REFINEMENT to context-indexed `Equiv C`.
- CX-NDet  : the committed functional alias `SCR.Transition`
             (`State → Transformation → Option State`) cannot realize
             a nondeterministic outcome set ⇒ relational M REQUIRED.
- CX-RESULT: two legal `ResultState` structures over IDENTICAL kernel
             data diverge on composition ⇒ GAP G1: composition needs
             structure beyond ⟨S,C,T,K,O,≡⟩.
- CX-IND   : equally deterministic/total machines can commute or not ⇒
             GAP G3: independence needs footprint structure.
-/

namespace SCR.STC.Counterexamples

open SCR.STC

/-! ## CX-EQV — equality-based equivalence is representation-sensitive -/

/-- FACT: SCR's committed equivalence is propositional equality. -/
theorem committed_equivalence_is_equality (a b : SCR.State) :
    SCR.Equivalent a b ↔ a = b := Iff.rfl

def entA : SCR.Entity :=
  { id := ⟨"a"⟩, typeName := "T", value := .int 1, properties := [] }

def entB : SCR.Entity :=
  { id := ⟨"b"⟩, typeName := "T", value := .int 2, properties := [] }

/-- Two states differing ONLY in presentation order of the same
content. -/
def stateAB : SCR.State :=
  { entities := [entA, entB], relationships := [] }

def stateBA : SCR.State :=
  { entities := [entB, entA], relationships := [] }

/-- FACT: distinct as data — equality distinguishes them. -/
theorem cxeqv_ne : stateAB ≠ stateBA := by
  intro h
  have h₁ := congrArg (fun s : SCR.State =>
    (s.entities.map fun e => e.id.value)) h
  simp only [stateAB, stateBA, entA, entB, List.map] at h₁
  exact absurd h₁ (by simp)

/-- FACT: permutations of the same content — any order-insensitive
semantic observation identifies them. -/
theorem cxeqv_same_content :
    List.Perm (stateAB.entities.map fun e => e.id)
      (stateBA.entities.map fun e => e.id) := by
  show List.Perm [entA.id, entB.id] [entB.id, entA.id]
  exact (List.Perm.swap entA.id entB.id []).symm

/-! THE FINDING (spec §13): equality separates states that
order-insensitive observation identifies. `SCR.Equivalence` cannot
serve as semantic equivalence; the context-indexed kernel relation
`Equiv C` is the required refinement. -/

/-! ## CX-NDet — functional transitions cannot express nondeterminism -/

namespace NDet

abbrev St := Int
inductive Cx where
  | mk
def ctx : Cx := Cx.mk
inductive Tp where
  | toss
abbrev Kp := Int
abbrev Op := Int

instance : Applicable St Cx Tp := ⟨fun _ _ _ => True⟩
instance : Consents St Cx Tp Kp := ⟨fun _ _ _ _ => True⟩
instance ndOut : OutcomeOf St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ o => o = (0 : Op) ∨ o = 1⟩
instance : Equiv Cx Op := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance : OutcomeAdmissible St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩

def δnd : Transition St Cx Tp Kp :=
  instantiate (S := St) (C := Cx) (T := Tp) (K := Kp)
    Tp.toss (0 : St) ctx (0 : Kp)

/-- FACT: relational M realizes BOTH permitted outcomes. -/
theorem ndet_outcomes :
    outcomes δnd (0 : Op) ∧ outcomes δnd 1 := by
  constructor <;> simp [outcomes, δnd, ndOut]

end NDet

/-! THE FALSIFICATION (NDet above): a partial FUNCTION realizes at
most one value per instantiation, so it cannot cover M(δ) of the
Choice machine. See `ndet_no_functional_realization`: no single
value exhausts the outcome set — the functional model inherited from
conventional execution architectures is refuted for STC outcomes. -/

namespace NDet2

abbrev St := Int
inductive Cx where
  | mk
def ctx : Cx := Cx.mk
inductive Tp where
  | toss
abbrev Kp := Int
abbrev Op := Int

instance : Applicable St Cx Tp := ⟨fun _ _ _ => True⟩
instance : Consents St Cx Tp Kp := ⟨fun _ _ _ _ => True⟩
instance : OutcomeOf St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ o => o = (0 : Op) ∨ o = 1⟩
instance : Equiv Cx Op := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance : OutcomeAdmissible St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩

/-- FACT (the refutation): no v has M(δ) = {v}. -/
theorem ndet_no_single_valued_realization :
    ¬ ∃ v : Op, ∀ o : Op,
      ((o = (0 : Op) ∨ o = 1)) ↔ o = v := by
  rintro ⟨v, hv⟩
  have h0 : (0 : Op) = v := (hv 0).mp (Or.inl rfl)
  have h1 : (1 : Op) = v := (hv 1).mp (Or.inr rfl)
  have h : (0 : Int) = 1 := h0.trans h1.symm
  omega

end NDet2

/-! ## CX-RESULT — composition behavior is not fixed by kernel data -/

namespace Res

abbrev St := Bool
inductive Cx where
  | mk
def ctx : Cx := Cx.mk
inductive Tp where
  | step | probe
abbrev Kp := Int
abbrev Op := Bool

instance rApp : Applicable St Cx Tp := ⟨fun _ _ _ => True⟩
instance rCon : Consents St Cx Tp Kp := ⟨fun _ _ _ _ => True⟩
/-- Both transitions emit `true`: kernel outcome data CANNOT
distinguish `step` from `probe`. -/
instance rOut : OutcomeOf St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ o => o = true⟩
instance : Equiv Cx Op := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance : OutcomeAdmissible St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩

/-- FACT: the two outcome relations are pointwise equal — identical
kernel projections. -/
theorem outcomes_identical (s : St) (κ : Kp) (o : Op) :
    rOut.outcomeOf Tp.step s ctx κ o ↔
      rOut.outcomeOf Tp.probe s ctx κ o :=
  Iff.rfl

/-- TWO legal `ResultState` structures over the SAME kernel data.
(R2 is a plain def — two instances would clash, which is itself the
point: the choice of realization is EXTRA structure.) -/
instance rRes1 : ResultState St Cx Tp Kp Op where
  result τ s _ _ o s' := match τ with
    | .step  => s' = (!s && o)
    | .probe => s' = s

def rRes2 : ResultState St Cx Tp Kp Op :=
  ⟨fun _ s _ _ _ s' => s' = s⟩

/-- THE FALSIFICATION (GAP G1): the outcome `true` of `step` at
state `true` realizes state `false` under R1 while R2 realizes only
`true`. Kernel data is identical; composition behavior is not. -/
theorem composition_diverges :
    (∃ s' : St, rRes1.result Tp.step true ctx 0 true s' ∧ s' ≠ true) ∧
    ∀ s' : St, rRes2.result Tp.step true ctx 0 true s' → s' = true := by
  refine ⟨⟨false, rfl, by simp⟩, ?_⟩
  intro s' h; exact h

/-! CONSEQUENCE (spec §3): the published kernel minimality claim is
FALSIFIED for composition: `ResultState` is genuine additional
semantic structure, not notation. -/

end Res

/-! ## CX-IND — commutation is not a function of outcome data -/

namespace IND

abbrev St := Int
inductive Cx where
  | mk
def ctx : Cx := Cx.mk
inductive Tp where
  | dbl | inc
abbrev Kp := Int
abbrev Op := Int

instance : Applicable St Cx Tp := ⟨fun _ _ _ => True⟩
instance : Consents St Cx Tp Kp := ⟨fun _ _ _ _ => True⟩
instance iOut : OutcomeOf St Cx Tp Kp Op where
  outcomeOf τ s _ _ o := match τ with
    | .dbl => o = 2 * s
    | .inc => o = s + 1
instance : Equiv Cx Op := ⟨fun _ o₁ o₂ => o₁ = o₂⟩
instance : OutcomeAdmissible St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ _ _ => ⟨trivial, trivial⟩⟩
instance iRes : ResultState St Cx Tp Kp Op :=
  ⟨fun _ _ _ _ o s' => s' = o⟩

/-- FACT: each transition is deterministic. Same OUTCOME SHAPE as the
commuting Pair machine (STCExamples): deterministic, total,
functional. -/
@[simp] theorem dbl_outcome (s o : Int) :
    iOut.outcomeOf Tp.dbl s ctx 0 o ↔ o = 2 * s := Iff.rfl
@[simp] theorem inc_outcome (s o : Int) :
    iOut.outcomeOf Tp.inc s ctx 0 o ↔ o = s + 1 := Iff.rfl

theorem each_deterministic (s : St) :
    deterministic (instantiate (S := St) (C := Cx) (T := Tp)
        (K := Kp) Tp.dbl s ctx 0) ∧
    deterministic (instantiate (S := St) (C := Cx) (T := Tp)
        (K := Kp) Tp.inc s ctx 0) := by
  constructor
  · intro o₁ o₂ h₁ h₂
    exact h₁.trans h₂.symm
  · intro o₁ o₂ h₁ h₂
    exact h₁.trans h₂.symm

/-- FACT: yet the pair does NOT commute at 3:
inc-then-dbl reaches 8; dbl-then-inc reaches 7; both single-valued,
so a common composite outcome would force 8 = 7.

CONSEQUENCE (INFERENCE, spec §24 item 9): determinism+totality of
outcome data does not decide independence; the distinguishing fact
is WHICH PART of the state each transformation writes. Hence the
footprint refinement of `STC.lean` (G3): kernel minimality FALSIFIED
for concurrency. Contrast `Pair.pair_commutes` (STCExamples) — same
outcome shape, commutation HOLDS there. -/
theorem ind_not_commute_at_three :
    ¬ ∃ o : Op,
      composeOutcome (instantiate (S := St) (C := Cx) (T := Tp)
          (K := Kp) Tp.inc (3 : St) ctx 0)
        Tp.dbl ctx 0 o ∧
      composeOutcome (instantiate (S := St) (C := Cx) (T := Tp)
          (K := Kp) Tp.dbl (3 : St) ctx 0)
        Tp.inc ctx 0 o := by
  rintro ⟨o, ⟨o₁, s₁, h₁, h₂, h₃⟩, ⟨o₂, s₂, h₄, h₅, h₆⟩⟩
  have h₇ : o = 8 := by
    have e₁ : o₁ = 4 := h₁
    have e₂ : s₁ = o₁ := h₂
    have e₃ : o = 2 * s₁ := h₃
    simp only [Op, St] at *
    omega
  have h₈ : o = 7 := by
    have e₁ : o₂ = 6 := h₄
    have e₂ : s₂ = o₂ := h₅
    have e₃ : o = s₂ + 1 := h₆
    simp only [Op, St] at *
    omega
  have : (8 : Int) = 7 := h₇.symm.trans h₈
  omega

end IND

end SCR.STC.Counterexamples
