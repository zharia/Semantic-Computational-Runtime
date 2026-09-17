// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PhysicsError {
    DimensionMismatch(String),
    UnitMismatch(String),
    ConservationViolation(String),
    ConstraintViolation(String),
    InvariantViolation(String),
    HypergraphError(String),
    InvalidState(String),
}

impl fmt::Display for PhysicsError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::DimensionMismatch(msg) => write!(f, "Physical dimension mismatch: {}", msg),
            Self::UnitMismatch(msg) => write!(f, "Physical unit mismatch: {}", msg),
            Self::ConservationViolation(msg) => write!(f, "Conservation law violation: {}", msg),
            Self::ConstraintViolation(msg) => write!(f, "Physical constraint violation: {}", msg),
            Self::InvariantViolation(msg) => write!(f, "Physics invariant violation: {}", msg),
            Self::HypergraphError(msg) => write!(f, "Hypergraph projection error: {}", msg),
            Self::InvalidState(msg) => write!(f, "Invalid physical state: {}", msg),
        }
    }
}

impl std::error::Error for PhysicsError {}

pub type PhysicsResult<T> = Result<T, PhysicsError>;
