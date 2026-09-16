use scr_hypergraph::{
    Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role,
};
use crate::error::{SpatialError, SpatialResult};
use crate::position::Position;
use crate::relationship::SpatialRelationship;

/// Projects spatial positions and relationships into the canonical SCR Hypergraph (Section 33).
pub fn project_spatial_relationship_to_hypergraph(
    relationship_id: &str,
    source_position: &Position,
    target_position: &Position,
    relationship: SpatialRelationship,
    nullary_assertions: &[String],
    hypergraph: &mut Hypergraph,
) -> SpatialResult<()> {
    // 1. Create or retrieve Source Position Element
    let src_elem_id = ElementId(format!("elem:spatial:{}", source_position.entity_uri));
    if hypergraph.get_element(&src_elem_id).is_none() {
        hypergraph
            .create_element(
                src_elem_id.clone(),
                format!("Position:{}", source_position.entity_uri),
            )
            .map_err(|e| SpatialError::HypergraphMappingError(e.to_string()))?;
    }

    // 2. Create or retrieve Target Position Element
    let tgt_elem_id = ElementId(format!("elem:spatial:{}", target_position.entity_uri));
    if hypergraph.get_element(&tgt_elem_id).is_none() {
        hypergraph
            .create_element(
                tgt_elem_id.clone(),
                format!("Position:{}", target_position.entity_uri),
            )
            .map_err(|e| SpatialError::HypergraphMappingError(e.to_string()))?;
    }

    // 3. Create Spatial Relationship Hyperedge
    let rel_id = RelationId(format!("rel:spatial:{}", relationship_id));
    hypergraph
        .create_relation(rel_id.clone(), format!("{:?}", relationship))
        .map_err(|e| SpatialError::HypergraphMappingError(e.to_string()))?;

    // Connect Source (Role: Source / Subject, Direction: Outgoing)
    let inc_src = IncidenceId(format!("inc:src_{}", relationship_id));
    hypergraph
        .attach_incidence(
            inc_src,
            &src_elem_id,
            &rel_id,
            Role::Source,
            Direction::Outgoing,
        )
        .map_err(|e| SpatialError::HypergraphMappingError(e.to_string()))?;

    // Connect Target (Role: Target, Direction: Ingoing)
    let inc_tgt = IncidenceId(format!("inc:tgt_{}", relationship_id));
    hypergraph
        .attach_incidence(
            inc_tgt,
            &tgt_elem_id,
            &rel_id,
            Role::Target,
            Direction::Ingoing,
        )
        .map_err(|e| SpatialError::HypergraphMappingError(e.to_string()))?;

    // 4. Project Nullary Relations (|I(R)| = 0)
    for (i, assertion) in nullary_assertions.iter().enumerate() {
        let nullary_rel_id = RelationId(format!("rel:nullary_spatial:{}_{}", relationship_id, i));
        hypergraph
            .create_relation(nullary_rel_id, assertion.clone())
            .map_err(|e| SpatialError::HypergraphMappingError(e.to_string()))?;
        // Zero incidences attached
    }

    Ok(())
}
