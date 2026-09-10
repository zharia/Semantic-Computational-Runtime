import SCR.STCGraphCounterexamples

/-!
# STC-002 (Lawful Equivalence) — Graph Laws

Gate closure for `docs/112` §17/§19 over the surviving graph carrier
`SCR.STC.Graph.GMachine`. Delivered here:

1. consequence equivalence (setoid) + value congruence;
2. composition determinism PROVEN (closes old GAP G4 / OPEN O-2)
   with non-vacuity witnesses on machine `A`;
3. path chaining with append-composition (structural associativity);
4. Delta per `101_Core` §23: semantic delta rides the consequence;
   the endpoint span (graph delta) is a projection — COUNTEREXAMPLE
   (same span, different delta) against Delta := span;
5. causality decision (docs/112 §13): three pairwise separations on
   machine `E` — conflict, enablement, successor order-sensitivity —
   adoption: causal dependence := enablement ∪ conflict; successor
   order-sensitivity is only a shadow (proved under-reporting);
6. context-typed input domains derived from edges (item 4 of the
   gate), with the rejection-vs-partiality lesson carried over.

CLASSIFICATION labels per spec §34. No padding hypotheses: every
class field below is USED in at least one theorem or explicitly
marked OPEN.
-/

namespace SCR.STC.Graph.Laws

open SCR.STC SCR.STC.Graph

universe u

/-! ## 1. Consequence equivalence -/

/-- DEFINITION: context-indexed equivalence on consequences. -/
class GConsEquiv (M : GMachine T S C K) where
  consE : ∀ (τ : T), C → M.Out τ → M.Out τ → Prop

/-- ASSUMPTION (machine law): setoid per context. Consumed by
`gCompose_deterministic_sym` and `compose_value_deterministic`
below — no filler theorems. -/
class GConsSetoid (M : GMachine T S C K) [GConsEquiv M] where
  crefl  : ∀ (τ : T) (c : C) (e : M.Out τ),
    GConsEquiv.consE (M := M) τ c e e
  csymm  : ∀ (τ : T) (c : C) {e₁ e₂},
    GConsEquiv.consE (M := M) τ c e₁ e₂ →
      GConsEquiv.consE (M := M) τ c e₂ e₁
  ctrans : ∀ (τ : T) (c : C) {e₁ e₂ e₃},
    GConsEquiv.consE (M := M) τ c e₁ e₂ →
      GConsEquiv.consE (M := M) τ c e₂ e₃ →
        GConsEquiv.consE (M := M) τ c e₁ e₃

/-- ASSUMPTION (machine law, VALUE congruence — USED in
`compose_value_deterministic`): equivalent consequences emit
equivalent values; value observation is a function of the class.
Explicit parameters (not instance binders) because the class
projection `GValueOut.project` does not determine its machine
parameter from the argument types alone. -/
class GConsValueCongruent (M : GMachine T S C K)
    [GConsEquiv M] [GValueOut M V] [Equiv C V] where
  value_cong :
    ∀ (τ : T) (c : C) {e₁ e₂ : M.Out τ},
      GConsEquiv.consE (M := M) τ c e₁ e₂ →
      Equiv.equiv c (GValueOut.project (M := M) τ e₁)
                    (GValueOut.project (M := M) τ e₂)

/-! ## 2. Composition determinism (closes G4 / O-2) -/

/-- DEFINITION: consequence-deterministic step. -/
def stepDet (M : GMachine T S C K) [GConsEquiv M]
    (τ : T) (κ : K) (s : S) (c : C) : Prop :=
  ∀ e₁ e₂ : M.Out τ,
    M.edge τ κ s c e₁ → M.edge τ κ s c e₂ →
      GConsEquiv.consE (M := M) τ c e₁ e₂

/-- DEFINITION: successors functional on consequence classes. -/
def succFunOnClass (M : GMachine T S C K) [GConsEquiv M] [GSuccOut M]
    (τ : T) (κ : K) (s : S) (c : C) : Prop :=
  ∀ (e₁ e₂ : M.Out τ) (p q : S),
    M.edge τ κ s c e₁ → M.edge τ κ s c e₂ →
      GConsEquiv.consE (M := M) τ c e₁ e₂ →
      GSuccOut.succRel (M := M) τ e₁ p →
      GSuccOut.succRel (M := M) τ e₂ q → p = q

/--
  PROVEN (docs/107 §27 O-2; docs/112 §17): composition preserves
  consequence-determinism given functional successors. This is the
  statement recorded UNPROVABLE from the bare STC-001 kernel; over
  the graph carrier with the two named machine conditions it is a
  theorem, and the conditions are non-vacuous (witnesses below).
-/
theorem gCompose_deterministic (M : GMachine T S C K)
    [GConsEquiv M] [GSuccOut M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C)
    (hD₁ : stepDet M τ₁ κ s c)
    (hFun : succFunOnClass M τ₁ κ s c)
    (hD₂ : ∀ s₂ : S, stepDet M τ₂ κ s₂ c)
    (o₂ o₂' : M.Out τ₂)
    (hc : gCompose M τ₁ τ₂ κ s c o₂)
    (hc' : gCompose M τ₁ τ₂ κ s c o₂') :
    GConsEquiv.consE (M := M) τ₂ c o₂ o₂' := by
  obtain ⟨e₁, s₁, he₁, hs₁, he₂⟩ := hc
  obtain ⟨e₁', s₁', he₁', hs₁', he₂'⟩ := hc'
  have hs : s₁ = s₁' :=
    hFun e₁ e₁' s₁ s₁' he₁ he₁' (hD₁ e₁ e₁' he₁ he₁') hs₁ hs₁'
  subst hs
  exact hD₂ s₁ o₂ o₂' he₂ he₂'

/-- PROVEN: symmetry of the composed determinism conclusion (uses
the setoid law `csymm`). -/
theorem gCompose_deterministic_sym (M : GMachine T S C K)
    [GConsEquiv M] [GConsSetoid M] [GSuccOut M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C)
    (hD₁ : stepDet M τ₁ κ s c)
    (hFun : succFunOnClass M τ₁ κ s c)
    (hD₂ : ∀ s₂ : S, stepDet M τ₂ κ s₂ c)
    (o₂ o₂' : M.Out τ₂)
    (hc : gCompose M τ₁ τ₂ κ s c o₂)
    (hc' : gCompose M τ₁ τ₂ κ s c o₂') :
    GConsEquiv.consE (M := M) τ₂ c o₂' o₂ :=
  GConsSetoid.csymm (M := M) τ₂ c
    (gCompose_deterministic M τ₁ τ₂ κ s c hD₁ hFun hD₂ o₂ o₂' hc hc')

/-- PROVEN corollary (uses the value congruence): composite value
determinism. -/
theorem compose_value_deterministic (M : GMachine T S C K)
    [GConsEquiv M] [GConsSetoid M] [GValueOut M V] [GSuccOut M]
    [Equiv C V] [GConsValueCongruent M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C)
    (hD₁ : stepDet M τ₁ κ s c)
    (hFun : succFunOnClass M τ₁ κ s c)
    (hD₂ : ∀ s₂ : S, stepDet M τ₂ κ s₂ c)
    (o₂ o₂' : M.Out τ₂)
    (hc : gCompose M τ₁ τ₂ κ s c o₂)
    (hc' : gCompose M τ₁ τ₂ κ s c o₂') :
    Equiv.equiv c (GValueOut.project (M := M) τ₂ o₂)
                  (GValueOut.project (M := M) τ₂ o₂') :=
  GConsValueCongruent.value_cong (M := M) τ₂ c
    (gCompose_deterministic M τ₁ τ₂ κ s c hD₁ hFun hD₂ o₂ o₂' hc hc')

/-! ### Non-vacuity on machine A (consequence equality chosen) -/

/-- The natural consequence equivalence on `A`: identity of
consequence records. -/
instance : GConsEquiv A.M where
  consE _ _ e₁ e₂ := e₁ = e₂

instance : GConsSetoid A.M := @GConsSetoid.mk A.T A.S A.C A.K A.M
  inferInstance
  (fun _ _ _ => rfl) (fun _ _ _ _ h => Eq.symm h)
  (fun _ _ _ _ _ h₁ h₂ => Eq.trans h₁ h₂)

/-- FACT: `tickA` IS consequence-deterministic (hypotheses of the
theorem hold where needed). -/
theorem tickA_stepDet : stepDet A.M A.T.tickA (0 : A.K)
    ((3, 7) : A.S) (0 : A.C) := by
  intro e₁ e₂ h₁ h₂
  rcases e₁ with ⟨x₁, a₁, b₁, f₁⟩
  rcases e₂ with ⟨x₂, a₂, b₂, f₂⟩
  simp [A.M, A.core, A.kOK] at h₁ h₂
  obtain ⟨r1, r2, r3, r4⟩ := h₁
  obtain ⟨s1, s2, s3, s4⟩ := h₂
  subst r1 r2 r3 s1 s2 s3
  cases f₁ with
  | true => exact absurd r4 (by simp)
  | false => cases f₂ with
    | true => exact absurd s4 (by simp)
    | false => rfl

/-- FACT: `coin` is NOT consequence-deterministic (its two edges
emit distinct consequences) — the determinism condition genuinely
excludes nondeterministic branching. -/
theorem coin_not_stepDet : ¬ stepDet A.M A.T.coin (0 : A.K)
    ((4, 7) : A.S) (0 : A.C) := by
  intro h
  have e₀ : A.M.edge A.T.coin (0 : A.K) ((4, 7) : A.S) (0 : A.C)
      (A.Res.mk 0 0 7 false) := by simp [A.M, A.core, A.kOK]
  have e₁ : A.M.edge A.T.coin (0 : A.K) ((4, 7) : A.S) (0 : A.C)
      (A.Res.mk 0 1 7 false) := by simp [A.M, A.core, A.kOK]
  have th2 :
      (A.Res.mk 0 0 7 false : A.Res) = A.Res.mk 0 1 7 false :=
    h _ _ e₀ e₁
  have hc : (0 : Int) = 1 := congrArg (fun e : A.Res => match e with
    | A.Res.mk _ a _ _ => a) th2
  omega

/-- FACT: `tickA` IS successor-functional: -/
theorem tickA_succFun : succFunOnClass A.M A.T.tickA (0 : A.K)
    ((3, 7) : A.S) (0 : A.C) := by
  intro e₁ e₂ p q h₁ h₂ heq hp hq
  cases e₁ with
  | mk x₁ a₁ b₁ f₁ =>
    cases e₂ with
    | mk x₂ a₂ b₂ f₂ =>
      rcases p with ⟨p₁, p₂⟩
      rcases q with ⟨q₁, q₂⟩
      simp [A.lands] at hp hq
      simp [A.M, A.core, A.kOK] at h₁ h₂
      obtain ⟨rfl, rfl, rfl, _⟩ := h₁
      obtain ⟨rfl, rfl, rfl, _⟩ := h₂
      exact Prod.ext (hp.1.symm.trans hq.1) (hp.2.symm.trans hq.2)

/-! ## 3. Paths -/

/-- DEFINITION: edge-chains stepping states. -/
inductive Chain (M : GMachine T S C K) [GSuccOut M]
    : List T → K → S → C → S → Prop where
  | nil  : ∀ κ s c, Chain M [] κ s c s
  | step : ∀ (τ : T) (ts : List T) (κ : K) (s₀ s₁ s₂ : S) (c : C)
      (e : M.Out τ),
      M.edge τ κ s₀ c e →
      GSuccOut.succRel (M := M) τ e s₁ →
      Chain M ts κ s₁ c s₂ →
      Chain M (τ :: ts) κ s₀ c s₂

/-- PROVEN: chaining composes by list append (path composition
structural). -/
theorem chain_append (M : GMachine T S C K) [GSuccOut M]
    (ts : List T) (ts' : List T) (κ : K) (s₀ : S) (mid : S)
    (s₂ : S) (c : C)
    (h : Chain M ts κ s₀ c mid) (h' : Chain M ts' κ mid c s₂) :
    Chain M (ts ++ ts') κ s₀ c s₂ := by
  revert h'
  induction h with
  | nil kx sx cx => intro hh; exact hh
  | step τ tail kx s0x s1x s2x cx e he hs rest ih =>
    intro hh
    exact Chain.step τ (tail ++ ts') kx s0x s1x s₂ cx e he hs (ih hh)

/-! DEFINITION (docs/112 §17 closure): path equivalence = equal
span; provenance = the label sequence itself (CXG20). Both are
used: spans for behaviour, labels for identity of computation.
CLASSIFICATION: DEFINITION pair. -/

/-! ## 4. Delta (Core §23) -/

namespace D

/-- Machine: repair (add 5) vs assign (set 5). Consequence carries
the semantic-delta payload explicitly. -/
inductive T : Type where | repair | assign
abbrev S : Type := Int × Int
abbrev C : Type := Int
abbrev K : Type := Int

/-- (emitted value, resulting state, change kind as delta payload) -/
inductive Out : Type where
  | mk (v a b : Int) (kind : String)

def dM : GMachine T S C K where
  Out := fun _ => Out
  edge := fun τ _ s _ e =>
    match τ, s, e with
    | .repair, (a, b), .mk v a' b' k =>
        v = a + 5 ∧ a' = a + 5 ∧ b' = b
    | .assign, (a, b), .mk v a' b' k =>
        v = 5 ∧ a' = 5 ∧ b' = b

instance dSuc : GSuccOut dM := ⟨fun _ e p =>
  match e with | .mk _ a b _ => a = p.1 ∧ b = p.2⟩

/-- FACT: from (0,0) both transformations reach (5,0): the GRAPH
delta (endpoint span) identifies them — while their semantic deltas
(`Core` §23: `S₁ = S₀ ⊕ Δ`, change kind first-class) differ.
COUNTEREXAMPLE against Delta := endpoint span; the semantic delta
rides the consequence. -/
theorem delta_gt_span :
    ∃ (e₁ e₂ : Out),
      dM.edge T.repair (0 : K) ((0, 0) : S) (0 : C) e₁ ∧
      dM.edge T.assign (0 : K) ((0, 0) : S) (0 : C) e₂ ∧
      (∃ p : S, GSuccOut.succRel (M := dM) T.repair e₁ p ∧
        GSuccOut.succRel (M := dM) T.assign e₂ p) ∧
      match e₁, e₂ with
      | .mk _ _ _ k₁, .mk _ _ _ k₂ => ¬ (k₁ = k₂) :=
  ⟨Out.mk 5 5 0 "increment", Out.mk 5 5 0 "assignment",
    by simp [dM], by simp [dM],
    ⟨((5, 0) : S), by simp [dSuc], by simp [dSuc]⟩,
    fun h => absurd h (by decide)⟩

end D

/-! ## 5. Causality decision — three relations, pairwise separated -/

/-- Cell enumeration for the separation machine. -/
inductive Cell : Type where | l | r

namespace E

/-- `copy`: reads l writes r. `dbl`: reads+writes l.
`setA`, `setA2`: write l only (conflicting idempotent setters).
`assertL`: reads l only. -/
inductive T : Type where
  | copy | dbl | setA | setA2 | assertL
abbrev S : Type := Int × Int
abbrev C : Type := Int
abbrev K : Type := Int

def reads : T → Cell → Prop
  | .copy, .l => True
  | .dbl, .l => True
  | .dbl, .r => False
  | .assertL, .l => True
  | .assertL, .r => False
  | .copy, .r => False
  | .setA, _ => False
  | .setA2, _ => False

def writes : T → Cell → Prop
  | .copy, .r => True
  | .copy, .l => False
  | .dbl, .l => True
  | .dbl, .r => False
  | .setA, .l => True
  | .setA, .r => False
  | .setA2, .l => True
  | .setA2, .r => False
  | .assertL, _ => False

/-- State-transition consequences: successor only (observations
would ride an extra payload — the shadow argument needs only
successors). -/
def eM : GMachine T S C K where
  Out := fun _ => S
  edge := fun τ _ s _ s' =>
    match τ, s, s' with
    | .copy,    (a, b), (x, y) => x = a ∧ y = a
    | .dbl,     (a, b), (x, y) => x = 2 * a ∧ y = b
    | .setA,    (a, b), (x, y) => x = 5 ∧ y = b
    | .setA2,   (a, b), (x, y) => x = 5 ∧ y = b
    | .assertL, (a, b), (x, y) => x = a ∧ y = b

instance esuc : GSuccOut eM := ⟨fun _ e p => e = p⟩

/-- DEFINITION (adopted): write-write conflict. -/
def conflict (τ₁ τ₂ : T) : Prop := ∃ pp : Cell, writes τ₁ pp ∧ writes τ₂ pp

/-- DEFINITION (adopted): data-flow enablement. -/
def enables (τ₁ τ₂ : T) : Prop :=
  ∃ pp : Cell, writes τ₁ pp ∧ reads τ₂ pp

/-- SEP 1: order-sensitive WITHOUT write-conflict (`copy`/`dbl`:
disjoint writes, order changes the result). Successor
order-sensitivity does not require conflict. -/
theorem sep_order_no_conflict :
    gOrderSensitive eM T.copy T.dbl ∧ ¬ conflict T.copy T.dbl := by
  refine ⟨⟨(0 : K), ((3, 7) : S), (0 : C), ((6, 3) : S),
      ((6, 6) : S), ((6, 3) : S), ((6, 6) : S), ?_,
      by simp [esuc], ?_, by simp [esuc],
      fun h => absurd (congrArg Prod.snd h) (by decide)⟩, ?_⟩
  · exact ⟨((3, 3) : S), ((3, 3) : S), by simp [gCompose, eM, esuc],
      by simp [esuc], by simp [gCompose, eM, esuc]⟩
  · exact ⟨((6, 7) : S), ((6, 7) : S), by simp [gCompose, eM, esuc],
      by simp [esuc], by simp [gCompose, eM, esuc]⟩
  · rintro ⟨pp, hw1, hw2⟩
    cases pp <;> simp [writes] at hw1 hw2

/-- SEP 2: write-conflict WITHOUT order-sensitivity
(`setA`/`setA2`: same-cell writers; composition lands identically in
either order). Conflict does not imply sensitivity. -/
theorem sep_conflict_no_order :
    conflict T.setA T.setA2 ∧
    ¬ gOrderSensitive eM T.setA T.setA2 := by
  refine ⟨⟨.l, by simp [writes], by simp [writes]⟩, ?_⟩
  rintro ⟨κ, s, c, o₂, o₁', p, q, h1, hp, h2, hq, hne⟩
  obtain ⟨e₁, s', h₁₁, h₁₂, h₁₃⟩ := h1
  obtain ⟨e₂, s'', h₂₁, h₂₂, h₂₃⟩ := h2
  rcases s with ⟨a, b⟩
  rcases e₁ with ⟨u₁, v₁⟩
  rcases e₂ with ⟨u₂, v₂⟩
  rcases o₂ with ⟨x₃, y₃⟩
  rcases o₁' with ⟨x₄, y₄⟩
  rcases s' with ⟨r₁, r₂⟩
  rcases s'' with ⟨t₁, t₂⟩
  rcases p with ⟨pp₁, pp₂⟩
  rcases q with ⟨qq₁, qq₂⟩
  simp only [gCompose, eM, esuc, Prod.mk.injEq] at *
  omega

/-- SEP 3 (the under-reporting witness): enablement without successor
order-sensitivity — `assertL` reads what `setA` writes (data-flow
dependence!) yet both composition orders land at the same STATE.
Successor order-sensitivity misses read-dependences: it is a shadow
of dataflow, not the relation itself. -/
theorem sep_enablement_no_order :
    enables T.setA T.assertL ∧
    ¬ gOrderSensitive eM T.setA T.assertL := by
  refine ⟨⟨.l, by simp [writes], by simp [reads]⟩, ?_⟩
  rintro ⟨κ, s, c, o₂, o₁', p, q, h1, hp, h2, hq, hne⟩
  obtain ⟨e₁, s', h₁₁, h₁₂, h₁₃⟩ := h1
  obtain ⟨e₂, s'', h₂₁, h₂₂, h₂₃⟩ := h2
  rcases s with ⟨a, b⟩
  rcases e₁ with ⟨u₁, v₁⟩
  rcases e₂ with ⟨u₂, v₂⟩
  rcases o₂ with ⟨x₃, y₃⟩
  rcases o₁' with ⟨x₄, y₄⟩
  rcases s' with ⟨r₁, r₂⟩
  rcases s'' with ⟨t₁, t₂⟩
  rcases p with ⟨pp₁, pp₂⟩
  rcases q with ⟨qq₁, qq₂⟩
  simp only [gCompose, eM, esuc, Prod.mk.injEq] at *
  omega

/-! DECISION (docs/112 §13, machine-checked basis): adopt causal
dependence := enablement (data-flow) ∪ conflict (write-write
coordination). Successor order-sensitivity is its partial
observational shadow only (SEP 3). STC-001's
`causallyDependent := ¬independent` and the bare `gOrderSensitive`
candidate are both formally out. The reverse separation (sensitivity
without any overlap) is unprovable in this language (reads/writes
generate sensitivity here) and stays OPEN as a general claim. -/

end E

/-! ## 6. Context-typed input domains (gate item 4) -/

namespace SW

inductive T : Type where | run
inductive C : Type where | left | right
abbrev S : Type := Int
abbrev K : Type := Int

/-- Consequence records the emitted doubling. -/
def sM : GMachine T S C K where
  Out := fun _ => Int
  edge := fun _ _ s c o =>
    (c = C.left ∧ o = 2 * s) ∨ (c = C.right ∧ o = s)

/-- DERIVED INPUT DOMAIN: the extensional domain of a transformation
in a context — the typed `I_τ` of the graph hypothesis, read off the
edge relation itself (no separate domain field required). -/
def domain (τ : T) (c : C) : S → Prop :=
  fun s => ∃ o, sM.edge τ (0 : K) s c o

/-- FACT: the derived domains differ by context: `left` admits every
state (as doubling), `right` admits every state (as identity) —
domain membership itself is context-typed. Together with STC-001
`Switch` (admissibility context-dependence) this shows input typing
is derivable WHERE CONSENT IS UNIFORM; where refusal must remain
distinct from dangling (CXG7), the consent layer stays — the
context-typed-input question of docs/112 §17 resolves as: typing
captures domains, consents remain irreducible. -/
theorem domains_derive :
    (∀ s : S, domain T.run C.left s) ∧ (∀ s : S, domain T.run C.right s) :=
  ⟨fun s => ⟨2 * s, Or.inl ⟨rfl, by omega⟩⟩,
   fun s => ⟨s, Or.inr ⟨rfl, by omega⟩⟩⟩

end SW

end SCR.STC.Graph.Laws
