// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::collections::HashMap;

use crate::availability::AvailabilityStatus;
use crate::element::{StreamElement, StreamElementId};
use crate::error::{Result, StreamError};
use crate::lifecycle::StreamLifecycle;
use crate::loss::LossRecord;
use crate::occurrence::OccurrenceRecord;
use crate::ordering::{OrderingSemantics, VectorClock};
use crate::stream_types::StreamKind;
use crate::temporal::Watermark;

/// Canonical semantic representation of an SCR Stream.
///
/// Encapsulates:
/// S = (Identity, Elements, Occurrences, Availability, Temporal, Ordering,
///      Causality, State, Transformation, Lifecycle, Provenance, Completeness, Loss)
pub struct SemanticStream {
    pub stream_id: String,
    pub kind: StreamKind,
    pub ordering: OrderingSemantics,
    pub lifecycle: StreamLifecycle,
    pub elements: Vec<StreamElement>,
    pub occurrences: HashMap<StreamElementId, OccurrenceRecord>,
    pub availability: HashMap<StreamElementId, AvailabilityStatus>,
    pub causal_clocks: HashMap<StreamElementId, VectorClock>,
    pub watermark: Watermark,
    pub losses: Vec<LossRecord>,
    pub is_complete: bool,
}

impl SemanticStream {
    pub fn new(stream_id: impl Into<String>, kind: StreamKind, ordering: OrderingSemantics) -> Self {
        Self {
            stream_id: stream_id.into(),
            kind,
            ordering,
            lifecycle: StreamLifecycle::new(),
            elements: Vec::new(),
            occurrences: HashMap::new(),
            availability: HashMap::new(),
            causal_clocks: HashMap::new(),
            watermark: Watermark::new(0),
            losses: Vec::new(),
            is_complete: false,
        }
    }

    /// Appends an element with its occurrence, availability, and vector clock.
    pub fn append_element(
        &mut self,
        element: StreamElement,
        occurrence: OccurrenceRecord,
        availability: AvailabilityStatus,
        clock: VectorClock,
    ) -> Result<()> {
        if !self.lifecycle.is_active() {
            return Err(StreamError::StreamTerminated(format!(
                "Cannot append to stream in state {:?}",
                self.lifecycle.current()
            )));
        }

        if !occurrence.is_causally_consistent() {
            return Err(StreamError::CausalViolation(format!(
                "Inconsistent occurrence record for element {:?}",
                element.id
            )));
        }

        let id = element.id.clone();
        self.occurrences.insert(id.clone(), occurrence);
        self.availability.insert(id.clone(), availability);
        self.causal_clocks.insert(id, clock);
        self.elements.push(element);

        Ok(())
    }

    /// Records an explicit loss or dropped element.
    pub fn record_loss(&mut self, record: LossRecord) {
        self.losses.push(record);
    }

    /// Advances the stream's event-time watermark monotonically.
    pub fn advance_watermark(&mut self, next_timestamp: u64) -> Result<()> {
        self.watermark.advance_to(next_timestamp)
    }

    /// Returns the number of elements in the stream.
    pub fn element_count(&self) -> usize {
        self.elements.len()
    }

    /// Marks the stream as having complete historical or windowed coverage.
    pub fn mark_complete(&mut self) {
        self.is_complete = true;
    }
}
