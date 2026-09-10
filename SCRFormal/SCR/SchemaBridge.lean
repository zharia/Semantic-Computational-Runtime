import SCR.Schema
import SCR.STCGraphCounterexamples
import SCR.STCGraphLaws

/-!
# Schema ↔ Calculus Bridge (merge reconciliation, docs/113)

The retired root project's functional layer and the graph carrier of
`STCGraphCounterexamples` are shown to agree exactly where they
overlap: a functional transformation schema `f : C → S → S` IS a
deterministic, total graph machine — and the bridge properties are
precisely the conditions consumed by `Laws.gCompose_deterministic`.

Classification: REFINEMENT (the two layers are compatible face-to-
face; neither is redefined). -/

namespace SCR.Bridge

open SCR STC STC.Graph

open SCR.STC.Graph.Laws

universe u

/-- DEFINITION: the graph machine of a functional schema
(`Transformation F`-style `apply : C → S → S`). -/
def ofFun (S C K : Type u) (f : C → S → S) : GMachine (ULift Unit) S C K where
  Out := fun _ => S
  edge := fun _ _ s c o => o = f c s

instance ofFunSuc (S C K : Type u) (f : C → S → S) :
    GSuccOut (ofFun S C K f) := ⟨fun _ e p => e = p⟩

instance ofFunConsE (S C K : Type u) (f : C → S → S) :
    GConsEquiv (ofFun S C K f) := ⟨fun _ _ e₁ e₂ => e₁ = e₂⟩

/-- PROVEN: total — every admissible input has a consequence
(functional schemas cannot be partial). -/
theorem ofFun_total (S C K : Type u) (f : C → S → S)
    (κ : K) (s : S) (c : C) : ∃ o, (ofFun S C K f).edge (⟨()⟩ : ULift Unit) κ s c o :=
  ⟨f c s, rfl⟩

/-- PROVEN: consequence-deterministic. -/
theorem ofFun_stepDet (S C K : Type u) (f : C → S → S)
    (κ : K) (s : S) (c : C) : stepDet (ofFun S C K f) (⟨()⟩ : ULift Unit) κ s c :=
  fun _ _ h₁ h₂ => h₁.trans h₂.symm

/-- PROVEN: successors functional on consequence classes — the exact
hypothesis consumed by `Laws.gCompose_deterministic`, so every
schema-layer step composes deterministically in the calculus layer. -/
theorem ofFun_succFun (S C K : Type u) (f : C → S → S)
    (κ : K) (s : S) (c : C) : succFunOnClass (ofFun S C K f) (⟨()⟩ : ULift Unit) κ s c :=
  fun e₁ e₂ p q h₁ h₂ heq hp hq => hp.symm.trans (heq.trans hq)

/-- DEFINITION: the everywhere-empty machine. -/
def emptyM (S C K : Type u) : GMachine (ULift Unit) S C K where
  Out := fun _ => S
  edge := fun _ _ _ _ _ => False

/-- PROVEN (separation): the graph carrier is STRICTLY more general
than the functional schema — there are graph machines with no edges
at all (`emptyM`), which cannot be the graph of any functional
schema `f : C → S → S` whenever consequences exist. So totality is
genuinely extra structure the schema layer carried implicitly and
the calculus layer must state. Classification: REFINEMENT +
COUNTEREXAMPLE (schema-completeness of the graph form). -/
theorem graph_strictly_more_general (S C K : Type u)
    [Inhabited K] [Inhabited C] [Nonempty S] :
    ¬ ∃ (f : C → S → S),
      ∀ (κ : K) (s : S) (c : C) (o : S),
        (emptyM S C K).edge (⟨()⟩ : ULift Unit) κ s c o ↔ o = f c s := by
  intro ⟨f, hf⟩
  obtain ⟨s₀⟩ : Nonempty S := inferInstance
  have h := hf default s₀ default (f default s₀)
  exact absurd ((h).mpr rfl) (by simp [emptyM])

/-- FACT: `emptyM` witnesses schema-layer blindness: no functional
schema can have an empty graph when `S` is nonempty (the functional
`apply` always produces `f c s`). The failing total/stepDet pair for
`emptyM` is carried by `Laws.E`/`A` witnesses instead. -/
theorem emptyM_no_edges (S C K : Type u) (κ : K) (s : S) (c : C) :
    ¬ ∃ o, (emptyM S C K).edge (⟨()⟩ : ULift Unit) κ s c o := fun ⟨_, h⟩ => absurd h (by simp [emptyM])

end SCR.Bridge
