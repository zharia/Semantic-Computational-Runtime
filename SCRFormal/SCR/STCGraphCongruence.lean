import SCR.STCGraphLaws

/-!
# STC-002 (1a) — Continuation Congruence

Closes the last OPEN congruence clause of `docs/112` §17
("continuation-congruence — OPEN — no padded class exists").

The resolution: continuation congruence is NOT a new axiom — it is
DERIVED from successor congruence (`GConsSuccCongruent`), which is
the substantive half. The derivation is given twice (raw
continuation transfer and composition-through-consequence), and the
machinery is shown load-bearing by the `CV` witness in which the
axiom genuinely fails: there, equivalent consequences have
NON-equivalent continuations. So the package closes with no padding
and no laundering.

CLASSIFICATION: DEFINITION (succ-cong class), THEOREM×2 (derivation),
COUNTEREXAMPLE (CV: failure of the driving law ⇒ the law constrains).
-/

namespace SCR.STC.Graph.Laws

open SCR.STC SCR.STC.Graph

universe u

variable {T S C K V : Type u}

/-- ASSUMPTION (machine law, the substantive congruence):
equivalent consequences have shared successors. One direction
suffices — symmetry of `consE` gives the other. -/
class GConsSuccCongruent (M : GMachine T S C K) [GConsEquiv M]
    [GSuccOut M] where
  succ_cong :
    ∀ (τ : T) (c : C) {e₁ e₂ : M.Out τ} (s : S),
      GConsEquiv.consE (M := M) τ c e₁ e₂ →
      GSuccOut.succRel (M := M) τ e₁ s →
      GSuccOut.succRel (M := M) τ e₂ s

/-- PROVEN (docs/112 §17 closure): continuations are congruent
through equivalent consequences. Derived from successor congruence
alone — the "missing" law never was independent structure. -/
theorem continuation_congruence (M : GMachine T S C K)
    [GConsEquiv M] [GSuccOut M] [GConsSuccCongruent M]
    (τ₁ τ₂ : T) (κ : K) (c : C) {e₁ e₁' : M.Out τ₁}
    (he : GConsEquiv.consE (M := M) τ₁ c e₁ e₁') (o₂ : M.Out τ₂) :
    (∃ s₁, GSuccOut.succRel (M := M) τ₁ e₁ s₁ ∧ M.edge τ₂ κ s₁ c o₂) →
    ∃ s₁', GSuccOut.succRel (M := M) τ₁ e₁' s₁' ∧
      M.edge τ₂ κ s₁' c o₂ :=
  fun ⟨s₁, hs, ho⟩ =>
    ⟨s₁, GConsSuccCongruent.succ_cong (M := M) τ₁ c he (s := s₁) hs,
      ho⟩

/-- DEFINITION: composition through a NAMED first consequence. -/
def gComposeThrough (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C)
    (e₁ : M.Out τ₁) (o₂ : M.Out τ₂) : Prop :=
  ∃ s₁, GSuccOut.succRel (M := M) τ₁ e₁ s₁ ∧ M.edge τ₂ κ s₁ c o₂

/-- PROVEN: `gCompose` is exactly the existential closure of
`gComposeThrough` — the through-form is the right atomic unit. -/
theorem gCompose_iff_through (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C) (o₂ : M.Out τ₂) :
    gCompose M τ₁ τ₂ κ s c o₂ ↔
    ∃ e₁, M.edge τ₁ κ s c e₁ ∧ gComposeThrough M τ₁ τ₂ κ s c e₁ o₂ := by
  constructor
  · rintro ⟨e₁, s₁, he₁, hs, ho⟩
    exact ⟨e₁, he₁, s₁, hs, ho⟩
  · rintro ⟨e₁, he₁, s₁, hs, ho⟩
    exact ⟨e₁, s₁, he₁, hs, ho⟩

/-- PROVEN: composition through equivalent first consequences is
congruent — the named-consequence form of continuation transfer. -/
theorem gComposeThrough_congruent (M : GMachine T S C K)
    [GConsEquiv M] [GSuccOut M] [GConsSuccCongruent M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C)
    {e₁ e₁' : M.Out τ₁} (he : GConsEquiv.consE (M := M) τ₁ c e₁ e₁')
    (o₂ : M.Out τ₂) :
    gComposeThrough M τ₁ τ₂ κ s c e₁ o₂ →
      gComposeThrough M τ₁ τ₂ κ s c e₁' o₂ :=
  continuation_congruence M τ₁ τ₂ κ c he o₂

/-! ## Non-vacuity witness: the driving law genuinely constrains -/

namespace CV

inductive TT : Type where
  | coin2   -- nondeterministic branch into state 0 or 1
  | use2    -- defined ONLY at state 0

abbrev SS : Type := Int
abbrev CC : Type := Int
abbrev KK : Type := Int

def m : GMachine TT SS CC KK where
  Out := fun _ => Int
  edge := fun τ _ s _ o => match τ with
    | .coin2 => o = 0 ∨ o = 1
    | .use2  => s = 0 ∧ o = 42

instance : GSuccOut m := ⟨fun _ e p => e = p⟩

/-- The most indiscriminating consequence equivalence: every two
consequences of `coin2` are "equivalent". The setoid laws hold
(trivially), so only the congruence can separate this machine —
and it does fail. -/
instance : GConsEquiv m := ⟨fun _ _ _ _ => True⟩

instance : GConsSetoid m where
  crefl := fun _ _ _ => trivial
  csymm := by intro τ c e₁ e₂ h; trivial
  ctrans := by intro τ c e₁ e₂ e₃ h₁ h₂; trivial

/-- COUNTEREXAMPLE (non-vacuity of `GConsSuccCongruent`): with the
trivial consequence equivalence, successor congruence FAILS —
consequences `0` and `1` are "equivalent" but only `0` successors
itself as state 0. Hence the congruence law in the derivation above
is a genuine constraint, not a tautology: the closure of
`docs/112` §17's OPEN item is therefore meaningful. -/
theorem succ_cong_is_genuine :
    ¬ ∃ (i : GConsSuccCongruent m), True := by
  intro ⟨i, _⟩
  have h : (GSuccOut.succRel (M := m) TT.coin2 (1 : Int) (0 : SS)) :=
    GConsSuccCongruent.succ_cong (M := m) TT.coin2 (0 : CC)
      (e₁ := (0 : Int)) (e₂ := (1 : Int)) (s := 0) trivial rfl
  have hh : (1 : Int) = 0 := h
  omega

/-- COUNTEREXAMPLE (non-vacuity of the derived law): continuations
through the two "equivalent" consequences genuinely differ —
`use2` continues one and not the other. Without successor
congruence the continuation transfer is FALSE, so the theorem's
hypothesis cannot be dropped. -/
theorem continuations_genuinely_differ :
    (∃ s₁, GSuccOut.succRel (M := m) TT.coin2 (0 : Int) s₁ ∧
      m.edge TT.use2 (0 : KK) s₁ (0 : CC) (42 : Int)) ∧
    ¬ (∃ s₁, GSuccOut.succRel (M := m) TT.coin2 (1 : Int) s₁ ∧
      m.edge TT.use2 (0 : KK) s₁ (0 : CC) (42 : Int)) := by
  refine ⟨⟨0, rfl, ⟨rfl, rfl⟩⟩, ?_⟩
  rintro ⟨s₁, hs, he⟩
  obtain ⟨h1, _⟩ := he
  have hs' : (1 : Int) = s₁ := hs
  have h1' : s₁ = (0 : SS) := h1
  subst h1'
  exact absurd hs' (by decide)

end CV

end SCR.STC.Graph.Laws
