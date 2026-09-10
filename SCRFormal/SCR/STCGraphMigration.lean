import SCR.STCGraphCounterexamples
import SCR.STCExamples

/-!
# STC-002 (Lawful Equivalence) — Migration Re-derivation

Gate item: re-derive the canonical multi-entity golden path (the
Milestone-005 witness) over the graph carrier, so the STC-001
`OutcomeOf`/`ResultState` pair is DEMOTED WITH EVIDENCE, not by
decree: the golden facts hold unchanged after transport through
`toG` (`STCGraphCounterexamples.lean`).

The Witness machine here is the committed ontology itself:
`SCR.State`, `SCR.Entity`, `SCR.Relationship` — carried verbatim.
-/

namespace SCR.STC.Graph.Migration

open SCR.STC SCR.STC.Examples.Witness

/-- The golden machine in graph form: consequences are
(successor state, its result fiber). -/
def WM : GMachine WOp State Ctx Bound := toG State Ctx WOp Bound State

/-- GOLDEN STEP 1+2 MIGRATED: `add c1 3` then `add c2 (−2)` composes
on the graph carrier exactly as under STC-001 (`step4_compose`), the
successor relation now being the consequence fiber itself. -/
theorem wm_golden_composition :
    ∃ (s₁ s₂ : State),
      WM.edge (WOp.add ⟨"c1"⟩ 3) (0 : Bound) s0 ctx
        (s₁, fun x =>
          ResultState.result (WOp.add ⟨"c1"⟩ 3) s0 ctx (0 : Bound) s₁ x) ∧
      WM.edge (WOp.add ⟨"c2"⟩ (0 - 2)) (0 : Bound) s₁ ctx
        (s₂, fun x =>
          ResultState.result (WOp.add ⟨"c2"⟩ (0 - 2)) s₁ ctx (0 : Bound) s₂ x) := by
  obtain ⟨mid, fin, h₁, h₂, h₃⟩ := step4_compose
  subst h₂
  exact ⟨fin, upd (upd s0 ⟨"c1"⟩ 8) ⟨"c2"⟩ 8,
    ⟨h₁, fun _ => Iff.rfl⟩, ⟨h₃, fun _ => Iff.rfl⟩⟩

/-- GOLDEN STEP 3 MIGRATED (observation): the canonical end state is
unchanged by the transport: c1 = 8, c2 = 8. -/
theorem wm_golden_observation :
    getVal (upd (upd s0 ⟨"c1"⟩ 8) ⟨"c2"⟩ 8) ⟨"c1"⟩ = some 8 ∧
    getVal (upd (upd s0 ⟨"c1"⟩ 8) ⟨"c2"⟩ 8) ⟨"c2"⟩ = some 8 :=
  step5_observe

/-! RETIREMENT NOTE (classification: REFINEMENT, evidence-backed):
`wm_golden_composition'` + `toG_preserves_outcome` +
`toG_preserves_result` show the golden path's admissibility,
composition, and observation facts survive with `OutcomeOf` and
`ResultState` read off a SINGLE consequence relation (`toG.edge`).
The pair is therefore not needed as two primitives — it is
coordinate structure on the edge. STC-001 code is retained (this
increment refines, it does not delete); STC-002 proper adopts the
graph carrier. -/

end SCR.STC.Graph.Migration
