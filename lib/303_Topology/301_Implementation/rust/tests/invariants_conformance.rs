// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Topology Invariant Conformance Tests
//!
//! Verifies TOPOLOGY-INV-001 through TOPOLOGY-INV-018.
//!
//! These are specification tests — they test semantic contracts, not merely
//! implementation details. Per SCR Rule 11: test contracts, not just implementations.

use scr_topology::cell::{CellDimension, CellId};
use scr_topology::connectivity::ConnectivityStructure;
use scr_topology::continuity::{ContinuityClass, ContinuityContract};
use scr_topology::delta::{TopologicalDelta, TopologicalDeltaKind};
use scr_topology::invariants::*;
use scr_topology::space::{TopologicalSpace, TopologyKind};
use scr_topology::transformation::{TopologicalTransformation, TransformationClass};

// ─── TOPOLOGY-INV-001: Identity ───────────────────────────────────────────────

#[test]
fn test_inv_001_valid_identity() {
    assert!(verify_topology_inv_001_identity("topo-space-001").is_ok());
    assert!(verify_topology_inv_001_identity("σ-complex-k3").is_ok());
}

#[test]
fn test_inv_001_empty_identity_rejected() {
    let result = verify_topology_inv_001_identity("");
    assert!(result.is_err());
    let result = verify_topology_inv_001_identity("   ");
    assert!(result.is_err());
}

// ─── TOPOLOGY-INV-002: Connectivity Integrity ─────────────────────────────────

#[test]
fn test_inv_002_connected_single_component() {
    let mut conn = ConnectivityStructure::new();
    let a = CellId::new("v0");
    let b = CellId::new("v1");
    let c = CellId::new("v2");
    conn.declare_adjacent(&a, &b);
    conn.declare_adjacent(&b, &c);

    // 1 component
    assert!(verify_topology_inv_002_connectivity_integrity(&conn, 1).is_ok());
}

#[test]
fn test_inv_002_two_components() {
    let mut conn = ConnectivityStructure::new();
    let a = CellId::new("v0");
    let b = CellId::new("v1");
    let c = CellId::new("v2");
    let d = CellId::new("v3");
    conn.declare_adjacent(&a, &b); // component A
    conn.declare_adjacent(&c, &d); // component B

    assert!(verify_topology_inv_002_connectivity_integrity(&conn, 2).is_ok());
    assert!(verify_topology_inv_002_connectivity_integrity(&conn, 1).is_err());
}

// ─── TOPOLOGY-INV-003: Incidence Integrity ────────────────────────────────────

#[test]
fn test_inv_003_vertex_has_no_incidence() {
    let elem = CellId::new("v0");
    // 0-cells have no boundary elements
    assert!(
        verify_topology_inv_003_incidence_integrity(&elem, CellDimension(0), &[], None).is_ok()
    );
}

#[test]
fn test_inv_003_vertex_with_boundary_rejected() {
    let elem = CellId::new("v0");
    let fake_bnd = vec![CellId::new("v1")];
    let result = verify_topology_inv_003_incidence_integrity(
        &elem,
        CellDimension(0),
        &fake_bnd,
        None,
    );
    assert!(result.is_err());
}

#[test]
fn test_inv_003_edge_incidence_count() {
    let elem = CellId::new("e0");
    let bnds = vec![CellId::new("v0"), CellId::new("v1")];
    // An edge has exactly 2 boundary vertices
    assert!(
        verify_topology_inv_003_incidence_integrity(&elem, CellDimension(1), &bnds, Some(2))
            .is_ok()
    );
    assert!(
        verify_topology_inv_003_incidence_integrity(&elem, CellDimension(1), &bnds, Some(3))
            .is_err()
    );
}

// ─── TOPOLOGY-INV-004: Boundary Integrity ─────────────────────────────────────

#[test]
fn test_inv_004_vertex_has_empty_boundary() {
    use scr_topology::boundary::Boundary;
    let bnd =
        Boundary::empty(CellId::new("v0"), CellDimension(0));
    assert!(verify_topology_inv_004_boundary_integrity(&bnd).is_ok());
}

#[test]
fn test_inv_004_vertex_nonempty_boundary_rejected() {
    use scr_topology::boundary::Boundary;
    let result = Boundary::new(
        CellId::new("v0"),
        CellDimension(0),
        vec![CellId::new("spurious")],
    );
    assert!(result.is_err());
}

#[test]
fn test_inv_004_edge_has_boundary() {
    use scr_topology::boundary::Boundary;
    let bnd = Boundary::new(
        CellId::new("e0"),
        CellDimension(1),
        vec![CellId::new("v0"), CellId::new("v1")],
    )
    .unwrap();
    assert_eq!(bnd.boundary_dimension(), Some(CellDimension(0)));
    assert!(verify_topology_inv_004_boundary_integrity(&bnd).is_ok());
}

// ─── TOPOLOGY-INV-005: Continuity Integrity ───────────────────────────────────

#[test]
fn test_inv_005_unverified_contract_fails() {
    let domain = TopologicalSpace::new(
        "dom",
        TopologyKind::Combinatorial,
        4,
        "Domain",
    )
    .unwrap();
    let codomain = TopologicalSpace::new(
        "cod",
        TopologyKind::Combinatorial,
        4,
        "Codomain",
    )
    .unwrap();
    let contract = ContinuityContract::new(
        "contract-01",
        domain,
        codomain,
        ContinuityClass::Homeomorphism,
    )
    .unwrap();

    let result = verify_topology_inv_005_continuity_integrity(&contract);
    assert!(result.is_err());
}

#[test]
fn test_inv_005_verified_contract_passes() {
    let domain = TopologicalSpace::new(
        "dom",
        TopologyKind::Combinatorial,
        4,
        "Domain",
    )
    .unwrap();
    let codomain = TopologicalSpace::new(
        "cod",
        TopologyKind::Combinatorial,
        4,
        "Codomain",
    )
    .unwrap();
    let mut contract = ContinuityContract::new(
        "contract-01",
        domain,
        codomain,
        ContinuityClass::Homeomorphism,
    )
    .unwrap();
    contract.mark_verified();

    assert!(verify_topology_inv_005_continuity_integrity(&contract).is_ok());
}

// ─── TOPOLOGY-INV-006: Equivalence Integrity ──────────────────────────────────

#[test]
fn test_inv_006_euler_equivalence_passes() {
    assert!(verify_topology_inv_006_equivalence_integrity("euler", 2, 2).is_ok());
}

#[test]
fn test_inv_006_euler_equivalence_mismatch() {
    let result = verify_topology_inv_006_equivalence_integrity("euler", 2, 0);
    assert!(result.is_err());
}

#[test]
fn test_inv_006_empty_relation_rejected() {
    let result = verify_topology_inv_006_equivalence_integrity("", 2, 2);
    assert!(result.is_err());
}

// ─── TOPOLOGY-INV-007: Invariant Integrity ────────────────────────────────────

#[test]
fn test_inv_007_declared_preservation_passes() {
    let t = TopologicalTransformation::preserving(
        "t-001",
        TransformationClass::Homeomorphism,
        vec!["euler-characteristic".to_string(), "genus".to_string()],
    )
    .unwrap();

    assert!(verify_topology_inv_007_invariant_integrity(&t, "euler-characteristic").is_ok());
    assert!(verify_topology_inv_007_invariant_integrity(&t, "genus").is_ok());
}

#[test]
fn test_inv_007_undeclared_invariant_fails() {
    let t = TopologicalTransformation::preserving(
        "t-001",
        TransformationClass::Homeomorphism,
        vec!["euler-characteristic".to_string()],
    )
    .unwrap();

    let result = verify_topology_inv_007_invariant_integrity(&t, "genus");
    assert!(result.is_err());
}

// ─── TOPOLOGY-INV-008: Transformation Integrity ───────────────────────────────

#[test]
fn test_inv_008_preserving_transformation_euler_consistent() {
    let t = TopologicalTransformation::preserving(
        "t-001",
        TransformationClass::Homeomorphism,
        vec!["euler-characteristic".to_string()],
    )
    .unwrap();

    // Euler characteristic preserved
    assert!(verify_topology_inv_008_transformation_integrity(&t, 2, 2).is_ok());
}

#[test]
fn test_inv_008_preserving_transformation_euler_changed_fails() {
    let t = TopologicalTransformation::preserving(
        "t-001",
        TransformationClass::Homeomorphism,
        vec!["euler-characteristic".to_string()],
    )
    .unwrap();

    // Euler characteristic changed despite preservation claim → violation
    let result = verify_topology_inv_008_transformation_integrity(&t, 2, 0);
    assert!(result.is_err());
}

#[test]
fn test_inv_008_topology_changing_euler_change_allowed() {
    let t = TopologicalTransformation::topology_changing(
        "t-002",
        "merge-components",
        "β₀ decreases by 1",
    )
    .unwrap();

    // Topology-changing transformation may change Euler characteristic
    assert!(verify_topology_inv_008_transformation_integrity(&t, 2, 1).is_ok());
}

// ─── TOPOLOGY-INV-012: Delta Integrity ───────────────────────────────────────

#[test]
fn test_inv_012_topology_changing_delta_rejected_when_preserving_required() {
    let delta = TopologicalDelta::new(
        "delta-01",
        TopologicalDeltaKind::MergeComponent,
        vec![CellId::new("comp-A"), CellId::new("comp-B")],
        None,
    )
    .unwrap();

    let result = delta.assert_preserving();
    assert!(result.is_err());
}

#[test]
fn test_inv_012_add_element_delta_is_valid() {
    let delta = TopologicalDelta::new(
        "delta-02",
        TopologicalDeltaKind::AddElement,
        vec![CellId::new("v-new")],
        Some("from-source-complex".to_string()),
    )
    .unwrap();

    assert!(verify_topology_inv_012_delta_integrity(&delta).is_ok());
}

// ─── TOPOLOGY-INV-013..018: Authority Invariants ──────────────────────────────

#[test]
fn test_inv_014_representation_cannot_claim_authority() {
    let result = verify_topology_inv_014_representation_independence("OBJ-mesh", true);
    assert!(result.is_err());
}

#[test]
fn test_inv_014_representation_as_carrier_is_fine() {
    assert!(
        verify_topology_inv_014_representation_independence("OBJ-mesh", false).is_ok()
    );
}

#[test]
fn test_inv_016_provider_cannot_claim_authority() {
    let result = verify_topology_inv_016_provider_independence("geogram-library", true);
    assert!(result.is_err());
}

#[test]
fn test_inv_017_rendering_cannot_define_topology() {
    let result = verify_topology_inv_017_rendering_independence("OpenGL", true);
    assert!(result.is_err());
}

#[test]
fn test_inv_018_storage_cannot_define_topology() {
    let result = verify_topology_inv_018_storage_independence("VDB-file", true);
    assert!(result.is_err());
}

#[test]
fn test_authority_invariants_aggregated() {
    assert!(verify_topology_authority_invariants("any-system", false).is_ok());
    assert!(verify_topology_authority_invariants("any-system", true).is_err());
}
