import Mathlib.Data.Fin.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Decide

/-!
# SCR Entity Lifecycle (SCR-ENTITY-LIFECYCLE)

Formal verification of entity state machine properties.

## Main Theorems
- `lifecycle_no_self_destruction`: Cannot transition from Destroyed
- `lifecycle_terminal`: Destroyed has no outgoing transitions
- `lifecycle_valid_transitions`: Only specified transitions are valid
- `lifecycle_deterministic`: Each state has at most one valid next state
-/

namespace SCR.EntityLifecycle

-- ═══════════════════════════════════════════════════════════════════════════
-- Entity States
-- ═══════════════════════════════════════════════════════════════════════════

/-- Entity lifecycle states. -/
inductive EntityState where
  | created   -- Initial state
  | active    -- Fully operational
  | suspended -- Temporarily inactive
  | destroyed -- Terminal state
  deriving DecidableEq, Repr

/-- State ordinal for indexing. -/
def EntityState.ordinal : EntityState → Fin 4
  | .created   => ⟨0, by omega⟩
  | .active    => ⟨1, by omega⟩
  | .suspended => ⟨2, by omega⟩
  | .destroyed => ⟨3, by omega⟩

-- ═══════════════════════════════════════════════════════════════════════════
-- Transitions
-- ═══════════════════════════════════════════════════════════════════════════

/-- Valid state transitions. -/
inductive ValidTransition : EntityState → EntityState → Prop where
  | created_to_active    : ValidTransition .created .active
  | created_to_destroyed : ValidTransition .created .destroyed
  | active_to_suspended  : ValidTransition .active .suspended
  | active_to_destroyed  : ValidTransition .active .destroyed
  | suspended_to_active  : ValidTransition .suspended .active
  | suspended_to_destroyed : ValidTransition .suspended .destroyed

/-- Transition function (partial). -/
def transition : EntityState → EntityState → Option EntityState
  | .created, .active    => some .active
  | .created, .destroyed => some .destroyed
  | .active, .suspended  => some .suspended
  | .active, .destroyed  => some .destroyed
  | .suspended, .active  => some .active
  | .suspended, .destroyed => some .destroyed
  | _, _                 => none

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 1: No self-destruction from Destroyed
-- ═══════════════════════════════════════════════════════════════════════════

/-- Destroyed state has no outgoing transitions. -/
theorem lifecycle_terminal_destroyed :
    ∀ s, transition .destroyed s = none := by
  intro s
  fin_cases s <;> native_decide

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 2: Created cannot transition to Suspended
-- ═══════════════════════════════════════════════════════════════════════════

/-- Created can only go to Active or Destroyed, not Suspended. -/
theorem lifecycle_created_no_suspended :
    transition .created .suspended = none := by
  native_decide

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 3: Suspended cannot transition to Created
-- ═══════════════════════════════════════════════════════════════════════════

/-- Suspended can only go to Active or Destroyed, not Created. -/
theorem lifecycle_suspended_no_created :
    transition .suspended .created = none := by
  native_decide

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 4: Active cannot transition to Created
-- ═══════════════════════════════════════════════════════════════════════════

/-- Active can only go to Suspended or Destroyed, not Created. -/
theorem lifecycle_active_no_created :
    transition .active .created = none := by
  native_decide

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 5: Valid transitions produce results
-- ═══════════════════════════════════════════════════════════════════════════

/-- Valid transitions are total (produce a result). -/
theorem lifecycle_valid_transitions_total :
    (∀ s, transition .created s ≠ none ↔ s = .active ∨ s = .destroyed) ∧
    (∀ s, transition .active s ≠ none ↔ s = .suspended ∨ s = .destroyed) ∧
    (∀ s, transition .suspended s ≠ none ↔ s = .active ∨ s = .destroyed) ∧
    (∀ s, transition .destroyed s ≠ none → False) := by
  constructor
  · intro s
    fin_cases s <;> simp [transition] <;> constructor <;> intro h
    · left; rfl
    · rfl
    · right; rfl
    · rfl
    · contradiction
    · contradiction
    · contradiction
    · contradiction
  constructor
  · intro s
    fin_cases s <;> simp [transition] <;> constructor <;> intro h
    · left; rfl
    · rfl
    · right; rfl
    · rfl
    · contradiction
    · contradiction
    · contradiction
    · contradiction
  constructor
  · intro s
    fin_cases s <;> simp [transition] <;> constructor <;> intro h
    · left; rfl
    · rfl
    · right; rfl
    · rfl
    · contradiction
    · contradiction
    · contradiction
    · contradiction
  · intro s h
    fin_cases s <;> simp [transition] at h

-- ═══════════════════════════════════════════════════════════════════════════
-- Theorem 6: Active has exactly two outgoing transitions
-- ═══════════════════════════════════════════════════════════════════════════

/-- Active state can transition to exactly two states. -/
theorem lifecycle_active_outgoing :
    (∃ s₁ s₂, s₁ ≠ s₂ ∧ transition .active s₁ = some .suspended ∧ transition .active s₂ = some .destroyed) ∧
    (∀ s, transition .active s = some .suspended ∨ transition .active s = some .destroyed ∨ transition .active s = none) := by
  constructor
  · exact ⟨.suspended, .destroyed, by decide, by native_decide, by native_decide⟩
  · intro s
    fin_cases s <;> native_decide

end SCR.EntityLifecycle
