// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Physics Invariant Conformance Tests
//!
//! Specification tests verifying PHYSICS-INV-001 through PHYSICS-INV-018.

use scr_geometry::point::Point3D;
use scr_physics::body::{KinematicState, PhysicalBody};
use scr_physics::constraint::PhysicalConstraint;
use scr_physics::id::{BodyId, ConstraintId, LawId, PhysicsEntityId};
use scr_physics::invariants::*;
use scr_physics::law::{ConservationContract, ConservationKind, PhysicalLaw};
use scr_physics::quantity::{Dimension, Quantity};

#[test]
fn test_inv_001_semantic_primacy() {
    let valid_id = PhysicsEntityId::new("phys:pendulum:001");
    assert!(verify_physics_inv_001_semantic_primacy(&valid_id).is_ok());

    let empty_id = PhysicsEntityId::new("   ");
    assert!(verify_physics_inv_001_semantic_primacy(&empty_id).is_err());
}

#[test]
fn test_inv_002_quantity_integrity() {
    let q = Quantity::force(9.81);
    assert!(verify_physics_inv_002_quantity_integrity(&q).is_ok());

    let q_nan = Quantity::new(f64::NAN, Dimension::FORCE, "N");
    assert!(verify_physics_inv_002_quantity_integrity(&q_nan).is_err());

    let q_no_unit = Quantity::new(10.0, Dimension::MASS, " ");
    assert!(verify_physics_inv_002_quantity_integrity(&q_no_unit).is_err());
}

#[test]
fn test_inv_003_law_integrity() {
    let law = PhysicalLaw::new(
        LawId::new("law:newton_second"),
        "Newton's Second Law of Motion",
        "Classical non-relativistic mechanics (v << c)",
    );
    assert!(verify_physics_inv_003_law_integrity(&law).is_ok());

    let empty_law = PhysicalLaw::new(LawId::new("law:unnamed"), "", "Any");
    assert!(verify_physics_inv_003_law_integrity(&empty_law).is_err());
}

#[test]
fn test_inv_004_state_integrity() {
    let state = KinematicState::at_rest(Point3D::new(0.0, 1.0, 0.0));
    let body = PhysicalBody::new(BodyId::new("body:block"), 5.0, state).unwrap();
    assert!(verify_physics_inv_004_state_integrity(&body).is_ok());

    // Negative mass fails
    let bad_body = PhysicalBody::new(BodyId::new("body:bad"), -1.0, KinematicState::at_rest(Point3D::ORIGIN));
    assert!(bad_body.is_err());
}

#[test]
fn test_inv_005_constraint_integrity() {
    let p_a = Point3D::new(0.0, 0.0, 0.0);
    let p_b = Point3D::new(2.0, 0.0, 0.0);

    let joint = PhysicalConstraint::distance_joint(
        ConstraintId::new("joint:rigid_rod"),
        BodyId::new("body_a"),
        BodyId::new("body_b"),
        2.0,
    );

    // Distance 2.0 satisfied with tolerance 1e-4
    assert!(verify_physics_inv_005_constraint_integrity(&joint, &p_a, Some(&p_b), 1e-4).is_ok());

    // Point moved to 2.5 violates constraint
    let p_b_moved = Point3D::new(2.5, 0.0, 0.0);
    assert!(verify_physics_inv_005_constraint_integrity(&joint, &p_a, Some(&p_b_moved), 1e-4).is_err());
}

#[test]
fn test_inv_006_conservation_integrity() {
    let energy_contract = ConservationContract::new(ConservationKind::Energy, 1e-6);

    // Exact conservation
    assert!(verify_physics_inv_006_conservation_integrity(&energy_contract, 100.0, 100.0000001).is_ok());

    // Numerical drift exceeding tolerance fails
    assert!(verify_physics_inv_006_conservation_integrity(&energy_contract, 100.0, 100.05).is_err());
}

#[test]
fn test_inv_007_model_validity() {
    let law = PhysicalLaw::new(
        LawId::new("law:ideal_gas"),
        "Ideal Gas Law",
        "Low density, moderate temperature, non-interacting point molecules",
    );
    assert!(verify_physics_inv_007_model_validity(&law).is_ok());

    let law_no_domain = PhysicalLaw::new(LawId::new("law:unknown"), "Hypothetical Law", "   ");
    assert!(verify_physics_inv_007_model_validity(&law_no_domain).is_err());
}

#[test]
fn test_inv_008_009_010_representation_provider_reference_independence() {
    assert!(verify_physics_inv_008_representation_independence("TensorRepresentation").is_ok());
    assert!(verify_physics_inv_008_representation_independence("").is_err());

    assert!(verify_physics_inv_009_provider_independence("ProviderPhysX").is_ok());
    assert!(verify_physics_inv_009_provider_independence("").is_err());

    assert!(verify_physics_inv_010_reference_integrity("InertialEarthCentered").is_ok());
    assert!(verify_physics_inv_010_reference_integrity("   ").is_err());
}

#[test]
fn test_inv_011_temporal_integrity() {
    assert!(verify_physics_inv_011_temporal_integrity(0.001).is_ok());
    assert!(verify_physics_inv_011_temporal_integrity(-0.01).is_err());
    assert!(verify_physics_inv_011_temporal_integrity(0.0).is_err());
}

#[test]
fn test_inv_012_uncertainty_integrity() {
    let q_with_uncertainty = Quantity::length(10.0).with_uncertainty(0.02);
    assert!(verify_physics_inv_012_uncertainty_integrity(&q_with_uncertainty).is_ok());

    let q_bad_uncertainty = Quantity::length(10.0).with_uncertainty(-0.5);
    assert!(verify_physics_inv_012_uncertainty_integrity(&q_bad_uncertainty).is_err());
}

#[test]
fn test_inv_013_approximation_integrity() {
    assert!(verify_physics_inv_013_approximation_integrity(false, None).is_ok());
    assert!(verify_physics_inv_013_approximation_integrity(true, Some(0.001)).is_ok());
    assert!(verify_physics_inv_013_approximation_integrity(true, None).is_err());
}

#[test]
fn test_inv_014_dimensional_integrity() {
    assert!(verify_physics_inv_014_dimensional_integrity(&Dimension::FORCE, &Dimension::FORCE).is_ok());
    assert!(verify_physics_inv_014_dimensional_integrity(&Dimension::FORCE, &Dimension::ENERGY).is_err());
}

#[test]
fn test_inv_015_016_017_018_interaction_provenance_equivalence_runtime() {
    let p1 = BodyId::new("b1");
    let inter = scr_physics::interaction::PhysicalInteraction::new(
        scr_physics::id::InteractionId::new("int:gravity"),
        scr_physics::interaction::InteractionKind::GravitationalNBody,
        vec![p1],
        Quantity::force(100.0),
        Point3D::ORIGIN,
        0.0,
    ).unwrap();
    assert!(verify_physics_inv_015_interaction_integrity(&inter).is_ok());

    assert!(verify_physics_inv_016_provenance_integrity(Some("experiment://cern_lhc_run3")).is_ok());
    assert!(verify_physics_inv_016_provenance_integrity(None).is_err());

    assert!(verify_physics_inv_017_equivalence_integrity("NonRelativisticApproximation(v < 0.01c)").is_ok());
    assert!(verify_physics_inv_017_equivalence_integrity("  ").is_err());

    assert!(verify_physics_inv_018_runtime_independence("CudaComputeSubstrate").is_ok());
    assert!(verify_physics_inv_018_runtime_independence("").is_err());
}
