// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{Result, StreamError};
use crate::stream::SemanticStream;
use scr_hypergraph::{Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role};

/// Projects a semantic stream and its constituent elements into the canonical SCR Hypergraph.
///
/// In accordance with:
/// - STREAM-INV-017: Stream semantics MUST support nullary semantic relations (hyperedges with 0 incidences).
/// - STREAM-INV-018: Stream topology is subordinate to the canonical SCR semantic hypergraph.
pub fn project_stream_to_hypergraph(
    stream: &SemanticStream,
    hypergraph: &mut Hypergraph,
) -> Result<()> {
    // 1. Stream Node Element
    let stream_elem_id = ElementId(format!("elem:stream:{}", stream.stream_id));
    if hypergraph.get_element(&stream_elem_id).is_none() {
        hypergraph
            .create_element(stream_elem_id.clone(), format!("Stream:{}", stream.stream_id))
            .map_err(|e| StreamError::SemanticInvalidity(e.to_string()))?;
    }

    // 2. Constituent Elements and Membership Relations
    for elem in &stream.elements {
        let elem_id = ElementId(format!("elem:stream_elem:{}", elem.id.as_str()));
        if hypergraph.get_element(&elem_id).is_none() {
            hypergraph
                .create_element(elem_id.clone(), format!("Element:{}:{}", elem.id.as_str(), elem.semantic_type))
                .map_err(|e| StreamError::SemanticInvalidity(e.to_string()))?;
        }

        let rel_id = RelationId(format!("rel:stream_membership:{}_{}", stream.stream_id, elem.id.as_str()));
        if hypergraph.get_relation(&rel_id).is_none() {
            hypergraph
                .create_relation(rel_id.clone(), "StreamElementMembership".to_string())
                .map_err(|e| StreamError::SemanticInvalidity(e.to_string()))?;

            let inc_stream = IncidenceId(format!("inc:stream_{}_{}", stream.stream_id, elem.id.as_str()));
            hypergraph
                .attach_incidence(inc_stream, &stream_elem_id, &rel_id, Role::Source, Direction::Outgoing)
                .map_err(|e| StreamError::SemanticInvalidity(e.to_string()))?;

            let inc_elem = IncidenceId(format!("inc:elem_{}_{}", stream.stream_id, elem.id.as_str()));
            hypergraph
                .attach_incidence(inc_elem, &elem_id, &rel_id, Role::Target, Direction::Ingoing)
                .map_err(|e| StreamError::SemanticInvalidity(e.to_string()))?;
        }
    }

    // 3. Nullary Relation: Ambient Stream Axiom / Invariant Condition (STREAM-INV-017)
    let nullary_rel_id = RelationId(format!("rel:ambient_stream_axiom:{}", stream.stream_id));
    if hypergraph.get_relation(&nullary_rel_id).is_none() {
        hypergraph
            .create_relation(nullary_rel_id, "AmbientStreamInvariantContract".to_string())
            .map_err(|e| StreamError::SemanticInvalidity(e.to_string()))?;
        // Deliberately attach 0 incidences: valid nullary semantic hypergraph relation!
    }

    Ok(())
}
