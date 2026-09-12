import SCR.Basic
import SCR.Hypergraph
import SCR.Algebra
import SCR.STCGraphLaws
import SCR.STCGraphCausality
import SCR.STCGraphHyperedges

/-!
# Semantic Algebra Counterexample & Falsification Corpus

This module formalizes the negative witnesses and falsification theorems required
by `DEVELOPMENT_AGENT_INSTRUCTION.md` (§7, §8, §13, §14, §15, §25).

## Falsification Invariants Proven
1. `CX_01_failure_distinguishable_from_noop`: Failure is semantically distinct from successful no-op.
2. `CX_02_dangling_edge_rejected`: Adding an edge with unresolvable role targets is strictly rejected.
3. `CX_03_incident_node_removal_rejected`: Removing a node with active incident hyperedges is rejected.
4. `CX_04_conflicting_writes_do_not_commute`: State updates to the same target do not commute.
5. `CX_05_trace_shadow_incomparability`: Observational successor shadows do not capture causality.
6. `CX_06_hyperedge_fanout_non_functional`: Relational multi-endpoint fan-out exits functional subclass.
-/

namespace SCR.Algebra.Counterexamples

open SCR STC STC.Graph STC.Graph.Laws SCR.Hypergraph SCR.Algebra

/-! ## CX-01: Failure is Distinguishable from Successful No-Op -/

def testNode : Entity :=
  { id := ⟨"e_dup"⟩, typeName := "Thing", value := .unit, properties := [] }

def testStateWithNode : SemanticState :=
  { nodes := [testNode], edges := [], logical_step := 0 }

def testContext : Context :=
  { logical_step := 0, label := "test" }

/-- FALSIFICATION: Failure to add duplicate node does NOT equal a successful noOp. -/
theorem CX_01_failure_distinguishable_from_noop :
    step (.graphOp (.addNode testNode)) testStateWithNode testContext ≠
    step .noOp testStateWithNode testContext := by
  dsimp [step, Hypergraph.step, testStateWithNode, testNode, Hypergraph.NodeIds, testContext]
  intro h
  nomatch h

/-! ## CX-02: Dangling Hyperedge Role Targets are Rejected -/

def danglingEdge : Hyperedge :=
  { id := "dangling_1",
    edgeType := "REL",
    roles := [⟨"target", ⟨"missing_node"⟩⟩],
    properties := [] }

/-- FALSIFICATION: Adding a hyperedge with nonexistent role target returns .fail. -/
theorem CX_02_dangling_edge_rejected :
    ∃ reason, step (.graphOp (.addEdge danglingEdge)) testStateWithNode testContext =
      .fail testStateWithNode testContext reason := by
  dsimp [step, Hypergraph.step, testStateWithNode, danglingEdge, Hypergraph.EdgeIds,
         Hypergraph.NodeIds, checkRolesIncident, testContext]
  exact ⟨"dangling role target in hyperedge", rfl⟩

/-! ## CX-03: Incident Node Removal is Rejected -/

def incidentEdge : Hyperedge :=
  { id := "edge_1",
    edgeType := "REL",
    roles := [⟨"target", ⟨"e_dup"⟩⟩],
    properties := [] }

def stateWithIncidentEdge : SemanticState :=
  { nodes := [testNode], edges := [incidentEdge], logical_step := 0 }

/-- FALSIFICATION: Removing an entity that participates in an active edge returns .fail. -/
theorem CX_03_incident_node_removal_rejected :
    ∃ reason, step (.graphOp (.removeNode ⟨"e_dup"⟩)) stateWithIncidentEdge testContext =
      .fail stateWithIncidentEdge testContext reason := by
  dsimp [step, Hypergraph.step, stateWithIncidentEdge, incidentEdge, testNode,
         Hypergraph.NodeIds, checkNodeFreeOfEdges, testContext]
  exact ⟨"cannot remove node with incident hyperedges", rfl⟩

/-! ## CX-04: Conflicting Writes Do Not Commute -/

def opWriteA : Transformation :=
  .graphOp (.updateNodeValue ⟨"e_dup"⟩ (.int 10))

def opWriteB : Transformation :=
  .graphOp (.updateNodeValue ⟨"e_dup"⟩ (.int 20))

/-- FALSIFICATION: Order of conflicting write operations is observable (non-commutative). -/
theorem CX_04_conflicting_writes_do_not_commute :
    step (.atomicTx opWriteA opWriteB) testStateWithNode testContext ≠
    step (.atomicTx opWriteB opWriteA) testStateWithNode testContext := by
  dsimp [step, Hypergraph.step, opWriteA, opWriteB, testStateWithNode, testNode,
         Hypergraph.NodeIds, testContext]
  intro h
  injection h with h_state _
  injection h_state with h_nodes _ _
  injection h_nodes with h_head _
  injection h_head with _ _ h_val _
  nomatch h_val

/-! ## CX-05: Causality Is Distinct From Observational Shadows -/

/-- FACT: Value-trace sensitivity detects read-dependence where successor shadow is blind. -/
theorem CX_05_trace_shadow_incomparability :
    (¬ gOrderSensitive STC.Graph.Causal.CA.m STC.Graph.Causal.CA.TT.assertL STC.Graph.Causal.CA.TT.setA) ∧
    ((gOrderSensitive STC.Graph.Causal.Z.m STC.Graph.Causal.Z.TT.dbl STC.Graph.Causal.Z.TT.inc) ∧
     (¬ STC.Graph.Causal.traceSensitive STC.Graph.Causal.Z.m STC.Graph.Causal.Z.ρ0 STC.Graph.Causal.Z.TT.dbl STC.Graph.Causal.Z.TT.inc)) :=
  ⟨STC.Graph.Causal.CA.succ_shadow_blind,
   STC.Graph.Causal.Z.shadows_incomparable_1⟩

/-! ## CX-06: Hyperedge Fan-Out Breaks Functional Determinism -/

/-- FACT: Multi-endpoint fanout relation exits the functional composition subclass. -/
theorem CX_06_hyperedge_fanout_non_functional :
    ¬ succFunOnClass STC.Graph.Hyper.FAN.m
      STC.Graph.Hyper.FAN.TT.pick (0 : Int) (0 : Int) (0 : Int) :=
  STC.Graph.Hyper.FAN.not_succFun

end SCR.Algebra.Counterexamples
