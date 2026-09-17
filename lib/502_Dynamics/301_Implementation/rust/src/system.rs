// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Dynamical Systems & Temporal Trajectories
//!
//! Enforces DYNAMICS-INV-004 (Temporal Integrity), DYNAMICS-INV-005 (Evolution Integrity),
//! and DYNAMICS-INV-011 (History Integrity).

use crate::error::{DynamicsError, DynamicsResult};
use crate::id::{SystemId, TrajectoryId};
use crate::state::{DynamicalState, StateSpace};
use crate::transition::EvolutionLaw;

/// An ordered sequence of states representing a system's temporal evolution (DYNAMICS-INV-004, 011).
#[derive(Debug, Clone, PartialEq)]
pub struct Trajectory {
    pub id: TrajectoryId,
    pub states: Vec<DynamicalState>,
}

impl Trajectory {
    pub fn new(id: TrajectoryId, initial_state: DynamicalState) -> Self {
        Self {
            id,
            states: vec![initial_state],
        }
    }

    /// Appends a state enforcing strict temporal progression $t_{k+1} > t_k$ (DYNAMICS-INV-004).
    pub fn append(&mut self, next_state: DynamicalState) -> DynamicsResult<()> {
        if let Some(last) = self.states.last() {
            if next_state.time <= last.time {
                return Err(DynamicsError::NonMonotonicTime(format!(
                    "DYNAMICS-INV-004: Next state time {} <= current state time {}",
                    next_state.time, last.time
                )));
            }
            if next_state.dimension() != last.dimension() {
                return Err(DynamicsError::StateSpaceMismatch(format!(
                    "Next state dimension {} != trajectory dimension {}",
                    next_state.dimension(),
                    last.dimension()
                )));
            }
        }

        self.states.push(next_state);
        Ok(())
    }

    pub fn state_count(&self) -> usize {
        self.states.len()
    }

    pub fn start_time(&self) -> Option<f64> {
        self.states.first().map(|s| s.time)
    }

    pub fn end_time(&self) -> Option<f64> {
        self.states.last().map(|s| s.time)
    }

    pub fn duration(&self) -> f64 {
        match (self.start_time(), self.end_time()) {
            (Some(t0), Some(t1)) => t1 - t0,
            _ => 0.0,
        }
    }
}

/// A formal dynamical system entity combining state space, evolution laws, and trajectory histories.
#[derive(Debug, Clone, PartialEq)]
pub struct DynamicalSystem {
    pub id: SystemId,
    pub state_space: StateSpace,
    pub law: EvolutionLaw,
    pub is_deterministic: bool,
    pub trajectories: Vec<Trajectory>,
}

impl DynamicalSystem {
    pub fn new(
        id: SystemId,
        state_space: StateSpace,
        law: EvolutionLaw,
        is_deterministic: bool,
    ) -> Self {
        Self {
            id,
            state_space,
            law,
            is_deterministic,
            trajectories: Vec::new(),
        }
    }

    pub fn add_trajectory(&mut self, trajectory: Trajectory) -> DynamicsResult<()> {
        for state in &trajectory.states {
            if !self.state_space.contains_state(state) {
                return Err(DynamicsError::ConstraintViolation(format!(
                    "Trajectory state {} lies outside declared state space bounds",
                    state.id
                )));
            }
        }
        self.trajectories.push(trajectory);
        Ok(())
    }
}
