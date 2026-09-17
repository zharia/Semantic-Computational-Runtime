// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Physics Hypergraph Projection Tests
//!
//! Verifies canonical hypergraph projection of multi-body interactions conforming to Section
//! on Semantic Hypergraph Integration of `lib/501_Physics/101_definition.md`.

use scr_geometry::point::Point3D;
use scr_hypergraph::Hypergraph;
use scr_physics::body::{KinematicState, PhysicalBody};
use scr_physics::hypergraph::project_interaction_to_hypergraph;
use scr_physics::id::{BodyId, InteractionId, LawId, PhysicsEntityId};
use scr_physics::interaction::{InteractionKind, PhysicalInteraction};
use scr_physics::law::PhysicalLaw;
use scr_physics::quantity::Quantity;

#[test]
fn test_project_multi_body_interaction_to_hypergraph() {
    let mut hg = Hypergraph::new();

    let model_id = PhysicsEntityId::new("phys_system:binary_orbit");

    let b1 = PhysicalBody::new(
        BodyId::new("star_alpha"),
        1.989e30,
        KinematicState::at_rest(Point3D::new(-1e11, 0.0, 0.0)),
    ).unwrap();

    let b2 = PhysicalBody::new(
        BodyId::new("star_beta"),
        1.5e30,
        KinematicState::at_rest(Point3D::new(1e11, 0.0, 0.0)),
    ).unwrap();

    let interaction = PhysicalInteraction::new(
        InteractionId::new("int:mutual_gravitation"),
        InteractionKind::GravitationalNBody,
        vec![b1.id.clone(), b2.id.clone()],
        Quantity::force(6.674e25),
        Point3D::ORIGIN,
        0.0,
    ).unwrap().with_medium("Vacuum");

    let law = PhysicalLaw::new(
        LawId::new("law:universal_gravitation"),
        "Newton's Law of Universal Gravitation",
        "Celestial mechanics, weak gravitational fields",
    );

    project_interaction_to_hypergraph(
        &model_id,
        &[b1, b2],
        &interaction,
        Some(&law),
        &mut hg,
    ).unwrap();

    // Verify elements: model (1) + bodies (2) + force (1) + law (1) = 5
    assert!(hg.elements().count() >= 5);

    // Verify relations: contains_body (2) + interaction (1) + governs (1) = 4
    assert!(hg.relations().count() >= 4);
}

#[test]
fn test_idempotent_physics_projection() {
    let mut hg = Hypergraph::new();

    let model_id = PhysicsEntityId::new("phys_system:single_body");
    let b1 = PhysicalBody::new(
        BodyId::new("mass_point"),
        10.0,
        KinematicState::at_rest(Point3D::ORIGIN),
    ).unwrap();

    let interaction = PhysicalInteraction::new(
        InteractionId::new("int:self_damping"),
        InteractionKind::FluidDrag,
        vec![b1.id.clone()],
        Quantity::force(1.5),
        Point3D::ORIGIN,
        0.0,
    ).unwrap();

    // Project once
    project_interaction_to_hypergraph(&model_id, &[b1.clone()], &interaction, None, &mut hg).unwrap();
    let elem_count_1 = hg.elements().count();
    let rel_count_1 = hg.relations().count();

    // Project again
    project_interaction_to_hypergraph(&model_id, &[b1], &interaction, None, &mut hg).unwrap();
    let elem_count_2 = hg.elements().count();
    let rel_count_2 = hg.relations().count();

    assert_eq!(elem_count_1, elem_count_2);
    assert_eq!(rel_count_1, rel_count_2);
}
