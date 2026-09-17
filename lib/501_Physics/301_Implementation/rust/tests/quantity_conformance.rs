// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Quantity & Dimensional Conformance Tests
//!
//! Tests for dimensional analysis, unit compatibility, and physical quantity operations.

use scr_geometry::point::{Point3D, Vector3D};
use scr_physics::body::{KinematicState, PhysicalBody};
use scr_physics::id::BodyId;
use scr_physics::quantity::{Dimension, Quantity};

#[test]
fn test_dimensional_arithmetic_f_equals_m_a() {
    let mass = Quantity::mass(10.0); // 10 kg
    let accel = Quantity::new(2.5, Dimension::ACCELERATION, "m/s^2"); // 2.5 m/s^2

    // F = m * a
    let force = mass * accel;
    assert_eq!(force.dimension, Dimension::FORCE);
    assert!((force.value - 25.0).abs() < 1e-9);

    // E = F * d (Work = Force * displacement)
    let dist = Quantity::length(4.0); // 4 m
    let work = force * dist;
    assert_eq!(work.dimension, Dimension::ENERGY);
    assert!((work.value - 100.0).abs() < 1e-9);

    // Power = Work / time
    let time = Quantity::time(2.0); // 2 s
    let power = work / time;
    assert_eq!(power.dimension, Dimension::POWER);
    assert!((power.value - 50.0).abs() < 1e-9);
}

#[test]
fn test_quantity_addition_and_subtraction() {
    let q1 = Quantity::length(15.0);
    let q2 = Quantity::length(7.5);

    let sum = (q1.clone() + q2.clone()).unwrap();
    assert_eq!(sum.value, 22.5);
    assert_eq!(sum.dimension, Dimension::LENGTH);

    let diff = (q1 - q2).unwrap();
    assert_eq!(diff.value, 7.5);
    assert_eq!(diff.dimension, Dimension::LENGTH);

    // Incompatible addition (length + mass) must fail
    let mass = Quantity::mass(5.0);
    let invalid_add = Quantity::length(10.0) + mass;
    assert!(invalid_add.is_err());
}

#[test]
fn test_body_momentum_and_kinetic_energy() {
    let state = KinematicState {
        position: Point3D::new(0.0, 0.0, 0.0),
        velocity: Vector3D::new(3.0, 4.0, 0.0), // speed = 5 m/s
        orientation: scr_math::Quaternion::identity(),
        angular_velocity: Vector3D::ZERO,
    };

    let body = PhysicalBody::new(BodyId::new("projectile"), 2.0, state).unwrap();

    // Linear momentum: P = m * v = 2 * (3, 4, 0) = (6, 8, 0) -> norm = 10
    let momentum = body.linear_momentum();
    assert_eq!(momentum, Vector3D::new(6.0, 8.0, 0.0));
    assert!((momentum.norm() - 10.0).abs() < 1e-9);

    // Kinetic energy: 0.5 * m * v^2 = 0.5 * 2.0 * 25.0 = 25.0 Joules
    assert!((body.translational_kinetic_energy() - 25.0).abs() < 1e-9);
}
