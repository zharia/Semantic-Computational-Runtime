// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::element::StreamElement;
use crate::error::Result;

/// Delivery expectation contract declared for a stream sink.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DeliveryGuarantee {
    AtMostOnce,
    AtLeastOnce,
    EffectivelyOnce,
}

/// Transport-independent semantic intake boundary for a stream.
pub struct StreamSource {
    pub source_id: String,
    pub element_type: String,
}

impl StreamSource {
    pub fn new(source_id: impl Into<String>, element_type: impl Into<String>) -> Self {
        Self {
            source_id: source_id.into(),
            element_type: element_type.into(),
        }
    }
}

/// Transport-independent semantic egress boundary for a stream.
pub struct StreamSink {
    pub sink_id: String,
    pub target_domain: String,
    pub delivery_guarantee: DeliveryGuarantee,
    pub committed_elements: Vec<StreamElement>,
}

impl StreamSink {
    pub fn new(
        sink_id: impl Into<String>,
        target_domain: impl Into<String>,
        delivery_guarantee: DeliveryGuarantee,
    ) -> Self {
        Self {
            sink_id: sink_id.into(),
            target_domain: target_domain.into(),
            delivery_guarantee,
            committed_elements: Vec::new(),
        }
    }

    pub fn consume(&mut self, element: StreamElement) -> Result<()> {
        self.committed_elements.push(element);
        Ok(())
    }

    pub fn committed_count(&self) -> usize {
        self.committed_elements.len()
    }
}
