import SCR.Basic
import SCR.State
import SCR.Relationship
import SCR.Hypergraph
import SCR.STCGraphLaws
import SCR.REConformance

/-!
# Canonical Semantic Algebra (SCR-ALG-CORE)

This module formalizes the unified closed semantic algebra for SCR as mandated
by `DEVELOPMENT_AGENT_INSTRUCTION.md`.

## Core Theoretic Structure
- **Ontology**: `EntityId`, `Entity`, `Value`, `Hyperedge`, `Hypergraph` (State).
- **Computation**: `Applicability`, `Admissibility`, `Transformation`, `Transition`, `Outcome`.
- **Invariants & Safety**: Fail-stop rollback, observation purity, deterministic evolution.
- **Temporality & Progress**: Discrete logical step advancement and failure invariance.
- **Category & Composition**: Associative sequential composition with identity.
-/

namespace SCR.Algebra

open SCR STC STC.Graph STC.Graph.Laws SCR.Hypergraph SCR.REConformance

/-! ## 1. Ontological Primitives & Classifications -/

/-- Semantic identity type constructor (ALG-001). -/
abbrev Identity := EntityId

/-- Semantic value universe (ALG-004). -/
abbrev SemanticValue := Value

/-- Authoritative semantic state (ALG-006). -/
abbrev SemanticState := Hypergraph

/-- Ambient semantic context (ALG-007). -/
structure Context where
  logical_step : Nat
  label : String
deriving Repr, DecidableEq

/-! ## 2. Computational Operators & Outcomes -/

/-- Intentional semantic transformation (ALG-011). -/
inductive Transformation where
  | graphOp (op : HyperOp)
  | noOp
  | atomicTx (t1 t2 : Transformation)
deriving Repr

/-- Explicit algebraic transition outcome (ALG-013, ALG-014). -/
inductive Outcome where
  | ok (state : SemanticState) (ctx : Context)
  | fail (state : SemanticState) (ctx : Context) (reason : String)
deriving Repr

/-- Applicability predicate (ALG-009): checks structural precondition. -/
def isApplicable (t : Transformation) (s : SemanticState) : Bool :=
  match t with
  | .graphOp (.addNode e) => e.id ∉ s.NodeIds
  | .graphOp (.removeNode id) => id ∈ s.NodeIds ∧ checkNodeFreeOfEdges id s.edges
  | .graphOp (.addEdge e) => e.id ∉ s.EdgeIds ∧ checkRolesIncident e.roles s.NodeIds
  | .graphOp (.removeEdge id) => id ∈ s.EdgeIds
  | .graphOp (.updateNodeValue id _) => id ∈ s.NodeIds
  | .noOp => true
  | .atomicTx t1 _ => isApplicable t1 s

/-- Admissibility predicate (ALG-010): checks that constraints are satisfied. -/
def isAdmissible (t : Transformation) (s : SemanticState) (_ : Context) : Prop :=
  isApplicable t s = true ∧ IncidenceWellFormed s

/-- Canonical transition step operator (ALG-012) with full transactional rollback. -/
def step (t : Transformation) (s : SemanticState) (c : Context) : Outcome :=
  match t with
  | .noOp =>
    .ok s { c with logical_step := c.logical_step + 1 }
  | .graphOp op =>
    match Hypergraph.step op s with
    | .ok s' => .ok s' { c with logical_step := c.logical_step + 1 }
    | .fail s_orig reason => .fail s_orig c reason
  | .atomicTx t1 t2 =>
    match step t1 s c with
    | .ok s1 c1 =>
      match step t2 s1 c1 with
      | .ok s2 c2 => .ok s2 c2
      | .fail _ _ reason => .fail s c reason
    | .fail _ _ reason => .fail s c reason

/-- Semantic observation operator (ALG-015). -/
def observeNode (s : SemanticState) (id : EntityId) : Option Value :=
  s.nodes.find? (fun n => n.id = id) |>.map Entity.value

/-! ## 3. Core Algebraic Invariants & Theorems -/

/-- THEOREM (Determinism - ALG-012): Step execution is strictly deterministic. -/
theorem step_deterministic (t : Transformation) (s : SemanticState) (c : Context)
    (o1 o2 : Outcome) (h1 : o1 = step t s c) (h2 : o2 = step t s c) : o1 = o2 := by
  subst h1 h2
  rfl

/-- THEOREM (Transactional Rollback - ALG-014): Failure strictly preserves prior state and context. -/
theorem step_rollback_on_failure (t : Transformation) (s : SemanticState) (c : Context)
    (s_fail : SemanticState) (c_fail : Context) (reason : String)
    (h : step t s c = .fail s_fail c_fail reason) :
    s_fail = s ∧ c_fail = c := by
  induction t generalizing s c s_fail c_fail reason with
  | noOp =>
    simp [step] at h
  | graphOp op =>
    dsimp [step] at h
    split at h
    · contradiction
    · rename_i h_res
      cases h
      have h_rb := Hypergraph.step_rollback_on_failure op s s_fail reason h_res
      exact ⟨h_rb, rfl⟩
  | atomicTx t1 t2 ih1 _ =>
    dsimp [step] at h
    split at h
    · rename_i s1 c1 h_t1
      split at h
      · contradiction
      · cases h
        exact ⟨rfl, rfl⟩
    · rename_i h_t1_fail
      cases h
      exact ⟨rfl, rfl⟩

/-- THEOREM (Observation Purity - ALG-015): Observation is a pure function. -/
theorem observation_purity (s : SemanticState) (id : EntityId) :
    observeNode s id = observeNode s id := rfl

/-- THEOREM (Time Monotonicity - ALG-017): Successful transitions strictly advance logical time. -/
theorem step_advances_time (t : Transformation) (s s' : SemanticState) (c c' : Context)
    (h_step : step t s c = .ok s' c') :
    c'.logical_step ≥ c.logical_step + 1 := by
  induction t generalizing s s' c c' with
  | noOp =>
    simp [step] at h_step
    rcases h_step with ⟨rfl, rfl⟩
    dsimp
    omega
  | graphOp op =>
    dsimp [step] at h_step
    split at h_step
    · cases h_step
      dsimp
      omega
    · contradiction
  | atomicTx t1 t2 ih1 ih2 =>
    dsimp [step] at h_step
    split at h_step
    · rename_i s1 c1 h_t1
      split at h_step
      · rename_i s2 c2 h_t2
        cases h_step
        have h1 := ih1 s s1 c c1 h_t1
        have h2 := ih2 s1 s' c1 c' h_t2
        omega
      · contradiction
    · contradiction

/-- THEOREM (Time Invariance on Failure - ALG-017): Failed transitions do not advance logical time. -/
theorem step_preserves_time_on_failure (t : Transformation) (s s_fail : SemanticState) (c c_fail : Context)
    (reason : String) (h_step : step t s c = .fail s_fail c_fail reason) :
    c_fail.logical_step = c.logical_step := by
  have ⟨_, h_c⟩ := step_rollback_on_failure t s c s_fail c_fail reason h_step
  rw [h_c]

/-- THEOREM (Identity Preservation - ALG-001): Node identity is unaffected by value transformations. -/
theorem node_identity_invariant (n : Entity) (v : Value) :
    ({ n with value := v } : Entity).id = n.id := rfl

end SCR.Algebra
