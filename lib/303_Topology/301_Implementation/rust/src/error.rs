// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Topology Error Types
//!
//! Error types for SCR Topology operations. Distinct from geometry errors:
//! topology errors concern structural/relational violations, not metric ones.

use std::fmt;

/// Errors that may arise in SCR Topology computations.
#[derive(Debug, Clone, PartialEq)]
pub enum TopologyError {
    /// A declared topological invariant was violated.
    InvariantViolation(String),

    /// A structural relationship (adjacency, incidence, boundary) is inconsistent.
    StructuralInconsistency(String),

    /// An element index or reference is out of bounds or invalid.
    InvalidElement(String),

    /// An operation is not valid for the declared topology or structure.
    InvalidOperation(String),

    /// A continuity contract was violated.
    ContinuityViolation(String),

    /// A topology-changing delta was applied where preservation was required.
    UnexpectedTopologyChange(String),

    /// An element was not found in the expected structure.
    ElementNotFound(String),

    /// Dimension mismatch between expected and actual.
    DimensionMismatch { expected: usize, found: usize },

    /// Hypergraph projection error.
    HypergraphMappingError(String),
}

impl fmt::Display for TopologyError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvariantViolation(msg) => write!(f, "Topological invariant violation: {}", msg),
            Self::StructuralInconsistency(msg) => {
                write!(f, "Topological structural inconsistency: {}", msg)
            }
            Self::InvalidElement(msg) => write!(f, "Invalid topological element: {}", msg),
            Self::InvalidOperation(msg) => write!(f, "Invalid topological operation: {}", msg),
            Self::ContinuityViolation(msg) => write!(f, "Continuity violation: {}", msg),
            Self::UnexpectedTopologyChange(msg) => {
                write!(f, "Unexpected topology change: {}", msg)
            }
            Self::ElementNotFound(msg) => write!(f, "Topological element not found: {}", msg),
            Self::DimensionMismatch { expected, found } => write!(
                f,
                "Dimension mismatch: expected {}, found {}",
                expected, found
            ),
            Self::HypergraphMappingError(msg) => write!(f, "Hypergraph mapping error: {}", msg),
        }
    }
}

impl std::error::Error for TopologyError {}

/// Convenience alias for topology operation results.
pub type TopologyResult<T> = Result<T, TopologyError>;
