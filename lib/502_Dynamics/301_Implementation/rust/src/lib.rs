// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Dynamics Foundation (`SCR-LIB-DYNAMICS`)
//!
//! Authoritative Normative Dynamics Semantic Domain implementation for SCR.
//!
//! Conforms to `lib/502_Dynamics/101_definition.md`.

pub mod error;
pub mod hypergraph;
pub mod id;
pub mod invariants;
pub mod stability;
pub mod state;
pub mod system;
pub mod transition;

pub use error::{DynamicsError, DynamicsResult};
pub use hypergraph::project_system_to_hypergraph;
pub use id::{AttractorId, StateId, SystemId, TrajectoryId, TransitionId};
pub use stability::{Attractor, EquilibriumPoint, StabilityKind};
pub use state::{DynamicalState, StateSpace};
pub use system::{DynamicalSystem, Trajectory};
pub use transition::{EvolutionLaw, StateDelta, StateTransition};
