use scr_hypergraph::{
    Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role,
};
use crate::error::{PerceptionError, PerceptionResult};
use crate::process::PerceptualRepresentation;

/// Projects a PerceptualRepresentation directly into the canonical SCR Semantic Hypergraph
/// satisfying PERCEPTION-INV-019, PERCEPTION-INV-020, and PERCEPTION-INV-023.
pub fn project_perception_to_hypergraph(
    representation: &PerceptualRepresentation,
    hypergraph: &mut Hypergraph,
) -> PerceptionResult<()> {
    // 1. Create a root element representing the perceptual result node
    let rep_elem_id = ElementId(format!("elem:perception:{}", representation.id));
    hypergraph
        .create_element(rep_elem_id.clone(), format!("Perception:{}", representation.id))
        .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;

    // 2. Project Detections as hyperedges connecting the perception node to detected candidates
    for (i, det) in representation.detections.iter().enumerate() {
        let det_elem_id = ElementId(format!("elem:candidate:{}", det.id));
        if hypergraph.get_element(&det_elem_id).is_none() {
            hypergraph
                .create_element(det_elem_id.clone(), det.candidate_label.clone())
                .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;
        }

        let rel_id = RelationId(format!("rel:detection:{}", det.id));
        hypergraph
            .create_relation(rel_id.clone(), "DetectedIn")
            .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;

        // Incidence from candidate to relation
        let inc_cand = IncidenceId(format!("inc:det_cand:{}_{}", det.id, i));
        hypergraph
            .attach_incidence(
                inc_cand,
                &det_elem_id,
                &rel_id,
                Role::Subject,
                Direction::Outgoing,
            )
            .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;

        // Incidence from perception to relation
        let inc_rep = IncidenceId(format!("inc:det_rep:{}_{}", det.id, i));
        hypergraph
            .attach_incidence(
                inc_rep,
                &rep_elem_id,
                &rel_id,
                Role::Custom("Context".into()),
                Direction::Ingoing,
            )
            .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;
    }

    // 3. Project Identifications (Section 15 & INV-010)
    for (i, ident) in representation.identifications.iter().enumerate() {
        let entity_elem_id = ElementId(format!("elem:entity:{}", ident.persistent_entity_id));
        if hypergraph.get_element(&entity_elem_id).is_none() {
            hypergraph
                .create_element(entity_elem_id.clone(), ident.persistent_entity_id.clone())
                .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;
        }

        let rel_id = RelationId(format!("rel:identification:{}", ident.id));
        hypergraph
            .create_relation(rel_id.clone(), "IdentifiedAs")
            .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;

        let inc_ent = IncidenceId(format!("inc:id_ent:{}_{}", ident.id, i));
        hypergraph
            .attach_incidence(
                inc_ent,
                &entity_elem_id,
                &rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;

        let inc_rep = IncidenceId(format!("inc:id_rep:{}_{}", ident.id, i));
        hypergraph
            .attach_incidence(
                inc_rep,
                &rep_elem_id,
                &rel_id,
                Role::Custom("ObserverEvidence".into()),
                Direction::Outgoing,
            )
            .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;
    }

    // 4. Project Nullary Relations (Section 43 & PERCEPTION-INV-023: |I(R)| = 0)
    for (i, assertion) in representation.nullary_assertions.iter().enumerate() {
        let nullary_rel_id = RelationId(format!("rel:nullary:{}_{}", representation.id, i));
        hypergraph
            .create_relation(nullary_rel_id, assertion.clone())
            .map_err(|e| PerceptionError::HypergraphMappingError(e.to_string()))?;
        // Zero incidences attached, preserving |I(R)| = 0
    }

    Ok(())
}
