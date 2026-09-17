// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Morphological Transformations & Lifecycle Dynamics
//!
//! Enforces MORPHOLOGY-INV-006 (Topological Integrity), MORPHOLOGY-INV-007 (Geometric Integrity),
//! MORPHOLOGY-INV-009 (Transformation Integrity), and MORPHOLOGY-INV-013 (Delta Integrity).

use crate::error::{MorphologyError, MorphologyResult};
use crate::id::ComponentId;
use crate::structure::PartWholeHierarchy;

/// The nature of morphological state change.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TransformationKind {
    Growth,
    Deformation,
    Erosion,
    Fracture,
    Composition,
}

/// Explicit preservation contract declared for a morphological transformation.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PreservationContract {
    pub preserves_topology: bool,
    pub preserves_geometry: bool,
    pub preserves_hierarchy: bool,
}

impl PreservationContract {
    pub const TOPOLOGY_PRESERVING: Self = Self {
        preserves_topology: true,
        preserves_geometry: false,
        preserves_hierarchy: true,
    };

    pub const RIGID: Self = Self {
        preserves_topology: true,
        preserves_geometry: true,
        preserves_hierarchy: true,
    };

    pub const TOPOLOGY_CHANGING: Self = Self {
        preserves_topology: false,
        preserves_geometry: false,
        preserves_hierarchy: false,
    };
}

/// A morphological transformation operator.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MorphologicalTransformation {
    pub kind: TransformationKind,
    pub contract: PreservationContract,
    pub description: String,
}

impl MorphologicalTransformation {
    pub fn new(
        kind: TransformationKind,
        contract: PreservationContract,
        description: impl Into<String>,
    ) -> Self {
        Self {
            kind,
            contract,
            description: description.into(),
        }
    }

    /// Validates a transformation against the current hierarchy state.
    pub fn validate(&self, hierarchy: &PartWholeHierarchy) -> MorphologyResult<()> {
        hierarchy.verify_integrity()?;

        // Fracture requires at least one component to fragment
        if self.kind == TransformationKind::Fracture && hierarchy.component_count() == 0 {
            return Err(MorphologyError::TransformationError(
                "Cannot apply fracture transformation to an empty morphology".to_string(),
            ));
        }

        // If transformation claims hierarchy preservation, fracture or violent accretion is forbidden
        if self.contract.preserves_hierarchy && self.kind == TransformationKind::Fracture {
            return Err(MorphologyError::InvariantViolation(
                "MORPHOLOGY-INV-009: Fracture alters structural hierarchy and cannot declare preserves_hierarchy=true".to_string(),
            ));
        }

        Ok(())
    }
}

/// A discrete semantic delta representing an atomic transition between morphological states (MORPHOLOGY-INV-013).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MorphologicalDelta {
    AddComponent { parent: Option<ComponentId>, child: ComponentId, name: String },
    RemoveComponent { id: ComponentId },
    ModifyLevelOfDetail { id: ComponentId, new_lod: usize },
}
