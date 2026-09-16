// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{InterfaceError, Result};

/// A formal precondition required to hold prior to operation invocation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Precondition {
    pub name: String,
    pub description: String,
}

impl Precondition {
    pub fn new(name: impl Into<String>, description: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
        }
    }

    pub fn verify(&self, satisfied: bool) -> Result<()> {
        if !satisfied {
            Err(InterfaceError::PreconditionViolated(format!(
                "{}: {}",
                self.name, self.description
            )))
        } else {
            Ok(())
        }
    }
}

/// A formal postcondition guaranteed to hold upon successful operation completion.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Postcondition {
    pub name: String,
    pub description: String,
}

impl Postcondition {
    pub fn new(name: impl Into<String>, description: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
        }
    }

    pub fn verify(&self, satisfied: bool) -> Result<()> {
        if !satisfied {
            Err(InterfaceError::PostconditionViolated(format!(
                "{}: {}",
                self.name, self.description
            )))
        } else {
            Ok(())
        }
    }
}

/// An invariant contract guaranteed across all state transitions.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct InvariantContract {
    pub name: String,
    pub description: String,
}

impl InvariantContract {
    pub fn new(name: impl Into<String>, description: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
        }
    }

    pub fn verify(&self, holds: bool) -> Result<()> {
        if !holds {
            Err(InterfaceError::InvariantViolated(format!(
                "{}: {}",
                self.name, self.description
            )))
        } else {
            Ok(())
        }
    }
}
