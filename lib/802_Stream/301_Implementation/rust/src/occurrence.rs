// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{Result, StreamError};

/// Explicit tracking of temporal checkpoints for an element's lifecycle.
///
/// In accordance with STREAM-INV-004:
/// Occurrence MUST remain distinguishable from observation, publication,
/// processing, and consumption.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OccurrenceRecord {
    /// Timestamp of when the phenomenon actually occurred in the domain.
    pub occurred_at: u64,
    /// Timestamp when an observer or sensor detected the occurrence.
    pub observed_at: Option<u64>,
    /// Timestamp when the occurrence was published to the stream.
    pub published_at: Option<u64>,
    /// Timestamp when a processor began transforming the element.
    pub processed_at: Option<u64>,
    /// Timestamp when a consumer successfully committed or consumed the element.
    pub consumed_at: Option<u64>,
}

impl OccurrenceRecord {
    pub fn new(occurred_at: u64) -> Self {
        Self {
            occurred_at,
            observed_at: None,
            published_at: None,
            processed_at: None,
            consumed_at: None,
        }
    }

    pub fn with_observed(mut self, timestamp: u64) -> Result<Self> {
        if timestamp < self.occurred_at {
            return Err(StreamError::SemanticInvalidity(
                "Observed timestamp cannot precede occurrence timestamp".into(),
            ));
        }
        self.observed_at = Some(timestamp);
        Ok(self)
    }

    pub fn with_published(mut self, timestamp: u64) -> Result<Self> {
        if let Some(obs) = self.observed_at {
            if timestamp < obs {
                return Err(StreamError::SemanticInvalidity(
                    "Published timestamp cannot precede observation timestamp".into(),
                ));
            }
        }
        self.published_at = Some(timestamp);
        Ok(self)
    }

    pub fn with_processed(mut self, timestamp: u64) -> Result<Self> {
        if let Some(pub_time) = self.published_at {
            if timestamp < pub_time {
                return Err(StreamError::SemanticInvalidity(
                    "Processed timestamp cannot precede published timestamp".into(),
                ));
            }
        }
        self.processed_at = Some(timestamp);
        Ok(self)
    }

    pub fn with_consumed(mut self, timestamp: u64) -> Result<Self> {
        if let Some(proc_time) = self.processed_at {
            if timestamp < proc_time {
                return Err(StreamError::SemanticInvalidity(
                    "Consumed timestamp cannot precede processed timestamp".into(),
                ));
            }
        }
        self.consumed_at = Some(timestamp);
        Ok(self)
    }

    /// Verifies that all recorded lifecycle phases obey causal/temporal ordering.
    pub fn is_causally_consistent(&self) -> bool {
        let mut last = self.occurred_at;
        if let Some(obs) = self.observed_at {
            if obs < last { return false; }
            last = obs;
        }
        if let Some(pub_time) = self.published_at {
            if pub_time < last { return false; }
            last = pub_time;
        }
        if let Some(proc_time) = self.processed_at {
            if proc_time < last { return false; }
            last = proc_time;
        }
        if let Some(cons) = self.consumed_at {
            if cons < last { return false; }
        }
        true
    }
}
