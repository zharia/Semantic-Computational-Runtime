import SCR.STCGraphCounterexamples

/-!
# STC-002 (1c) — Causality Algebra: separating the notions

`docs/112` §13 adopted: causal dependence := enablement ∪ conflict,
with successor order-sensitivity (`gOrderSensitive`) demoted to an
observational shadow after `Laws.E.sep_enablement_no_order` showed it
UNDER-REPORTS read-dependences.

This module completes the algebra with a finer shadow — value-TRACE
sensitivity (observations ride consequences, compared per step):

- `CA.trace_sees_what_succ_shadow_misses` — the SEP-3 pair is
  trace-sensitive while successor-blind: the finer shadow closes
  exactly the documented gap;
- `Z.shadows_incomparable_1` — successor-sensitive with a blind
  trace: the finer shadow does NOT subsume the coarser; they are
  INCOMPARABLE;
- `CF.conflict_structural` — write-write conflict with no
  enablement and no sensitivity of either kind: the structural
  account is not observationally generated;
- the reverse separation (sensitivity without ANY read/write
  overlap) remains OPEN — CONJECTURE, unchanged from 1a.
-/

namespace SCR.STC.Graph.Causal

open SCR.STC SCR.STC.Graph

universe u

/-- DEFINITION: value-TRACE sensitivity of a pair: from one start,
two opposite two-step chains whose FIRST consequences carry
different observed values (per-transformation observation family). -/
def traceSensitive {T S C K V : Type u} (M : GMachine T S C K)
    [GSuccOut M] (ρ : ∀ (τ : T), M.Out τ → V) (τ₁ τ₂ : T) : Prop :=
  ∃ (κ : K) (s : S) (c : C) (e₁ : M.Out τ₁) (f₁ : M.Out τ₂),
    M.edge τ₁ κ s c e₁ ∧
    (∃ s₁, GSuccOut.succRel (M := M) τ₁ e₁ s₁ ∧
      ∃ o₂, M.edge τ₂ κ s₁ c o₂) ∧
    M.edge τ₂ κ s c f₁ ∧
    (∃ s₂, GSuccOut.succRel (M := M) τ₂ f₁ s₂ ∧
      ∃ o₁, M.edge τ₁ κ s₂ c o₁) ∧
    ¬ (ρ τ₁ e₁ = ρ τ₂ f₁)

/-! ## CA — successor shadow blind (Laws.E SEP-3); trace shadow sees. -/

namespace CA

inductive TT : Type where
  | setA    -- a := 5
  | assertL -- pure read of a

abbrev SS : Type := Int × Int
abbrev CC : Type := Int
abbrev KK : Type := Int

def m : GMachine TT SS CC KK where
  Out := fun _ => SS
  edge := fun τ _ s _ o => match τ with
    | .setA    => o = (5, s.2)
    | .assertL => o = s

instance : GSuccOut m := ⟨fun _ e p => e = p⟩

@[simp] theorem eA (κ : KK) (s : SS) (c : CC) (o : SS) :
    m.edge TT.setA κ s c o ↔ o = (5, s.2) := Iff.rfl
@[simp] theorem eL (κ : KK) (s : SS) (c : CC) (o : SS) :
    m.edge TT.assertL κ s c o ↔ o = s := Iff.rfl
@[simp] theorem sR (τ : TT) (e p : SS) :
    GSuccOut.succRel (M := m) τ e p ↔ e = p := Iff.rfl

/-- Observed value: the state AFTER the operation. -/
def ρ : ∀ (τ : TT), m.Out τ → Int
  | _, (a, _) => a

/-- FACT: read-after-write dependence IS visible to the value trace:
from (-3,7), the first-step read yields -3 in `assertL;setA` order
and the first-step write yields 5 in the other. -/
theorem trace_sees_what_succ_shadow_misses :
    traceSensitive m ρ TT.assertL TT.setA :=
  ⟨(0 : KK), ((-3, 7) : SS), (0 : CC), ((-3, 7) : SS), (5, 7),
   rfl,
   ⟨((-3, 7) : SS), rfl, (5, 7), by rw [eA]⟩,
   rfl,
   ⟨((5, 7) : SS), rfl, (5, 7), by rw [eL]⟩,
   by
     show ¬ (ρ TT.assertL ((-3, 7) : SS) = ρ TT.setA ((5, 7) : SS))
     simp [ρ]⟩

/-- FACT: the successor shadow is BLIND for this pair. -/
theorem succ_shadow_blind :
    ¬ gOrderSensitive m TT.assertL TT.setA := by
  rintro ⟨κ, s, c, o₂, o₁', p, q,
    ⟨e₁, s₁, h₁₁, h₁₂, h₁₃⟩, hp,
    ⟨e₂, s₂, h₂₁, h₂₂, h₂₃⟩, hq, hne⟩
  simp only [gCompose, eA, eL, sR] at h₁₁ h₁₂ h₁₃ h₂₁ h₂₂ h₂₃ hp hq
  subst h₁₂ h₂₂ hp hq
  subst h₁₃ h₂₃
  simp_all

end CA

/-! ## Z — successor-shadow WITHOUT trace sensitivity. -/

namespace Z

inductive TT : Type where | dbl | inc
abbrev SS : Type := Int
abbrev CC : Type := Int
abbrev KK : Type := Int

def m : GMachine TT SS CC KK where
  Out := fun _ => SS
  edge := fun τ _ s _ o => match τ with
    | .dbl => o = 2 * s
    | .inc => o = s + 1

instance : GSuccOut m := ⟨fun _ e p => e = p⟩

@[simp] theorem eD (κ : KK) (s : SS) (c : CC) (o : SS) :
    m.edge TT.dbl κ s c o ↔ o = 2 * s := Iff.rfl
@[simp] theorem eI (κ : KK) (s : SS) (c : CC) (o : SS) :
    m.edge TT.inc κ s c o ↔ o = s + 1 := Iff.rfl
@[simp] theorem sR (τ : TT) (e p : SS) :
    GSuccOut.succRel (M := m) τ e p ↔ e = p := Iff.rfl

/-- A trace family that observes nothing. -/
def ρ0 : ∀ (τ : TT), m.Out τ → Bool
  | _, _ => true

/-- FACT: `dbl`/`inc` are successor-sensitive (from 3: 7 vs 8). -/
theorem succ_sensitive : gOrderSensitive m TT.dbl TT.inc := by
  refine ⟨(0 : KK), (3 : SS), (0 : CC), (7 : SS), (8 : SS),
    (7 : SS), (8 : SS),
    ⟨(6 : SS), (6 : SS), by simp [gCompose, eD, sR], by simp [sR],
      by simp [eI, sR]⟩,
    by simp [sR],
    ⟨(4 : SS), (4 : SS), by simp [gCompose, eI, sR], by simp [sR],
      by simp [eD, sR]⟩,
    by simp [sR], fun h => absurd h (by decide)⟩

theorem trace_blind : ¬ traceSensitive m ρ0 TT.dbl TT.inc := by
  rintro ⟨κ, s, c, e₁, f₁, _, ⟨s₁, ⟨o₂, _⟩⟩, _, ⟨s₂, ⟨o₁, _⟩⟩, hne⟩
  exact absurd hne (by simp [ρ0])

/-- INCOMPARABILITY: successor-shadow ⇏ trace-shadow. -/
theorem shadows_incomparable_1 :
    (gOrderSensitive m TT.dbl TT.inc) ∧
      (¬ traceSensitive m ρ0 TT.dbl TT.inc) :=
  ⟨succ_sensitive, trace_blind⟩

end Z

/-! ## CF — conflict with no dependence and no sensitivity. -/

namespace CF

inductive TT : Type where | setX | setX2
abbrev SS : Type := Int × Int
abbrev CC : Type := Int
abbrev KK : Type := Int

def m : GMachine TT SS CC KK where
  Out := fun _ => SS
  edge := fun _ _ s _ o => o = (5, s.2)

instance : GSuccOut m := ⟨fun _ e p => e = p⟩

@[simp] theorem eX (τ : TT) (κ : KK) (s : SS) (c : CC) (o : SS) :
    m.edge τ κ s c o ↔ o = (5, s.2) := Iff.rfl
@[simp] theorem sR (τ : TT) (e p : SS) :
    GSuccOut.succRel (M := m) τ e p ↔ e = p := Iff.rfl

/-- Both write cell `false`; neither reads anything. -/
def writes : TT → Bool → Prop
  | _, b => b = false

def reads : TT → Bool → Prop
  | _, _ => False

theorem conflict_structural :
    (∃ p, writes TT.setX p ∧ writes TT.setX2 p) ∧
    (¬ ∃ p, writes TT.setX p ∧ reads TT.setX2 p) ∧
    (¬ ∃ p, writes TT.setX2 p ∧ reads TT.setX p) ∧
    ¬ gOrderSensitive m TT.setX TT.setX2 := by
  refine ⟨⟨false, rfl, rfl⟩, ?_, ?_, ?_⟩
  · rintro ⟨p, _, h⟩
    exact absurd h (by simp [reads])
  · rintro ⟨p, _, h⟩
    exact absurd h (by simp [reads])
  · rintro ⟨κ, s, c, o₂, o₁', p, q,
      ⟨e₁, s₁, h₁₁, h₁₂, h₁₃⟩, hp,
      ⟨e₂, s₂, h₂₁, h₂₂, h₂₃⟩, hq, hne⟩
    simp only [gCompose, eX, sR] at h₁₁ h₁₂ h₁₃ h₂₁ h₂₂ h₂₃ hp hq
    subst h₁₂ h₂₂ hp hq
    subst h₁₃ h₂₃
    simp_all

/-- FACT: no trace sensitivity either (successor-valued trace). -/
theorem cf_trace_blind :
    ¬ traceSensitive m (fun _ o => o) TT.setX TT.setX2 := by
  rintro ⟨κ, s, c, e₁, f₁, he₁, ⟨s₁, _, ⟨o₂, _⟩⟩, hf₁,
    ⟨s₂, _, ⟨o₁, _⟩⟩, hne⟩
  rw [eX] at he₁ hf₁
  exact absurd hne (by simp [he₁, hf₁])

end CF

end SCR.STC.Graph.Causal
