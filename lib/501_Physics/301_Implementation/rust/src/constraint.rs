// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Physical Constraints
//!
//! Enforces PHYSICS-INV-005 (Constraint Integrity).

use crate::id::{BodyId, ConstraintId};
use scr_geometry::point::Point3D;

/// Classification of physical constraints.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConstraintKind {
    FixedDistanceJoint,
    FixedOrientation,
    UnilateralContactNonPenetration,
    PlanarBoundary,
}

/// A formal physical constraint acting upon one or more physical bodies.
#[derive(Debug, Clone, PartialEq)]
pub struct PhysicalConstraint {
    pub id: ConstraintId,
    pub kind: ConstraintKind,
    pub body_a: BodyId,
    pub body_b: Option<BodyId>,
    pub target_value: f64,
}

impl PhysicalConstraint {
    pub fn distance_joint(id: ConstraintId, body_a: BodyId, body_b: BodyId, distance: f64) -> Self {
        Self {
            id,
            kind: ConstraintKind::FixedDistanceJoint,
            body_a,
            body_b: Some(body_b),
            target_value: distance,
        }
    }

    /// Tests if a distance joint is satisfied within tolerance.
    pub fn is_distance_satisfied(&self, pos_a: &Point3D, pos_b: &Point3D, tolerance: f64) -> bool {
        let current_distance = (*pos_a - *pos_b).norm();
        (current_distance - self.target_value).abs() <= tolerance
    }
}
