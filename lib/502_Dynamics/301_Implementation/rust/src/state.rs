// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Dynamical States & State Spaces
//!
//! Enforces DYNAMICS-INV-002 (State Integrity).
//!
//! Semantic state remains distinct from implementation-level memory representations.

use crate::error::{DynamicsError, DynamicsResult};
use crate::id::StateId;

/// An instantaneous semantic state of a dynamical system.
#[derive(Debug, Clone, PartialEq)]
pub struct DynamicalState {
    pub id: StateId,
    pub time: f64,
    pub coordinates: Vec<f64>,
    pub discrete_mode: usize,
}

impl DynamicalState {
    pub fn new(id: StateId, time: f64, coordinates: Vec<f64>) -> Self {
        Self {
            id,
            time,
            coordinates,
            discrete_mode: 0,
        }
    }

    pub fn with_mode(mut self, mode: usize) -> Self {
        self.discrete_mode = mode;
        self
    }

    pub fn dimension(&self) -> usize {
        self.coordinates.len()
    }

    /// Computes the Euclidean metric distance in state space to another state.
    pub fn distance_to(&self, other: &Self) -> DynamicsResult<f64> {
        if self.dimension() != other.dimension() {
            return Err(DynamicsError::StateSpaceMismatch(format!(
                "Cannot compute distance between states of dimension {} and {}",
                self.dimension(),
                other.dimension()
            )));
        }

        let sum_sq: f64 = self
            .coordinates
            .iter()
            .zip(other.coordinates.iter())
            .map(|(a, b)| (a - b) * (a - b))
            .sum();

        Ok(sum_sq.sqrt())
    }
}

/// The admissible state space manifold constraining dynamical states.
#[derive(Debug, Clone, PartialEq)]
pub struct StateSpace {
    pub dimension: usize,
    pub bounds_min: Vec<f64>,
    pub bounds_max: Vec<f64>,
}

impl StateSpace {
    pub fn unconstrained(dimension: usize) -> Self {
        Self {
            dimension,
            bounds_min: vec![f64::NEG_INFINITY; dimension],
            bounds_max: vec![f64::INFINITY; dimension],
        }
    }

    pub fn bounded(bounds_min: Vec<f64>, bounds_max: Vec<f64>) -> DynamicsResult<Self> {
        if bounds_min.len() != bounds_max.len() {
            return Err(DynamicsError::StateSpaceMismatch(
                "Min and max bounds must have identical dimensions".to_string(),
            ));
        }

        for (min, max) in bounds_min.iter().zip(bounds_max.iter()) {
            if min > max {
                return Err(DynamicsError::StateSpaceMismatch(format!(
                    "Min bound {} exceeds max bound {}",
                    min, max
                )));
            }
        }

        Ok(Self {
            dimension: bounds_min.len(),
            bounds_min,
            bounds_max,
        })
    }

    /// Verifies whether a state lies within this state space's declared bounds.
    pub fn contains_state(&self, state: &DynamicalState) -> bool {
        if state.dimension() != self.dimension {
            return false;
        }

        state
            .coordinates
            .iter()
            .zip(self.bounds_min.iter().zip(self.bounds_max.iter()))
            .all(|(&coord, (&min, &max))| coord >= min && coord <= max)
    }
}
