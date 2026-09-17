// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MorphologyError {
    InvalidStructure(String),
    CycleDetected(String),
    PartNotFound(String),
    PatternMismatch(String),
    InvariantViolation(String),
    TransformationError(String),
    HypergraphError(String),
}

impl fmt::Display for MorphologyError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidStructure(msg) => write!(f, "Invalid morphological structure: {}", msg),
            Self::CycleDetected(msg) => write!(f, "Cycle detected in part-whole hierarchy: {}", msg),
            Self::PartNotFound(msg) => write!(f, "Component part not found: {}", msg),
            Self::PatternMismatch(msg) => write!(f, "Pattern consistency mismatch: {}", msg),
            Self::InvariantViolation(msg) => write!(f, "Morphology invariant violation: {}", msg),
            Self::TransformationError(msg) => write!(f, "Morphological transformation error: {}", msg),
            Self::HypergraphError(msg) => write!(f, "Hypergraph projection error: {}", msg),
        }
    }
}

impl std::error::Error for MorphologyError {}

pub type MorphologyResult<T> = Result<T, MorphologyError>;
