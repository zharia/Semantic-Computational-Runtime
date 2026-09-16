// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::element::{ElementPayload, StreamElement};
use crate::error::{Result, StreamError};

/// Classification of the semantic stream specialization.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StreamKind {
    /// Emits complete state snapshots at designated moments.
    State,
    /// Emits incremental change deltas relative to a prior state.
    Delta,
    /// Emits instantaneous point occurrences.
    Event,
    /// Emits sensor/perceptual measurements with uncertainty.
    Observation,
    /// Emits semantic operations/commands to be executed.
    Operation,
}

/// Reconstruction contract enabling folding of a Delta stream into a full State snapshot.
///
/// In accordance with STREAM-INV-009:
/// State Streams and Delta Streams MUST NOT be considered equivalent without
/// an explicit and verified reconstruction contract.
pub struct StateReconstructionContract {
    pub base_state: Vec<u8>,
}

impl StateReconstructionContract {
    pub fn new(base_state: Vec<u8>) -> Self {
        Self { base_state }
    }

    /// Reconstructs state by applying deltas in sequence.
    pub fn reconstruct(&self, deltas: &[StreamElement]) -> Result<Vec<u8>> {
        let mut current = self.base_state.clone();
        for delta in deltas {
            match &delta.payload {
                ElementPayload::Delta(bytes) => {
                    // Apply delta patch to current state
                    current.extend_from_slice(bytes);
                }
                _ => {
                    return Err(StreamError::SemanticInvalidity(
                        "Expected Delta payload in delta stream reconstruction".into(),
                    ));
                }
            }
        }
        Ok(current)
    }
}
