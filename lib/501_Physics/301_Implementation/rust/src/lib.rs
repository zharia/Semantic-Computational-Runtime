// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Physics Foundation (`SCR-LIB-PHYSICS`)
//!
//! Authoritative Normative Physics Semantic Domain implementation for SCR.
//!
//! Conforms to `lib/501_Physics/101_definition.md`.

pub mod body;
pub mod constraint;
pub mod error;
pub mod hypergraph;
pub mod id;
pub mod invariants;
pub mod interaction;
pub mod law;
pub mod quantity;

pub use body::{KinematicState, PhysicalBody};
pub use constraint::{ConstraintKind, PhysicalConstraint};
pub use error::{PhysicsError, PhysicsResult};
pub use hypergraph::project_interaction_to_hypergraph;
pub use id::{BodyId, ConstraintId, InteractionId, LawId, PhysicsEntityId, QuantityId};
pub use interaction::{InteractionKind, PhysicalInteraction};
pub use law::{ConservationContract, ConservationKind, PhysicalLaw};
pub use quantity::{Dimension, Quantity};
