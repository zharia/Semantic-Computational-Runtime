// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

/// Distinct error conditions across the SCR Interfaces semantic domain.
///
/// In accordance with INTERFACE-INV-009, material failure modes MUST be
/// explicitly represented in the error contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum InterfaceError {
    PreconditionViolated(String),
    PostconditionViolated(String),
    InvariantViolated(String),
    IncompatibleInterface(String),
    SubstitutabilityViolation(String),
    UndeclaredEffect(String),
    TypeMismatch { expected: String, actual: String },
    CapabilityMissing(String),
    ProviderError(String),
    SemanticInvalidity(String),
}

impl fmt::Display for InterfaceError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            InterfaceError::PreconditionViolated(msg) => write!(f, "Precondition violated: {}", msg),
            InterfaceError::PostconditionViolated(msg) => write!(f, "Postcondition violated: {}", msg),
            InterfaceError::InvariantViolated(msg) => write!(f, "Interface invariant violated: {}", msg),
            InterfaceError::IncompatibleInterface(msg) => write!(f, "Incompatible interface: {}", msg),
            InterfaceError::SubstitutabilityViolation(msg) => {
                write!(f, "Substitutability violation: {}", msg)
            }
            InterfaceError::UndeclaredEffect(msg) => write!(f, "Undeclared effect: {}", msg),
            InterfaceError::TypeMismatch { expected, actual } => {
                write!(f, "Type mismatch: expected {}, got {}", expected, actual)
            }
            InterfaceError::CapabilityMissing(msg) => write!(f, "Capability missing: {}", msg),
            InterfaceError::ProviderError(msg) => write!(f, "Provider failure: {}", msg),
            InterfaceError::SemanticInvalidity(msg) => write!(f, "Semantic contract invalid: {}", msg),
        }
    }
}

impl std::error::Error for InterfaceError {}

pub type Result<T> = std::result::Result<T, InterfaceError>;
