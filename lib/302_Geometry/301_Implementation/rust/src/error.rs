// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub enum GeometryError {
    DimensionMismatch {
        expected: usize,
        found: usize,
    },
    DegenerateEntity(String),
    InvalidOperation(String),
    InvariantViolation(String),
    ToleranceExceeded {
        expected: f64,
        actual: f64,
    },
    HypergraphMappingError(String),
    ConversionError(String),
}

impl fmt::Display for GeometryError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::DimensionMismatch { expected, found } => {
                write!(f, "Dimension mismatch: expected {}, found {}", expected, found)
            }
            Self::DegenerateEntity(msg) => write!(f, "Degenerate geometric entity: {}", msg),
            Self::InvalidOperation(msg) => write!(f, "Invalid geometric operation: {}", msg),
            Self::InvariantViolation(msg) => write!(f, "Geometric invariant violation: {}", msg),
            Self::ToleranceExceeded { expected, actual } => {
                write!(f, "Tolerance exceeded: expected <= {}, got {}", expected, actual)
            }
            Self::HypergraphMappingError(msg) => write!(f, "Hypergraph mapping error: {}", msg),
            Self::ConversionError(msg) => write!(f, "Conversion error: {}", msg),
        }
    }
}

impl std::error::Error for GeometryError {}

pub type GeometryResult<T> = Result<T, GeometryError>;
