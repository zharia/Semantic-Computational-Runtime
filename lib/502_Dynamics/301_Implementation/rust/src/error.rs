// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DynamicsError {
    StateSpaceMismatch(String),
    NonMonotonicTime(String),
    ConstraintViolation(String),
    InvariantViolation(String),
    HypergraphError(String),
    InvalidTransition(String),
}

impl fmt::Display for DynamicsError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::StateSpaceMismatch(msg) => write!(f, "State space mismatch: {}", msg),
            Self::NonMonotonicTime(msg) => write!(f, "Non-monotonic temporal progression: {}", msg),
            Self::ConstraintViolation(msg) => write!(f, "Dynamical constraint violation: {}", msg),
            Self::InvariantViolation(msg) => write!(f, "Dynamics invariant violation: {}", msg),
            Self::HypergraphError(msg) => write!(f, "Hypergraph projection error: {}", msg),
            Self::InvalidTransition(msg) => write!(f, "Invalid state transition: {}", msg),
        }
    }
}

impl std::error::Error for DynamicsError {}

pub type DynamicsResult<T> = Result<T, DynamicsError>;
