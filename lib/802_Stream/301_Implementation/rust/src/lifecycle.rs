// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{Result, StreamError};

/// Formal lifecycle state of a Stream.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum StreamState {
    Created,
    Active,
    Suspended,
    Draining,
    Completed,
    Closed,
}

/// State machine governing stream lifecycle progression.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StreamLifecycle {
    current: StreamState,
    history: Vec<StreamState>,
}

impl StreamLifecycle {
    pub fn new() -> Self {
        Self {
            current: StreamState::Created,
            history: vec![StreamState::Created],
        }
    }

    pub fn current(&self) -> StreamState {
        self.current
    }

    pub fn history(&self) -> &[StreamState] {
        &self.history
    }

    pub fn transition_to(&mut self, next: StreamState) -> Result<()> {
        let valid = match (self.current, next) {
            (StreamState::Created, StreamState::Active) => true,
            (StreamState::Active, StreamState::Suspended) => true,
            (StreamState::Suspended, StreamState::Active) => true,
            (StreamState::Active, StreamState::Draining) => true,
            (StreamState::Draining, StreamState::Completed) => true,
            (StreamState::Completed, StreamState::Closed) => true,
            (StreamState::Active, StreamState::Closed) => true,
            (StreamState::Suspended, StreamState::Closed) => true,
            _ => false,
        };

        if !valid {
            return Err(StreamError::InvalidStateTransition {
                from: format!("{:?}", self.current),
                to: format!("{:?}", next),
            });
        }

        self.current = next;
        self.history.push(next);
        Ok(())
    }

    pub fn is_active(&self) -> bool {
        self.current == StreamState::Active
    }

    pub fn is_terminal(&self) -> bool {
        self.current == StreamState::Completed || self.current == StreamState::Closed
    }
}

impl Default for StreamLifecycle {
    fn default() -> Self {
        Self::new()
    }
}
