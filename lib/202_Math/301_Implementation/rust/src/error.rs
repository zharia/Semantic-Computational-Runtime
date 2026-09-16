// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

/// Distinct error conditions across the SCR Mathematics semantic domain.
#[derive(Debug, Clone, PartialEq)]
pub enum MathError {
    DivisionByZero,
    DimensionMismatch { expected: String, actual: String },
    SingularMatrix(String),
    ConvergenceFailure(String),
    DomainViolation(String),
    ToleranceExceeded { bound: f64, actual: f64 },
    SemanticInvalidity(String),
}

impl fmt::Display for MathError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            MathError::DivisionByZero => write!(f, "Division by zero is undefined"),
            MathError::DimensionMismatch { expected, actual } => {
                write!(f, "Dimension mismatch: expected {}, got {}", expected, actual)
            }
            MathError::SingularMatrix(msg) => write!(f, "Singular matrix (non-invertible): {}", msg),
            MathError::ConvergenceFailure(msg) => write!(f, "Numerical convergence failed: {}", msg),
            MathError::DomainViolation(msg) => write!(f, "Mathematical domain violation: {}", msg),
            MathError::ToleranceExceeded { bound, actual } => {
                write!(f, "Tolerance exceeded: allowed {}, got {}", bound, actual)
            }
            MathError::SemanticInvalidity(msg) => write!(f, "Semantic validity violation: {}", msg),
        }
    }
}

impl std::error::Error for MathError {}

pub type Result<T> = std::result::Result<T, MathError>;
