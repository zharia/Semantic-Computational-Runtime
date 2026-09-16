// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::element::{ElementPayload, StreamElement, StreamElementId};
use crate::error::Result;

/// Classification of operator purity and statefulness.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OperatorPurity {
    StatelessPure,
    StatefulDeterministic,
    SideEffecting,
}

/// A Map operator transforming each element 1-to-1 while preserving relative order and causality.
pub struct MapOperator<F>
where
    F: Fn(&StreamElement) -> Result<ElementPayload>,
{
    pub name: String,
    pub func: F,
}

impl<F> MapOperator<F>
where
    F: Fn(&StreamElement) -> Result<ElementPayload>,
{
    pub fn new(name: impl Into<String>, func: F) -> Self {
        Self {
            name: name.into(),
            func,
        }
    }

    pub fn apply(&self, element: &StreamElement) -> Result<StreamElement> {
        let new_payload = (self.func)(element)?;
        let new_id = StreamElementId::new(format!("{}-map-{}", element.id.as_str(), self.name));
        let derived_provenance = element.provenance.derive(&self.name, element.id.clone());

        Ok(StreamElement::new(
            new_id,
            element.semantic_type.clone(),
            new_payload,
            derived_provenance,
        ))
    }
}

/// A Filter operator evaluating a predicate to selectively retain elements.
pub struct FilterOperator<P>
where
    P: Fn(&StreamElement) -> bool,
{
    pub name: String,
    pub predicate: P,
}

impl<P> FilterOperator<P>
where
    P: Fn(&StreamElement) -> bool,
{
    pub fn new(name: impl Into<String>, predicate: P) -> Self {
        Self {
            name: name.into(),
            predicate,
        }
    }

    pub fn filter(&self, element: &StreamElement) -> bool {
        (self.predicate)(element)
    }
}

/// Merges two streams preserving provenance and ordering.
pub fn merge_streams(
    stream_a: &[StreamElement],
    stream_b: &[StreamElement],
    preserve_provenance: bool,
) -> Vec<StreamElement> {
    let mut merged = Vec::with_capacity(stream_a.len() + stream_b.len());
    for elem in stream_a {
        let mut e = elem.clone();
        if preserve_provenance {
            e.metadata.insert("merged_from".to_string(), "branch_a".to_string());
        }
        merged.push(e);
    }
    for elem in stream_b {
        let mut e = elem.clone();
        if preserve_provenance {
            e.metadata.insert("merged_from".to_string(), "branch_b".to_string());
        }
        merged.push(e);
    }
    merged
}

/// Splits a stream into two streams based on a routing predicate.
pub fn split_stream<P>(
    elements: &[StreamElement],
    predicate: P,
) -> (Vec<StreamElement>, Vec<StreamElement>)
where
    P: Fn(&StreamElement) -> bool,
{
    let mut branch_true = Vec::new();
    let mut branch_false = Vec::new();

    for elem in elements {
        if predicate(elem) {
            branch_true.push(elem.clone());
        } else {
            branch_false.push(elem.clone());
        }
    }

    (branch_true, branch_false)
}
