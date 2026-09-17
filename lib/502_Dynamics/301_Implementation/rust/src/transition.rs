// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # State Transitions & Semantic State Deltas
//!
//! Enforces DYNAMICS-INV-003 (Transition Integrity), DYNAMICS-INV-009 (Causal Integrity),
//! and DYNAMICS-INV-010 (Delta Integrity).

use crate::error::{DynamicsError, DynamicsResult};
use crate::id::{StateId, TransitionId};
use crate::state::DynamicalState;

/// A discrete semantic delta representing an atomic transition between dynamical states (DYNAMICS-INV-010).
#[derive(Debug, Clone, PartialEq)]
pub struct StateDelta {
    pub dt: f64,
    pub coordinate_deltas: Vec<f64>,
    pub new_mode: Option<usize>,
}

impl StateDelta {
    pub fn between(from: &DynamicalState, to: &DynamicalState) -> DynamicsResult<Self> {
        if from.dimension() != to.dimension() {
            return Err(DynamicsError::StateSpaceMismatch(
                "Cannot compute delta between states of different dimensions".to_string(),
            ));
        }

        let dt = to.time - from.time;
        if dt < 0.0 {
            return Err(DynamicsError::NonMonotonicTime(format!(
                "Negative time delta: t_to ({}) < t_from ({})",
                to.time, from.time
            )));
        }

        let coordinate_deltas: Vec<f64> = to
            .coordinates
            .iter()
            .zip(from.coordinates.iter())
            .map(|(a, b)| a - b)
            .sum_deltas();

        let new_mode = if to.discrete_mode != from.discrete_mode {
            Some(to.discrete_mode)
        } else {
            None
        };

        Ok(Self {
            dt,
            coordinate_deltas,
            new_mode,
        })
    }
}

trait SumDeltas: Iterator<Item = f64> {
    fn sum_deltas(self) -> Vec<f64>
    where
        Self: Sized,
    {
        self.collect()
    }
}
impl<I: Iterator<Item = f64>> SumDeltas for I {}

/// A formal transition linking an antecedent state to a successor state.
#[derive(Debug, Clone, PartialEq)]
pub struct StateTransition {
    pub id: TransitionId,
    pub from_state: StateId,
    pub to_state: StateId,
    pub delta: StateDelta,
    pub is_causal: bool,
}

impl StateTransition {
    pub fn new(
        id: TransitionId,
        from_state: StateId,
        to_state: StateId,
        delta: StateDelta,
        is_causal: bool,
    ) -> Self {
        Self {
            id,
            from_state,
            to_state,
            delta,
            is_causal,
        }
    }
}

/// An abstract continuous or discrete evolution rule: $\dot{x} = f(x, t)$ or $x_{k+1} = f(x_k)$.
#[derive(Debug, Clone, PartialEq)]
pub struct EvolutionLaw {
    pub name: String,
    pub is_continuous: bool,
    pub description: String,
}

impl EvolutionLaw {
    pub fn new(name: impl Into<String>, is_continuous: bool, description: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            is_continuous,
            description: description.into(),
        }
    }
}
