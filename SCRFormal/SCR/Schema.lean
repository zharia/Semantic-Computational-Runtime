import SCR.Basic

/-!
# Semantic Field Schema (merged from the retired root `formal/` project)

The type-level formalization of the canonical Semantic Field
`F = (E, R, T, C, S, K, M)` of `docs/103`/`docs/106` §3–§4, the
functional transformation layer with its composition laws, state
evolution, constraints, manifestation, semantic time, and the
executor-shaped `tryEvolve` oracle.

MERGE NOTE (docs/113_FORMAL_ONTOLOGY_MERGE.md): ported verbatim from
`formal/SCR/Basic.lean` (Lean v4.34 project, retired 2026-09-10) with
these reconciliation renames, semantics preserved:

- `SCR.Relationship (E)` (predicate)          → `RelationshipSchema`
  (inner `SCR.Relationship` is the recorded-structure kind);
- `SCR.Transformation` (functional)           → `FunTransformation`
  (inner `SCR.Transformation` is the descriptive record);
- `SCR.SemanticField` (record of TYPES)       → `FieldSchema`
  (inner `SCR.SemanticField` is a data instance);
- `SCR.Transformation`-over-field             → `FunFieldTransformation`;
- root's `Value` ({content : String})         → DROPPED; the merged
  ontology uses the inner sum-type `SCR.Value` (aligned with the Mojo
  kernel and Reference Executor `value_int`).

This is the SCHEMA layer: representations of what a field IS.
The STC/Graph corpus (`SCR.STC.*`) is the CALCULUS layer: what
happens in one. `STCGraphLaws`/`STC` do not import this file;
`SchemaBridge` proves the two layers agree where they overlap.
-/

namespace SCR

universe uE uC uS uM

def version : String := "0.2.0"

/-- A semantic relationship between entities of a typed field
(the schema-level predicate form; distinct from the recorded
`SCR.Relationship` structure of the data layer). -/
def RelationshipSchema (E : Type uE) : Type uE :=
  E → E → Prop

/-- A semantic transformation maps a state to a new state under a
particular context (functional schema form). -/
structure FunTransformation (C : Type uC) (S : Type uS) where
  apply : C → S → S

/-- Identity semantic transformation. -/
def FunTransformation.identity (C : Type uC) (S : Type uS) :
    FunTransformation C S where
  apply := fun _ s => s

/-- Composition of semantic transformations. -/
def FunTransformation.comp
    {C : Type uC} {S : Type uS}
    (g : FunTransformation C S) (f : FunTransformation C S) :
    FunTransformation C S where
  apply := fun c s => g.apply c (f.apply c s)

theorem FunTransformation.identity_apply
    {C : Type uC} {S : Type uS} (c : C) (s : S) :
    (FunTransformation.identity C S).apply c s = s := rfl

theorem FunTransformation.comp_assoc
    {C : Type uC} {S : Type uS}
    (f g h : FunTransformation C S) (c : C) (s : S) :
    ((FunTransformation.comp h g).comp f).apply c s =
      (FunTransformation.comp h (FunTransformation.comp g f)).apply c s := rfl

theorem FunTransformation.identity_comp
    {C : Type uC} {S : Type uS} (f : FunTransformation C S) (c : C) (s : S) :
    (FunTransformation.comp (FunTransformation.identity C S) f).apply c s =
      f.apply c s := rfl

theorem FunTransformation.comp_identity
    {C : Type uC} {S : Type uS} (f : FunTransformation C S) (c : C) (s : S) :
    (FunTransformation.comp f (FunTransformation.identity C S)).apply c s =
      f.apply c s := rfl

/-- A semantic constraint over field state. -/
def Constraint (S : Type uS) := S → Prop

/-- A physical manifestation of semantic structure: representation is
abstract because semantic identity must not depend on it
(docs/106 §5). -/
structure Manifestation (E : Type uE) (S : Type uS) (M : Type uM) where
  entity : E
  state : S
  representation : M

/-- The canonical Semantic Field tuple
`F = (E, R, T, C, S, K, M)` as a record of semantic DOMAINS. -/
structure FieldSchema where
  Entity : Type uE
  Relationship : RelationshipSchema Entity
  Context : Type uC
  State : Type uS
  Transformation : Type
  Constraint : Constraint State
  constraintDecidable : ∀ s, Decidable (Constraint s)
  Manifestation : Type uM

/-- A transformation operating within a particular Semantic Field. -/
structure FunFieldTransformation (F : FieldSchema) where
  apply : F.Context → F.State → F.State

/-- Semantic state evolution: `F(t + 1) = T(F(t), C(t))`. -/
def evolve (F : FieldSchema) (T : FunFieldTransformation F)
    (context : F.Context) (state : F.State) : F.State :=
  T.apply context state

/-- A state satisfies the field's semantic constraint. -/
def Satisfies (F : FieldSchema) (state : F.State) : Prop :=
  F.Constraint state

/-- A field transformation is constraint-preserving when every
admissible state remains admissible after transformation. -/
def ConstraintPreserving (F : FieldSchema) (T : FunFieldTransformation F) :
    Prop :=
  ∀ context state, Satisfies F state →
    Satisfies F (evolve F T context state)

/-- Equality is reflexive for every semantic state. -/
theorem state_identity (F : FieldSchema) (state : F.State) :
    state = state := rfl

theorem evolve_def (F : FieldSchema) (T : FunFieldTransformation F)
    (context : F.Context) (state : F.State) :
    evolve F T context state = T.apply context state := rfl

theorem constraint_preserved (F : FieldSchema) (T : FunFieldTransformation F)
    (h : ConstraintPreserving F T) (context : F.Context) (state : F.State)
    (hs : Satisfies F state) :
    Satisfies F (evolve F T context state) := h context state hs

/-- Semantic time — explicit temporal dimension for state evolution. -/
structure SemanticTime where
  step : Int
  deriving DecidableEq, Repr

/-- Time always progresses forward. -/
def TimeProgresses (before after : SemanticTime) : Prop :=
  after.step ≥ before.step

/-- An observation is a semantic read of state — it must not mutate
authoritative state (docs/106 §15 schema form). -/
structure Observation (S : Type uS) where
  source : S
  result : Value

/-- Observe without touching the state. -/
def observe (S : Type uS) (state : S) (f : S → Value) : S × Observation S :=
  (state, { source := state, result := f state })

theorem observation_preserves_state {S : Type uS} (state : S) (f : S → Value) :
    (observe S state f).1 = state := rfl

theorem observation_result_correct {S : Type uS} (state : S) (f : S → Value) :
    (observe S state f).2.result = f state := rfl

/-- A semantic context provides conditions under which transformation
is meaningful. -/
structure SemanticContext where
  time : SemanticTime
  label : String
  deriving Repr

/-- Constraint failure semantics: a semantic transformation result.
Distinguishes successful transformation from constraint violation —
the executor-shaped oracle mirrored in `Laws.Oracle`. -/
inductive TransformResult (S : Type uS) where
  | success : S → TransformResult S
  | failure

/-- Conditional evolution: applies the transformation only when the
resulting state satisfies the field constraint; on violation the
authoritative state is NOT replaced and the failure is observable. -/
def tryEvolve (F : FieldSchema) (T : FunFieldTransformation F)
    (ctx : F.Context) (state : F.State) : TransformResult F.State :=
  haveI := F.constraintDecidable
  if _h : F.Constraint (evolve F T ctx state) then
    .success (evolve F T ctx state)
  else
    .failure

theorem tryEvolve_failure_is_failure (F : FieldSchema)
    (T : FunFieldTransformation F) (ctx : F.Context) (state : F.State)
    (h : tryEvolve F T ctx state = .failure) :
    tryEvolve F T ctx state = .failure := h

theorem tryEvolve_success_carry_state (F : FieldSchema)
    (T : FunFieldTransformation F) (ctx : F.Context) (state : F.State)
    (s : F.State) (h : tryEvolve F T ctx state = .success s) :
    s = evolve F T ctx state := by
  simp [tryEvolve] at h
  split at h
  · injection h with h_eq; exact h_eq.symm
  · contradiction

theorem constraint_preserving_tryEvolve_succeeds (F : FieldSchema)
    (T : FunFieldTransformation F) (h : ConstraintPreserving F T)
    (ctx : F.Context) (state : F.State) (hs : Satisfies F state) :
    ∃ s, tryEvolve F T ctx state = .success s := by
  simp [tryEvolve]
  split
  · exact ⟨_, rfl⟩
  · rename_i h_not
    exact absurd (h ctx state hs) h_not

end SCR
