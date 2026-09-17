// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Stability Analysis & Equilibrium Points
//!
//! Enforces DYNAMICS-INV-013 (Stability Integrity).
//!
//! Semantic stability is distinguishable from numerical integration stability.

use crate::id::AttractorId;
use crate::state::DynamicalState;

/// Qualitative classification of stability for dynamical states and invariant sets.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StabilityKind {
    AsymptoticallyStable,
    LyapunovStable,
    Unstable,
    LimitCycle,
    ChaoticAttractor,
}

/// An equilibrium or stationary point in state space where rates of change vanish: $\dot{x} = 0$.
#[derive(Debug, Clone, PartialEq)]
pub struct EquilibriumPoint {
    pub state: DynamicalState,
    pub stability: StabilityKind,
    pub tolerance: f64,
}

impl EquilibriumPoint {
    pub fn new(state: DynamicalState, stability: StabilityKind, tolerance: f64) -> Self {
        Self {
            state,
            stability,
            tolerance,
        }
    }

    /// Verifies if a given evaluated velocity vector satisfies the equilibrium condition $||\dot{x}|| \le \epsilon$.
    pub fn is_stationary(&self, velocity: &[f64]) -> bool {
        let norm_sq: f64 = velocity.iter().map(|v| v * v).sum();
        norm_sq.sqrt() <= self.tolerance
    }
}

/// An invariant attractor set in phase space toward which neighboring trajectories converge.
#[derive(Debug, Clone, PartialEq)]
pub struct Attractor {
    pub id: AttractorId,
    pub kind: StabilityKind,
    pub basin_of_attraction_radius: f64,
}
