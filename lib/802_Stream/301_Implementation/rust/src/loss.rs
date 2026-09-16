// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::element::StreamElementId;

/// Classification of why an element is missing, lost, or removed.
///
/// In accordance with:
/// - STREAM-INV-013: Absence of an element != absence of underlying phenomenon.
/// - STREAM-INV-016: Deletion != invalidation != supersession.
/// - STREAM-INV-028: Loss MUST be distinguishable from intentional filtering.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LossClassification {
    /// Element was lost due to transport corruption, buffer overflow, or network failure.
    DroppedInTransit { reason: String },
    /// Element was intentionally filtered out by a semantic predicate.
    FilteredIntentional { predicate: String },
    /// Element was withdrawn by the source authority.
    Withdrawn { withdrawn_at: u64, reason: String },
    /// Element was invalidated due to semantic constraint violation.
    Invalidated { error: String },
    /// Element was replaced by a more authoritative version.
    Superseded { superseded_by: StreamElementId },
    /// Element was evicted due to buffer capacity bounds.
    EvictedFromBuffer { capacity_limit: usize },
}

/// Explicit record tracking a lost or removed element in the stream.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LossRecord {
    pub element_id: StreamElementId,
    pub timestamp: u64,
    pub classification: LossClassification,
}

impl LossRecord {
    pub fn new(element_id: StreamElementId, timestamp: u64, classification: LossClassification) -> Self {
        Self {
            element_id,
            timestamp,
            classification,
        }
    }

    /// True if the loss was an unrecoverable delivery failure rather than an intentional semantic action.
    pub fn is_involuntary_loss(&self) -> bool {
        matches!(
            self.classification,
            LossClassification::DroppedInTransit { .. } | LossClassification::EvictedFromBuffer { .. }
        )
    }
}
