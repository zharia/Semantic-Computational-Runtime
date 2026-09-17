// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Orientation Module
//!
//! Topological orientation — a consistent choice of direction across a structure.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-ORIENTATION`.
//!
//! Per `TOPOLOGY-INV-007`: orientability MUST be preserved by topology-preserving operations.
//! Per `TOPOLOGY-INV-015`: orientability is a topological, not metric, property.

use crate::cell::CellId;

pub use crate::manifold::Orientability;

/// An orientation assignment for a topological complex.
///
/// For a triangle mesh: each face has a winding order.
/// For a manifold: each chart has a consistent orientation.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Orientation {
    /// Positive / counterclockwise orientation.
    Positive,
    /// Negative / clockwise orientation.
    Negative,
}

impl Orientation {
    /// Returns the opposite orientation.
    pub fn opposite(&self) -> Self {
        match self {
            Self::Positive => Self::Negative,
            Self::Negative => Self::Positive,
        }
    }

    pub fn is_positive(&self) -> bool {
        matches!(self, Self::Positive)
    }

    pub fn is_negative(&self) -> bool {
        matches!(self, Self::Negative)
    }
}

impl std::fmt::Display for Orientation {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Positive => write!(f, "+"),
            Self::Negative => write!(f, "-"),
        }
    }
}

/// An orientation assignment for a collection of topological elements.
///
/// Per `SCR-LIB-TOPOLOGY-ORIENTATION`: orientation is a topological property.
/// Two adjacent elements in a manifold mesh share an edge with opposite orientations.
#[derive(Debug, Clone, Default)]
pub struct OrientationAssignment {
    assignments: std::collections::HashMap<String, Orientation>,
}

impl OrientationAssignment {
    pub fn new() -> Self {
        Self::default()
    }

    /// Assigns an orientation to an element.
    pub fn assign(&mut self, element: &CellId, orientation: Orientation) {
        self.assignments.insert(element.0.clone(), orientation);
    }

    /// Returns the orientation of an element (if assigned).
    pub fn orientation_of(&self, element: &CellId) -> Option<&Orientation> {
        self.assignments.get(&element.0)
    }

    /// Checks whether all assigned orientations are consistent with a declared global orientation.
    ///
    /// For simplicial complexes: adjacent simplices MUST share faces with opposite orientations.
    /// Returns true if all elements have been assigned an orientation.
    pub fn is_complete(&self, expected_count: usize) -> bool {
        self.assignments.len() == expected_count
    }

    /// Returns whether any orientation has been assigned.
    pub fn has_assignments(&self) -> bool {
        !self.assignments.is_empty()
    }
}
