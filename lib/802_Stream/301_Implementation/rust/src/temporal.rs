// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{Result, StreamError};

/// Identifies the temporal reference clock governing a timestamp.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum ClockDomain {
    /// Time when the event or state occurred in the source domain.
    EventTime,
    /// Time when the event was ingested by the stream source.
    IngestionTime,
    /// Wall-clock time of the executing runtime processor.
    ProcessingTime,
    /// Discrete monotonically advancing logical clock (e.g. tick / step).
    LogicalClock(String),
    /// Simulation virtual time.
    SimulatedTime,
}

/// A monotonic progress indicator in event time.
///
/// Elements with event time <= watermark are guaranteed to be complete,
/// allowing windows to trigger aggregation and close.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Watermark {
    pub timestamp: u64,
}

impl Watermark {
    pub fn new(timestamp: u64) -> Self {
        Self { timestamp }
    }

    pub fn advance_to(&mut self, next: u64) -> Result<()> {
        if next < self.timestamp {
            return Err(StreamError::SemanticInvalidity(format!(
                "Watermark regression prohibited: cannot retreat from {} to {}",
                self.timestamp, next
            )));
        }
        self.timestamp = next;
        Ok(())
    }
}

/// Explicit temporal coordinates of an element.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TemporalReference {
    pub clock_domain: ClockDomain,
    pub timestamp: u64,
    pub uncertainty_ns: u64,
}

impl TemporalReference {
    pub fn new(clock_domain: ClockDomain, timestamp: u64) -> Self {
        Self {
            clock_domain,
            timestamp,
            uncertainty_ns: 0,
        }
    }

    pub fn with_uncertainty(mut self, uncertainty_ns: u64) -> Self {
        self.uncertainty_ns = uncertainty_ns;
        self
    }
}
