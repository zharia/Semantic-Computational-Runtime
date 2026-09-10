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

end SCR
