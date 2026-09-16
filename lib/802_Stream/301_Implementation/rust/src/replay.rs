// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{Result, StreamError};

/// Replay execution mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ReplayMode {
    /// Historical audit or reprocessing where all external side effects MUST be suppressed/fenced.
    HistoricalAudit,
    /// Live execution where idempotent side effects are permitted.
    LiveExecution,
}

/// Controller ensuring replay safety and side-effect fencing.
pub struct ReplayController {
    mode: ReplayMode,
}

impl ReplayController {
    pub fn new(mode: ReplayMode) -> Self {
        Self { mode }
    }

    pub fn mode(&self) -> ReplayMode {
        self.mode
    }

    /// Verifies if a side effect is allowed to proceed under the current replay mode.
    pub fn guard_side_effect(&self, effect_name: &str) -> Result<()> {
        if self.mode == ReplayMode::HistoricalAudit {
            Err(StreamError::ReplaySideEffectViolation(format!(
                "Side effect '{}' prohibited during historical replay",
                effect_name
            )))
        } else {
            Ok(())
        }
    }
}
