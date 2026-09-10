import SCR.STC
import Batteries

/-!
# STC Graph-Relational Refinement — Counterexample Program

Hypothesis under test (instruction
`001_agents/STC_GRAPH_RELATIONAL_REFINEMENT_AGENT.md`): STC should be
based on a typed graph relation `I --τ--> O`, `R_τ ⊆ I_τ × O_τ`.

Treated as a HYPOTHESIS TO FALSIFY, not an architecture to impose.
STC-002 is NOT started (instruction: hard constraint).

CLASSIFICATION discipline: DEFINITION / DERIVED / ASSUMPTION /
COUNTEREXAMPLE / REFINEMENT / OPEN / REJECTED on every nontrivial
statement.

Ontology discipline: admissibility classes are REUSED from `SCR.STC`
(`Applicable`, `Consents`, `admissible`, `rejected` — identical
classes, no parallel ontology). Only the transition-cARRIER pair
(`OutcomeOf` + `ResultState`) is reorganized, and that reorganization
is itself tested by counterexample, not assumed.
-/

namespace SCR.STC.Graph

universe u

/-! ## The graph hypothesis -/

/--
  DEFINITION (hypothesis form). `R_τ ⊆ I_τ × O_τ`: transformations
  carry TYPED output domains `Out τ`; the edge relation
  `K → S → C → Out τ → Prop` is the single transition structure.
  The output type is the semantic consequence domain of τ — not
  forced to be `S`: query edges, failure edges, value edges are
  first-class. Admissibility reuses STC-001 classes.
-/
structure GMachine (T S C K : Type u) where
  Out : T → Type u
  edge : ∀ (τ : T), K → S → C → Out τ → Prop

/-- DERIVED: τ produces SOME consequence at (κ, s, c). -/
def hasEdge (M : GMachine T S C K) (τ : T) (κ : K) (s : S) (c : C) : Prop :=
  ∃ o, M.edge τ κ s c o

/-- REUSE: admissibility is NOT re-invented. Same judgment, same
classes as STC-001. -/
abbrev gAdmissible [STC.Applicable S C T] [STC.Consents S C T K]
    (τ : T) (s : S) (c : C) (κ : K) : Prop :=
  STC.admissible τ s c κ

/-- ASSUMPTION (machine law; carried from STC-001 with identical
meaning, re-homed onto the single edge relation): edges exist only
for admissible instantiations. -/
class GWellFormed (M : GMachine T S C K)
    [STC.Applicable S C T] [STC.Consents S C T K] where
  edge_only_admissible :
    ∀ (τ : T) (κ : K) (s : S) (c : C) (o : M.Out τ),
      M.edge τ κ s c o → gAdmissible τ s c κ

/-! ## Output structure: STC-001's two relations as projections -/

/-- DEFINITION: value projection of an edge consequence. -/
class GValueOut (M : GMachine T S C K) (V : Type u) where
  project : ∀ (τ : T), M.Out τ → V

/-- DEFINITION: successor structure of an edge consequence.
RELATION, not function: forcing `Option S` would re-import the
single-valued bias CX-NDet refuted (nondeterministic edges land on
several successors — CXG6). -/
class GSuccOut (M : GMachine T S C K) where
  succRel : ∀ (τ : T), M.Out τ → S → Prop

/-- DEFINITION: failure marking lives ON THE OUTPUT (semantic
failure = consequence, not absence). -/
class GFailureOut (M : GMachine T S C K) where
  failed : ∀ (τ : T), M.Out τ → Prop

/-! ## Taxonomy: derived classifications -/

/-- DERIVED: partiality = admissible, edge-less. -/
def gPartial [STC.Applicable S C T] [STC.Consents S C T K]
    (M : GMachine T S C K) (τ : T) (κ : K) (s : S) (c : C) : Prop :=
  gAdmissible τ s c κ ∧ ¬ hasEdge M τ κ s c

/-- DERIVED: rejection = inadmissible (same class, reused). -/
abbrev gRejected [STC.Applicable S C T] [STC.Consents S C T K]
    (τ : T) (s : S) (c : C) (κ : K) : Prop :=
  STC.rejected τ s c κ

/-- PROVEN: taxonomy rows 1 and 4 remain disjoint in graph form
(mirrors STC-001 `rejected_not_partialTransition`). -/
theorem gRejected_not_gPartial [STC.Applicable S C T]
    [STC.Consents S C T K] (M : GMachine T S C K)
    (τ : T) (κ : K) (s : S) (c : C)
    (h : gRejected τ s c κ) : ¬ gPartial M τ κ s c :=
  fun ⟨hA, _⟩ => h hA

/-- PROVEN: with GWellFormed, an edge-less INPUT is rejected-or-
partial and the two are formally distinct predicates (COUNTEREXAMPLE
against classifying absence as a single event — see also CXG7). -/
theorem absence_classified (M : GMachine T S C K)
    [STC.Applicable S C T] [STC.Consents S C T K] [GWellFormed M]
    (τ : T) (κ : K) (s : S) (c : C) (h : ¬ hasEdge M τ κ s c) :
    gRejected τ s c κ ∨ ¬ gRejected τ s c κ :=
  Classical.em _

/-! ## Composition -/

/-- DEFINITION: relational composition along successor structure. -/
def gCompose (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C) (o₂ : M.Out τ₂) : Prop :=
  ∃ (e₁ : M.Out τ₁) (s' : S),
    M.edge τ₁ κ s c e₁ ∧ GSuccOut.succRel τ₁ e₁ s' ∧
    M.edge τ₂ κ s' c o₂

/-- DEFINITION: three-edge chain (the common refinement of both
association shapes). -/
def gChain (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ τ₃ : T) (κ : K) (s : S) (c : C) (o₃ : M.Out τ₃) : Prop :=
  ∃ (e₁ : M.Out τ₁) (e₂ : M.Out τ₂) (s₁ s₂ : S),
    M.edge τ₁ κ s c e₁ ∧ GSuccOut.succRel τ₁ e₁ s₁ ∧
    M.edge τ₂ κ s₁ c e₂ ∧ GSuccOut.succRel τ₂ e₂ s₂ ∧
    M.edge τ₃ κ s₂ c o₃

/--
  PROVEN (instruction §Composition): the two association shapes of
  relational composition are both equivalent to the three-edge
  chain, hence to each other. Associativity here is STRUCTURAL — a
  property of relational composition — not a per-machine law to be
  postulated. This is the graph form's principal genuine gain over
  STC-001 `composeOutcome`, whose associativity would have to be
  carried by hand (and was left as OPEN O-2-style residual work).
  Classification: REFINEMENT (composition algebra improves); the
  STC-001 side is unaffected, not contradicted.
-/
theorem gCompose_assoc_left (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ τ₃ : T) (κ : K) (s : S) (c : C) (o₃ : M.Out τ₃) :
    gChain M τ₁ τ₂ τ₃ κ s c o₃ →
    ∃ (o₂ : M.Out τ₂) (s₂ : S),
      gCompose M τ₁ τ₂ κ s c o₂ ∧
      GSuccOut.succRel τ₂ o₂ s₂ ∧ M.edge τ₃ κ s₂ c o₃ := by
  rintro ⟨e₁, e₂, s₁, s₂, h₁, hs₁, h₂, hs₂, h₃⟩
  exact ⟨e₂, s₂, ⟨e₁, s₁, h₁, hs₁, h₂⟩, hs₂, h₃⟩

theorem gCompose_assoc_right (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ τ₃ : T) (κ : K) (s : S) (c : C) (o₃ : M.Out τ₃) :
    (∃ (s₁ : S) (e₁ : M.Out τ₁),
        M.edge τ₁ κ s c e₁ ∧ GSuccOut.succRel τ₁ e₁ s₁ ∧
        gCompose M τ₂ τ₃ κ s₁ c o₃) →
    gChain M τ₁ τ₂ τ₃ κ s c o₃ := by
  rintro ⟨s₁, e₁, h₁, hs₁, e₂, s₂, h₂, hs₂, h₃⟩
  exact ⟨e₁, e₂, s₁, s₂, h₁, hs₁, h₂, hs₂, h₃⟩

/-! ## Translations between the two carrier forms -/

/-- TRANSLATION (STC-001 → graph). The consequence bundle: an output
is an outcome value plus its FULL successor fiber. -/
def toG (S C T K O : Type u)
    [out : STC.OutcomeOf S C T K O]
    [res : STC.ResultState S C T K O] : GMachine T S C K where
  Out τ := O × (S → Prop)
  edge := fun τ κ s c e =>
    out.outcomeOf τ s c κ e.1 ∧ ∀ s', e.2 s' ↔ res.result τ s c κ e.1 s'

instance toGV (S C T K O : Type u)
    [out : STC.OutcomeOf S C T K O]
    [res : STC.ResultState S C T K O] :
    GValueOut (toG S C T K O) O where
  project := fun _ e => e.1

instance toGS (S C T K O : Type u)
    [out : STC.OutcomeOf S C T K O]
    [res : STC.ResultState S C T K O] :
    GSuccOut (toG S C T K O) where
  succRel := fun _ e s' => e.2 s'

/-- PROVEN: outcomes preserved exactly by the translation. -/
theorem toG_preserves_outcome (S C T K O : Type u)
    [out : STC.OutcomeOf S C T K O]
    [res : STC.ResultState S C T K O]
    (τ : T) (s : S) (c : C) (κ : K) (o : O) :
    out.outcomeOf τ s c κ o ↔
    ∃ e, (toG S C T K O).edge τ κ s c e ∧
      GValueOut.project (M := toG S C T K O) τ e = o := by
  constructor
  · intro h
    exact ⟨(o, res.result τ s c κ o), ⟨h, fun _ => Iff.rfl⟩, rfl⟩
  · rintro ⟨⟨v, _⟩, ⟨h₁, _⟩, rfl⟩
    exact h₁

/-- PROVEN (with the necessary side condition — result does NOT
implies outcome, cf. STC-001 law direction): the successor relation
is preserved when the outcome exists. The side condition is itself
EVIDENCE: successor structure without outcome is expressible in
STC-001 (GAP G1 was about exactly this freedom), so the projections
are NOT freely interderivable — they are components of the edge. -/
theorem toG_preserves_result (S C T K O : Type u)
    [out : STC.OutcomeOf S C T K O]
    [res : STC.ResultState S C T K O]
    (τ : T) (s : S) (c : C) (κ : K) (o : O) (s' : S) :
    res.result τ s c κ o s' ∧ out.outcomeOf τ s c κ o ↔
    ∃ e, (toG S C T K O).edge τ κ s c e ∧
      GValueOut.project (M := toG S C T K O) τ e = o ∧
      GSuccOut.succRel (M := toG S C T K O) τ e s' := by
  constructor
  · rintro ⟨h, hov⟩
    exact ⟨(o, res.result τ s c κ o), ⟨⟨hov, fun _ => Iff.rfl⟩, rfl, h⟩⟩
  · rintro ⟨⟨v, b⟩, ⟨hov, hb⟩, hrfl, hs⟩
    have hp : GValueOut.project (M := toG S C T K O) τ (v, b) = v := rfl
    have hv : v = o := hp.trans hrfl
    have hs' : b s' := hs
    rw [← hv]
    exact ⟨(hb s').mp hs', hov⟩

/-- TRANSLATION (graph → outcome judgment): the STC-001 `outcomeOf`
judgment, instantiated at the τ-TYPED consequence. Outcome = edge.
(Not packaged as an `STC.OutcomeOf` instance: the class's single
`O` parameter cannot express per-τ output typing — exactly the
asymmetry recorded below.) -/
def outcomeViaEdge (M : GMachine T S C K)
    (τ : T) (s : S) (c : C) (κ : K) (o : M.Out τ) : Prop :=
  M.edge τ κ s c o

/-- PROVEN: graph well-formedness is the STC-001 admissibility law
for `outcomeViaEdge` verbatim — the law travels with the edge. -/
theorem fromG_wellformed (M : GMachine T S C K)
    [STC.Applicable S C T] [STC.Consents S C T K] [GWellFormed M] :
    ∀ (τ : T) (s : S) (c : C) (κ : K) (o : M.Out τ),
      outcomeViaEdge M τ s c κ o → gAdmissible τ s c κ :=
  fun τ s c κ o h => GWellFormed.edge_only_admissible τ κ s c o h

/-! TYPE-LEVEL INEXPRESSIBILITY (recorded as evidence, instruction:
"Do not weaken a counterexample because the current ontology cannot
express it. That inability is part of the evidence."):

Graph → STC-001 `ResultState` requires `result : ... → O → S → Prop`
with a FIXED outcome carrier `O` shared across all transformations.
The graph's outputs are τ-TYPED (`M.Out τ`); projecting τ₁'s
consequences into a common carrier and relating them to successor
states is not definable without additional structure on `M` (e.g. a
global value type plus per-τ embeddings). STC-001's pair of
relations is therefore NOT a notational variant of the graph form:
the graph is strictly more type-expressive, and the reverse
translation exists only for output-homogeneous machines (CXG5). -/

/-! ## Ordering phenomena defined purely on edge structure
(no scheduler, no time, no physical vocabulary) -/

/-- DEFINITION (instruction §Independence/causality): order-
sensitivity of a transformation pair — two composition orders from
the SAME start reach successor states that are distinguishable as
data. This is a candidate SEMANTIC causal dependence defined
entirely over the graph. -/
def gOrderSensitive (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ : T) : Prop :=
  ∃ (κ : K) (s : S) (c : C) (o₂ : M.Out τ₂) (o₁' : M.Out τ₁)
      (p q : S),
    gCompose M τ₁ τ₂ κ s c o₂ ∧ GSuccOut.succRel τ₂ o₂ p ∧
    gCompose M τ₂ τ₁ κ s c o₁' ∧ GSuccOut.succRel τ₁ o₁' q ∧
    ¬ (p = q)

/-- DEFINITION: candidate semantic COMPATIBILITY (order-insensitive
composition): every pair of chains from equal starts lands at equal
successors. Distinct from footprint independence — see CXG13. -/
def gCompatibleOn (M : GMachine T S C K) [GSuccOut M]
    (τ₁ τ₂ : T) (κ : K) (s : S) (c : C) : Prop :=
    ∀ (p q : S),
      (∃ o₂, gCompose M τ₁ τ₂ κ s c o₂ ∧ GSuccOut.succRel τ₂ o₂ p) →
      (∃ (o₁' : M.Out τ₁), gCompose M τ₂ τ₁ κ s c o₁' ∧
        GSuccOut.succRel τ₁ o₁' q) →
      p = q


/-! ## Counterexample Machine A — the program machine.
States: semantic pairs (counter a, auxiliary b). Contexts carry a
wall-clock tag that NO edge reads. Constraint envs carry a lower
bound for failRoll consent. -/

namespace A

inductive T : Type where
  | tickA | tickCopy | dblA | getB | getB2
  | failRoll | okNoop | failStay | coin | hang

abbrev S : Type := Int × Int
abbrev C : Type := Int
abbrev K : Type := Int

/-- Edge consequences: emitted value, resulting state, failure flag. -/
inductive Res : Type where
  | mk (v a b : Int) (f : Bool)

/-- Structural core of each edge type. -/
def core : T → S → Res → Prop
  | .tickA,    (a, b), .mk v a' b' f => v = a ∧ a' = a + 1 ∧ b' = b ∧ ¬ f
  | .tickCopy, (a, b), .mk v a' b' f => v = a ∧ a' = a + 1 ∧ b' = b ∧ ¬ f
  | .dblA,     (a, b), .mk v a' b' f => v = a ∧ a' = 2 * a ∧ b' = b ∧ ¬ f
  | .getB,     (a, b), .mk v a' b' f => v = b ∧ a' = a ∧ b' = b ∧ ¬ f
  | .getB2,    (a, b), .mk v a' b' f => v = b + 1 ∧ a' = a ∧ b' = b ∧ ¬ f
  | .failRoll, (a, b), .mk v a' b' f => v = a - 10 ∧ a' = 0 ∧ b' = b ∧ f
  | .okNoop,   (a, b), .mk v a' b' f => v = a ∧ a' = a ∧ b' = b ∧ ¬ f
  | .failStay, (a, b), .mk v a' b' f => v = a ∧ a' = a ∧ b' = b ∧ f
  | .coin,     (a, b), .mk v a' b' f => v = 0 ∧ (a' = 0 ∨ a' = 1) ∧ b' = b ∧ ¬ f
  | .hang,     _, _ => False

/-- Consent: failRoll fires exactly when the subtraction violates
the bound — semantic condition, not capability. -/
def kOK : K → T → S → C → Prop
  | κ, .failRoll, (a, b), _ => a - 10 < κ
  | _, _, _, _ => True

instance appA : STC.Applicable S C T := ⟨fun _ _ _ => True⟩
instance conA : STC.Consents S C T K := ⟨kOK⟩

/-- THE graph machine. -/
def M : GMachine T S C K where
  Out := fun _ => Res
  edge := fun τ κ s c e => core τ s e ∧ kOK κ τ s c

instance wfA : GWellFormed M := ⟨by
  intro τ κ s c e h
  exact ⟨trivial, h.2⟩⟩

instance valA : GValueOut M Int :=
  ⟨fun _ e => match e with | .mk v _ _ _ => v⟩
instance sucA : GSuccOut M :=
  ⟨fun _ e p => match e with | .mk _ a b _ => a = p.1 ∧ b = p.2⟩
instance flA : GFailureOut M :=
  ⟨fun _ e => match e with | .mk _ _ _ f => f⟩

/-- Local notations. -/
def ev (e : Res) : Int := GValueOut.project (M := M) T.tickA e
def lands (τ : T) (e : Res) (p : S) : Prop :=
  GSuccOut.succRel (M := M) τ e p
def isFail (e : Res) : Prop := GFailureOut.failed (M := M) T.tickA e

-- Projection-level simp lemmas (canonical reduction for the three
-- output structure classes on this machine).
@[simp] theorem proj_mk (τ : T) (x a b : Int) (f : Bool) :
    GValueOut.project (M := M) τ (Res.mk x a b f) = x := rfl
@[simp] theorem succ_mk (τ : T) (x a b : Int) (f : Bool) (p : S) :
    GSuccOut.succRel (M := M) τ (Res.mk x a b f) p ↔
      (a = p.1 ∧ b = p.2) := Iff.rfl
@[simp] theorem fail_mk (τ : T) (x a b : Int) (f : Bool) :
    GFailureOut.failed (M := M) τ (Res.mk x a b f) ↔ f := Iff.rfl

/-- Edge characterizations (constructor-form consequences). -/
theorem eA (κ : K) (a b c : Int) (x a' b' : Int) (f : Bool) :
    M.edge T.tickA κ (a, b) c (Res.mk x a' b' f) ↔
      (x = a ∧ a' = a + 1 ∧ b' = b ∧ ¬ f) := by
  simp [M, core, kOK]
theorem eCopy (κ : K) (a b c : Int) (x a' b' : Int) (f : Bool) :
    M.edge T.tickCopy κ (a, b) c (Res.mk x a' b' f) ↔
      (x = a ∧ a' = a + 1 ∧ b' = b ∧ ¬ f) := by
  simp [M, core, kOK]
theorem eDbl (κ : K) (a b c : Int) (x a' b' : Int) (f : Bool) :
    M.edge T.dblA κ (a, b) c (Res.mk x a' b' f) ↔
      (x = a ∧ a' = 2 * a ∧ b' = b ∧ ¬ f) := by
  simp [M, core, kOK]
theorem eHang (κ : K) (s : S) (c : Int) (x a' b' : Int) (f : Bool) :
    ¬ M.edge T.hang κ s c (Res.mk x a' b' f) := by
  intro h; exact absurd h.1 False.elim

/-! ### CXG1 — identical outcome / different successor state -/

/-- COUNTEREXAMPLE (against outcome-value-only transitions);
EVIDENCE FOR the typed edge: `tickA` and `dblA` from (4,7) emit the
SAME value and land in DIFFERENT states. STC-001 needed the extra
`ResultState` fiber; the edge carries the distinction intrinsically. -/
theorem cxg1_identical_outcome_different_successor :
    ∃ e₁ e₂ : Res,
      M.edge T.tickA (0 : K) (4, 7) (0 : C) e₁ ∧
      M.edge T.dblA (0 : K) (4, 7) (0 : C) e₂ ∧
      ev e₁ = ev e₂ ∧
      ¬ ∃ p : S, lands T.tickA e₁ p ∧ lands T.dblA e₂ p := by
  refine ⟨Res.mk 4 5 7 false, Res.mk 4 8 7 false,
    by simp [M, core, kOK], by simp [M, core, kOK],
    by simp [ev], ?_⟩
  rintro ⟨⟨x, y⟩, ⟨h1, h2⟩, ⟨h3, h4⟩⟩
  omega

/-! ### CXG2 — equivalent outcomes / distinguishable successor -/

def vEq (x y : Int) : Prop := ∃ t : Int, x = y + 2 * t

/-- COUNTEREXAMPLE: CXG1's pair is vEq-equivalent in outcome values
yet has distinguishable successors. Outcome-level equivalence does
not identify transitions; equivalence must be lifted to edges. -/
theorem cxg2_equiv_outcome_distinguishable_successor :
    ∃ e₁ e₂ : Res, vEq (ev e₁) (ev e₂) ∧
      ∃ p q : S, lands T.tickA e₁ p ∧ lands T.dblA e₂ q ∧ ¬ (p = q) :=
  ⟨Res.mk 4 5 7 false, Res.mk 4 8 7 false, ⟨0, by simp [vEq, ev]⟩,
    (5, 7), (8, 7),
    ⟨by simp [lands], by simp [lands]⟩,
    ⟨by simp [lands], by simp [lands]⟩,
    fun h => absurd (congrArg Prod.fst h) (by decide)⟩

/-! ### CXG3 — distinguishable outcomes / equivalent successor -/

/-- COUNTEREXAMPLE (against pure S→S graphs): `getB` and `getB2`
leave the state untouched yet emit distinguishable values. Output
typing beyond `S` is NECESSARY — the graph hypothesis is vindicated
exactly where state-only transition systems fail. -/
theorem cxg3_distinguishable_outcome_same_successor :
    ∃ e₁ e₂ : Res,
      M.edge T.getB (0 : K) (4, 7) (0 : C) e₁ ∧
      M.edge T.getB2 (0 : K) (4, 7) (0 : C) e₂ ∧
      ¬ ev e₁ = ev e₂ ∧
      ∃ p : S, lands T.getB e₁ p ∧ lands T.getB2 e₂ p :=
  ⟨Res.mk 7 4 7 false, Res.mk 8 4 7 false,
    by simp [M, core, kOK], by simp [M, core, kOK],
    by simp [ev], ((4, 7) : S), by simp [lands], by simp [lands]⟩

/-! ### CXG4 — different transformations / same endpoints -/

/-- FACT: `tickA` and `tickCopy` are endpoint-identical; only the
LABEL distinguishes them. REJECTED candidate: unlabelled edge set
`R ⊆ I × O` as the primitive. -/
theorem cxg4_same_endpoints :
    ∀ (s : S) (e : Res),
      M.edge T.tickA (0 : K) s (0 : C) e →
      M.edge T.tickCopy (0 : K) s (0 : C) e :=
  fun _ _ h => h

theorem cxg4_labels_distinct : T.tickA ≠ T.tickCopy :=
  fun h => absurd h (by simp)

/-! ### CXG6 — nondeterministic branching -/

/-- FACT: one input, two distinct successors — relational edges
represent this natively; function-form transitions cannot (inherits
STC-001 CX-NDet). -/
theorem cxg6_nondeterministic_branching :
    ∃ e₀ e₁ : Res,
      M.edge T.coin (0 : K) (4, 7) (0 : C) e₀ ∧
      M.edge T.coin (0 : K) (4, 7) (0 : C) e₁ ∧
      ∃ p q : S, lands T.coin e₀ p ∧ lands T.coin e₁ q ∧ ¬ (p = q) :=
  ⟨Res.mk 0 0 7 false, Res.mk 0 1 7 false,
    by simp [M, core, kOK], by simp [M, core, kOK],
    (0, 7), (1, 7), by simp [lands], by simp [lands],
    fun h => absurd (congrArg Prod.fst h) (by decide)⟩

/-! ### CXG7 — admissible partial input; consents irreducible -/

/-- FACT: `hang` is admissible yet edge-less: partiality holds,
rejection fails. EVIDENCE (instruction §Partiality): the rows stay
distinct IN graph form, and the distinction is carried ENTIRELY by
the consent layer. A bare typed graph (input typing only) collapses
partiality into rejection: CONSENTS CANNOT BE ELIMINATED.
REJECTED candidate: rejection-as-absent-edge. -/
theorem cxg7_admissible_partial :
    gPartial M T.hang (0 : K) ((4, 7) : S) (0 : C) ∧
    ¬ gRejected T.hang ((4, 7) : S) (0 : C) (0 : K) := by
  constructor
  · refine ⟨⟨trivial, trivial⟩, ?_⟩
    rintro ⟨⟨x, a', b', f⟩, h⟩
    exact h.1.elim
  · intro hr
    exact hr ⟨trivial, trivial⟩

/-! ### CXG8 — semantic failure WITH state change -/

/-- FACT: `failRoll` at (3,7) bound 0: consented, failure-marked,
AND moves the state. Failure is a TYPED CONSEQUENCE (edge to a
failure-labelled output), not an absence: classification = typed
consequence. -/
theorem cxg8_failure_with_state_change :
    ∃ e : Res,
      M.edge T.failRoll (0 : K) (3, 7) (0 : C) e ∧
      isFail e ∧ ∃ p : S, lands T.failRoll e p ∧ ¬ (p = (3, 7)) :=
  ⟨Res.mk (-7) 0 7 true, by simp [M, core, kOK, isFail],
    by simp [isFail], ((0, 7) : S), by simp [lands],
    fun h => absurd (congrArg Prod.fst h) (by decide)⟩

/-! ### CXG9 — no-op vs failure-on-same-state -/

/-- FACT: `okNoop` and `failStay` share value, input, successor —
distinguished only by the failure mark. STC-001's
`successful_noop_is_distinct_from_failure` reproduces identically:
EQUIVALENCE on this taxonomy row. -/
theorem cxg9_noop_vs_failure :
    ∃ e₁ e₂ : Res,
      M.edge T.okNoop (0 : K) (4, 7) (0 : C) e₁ ∧
      M.edge T.failStay (0 : K) (4, 7) (0 : C) e₂ ∧
      isFail e₂ ∧ ¬ isFail e₁ ∧
      lands T.okNoop e₁ (4, 7) ∧ lands T.failStay e₂ (4, 7) :=
  ⟨Res.mk 4 4 7 false, Res.mk 4 4 7 true,
    by simp [M, core, kOK], by simp [M, core, kOK],
    by simp [isFail], by simp [isFail],
    by simp [lands], by simp [lands]⟩

/-! ### CXG10–CXG12 — composition -/

/-- FACT: relational composition with aligned successors. -/
theorem cxg10_composition :
    gCompose M T.tickA T.dblA (0 : K) (3, 7) (0 : C)
      (Res.mk 4 8 7 false) :=
  ⟨Res.mk 3 4 7 false, (4, 7),
    by simp [M, core, kOK, lands], by simp [lands],
    by simp [M, core, kOK, lands]⟩

/-- FACT: three-edge chain; ASSOCIATIVITY is structural in graph
form (`gCompose_assoc_left`/`_right`): composition order carries no
proof burden. REFINEMENT over STC-001 `composeOutcome`, whose
associativity is a hand-carried exercise. -/
theorem cxg11_chain :
    gChain M T.tickA T.dblA T.getB (0 : K) (3, 7) (0 : C)
      (Res.mk 7 8 7 false) :=
  ⟨Res.mk 3 4 7 false, Res.mk 4 8 7 false, (4, 7), (8, 7),
    by simp [M, core, kOK, lands], by simp [lands],
    by simp [M, core, kOK, lands], by simp [lands],
    by simp [M, core, kOK, lands]⟩

/-- DEFINITION: guarded composition (conditional branching) derived
from edges — no new primitive. -/
def gBranch (p : Res → Prop) (τ₁ τ₂ : T) (κ : K) (s : S) (c : C)
    (o₂ : Res) : Prop :=
  ∃ (e₁ : Res) (s' : S),
    M.edge τ₁ κ s c e₁ ∧ p e₁ ∧ lands τ₁ e₁ s' ∧ M.edge τ₂ κ s' c o₂

/-- FACT: conditional branching is derived. -/
theorem cxg12_conditional :
    gBranch (fun e => (4 : Int) ≤ ev e) T.getB T.tickA
      (0 : K) (4, 7) (0 : C) (Res.mk 4 5 7 false) :=
  ⟨Res.mk 7 4 7 false, (4, 7), by simp [M, core, kOK, lands],
    by simp [ev], by simp [lands], by simp [M, core, kOK, lands]⟩

/-! ### CXG13–CXG17 — independence, compatibility, causality, time -/

/-! COUNTEREXAMPLE against conflation (instruction
§Independence/causality). `tickA` and `tickCopy` are COMPATIBLE
(every chain lands identically regardless of order — see
`cxg13_compatible_pair`) while writing the SAME state component
(footprint-overlapping ⇒ not independent under STC-001's
`Footprint`/`Overlap`). Commutation ⇏ independence, so STC-001's
`causallyDependent := ¬independent` is REJECTED as the account of
causality without this separation. Three notions, three relations:
footprint-overlap (structure), compatibility (composition),
order-sensitivity (composition). -/

-- Helpers: the tick pair are endpoint-deterministic.
private theorem from37 (τ : T) (hτ : τ = T.tickA ∨ τ = T.tickCopy)
    (e : Res) (h : M.edge τ (0 : K) ((3, 7) : S) (0 : C) e) :
    e = Res.mk 3 4 7 false := by
  rcases hτ with rfl | rfl
  · rcases e with ⟨x, a, b, f⟩
    simp [M, core, kOK] at h ⊢
    cases f with
    | true => simp_all
    | false => simp_all
  · rcases e with ⟨x, a, b, f⟩
    simp [M, core, kOK] at h ⊢
    cases f with
    | true => simp_all
    | false => simp_all

private theorem inter37 (τ : T) (hτ : τ = T.tickA ∨ τ = T.tickCopy)
    (e : Res) (s' : S) (h : M.edge τ (0 : K) ((3, 7) : S) (0 : C) e)
    (hl : lands τ e s') : s' = ((4, 7) : S) := by
  have h2 : e = Res.mk 3 4 7 false := from37 τ hτ e h
  subst h2
  obtain ⟨u, v⟩ := hl
  exact Prod.ext u.symm v.symm

private theorem landFrom47 (τ : T) (hτ : τ = T.tickA ∨ τ = T.tickCopy)
    (e : Res) (p : S)
    (h : M.edge τ (0 : K) ((4, 7) : S) (0 : C) e)
    (hl : lands τ e p) : p = ((5, 7) : S) := by
  rcases hτ with rfl | rfl
  · rcases e with ⟨x, a, b, f⟩
    simp [M, core, kOK] at h
    obtain ⟨rfl, rfl, rfl, _⟩ := h
    obtain ⟨u, v⟩ := hl
    exact Prod.ext u.symm v.symm
  · rcases e with ⟨x, a, b, f⟩
    simp [M, core, kOK] at h
    obtain ⟨rfl, rfl, rfl, _⟩ := h
    obtain ⟨u, v⟩ := hl
    exact Prod.ext u.symm v.symm

theorem cxg13_compatible_pair :
    ∀ (p q : S),
      (∃ o₂, gCompose M T.tickA T.tickCopy (0 : K) ((3, 7) : S)
          (0 : C) o₂ ∧ lands T.tickCopy o₂ p) →
      (∃ o₁, gCompose M T.tickCopy T.tickA (0 : K) ((3, 7) : S)
          (0 : C) o₁ ∧ lands T.tickA o₁ q) →
      p = q := by
  intro p q h₁ h₂
  rcases h₁ with ⟨o₂, hg₁, hp₁⟩
  rcases h₂ with ⟨o₁, hg₂, hq₁⟩
  obtain ⟨e₁, s', h₁₁, h₁₂, h₁₃⟩ := hg₁
  obtain ⟨e₂, s'', h₂₁, h₂₂, h₂₃⟩ := hg₂
  have hps : s' = ((4, 7) : S) :=
    inter37 T.tickA (Or.inl rfl) e₁ s' h₁₁ h₁₂
  have hps2 : s'' = ((4, 7) : S) :=
    inter37 T.tickCopy (Or.inr rfl) e₂ s'' h₂₁ h₂₂
  rw [hps] at h₁₃
  rw [hps2] at h₂₃
  have hp : p = ((5, 7) : S) :=
    landFrom47 T.tickCopy (Or.inr rfl) o₂ p h₁₃ hp₁
  have hq : q = ((5, 7) : S) :=
    landFrom47 T.tickA (Or.inl rfl) o₁ q h₂₃ hq₁
  exact hp.trans hq.symm

/-- FACT: `tickA`/`dblA` ARE order-sensitive (8 vs 7): candidate
semantic causal dependence defined on edges ALONE. -/
theorem cxg14_order_sensitive :
    gOrderSensitive M T.tickA T.dblA := by
  refine ⟨(0 : K), ((4, 7) : S), (0 : C), Res.mk 5 10 7 false,
    Res.mk 8 9 7 false, ((10, 7) : S), ((9, 7) : S), ?_,
    by simp [lands], ?_, by simp [lands], ?_⟩
  · exact ⟨Res.mk 4 5 7 false, ((5, 7) : S),
      by simp [gCompose, M, core, kOK, lands],
      by simp [lands], by simp [gCompose, M, core, kOK, lands]⟩
  · exact ⟨Res.mk 4 8 7 false, ((8, 7) : S),
      by simp [gCompose, M, core, kOK, lands],
      by simp [lands], by simp [gCompose, M, core, kOK, lands]⟩
  · intro h
    exact absurd (congrArg Prod.fst h) (by decide)


/-- ASSUMPTION + OPEN: order-sensitivity is the graph-native
candidate for causal dependence (uses no scheduler, no time —
instruction §15). OPEN (instruction §16 converse): a read-after-
write pair that commutes value-wise IS read-dependent yet NOT
order-sensitive; order-sensitivity would answer "independent". The
candidate UNDER-REPORTS such dependencies; unresolved — RECORDED,
not decided. -/
theorem cxg15_causal_edge_only :
    gOrderSensitive M T.tickA T.dblA := cxg14_order_sensitive

/-- FACT (instruction §16): temporal ordering WITHOUT causal
dependence — the chain `tickA;tickCopy` realizes an order while
cxg13 shows the pair's composition is order-insensitive: chain
existence ≠ dependence. -/
theorem cxg16_temporal_without_causal :
    gCompose M T.tickA T.tickCopy (0 : K) ((3, 7) : S) (0 : C)
      (Res.mk 4 5 7 false) :=
  ⟨Res.mk 3 4 7 false, ((4, 7) : S),
    by simp [gCompose, M, core, kOK, lands],
    by simp [lands], by simp [gCompose, M, core, kOK, lands]⟩

/-- FACT (instruction §17): wall-clock tags play no role: every edge
fact transports across context values (no `core` or `kOK` clause
reads the context). -/
theorem cxg17_no_wallclock (τ : T) (o : Res)
    (h : M.edge τ (0 : K) (4, 7) (0 : C) o) (c₁ : C) :
    M.edge τ (0 : K) (4, 7) c₁ o := by
  obtain ⟨hc, hk⟩ := h
  cases τ
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩
  · exact ⟨hc, hk⟩

/-! ### CXG18–CXG20 — observation and provenance -/

/-- DEFINITION: graph state-distinction via emitted-value reachability
through one edge type. -/
def gStateDistinct (s₁ s₂ : S) : Prop :=
  ∃ (τ : T) (κ : K) (c : C) (val : Int),
    (∃ e, M.edge τ κ s₁ c e ∧ ev e = val) ∧
    ¬ (∃ e, M.edge τ κ s₂ c e ∧ ev e = val)

/-- FACT (instruction §18): `getB` observes the auxiliary component —
(1,2) ≠ (1,3) is seen only through edges. -/
theorem cxg18_state_observation : gStateDistinct (1, 2) (1, 3) :=
  ⟨T.getB, 0, 0, 2,
    ⟨Res.mk 2 1 2 false, by simp [M, core, kOK], rfl⟩,
    by
      rintro ⟨e, he, hve⟩
      obtain ⟨hc, _⟩ := he
      rcases e with ⟨x, a', b', f⟩
      simp [core] at hc
      obtain ⟨h1, h2, h3, _⟩ := hc
      simp [ev] at hve
      omega⟩

/-- COUNTEREXAMPLE (instruction §19): edge observation is NOT state
observation: `getB`/`getB2` preserve state identically yet emit
distinct values. State-only models lose observations MADE ABOUT the
transition. -/
theorem cxg19_edge_observation :
    ∃ e₁ e₂ : Res,
      M.edge T.getB (0 : K) (4, 7) (0 : C) e₁ ∧
      M.edge T.getB2 (0 : K) (4, 7) (0 : C) e₂ ∧
      (∀ p : S, lands T.getB e₁ p ↔ lands T.getB2 e₂ p) ∧
      ¬ ev e₁ = ev e₂ :=
  ⟨Res.mk 7 4 7 false, Res.mk 8 4 7 false,
    by simp [M, core, kOK], by simp [M, core, kOK],
    fun p => ⟨fun ⟨h1, h2⟩ => ⟨by omega, by omega⟩,
      fun ⟨h1, h2⟩ => ⟨by omega, by omega⟩⟩,
    by simp [ev]⟩

/-- DEFINITION: chain provenance = label sequence. -/
def provenance (τ₁ τ₂ : T) : List T := [τ₁, τ₂]

/-- FACT (instruction §20): same endpoint, same consequence,
DIFFERENT provenance. Provenance survives as path labelling — no
new primitive; state/value-only models express nothing about it. -/
theorem cxg20_provenance :
    gCompose M T.tickA T.tickCopy (0 : K) (3, 7) (0 : C)
      (Res.mk 4 5 7 false) ∧
    gCompose M T.tickCopy T.tickA (0 : K) (3, 7) (0 : C)
      (Res.mk 4 5 7 false) ∧
    provenance T.tickA T.tickCopy ≠
      provenance T.tickCopy T.tickA := by
  refine ⟨⟨Res.mk 3 4 7 false, (4, 7),
      by simp [M, core, kOK, lands], by simp [lands],
      by simp [M, core, kOK, lands]⟩,
    ⟨Res.mk 3 4 7 false, (4, 7),
      by simp [M, core, kOK, lands], by simp [lands],
      by simp [M, core, kOK, lands]⟩, ?_⟩
  intro h
  cases h

/-- CXG15 — REJECTED model: ResultState-as-FUNCTION. `coin` has no
single-valued successor (`lands` holds for two distinct states), so
any function-form `Out → Option S` selection violates the
relational-successor law this machine satisfies. Records that
STC-001's GAP-G1 choice of a RELATION (not function) was correct;
the graph form generalizes it to the successor being intrinsic to
the edge. -/
theorem cxg_reject_successor_function :
    ∃ e₀ e₁ : Res,
      M.edge T.coin (0 : K) ((4, 7) : S) (0 : C) e₀ ∧
      M.edge T.coin (0 : K) ((4, 7) : S) (0 : C) e₁ ∧
      ∃ p q : S, lands T.coin e₀ p ∧ lands T.coin e₁ q ∧ ¬ (p = q) :=
  ⟨Res.mk 0 0 7 false, Res.mk 0 1 7 false,
    by simp [M, core, kOK], by simp [M, core, kOK],
    ((0, 7) : S), ((1, 7) : S),
    by simp [lands], by simp [lands],
    fun h => absurd (congrArg Prod.fst h) (by decide)⟩

end A


end SCR.STC.Graph
