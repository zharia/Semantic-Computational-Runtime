// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Physical Bodies & Kinematic States
//!
//! Enforces PHYSICS-INV-004 (State Integrity) and PHYSICS-INV-010 (Reference Integrity).

use crate::error::{PhysicsError, PhysicsResult};
use crate::id::BodyId;
use scr_geometry::point::{Point3D, Vector3D};
use scr_math::Quaternion;

/// Kinematic state of a physical entity (position, velocity, orientation, angular velocity).
#[derive(Debug, Clone, PartialEq)]
pub struct KinematicState {
    pub position: Point3D,
    pub velocity: Vector3D,
    pub orientation: Quaternion,
    pub angular_velocity: Vector3D,
}

impl KinematicState {
    pub fn at_rest(position: Point3D) -> Self {
        Self {
            position,
            velocity: Vector3D::ZERO,
            orientation: Quaternion::identity(),
            angular_velocity: Vector3D::ZERO,
        }
    }
}

/// A physical body possessing mass, inertia, bounds, and kinematic state.
#[derive(Debug, Clone, PartialEq)]
pub struct PhysicalBody {
    pub id: BodyId,
    pub mass: f64,
    pub center_of_mass: Point3D,
    pub state: KinematicState,
}

impl PhysicalBody {
    pub fn new(id: BodyId, mass: f64, state: KinematicState) -> PhysicsResult<Self> {
        if mass <= 0.0 {
            return Err(PhysicsError::InvalidState(format!(
                "Physical body {} must have positive non-zero mass, got {}",
                id, mass
            )));
        }

        let center_of_mass = state.position;
        Ok(Self {
            id,
            mass,
            center_of_mass,
            state,
        })
    }

    /// Linear momentum vector: $P = m \cdot v$.
    pub fn linear_momentum(&self) -> Vector3D {
        self.state.velocity * self.mass
    }

    /// Translational kinetic energy: $E_k = \frac{1}{2} m v^2$.
    pub fn translational_kinetic_energy(&self) -> f64 {
        0.5 * self.mass * self.state.velocity.norm_squared()
    }
}
