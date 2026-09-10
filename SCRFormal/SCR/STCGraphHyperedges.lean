import SCR.State
import SCR.STCGraphCounterexamples
import SCR.STCGraphLaws

/-!
# STC-002 (1e) — Hyperedge Endpoints: graph-typed and fan-out

docs/112 §17 final line: "hyperedge endpoints (203_Graph bridge)".
Two structural FACTS close it additively:

1. `HEG` — a graph machine whose STATES (hence endpoints) ARE the
   committed entity/relationship graphs (`SCR.State`): no
   flattening, no new primitive — the carrier already hosts
   graph-structured endpoints.
2. `FAN` — a single consequence with THREE distinct successors:
   because `GSuccOut` relates a consequence to states by a
   RELATION (STC-002 design choice), multi-endpoint ("hyper")
   edges are already representable at arity > 2 without changing
   the kernel.

Classification of both: FACT (structure) + OPEN note: internal
STRUCTURE of hypergraph states (which entities co-changed,
incidence between edges) is NOT yet modeled end-to-end — that is
the executable-hypergraph milestone's job, not the kernel's.
-/

namespace SCR.STC.Graph.Hyper

open SCR STC STC.Graph STC.Graph.Laws

universe u

/-! ## HEG — endpoints that are graphs -/

namespace HEG

/-- Adding one entity to the field graph. -/
inductive TT : Type where
  | addEnt (e : SCR.Entity)

abbrev SS : Type := SCR.State
abbrev CC : Type := Int
abbrev KK : Type := Int

def m : GMachine TT SS CC KK where
  Out := fun _ => SS
  edge := fun τ _ s _ o => match τ with
    | .addEnt e => o = { s with entities := e :: s.entities }

instance : GSuccOut m := ⟨fun _ e p => e = p⟩

@[simp] theorem eAdd (κ : KK) (s : SS) (c : CC) (e : SCR.Entity)
    (o : SS) : m.edge (TT.addEnt e) κ s c o ↔
      o = { s with entities := e :: s.entities } := Iff.rfl

/-- FACT: total over graph states. -/
theorem total (κ : KK) (s : SS) (c : CC) (e : SCR.Entity) :
    ∃ o, m.edge (TT.addEnt e) κ s c o := ⟨_, rfl⟩

/-- FACT: graph structure preservation — the entity GRAPH's
relationship component is untouched by entity-adding edges
(connections between layers: matches `RelationshipsWellFormed`
stability proven in `Examples.Witness`). -/
theorem relationships_preserved (τ : TT) (κ : KK) (s : SS) (c : CC)
    (o : SS) (h : m.edge τ κ s c o) : o.relationships = s.relationships := by
  cases τ with
  | addEnt e =>
    rcases h with rfl
    rfl

end HEG

/-! ## FAN — one consequence, many endpoints (arity 3) -/

namespace FAN

inductive TT : Type where | pick
abbrev SS : Type := Int
abbrev CC : Type := Int
abbrev KK : Type := Int

def m : GMachine TT SS CC KK where
  Out := fun _ => SS
  edge := fun _ _ _ _ o => o = 0

/-- Relational successors: the consequence token `0` spans three
states. -/
instance : GSuccOut m :=
  ⟨fun _ _ p => p = (0 : SS) ∨ p = 1 ∨ p = 2⟩

@[simp] theorem sR (τ : TT) (e p : SS) :
    GSuccOut.succRel (M := m) τ e p ↔
      p = (0 : SS) ∨ p = 1 ∨ p = 2 := Iff.rfl

instance : GConsEquiv m := ⟨fun _ _ e₁ e₂ => e₁ = e₂⟩

/-- FACT: a single consequence with three pairwise distinct
successors — a genuine multi-endpoint ("hyper") edge inside the
binary-relation carrier. This is why `GSuccOut` was made a relation
and not an `Option S` function at kernel design time
(`Laws.succFunOnClass` then REQUIRES it to collapse to functional,
recovering the ordinary edge case as a machine law). -/
theorem hyperedge_fanout :
    ∃ (e : SS) (p q r : SS),
      GSuccOut.succRel (M := m) TT.pick e p ∧
      GSuccOut.succRel (M := m) TT.pick e q ∧
      GSuccOut.succRel (M := m) TT.pick e r ∧
      ¬ (p = q) ∧ ¬ (q = r) ∧ ¬ (p = r) :=
  ⟨(0 : SS), (0 : SS), (1 : SS), (2 : SS), by simp [sR],
    by simp [sR], by simp [sR], by decide, by decide, by decide⟩

/-- FACT: functionality failure of the fan-out — `succFunOnClass`
under equality-consequence fails: the composition laws therefore
apply only to the functional subclass, as designed. -/
theorem not_succFun : ¬ succFunOnClass m TT.pick (0 : KK) (0 : SS) (0 : CC) := by
  intro h
  have h1 := h (0 : SS) (0 : SS) (0 : SS) (1 : SS)
    (by simp [m]) (by simp [m]) rfl (by simp [sR]) (by simp [sR])
  have h2 : (0 : Int) = 1 := h1
  omega

end FAN

end SCR.STC.Graph.Hyper
