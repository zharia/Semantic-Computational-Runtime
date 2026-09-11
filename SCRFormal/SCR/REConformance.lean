import SCR.Basic
import SCR.STCGraphCounterexamples
import SCR.STCGraphLaws

/-!
# Reference Executor (RE) Semantic Conformance Model

This module formalizes the execution model of the Mojo Reference Executor
(`runtime/Reference_Executor/v0.0.1-0A-Reference_Executor_Mojo/src/scr_reference/`).

## Architectural Guarantees Formalized
1. **Deterministic State Evolution**: `re_step_deterministic`
2. **Strict Constraint Gate & Transactional Rollback**: `re_rollback_on_violation`
3. **Observation Purity**: `re_emit_preserves_values_and_step`
4. **Invariant Preservation**: `re_inc1_preserves_nonneg`, `re_inc2_preserves_nonneg`
5. **12 Conformance Ground-Truth Cases**: machine-checked evaluation of canonical
   and boundary scenarios matching the live Mojo probe suite.
-/

namespace SCR.REConformance

open SCR STC STC.Graph STC.Graph.Laws

/-- Semantic operations supported by the Reference Executor counter domain. -/
inductive REOp where
  | inc1 (n : Int)
  | inc2 (n : Int)
  | set1 (v : Int)
  | set2 (v : Int)
  | emit1
  | emit2
  | unknownOp
  deriving Repr, DecidableEq

/-- Observable state of the Reference Executor runtime environment. -/
structure REState where
  c1 : Int
  c2 : Int
  step : Int
  obs : List (String × Int)
  traceCount : Nat
  deriving Repr, DecidableEq

/-- Result of single-step execution: either committed state or failure with rollback. -/
inductive REOutcome where
  | ok (st : REState)
  | fail (st : REState) (reason : String)
  deriving Repr, DecidableEq

/-- Single-step transition semantics matching `Executor.execute` in `execution.mojo`. -/
def stepFn (op : REOp) (s : REState) : REOutcome :=
  match op with
  | .inc1 n =>
    let v' := s.c1 + n
    if v' ≥ 0 ∧ s.c2 ≥ 0 then
      .ok { s with c1 := v', step := s.step + 1, traceCount := s.traceCount + 1 }
    else
      .fail s "constraint violation: c1.value must be >= 0"
  | .inc2 n =>
    let v' := s.c2 + n
    if s.c1 ≥ 0 ∧ v' ≥ 0 then
      .ok { s with c2 := v', step := s.step + 1, traceCount := s.traceCount + 1 }
    else
      .fail s "constraint violation: c2.value must be >= 0"
  | .set1 v =>
    if v ≥ 0 ∧ s.c2 ≥ 0 then
      .ok { s with c1 := v, step := s.step + 1, traceCount := s.traceCount + 1 }
    else
      .fail s "constraint violation: c1.value must be >= 0"
  | .set2 v =>
    if s.c1 ≥ 0 ∧ v ≥ 0 then
      .ok { s with c2 := v, step := s.step + 1, traceCount := s.traceCount + 1 }
    else
      .fail s "constraint violation: c2.value must be >= 0"
  | .emit1 =>
    .ok { s with obs := s.obs ++ [("c1", s.c1)] }
  | .emit2 =>
    .ok { s with obs := s.obs ++ [("c2", s.c2)] }
  | .unknownOp =>
    .fail s "unknown semantic transformation"

/-- Program execution: sequential fold with fail-stop semantics. -/
def runProgram : List REOp → REState → REOutcome
  | [], s => .ok s
  | op :: rest, s =>
    match stepFn op s with
    | .ok s' => runProgram rest s'
    | .fail s_orig reason => .fail s_orig reason

/-! ## GMachine Integration -/

def reMachine : GMachine REOp REState Unit Unit where
  Out := fun _ => REOutcome
  edge := fun op _ s _ o => o = stepFn op s

instance : GSuccOut reMachine :=
  ⟨fun _ o p => match o with
    | .ok s' => p = s'
    | .fail s' _ => p = s'⟩

instance : GConsEquiv reMachine := ⟨fun _ _ e₁ e₂ => e₁ = e₂⟩

/-! ## Structural Invariants & Properties -/

/-- THEOREM: RE execution step is strictly deterministic. -/
theorem re_step_deterministic (op : REOp) (s : REState) (o1 o2 : REOutcome)
    (h1 : o1 = stepFn op s) (h2 : o2 = stepFn op s) : o1 = o2 := by
  subst h1 h2
  rfl

/-- THEOREM: RE transition relation is total over all operations and states. -/
theorem re_step_total (op : REOp) (s : REState) :
    ∃ o, reMachine.edge op () s () o :=
  ⟨stepFn op s, rfl⟩

/-- THEOREM: When constraint fails, state is preserved unchanged (transactional rollback). -/
theorem re_rollback_on_violation (op : REOp) (s : REState) (s_fail : REState) (reason : String)
    (h : stepFn op s = .fail s_fail reason) : s_fail = s := by
  cases op
  · simp [stepFn] at h; split at h <;> try contradiction
    cases h; rfl
  · simp [stepFn] at h; split at h <;> try contradiction
    cases h; rfl
  · simp [stepFn] at h; split at h <;> try contradiction
    cases h; rfl
  · simp [stepFn] at h; split at h <;> try contradiction
    cases h; rfl
  · simp [stepFn] at h
  · simp [stepFn] at h
  · simp [stepFn] at h; rcases h with ⟨rfl, rfl⟩; rfl

/-- THEOREM: EMIT operations preserve counter values, logical step, and trace count. -/
theorem re_emit1_purity (s : REState) :
    stepFn .emit1 s = .ok { s with obs := s.obs ++ [("c1", s.c1)] } := rfl

theorem re_emit2_purity (s : REState) :
    stepFn .emit2 s = .ok { s with obs := s.obs ++ [("c2", s.c2)] } := rfl

/-- THEOREM: Non-negative invariant preservation under INCREMENT 1. -/
theorem re_inc1_preserves_nonneg (s s' : REState) (n : Int)
    (h_step : stepFn (.inc1 n) s = .ok s') :
    s'.c1 ≥ 0 ∧ s'.c2 ≥ 0 := by
  simp [stepFn] at h_step
  split at h_step
  · rename_i h_cond
    cases h_step
    exact h_cond
  · contradiction

/-- THEOREM: Non-negative invariant preservation under INCREMENT 2. -/
theorem re_inc2_preserves_nonneg (s s' : REState) (n : Int)
    (h_step : stepFn (.inc2 n) s = .ok s') :
    s'.c1 ≥ 0 ∧ s'.c2 ≥ 0 := by
  simp [stepFn] at h_step
  split at h_step
  · rename_i h_cond
    cases h_step
    exact h_cond
  · contradiction

/-- THEOREM: Non-negative invariant preservation under SET 1. -/
theorem re_set1_preserves_nonneg (s s' : REState) (v : Int)
    (h_step : stepFn (.set1 v) s = .ok s') :
    s'.c1 ≥ 0 ∧ s'.c2 ≥ 0 := by
  simp [stepFn] at h_step
  split at h_step
  · rename_i h_cond
    cases h_step
    exact h_cond
  · contradiction

/-- THEOREM: Non-negative invariant preservation under SET 2. -/
theorem re_set2_preserves_nonneg (s s' : REState) (v : Int)
    (h_step : stepFn (.set2 v) s = .ok s') :
    s'.c1 ≥ 0 ∧ s'.c2 ≥ 0 := by
  simp [stepFn] at h_step
  split at h_step
  · rename_i h_cond
    cases h_step
    exact h_cond
  · contradiction

/-! ## 12 Ground-Truth Conformance Test Cases (Machine-Checked) -/

-- Case 1: Canonical increment on counter 1
theorem case1_inc1_positive :
    stepFn (.inc1 3) ⟨5, 10, 0, [], 0⟩ =
    .ok ⟨8, 10, 1, [], 1⟩ := by decide

-- Case 2: Decrement on counter 2 preserving non-negativity
theorem case2_inc2_negative_valid :
    stepFn (.inc2 (-2)) ⟨8, 10, 1, [], 1⟩ =
    .ok ⟨8, 8, 2, [], 2⟩ := by decide

-- Case 3: Decrement violating non-negativity rolls back
theorem case3_inc1_negative_invalid :
    stepFn (.inc1 (-10)) ⟨5, 10, 0, [], 0⟩ =
    .fail ⟨5, 10, 0, [], 0⟩ "constraint violation: c1.value must be >= 0" := by decide

-- Case 4: Set valid value
theorem case4_set1_valid :
    stepFn (.set1 7) ⟨5, 10, 0, [], 0⟩ =
    .ok ⟨7, 10, 1, [], 1⟩ := by decide

-- Case 5: Set negative value rolls back
theorem case5_set1_invalid :
    stepFn (.set1 (-1)) ⟨5, 10, 0, [], 0⟩ =
    .fail ⟨5, 10, 0, [], 0⟩ "constraint violation: c1.value must be >= 0" := by decide

-- Case 6: Emit counter 1 preserves values and records observation
theorem case6_emit1 :
    stepFn .emit1 ⟨5, 10, 0, [], 0⟩ =
    .ok ⟨5, 10, 0, [("c1", 5)], 0⟩ := by decide

-- Case 7: Full canonical program execution (inc1 5, inc2 3, emit1, emit2)
theorem case7_canonical_program :
    runProgram [.inc1 5, .inc2 3, .emit1, .emit2] ⟨0, 0, 0, [], 0⟩ =
    .ok ⟨5, 3, 2, [("c1", 5), ("c2", 3)], 2⟩ := by decide

-- Case 8: Program aborts on constraint violation at step 2 with state preserved
theorem case8_program_fail_stop :
    runProgram [.inc1 5, .inc1 (-10), .emit1] ⟨0, 0, 0, [], 0⟩ =
    .fail ⟨5, 0, 1, [], 1⟩ "constraint violation: c1.value must be >= 0" := by decide

-- Case 9: Unknown transformation rejected cleanly
theorem case9_unknown_op :
    stepFn .unknownOp ⟨5, 10, 0, [], 0⟩ =
    .fail ⟨5, 10, 0, [], 0⟩ "unknown semantic transformation" := by decide

-- Case 10: Emit initial state then increment
theorem case10_emit_before_inc :
    runProgram [.emit2, .inc2 5] ⟨0, 0, 0, [], 0⟩ =
    .ok ⟨0, 5, 1, [("c2", 0)], 1⟩ := by decide

-- Case 11: Set to boundary zero succeeds
theorem case11_set2_zero_boundary :
    stepFn (.set2 0) ⟨5, 10, 0, [], 0⟩ =
    .ok ⟨5, 0, 1, [], 1⟩ := by decide

-- Case 12: Sequential increment chain
theorem case12_sequential_inc_chain :
    runProgram [.inc1 1, .inc1 2, .inc1 3] ⟨0, 0, 0, [], 0⟩ =
    .ok ⟨6, 0, 3, [], 3⟩ := by decide

end SCR.REConformance
