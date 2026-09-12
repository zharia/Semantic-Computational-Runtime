//===- SCRVerification.td - SCR Verification Rules -*- tablegen -*-===//
//
// Verification pass definitions for the SCR dialect.
// Each rule traces to a Lean theorem or algebra invariant.
//
//===------------------------------------------------------===//

include "SCRDialect.td"
include "SCRTypes.td"
include "SCROperations.td"

//===------------------------------------------------------===//
// Verification Pass: IncidenceWellFormed
//===------------------------------------------------------===//

def SCR_IncidenceWellFormedPass : Pass<"scr-verify-incidence", "scr::SCRDialect"> {
  let summary = "Verify IncidenceWellFormed invariant on !scr.hypergraph.";
  let description = [{
    Checks that every hyperedge's role targets reference entities
    present in the hypergraph's node set.

    Invariant:
      ∀ e ∈ hypergraph.edges,
        ∀ r ∈ e.roles,
          r.target ∈ hypergraph.nodes.id

    Source: SCR.Hypergraph.IncidenceWellFormed
    Formal: isAdmissible includes IncidenceWellFormed

    Applied after every operation that returns !scr.hypergraph.
  }];

  let dependentDialects = [SCRDialect];

  let constructor = [{ return std::make_unique<SCR::IncidenceWellFormedPass>(); }];
}

//===------------------------------------------------------===//
// Verification Pass: TimeMonotonicity
//===------------------------------------------------------===//

def SCR_TimeMonotonicityPass : Pass<"scr-verify-time", "scr::SCRDialect"> {
  let summary = "Verify logical time advancement on successful operations.";
  let description = [{
    Checks that successful hypergraph operations advance logicalStep.

    Invariant:
      On success: result.logicalStep ≥ input.logicalStep + 1
      On failure: result.logicalStep = input.logicalStep

    Source: step_advances_time, step_preserves_time_on_failure
  }];

  let dependentDialects = [SCRDialect];

  let constructor = [{ return std::make_unique<SCR::TimeMonotonicityPass>(); }];
}

//===------------------------------------------------======//
// Verification Pass: IdentityPreservation
//===------------------------------------------------=========//

def SCR_IdentityPreservationPass : Pass<"scr-verify-identity", "scr::SCRDialect"> {
  let summary = "Verify entity identity preservation on value updates.";
  let description = [{
    Checks that scr.update_node_value does not change entity id.

    Invariant:
      result.nodes[entity_id].id = entity_id

    Source: node_identity_invariant
    Formal: { n with value := v }.id = n.id
  }];

  let dependentDialects = [SCRDialect];

  let constructor = [{ return std::make_unique<SCR::IdentityPreservationPass>(); }];
}

//===------------------------------------------------------===//
// Verification Pass: DanglingReference
//===------------------------------------------------------===//

def SCR_DanglingReferencePass : Pass<"scr-verify-dangling", "scr::SCRDialect"> {
  let summary = "Verify no dangling hyperedge references.";
  let description = [{
    Checks that no hyperedge references entities that do not exist.
    Complements IncidenceWellFormed by checking at operation boundaries.

    Invariant:
      ∀ e ∈ hypergraph.edges,
        ∀ r ∈ e.roles,
          r.target ∈ hypergraph.nodes.id

    Source: CX_02_dangling_edge_rejected, CX_03_incident_node_removal_rejected
  }];

  let dependentDialects = [SCRDialect];

  let constructor = [{ return std::make_unique<SCR::DanglingReferencePass>(); }];
}

//===------------------------------------------------------===//
// Combined Verification Pipeline
//===------------------------------------------------------===//

def SCR_VerifyPass : Pass<"scr-verify", "scr::SCRDialect"> {
  let summary = "Run all SCR verification passes.";
  let description = [{
    Combined pass that runs:
      1. IncidenceWellFormed
      2. TimeMonotonicity
      3. IdentityPreservation
      4. DanglingReference

    Ensures the hypergraph satisfies all algebraic invariants.
  }];

  let dependentDialects = [SCRDialect];

  let constructor = [{ return std::make_unique<SCR::VerifyPass>(); }];
}
