// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

/// Material observable side effects produced during operation execution.
///
/// In accordance with INTERFACE-INV-008:
/// Material externally observable effects MUST be explicitly declared.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Effect {
    /// Pure computation: referentially transparent, zero observable side effects.
    Pure,
    /// Reads internal or external state without modification.
    ReadsState(String),
    /// Mutates designated state components.
    MutatesState(String),
    /// Performs network, disk, or device I/O.
    ExternalIO(String),
    /// Allocates finite or shared computational resources.
    AllocatesResource(String),
}

impl Effect {
    pub fn is_pure(&self) -> bool {
        matches!(self, Effect::Pure)
    }

    pub fn is_mutating(&self) -> bool {
        matches!(self, Effect::MutatesState(_))
    }
}
