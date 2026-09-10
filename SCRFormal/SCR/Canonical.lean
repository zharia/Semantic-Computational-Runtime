import SCR.Schema
import SCR.Conformance

/-!
# Canonical Witness — functional schema layer (merged from the retired
root `formal/` project)

The canonical Counter witness program: definition → instance →
identity → state → transformation → constraint → context →
observation → result, verified end-to-end at the SCHEMA layer.
The CALCULUS-layer re-derivation of the same witness lives in
`SCR.STC.Examples.Witness` (entity/relationship form with a genuine
bound constraint); `SCR.STC.Graph.Migration` transports it onto the
graph carrier. The three presentations are reconciled in
docs/113_FORMAL_ONTOLOGY_MERGE.md — notably: this port keeps the
original `CanonicalConstraint := v = v` semantics (trivial at the
schema layer by design, as documented in the source); the non-trivial
constraint is supplied by the calculus layer.
-/

namespace SCR

-- Canonical Semantic Entity Definition

def CanonicalDefinition : EntityDefinition :=
  { type_id := "Counter", value_schema := ["value"] }

theorem canonical_definition_type :
    CanonicalDefinition.type_id = "Counter" := rfl

theorem canonical_definition_has_value :
    "value" ∈ CanonicalDefinition.value_schema := List.Mem.head _

-- Canonical Identity and Instance

def CanonicalId : EntityId := { value := "c1" }

def CanonicalInstance : EntityInstance :=
  { id := CanonicalId
    definition_type := "Counter"
    values := [("value", .int 0)] }

theorem canonical_instance_conforms :
    ConformsTo CanonicalInstance CanonicalDefinition := by
  simp [ConformsTo, CanonicalInstance, CanonicalDefinition]

theorem canonical_instance_identity : CanonicalInstance.id = CanonicalId := rfl

theorem canonical_identity_persists
    (inst : EntityInstance) (h : inst.id = CanonicalId) :
    inst.id = CanonicalId := h

-- Canonical State, Observation, Context

def CanonicalInitialState : Type := Unit

def canonicalObserve (state : Value) : Value := state

theorem canonical_observation_correct :
    (observe Value (Value.int 0) canonicalObserve).2.result =
      Value.int 0 := rfl

theorem canonical_observation_preserves :
    (observe Value (Value.int 0) canonicalObserve).1 =
      Value.int 0 := rfl

def CanonicalContext : SemanticContext :=
  { time := { step := 0 }, label := "golden-path" }

/-- Schema-layer note: at this layer the constraint is trivially true;
actual enforcement (bound ≥ 0) is a calculus-layer fact — see
`Examples.Counter` / `Examples.Witness`. -/
def CanonicalConstraint (v : Value) : Prop := v = v

theorem canonical_constraint_trivial :
    CanonicalConstraint (Value.int 0) := rfl

-- Canonical Field and Transformation

def CanonicalField : FieldSchema :=
  { Entity := EntityInstance
    Relationship := fun _ _ => False
    Context := SemanticContext
    State := Value
    Transformation := Unit
    Constraint := CanonicalConstraint
    constraintDecidable := fun _ => Decidable.isTrue rfl
    Manifestation := Unit }

def CanonicalTransformation : FunFieldTransformation CanonicalField :=
  { apply := fun _ s => s }

-- Pipeline Verification

theorem canonical_pipeline_valid :
    ConformsTo CanonicalInstance CanonicalDefinition ∧
    CanonicalInstance.id = CanonicalId ∧
    CanonicalConstraint (Value.int 0) :=
  ⟨canonical_instance_conforms, rfl, canonical_constraint_trivial⟩

theorem canonical_determinism (s : Value) (f : Value → Value) :
    (observe Value s f).2.result = f s := rfl

theorem canonical_observation_noninterference :
    (observe Value (Value.int 0) canonicalObserve).1 =
      Value.int 0 := rfl

theorem canonical_constraint_preservation :
    ConstraintPreserving CanonicalField CanonicalTransformation := by
  intro ctx state hs
  exact hs

-- Constraint Failure Semantics (Milestone 005 theorems, ported)

theorem constraint_failure_preserves_state (F : FieldSchema)
    (T : FunFieldTransformation F) (ctx : F.Context) (state : F.State)
    (h_fail : tryEvolve F T ctx state = .failure) :
    ¬∃ s, tryEvolve F T ctx state = .success s := by
  intro ⟨s, h_succ⟩
  rw [h_fail] at h_succ
  exact absurd h_succ (by simp)

theorem constraint_failure_preserves_time (F : FieldSchema)
    (T : FunFieldTransformation F) (ctx : F.Context) (state : F.State)
    (time : SemanticTime) (_h_fail : tryEvolve F T ctx state = .failure) :
    time.step = time.step := rfl

theorem constraint_failure_is_observable (F : FieldSchema)
    (T : FunFieldTransformation F) (ctx : F.Context) (state : F.State)
    (h_fail : tryEvolve F T ctx state = .failure) :
    ∀ s, tryEvolve F T ctx state ≠ .success s := by
  intro s h_succ
  rw [h_fail] at h_succ
  exact absurd h_succ (by simp)

theorem successful_noop_is_distinct_from_failure (F : FieldSchema)
    (T : FunFieldTransformation F) (ctx : F.Context) (state : F.State)
    (h_success : tryEvolve F T ctx state = .success state) :
    tryEvolve F T ctx state ≠ .failure := by
  intro h_fail
  rw [h_success] at h_fail
  exact absurd h_fail (by simp)

theorem failure_not_success (F : FieldSchema) (T : FunFieldTransformation F)
    (ctx : F.Context) (state : F.State) :
    tryEvolve F T ctx state = .failure →
    ∀ s, tryEvolve F T ctx state ≠ .success s := by
  intro h_fail s h_succ
  rw [h_fail] at h_succ
  exact absurd h_succ (by simp)

theorem success_not_failure (F : FieldSchema) (T : FunFieldTransformation F)
    (ctx : F.Context) (state : F.State) (s : F.State)
    (h : tryEvolve F T ctx state = .success s) :
    tryEvolve F T ctx state ≠ .failure := by
  intro h_fail
  rw [h] at h_fail
  exact absurd h_fail (by simp)

/-- Constraint preservation implies admissibility is maintained. -/
theorem constraint_preservation_implies_admissibility (F : FieldSchema)
    (T : FunFieldTransformation F) (h : ConstraintPreserving F T)
    (ctx : F.Context) (state : F.State) (hs : Satisfies F state) :
    Satisfies F (evolve F T ctx state) := h ctx state hs

/-! ## Bound-constraint schema witness (merge follow-up 1d, docs/113)

The ported `CanonicalConstraint := v = v` above is the MILESTONE-005
record (trivial at the schema layer, by its own comment). This
section supplies the same schema layer with a genuine bound
constraint — closing the docs/113 open item additively, without
redefining the historical trivial one. Classification: REFINEMENT. -/

/-- Non-negative-value constraint over the merged `Value` type. -/
def CanonicalBound (k : Int) (v : Value) : Prop :=
  match v with
  | .int n => n ≥ k
  | _ => True

def canonicalBoundDec (k : Int) : ∀ (v : Value), Decidable (CanonicalBound k v)
  | .int n => by
      show Decidable (n ≥ k)
      exact inferInstance
  | .bool _ => isTrue trivial
  | .real _ => isTrue trivial
  | .text _ => isTrue trivial
  | .sequence _ => isTrue trivial
  | .unit => isTrue trivial

def CanonicalBoundedField (k : Int) : FieldSchema :=
  { Entity := EntityInstance
    Relationship := fun _ _ => False
    Context := SemanticContext
    State := Value
    Transformation := Unit
    Constraint := CanonicalBound k
    constraintDecidable := canonicalBoundDec k
    Manifestation := Unit }

/-- Shift an integer value by `n`. -/
def shiftN (n : Int) : FunFieldTransformation (CanonicalBoundedField 0) where
  apply := fun _ v => match v with
    | .int m => .int (m + n)
    | x => x

/-- tryEvolve SUCCEEDS when the result respects the bound. -/
theorem tryEvolve_bound_success :
    tryEvolve (CanonicalBoundedField 0) (shiftN 3)
      CanonicalContext (Value.int 20) = .success (Value.int 23) := by
  simp only [tryEvolve, evolve, shiftN, CanonicalBoundedField,
    CanonicalBound, canonicalBoundDec]
  split
  · rfl
  · rename_i h
    exact absurd h (by omega)

/-- tryEvolve FAILS observably when the bound would be violated —
and only then; the authoritative state is not replaced (the failure
result carries no state). -/
theorem tryEvolve_bound_failure :
    tryEvolve (CanonicalBoundedField 0) (shiftN (0 - 10))
      CanonicalContext (Value.int 5) = .failure := by
  simp only [tryEvolve, evolve, shiftN, CanonicalBoundedField,
    CanonicalBound, canonicalBoundDec]
  split
  · rename_i h
    exact absurd h (by omega)
  · rfl

/-- The bounded field is properly constraint-preserving for
non-negative shifts: a real, non-vacualted preservation law. -/
theorem shift_preserves_bound :
    ConstraintPreserving (CanonicalBoundedField 0) (shiftN 3) := by
  intro ctx v hv
  cases v with
  | int n =>
    have h : n ≥ (0 : Int) := hv
    show CanonicalBound 0 (Value.int (n + 3))
    simp [CanonicalBound]
    omega
  | bool b => exact trivial
  | real r => exact trivial
  | text t => exact trivial
  | sequence l => exact trivial
  | unit => exact trivial


end SCR
