// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::element::StreamElement;
use crate::error::{Result, StreamError};
use crate::temporal::Watermark;

/// Types of window partition schemes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum WindowType {
    /// Non-overlapping, contiguous time intervals.
    Tumbling { duration_ms: u64 },
    /// Overlapping intervals of duration_ms, advancing every slide_ms.
    Sliding { duration_ms: u64, slide_ms: u64 },
    /// Dynamically bounded windows terminated by inactivity gaps.
    Session { gap_ms: u64 },
    /// Windows defined by a fixed number of elements.
    Count { count: usize },
}

/// A materialized or active semantic window over stream elements.
#[derive(Debug, Clone)]
pub struct StreamWindow {
    pub window_id: String,
    pub start_time: u64,
    pub end_time: u64,
    pub elements: Vec<StreamElement>,
    pub is_closed: bool,
}

impl StreamWindow {
    pub fn new(window_id: impl Into<String>, start_time: u64, end_time: u64) -> Self {
        Self {
            window_id: window_id.into(),
            start_time,
            end_time,
            elements: Vec::new(),
            is_closed: false,
        }
    }

    pub fn assign(&mut self, element: StreamElement, event_time: u64) -> Result<()> {
        if self.is_closed {
            return Err(StreamError::WindowClosed(self.window_id.clone()));
        }
        if event_time >= self.start_time && event_time < self.end_time {
            self.elements.push(element);
            Ok(())
        } else {
            Err(StreamError::SemanticInvalidity(format!(
                "Element event_time {} outside window bounds [{}, {})",
                event_time, self.start_time, self.end_time
            )))
        }
    }

    /// Evaluates if the current watermark has passed the window end boundary,
    /// triggering closure.
    pub fn evaluate_watermark(&mut self, watermark: Watermark) -> bool {
        if !self.is_closed && watermark.timestamp >= self.end_time {
            self.is_closed = true;
            true
        } else {
            false
        }
    }

    pub fn len(&self) -> usize {
        self.elements.len()
    }

    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
    }
}
