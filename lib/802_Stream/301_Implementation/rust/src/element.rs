// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::collections::HashMap;

/// Globally unique semantic identifier for an element participating in a stream.
///
/// In accordance with STREAM-INV-003, Stream elements retain semantic identity
/// independent of physical representation or transport encodings.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct StreamElementId(pub String);

impl StreamElementId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Semantic provenance record tracking the lineage of an element.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProvenanceRecord {
    pub source_id: String,
    pub generation: u64,
    pub parent_element_ids: Vec<StreamElementId>,
    pub transformation_history: Vec<String>,
}

impl ProvenanceRecord {
    pub fn root(source_id: impl Into<String>) -> Self {
        Self {
            source_id: source_id.into(),
            generation: 0,
            parent_element_ids: Vec::new(),
            transformation_history: Vec::new(),
        }
    }

    pub fn derive(&self, transform_name: &str, parent_id: StreamElementId) -> Self {
        let mut history = self.transformation_history.clone();
        history.push(transform_name.to_string());
        Self {
            source_id: self.source_id.clone(),
            generation: self.generation + 1,
            parent_element_ids: vec![parent_id],
            transformation_history: history,
        }
    }
}

/// Typed semantic payload of a stream element.
#[derive(Debug, Clone, PartialEq)]
pub enum ElementPayload {
    Scalar(f64),
    Text(String),
    Binary(Vec<u8>),
    Record(HashMap<String, String>),
    StateSnapshot(Vec<u8>),
    Delta(Vec<u8>),
    Null,
}

/// A first-class semantic element participating in a Stream.
#[derive(Debug, Clone, PartialEq)]
pub struct StreamElement {
    pub id: StreamElementId,
    pub semantic_type: String,
    pub payload: ElementPayload,
    pub metadata: HashMap<String, String>,
    pub provenance: ProvenanceRecord,
}

impl StreamElement {
    pub fn new(
        id: StreamElementId,
        semantic_type: impl Into<String>,
        payload: ElementPayload,
        provenance: ProvenanceRecord,
    ) -> Self {
        Self {
            id,
            semantic_type: semantic_type.into(),
            payload,
            metadata: HashMap::new(),
            provenance,
        }
    }

    pub fn with_metadata(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.metadata.insert(key.into(), value.into());
        self
    }
}
