// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::element::StreamElementId;

/// Explicit classification of an element's availability over time.
///
/// In accordance with STREAM-INV-005:
/// Availability MUST remain distinguishable from existence and occurrence.
/// An element may have occurred at t_0, exist in storage at t_1, but only become
/// available to a consumer at t_2.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AvailabilityStatus {
    /// Fully available for consumption within an optional validity window.
    Available {
        available_from: u64,
        valid_until: Option<u64>,
    },
    /// Element exists/occurred, but is delayed (e.g. buffering, throttling, or staging).
    Delayed {
        expected_at: u64,
    },
    /// Unavailable due to an explicit semantic reason.
    Unavailable {
        reason: String,
    },
    /// Previously available, but explicitly withdrawn.
    Withdrawn {
        withdrawn_at: u64,
        reason: String,
    },
    /// Replaced by a more authoritative or updated element.
    Superseded {
        superseded_by: StreamElementId,
    },
}

impl AvailabilityStatus {
    pub fn is_available_at(&self, current_time: u64) -> bool {
        match self {
            AvailabilityStatus::Available { available_from, valid_until } => {
                if current_time < *available_from {
                    false
                } else if let Some(until) = valid_until {
                    current_time <= *until
                } else {
                    true
                }
            }
            AvailabilityStatus::Delayed { expected_at } => current_time >= *expected_at,
            AvailabilityStatus::Unavailable { .. }
            | AvailabilityStatus::Withdrawn { .. }
            | AvailabilityStatus::Superseded { .. } => false,
        }
    }
}
