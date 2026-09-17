// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Higher-Order Physical Interactions
//!
//! Enforces PHYSICS-INV-015 (Interaction Integrity).
//!
//! Physical interactions may involve multiple participants, media, forces, and fields
//! without mandatory pairwise reduction.

use crate::error::{PhysicsError, PhysicsResult};
use crate::id::{BodyId, InteractionId, LawId};
use crate::quantity::Quantity;
use scr_geometry::point::Point3D;

/// Classification of physical interaction.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InteractionKind {
    GravitationalNBody,
    ElectromagneticLorentz,
    ContactImpact,
    FluidDrag,
    ThermodynamicExchange,
}

/// A higher-order physical interaction entity.
#[derive(Debug, Clone, PartialEq)]
pub struct PhysicalInteraction {
    pub id: InteractionId,
    pub kind: InteractionKind,
    pub participants: Vec<BodyId>,
    pub medium: Option<String>,
    pub force: Quantity,
    pub location: Point3D,
    pub time: f64,
    pub governing_law: Option<LawId>,
}

impl PhysicalInteraction {
    pub fn new(
        id: InteractionId,
        kind: InteractionKind,
        participants: Vec<BodyId>,
        force: Quantity,
        location: Point3D,
        time: f64,
    ) -> PhysicsResult<Self> {
        if participants.is_empty() {
            return Err(PhysicsError::InvalidState(
                "Physical interaction must have at least one participant".to_string(),
            ));
        }

        Ok(Self {
            id,
            kind,
            participants,
            medium: None,
            force,
            location,
            time,
            governing_law: None,
        })
    }

    pub fn with_medium(mut self, medium: impl Into<String>) -> Self {
        self.medium = Some(medium.into());
        self
    }

    pub fn with_law(mut self, law_id: LawId) -> Self {
        self.governing_law = Some(law_id);
        self
    }
}
