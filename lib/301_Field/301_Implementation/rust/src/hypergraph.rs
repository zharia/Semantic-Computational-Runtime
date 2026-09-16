use crate::error::{FieldError, FieldResult};
use crate::field::Field;
use scr_hypergraph::{
    Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role,
};

/// Projects a semantic Field into the canonical SCR Hypergraph.
pub fn project_field_to_hypergraph(
    field: &Field,
    hypergraph: &mut Hypergraph,
) -> FieldResult<()> {
    // 1. Field Element
    let field_elem_id = ElementId(format!("elem:field:{}", field.id));
    if hypergraph.get_element(&field_elem_id).is_none() {
        hypergraph
            .create_element(field_elem_id.clone(), format!("Field:{}", field.id))
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;
    }

    // 2. Domain Element
    let domain_elem_id = ElementId(format!("elem:domain:{}", field.domain.id));
    if hypergraph.get_element(&domain_elem_id).is_none() {
        hypergraph
            .create_element(
                domain_elem_id.clone(),
                format!("FieldDomain:{}:dim={}", field.domain.id, field.domain.dimension),
            )
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;
    }

    // 3. Value Space Element
    let val_elem_id = ElementId(format!("elem:valspace:{:?}", field.value_space));
    if hypergraph.get_element(&val_elem_id).is_none() {
        hypergraph
            .create_element(
                val_elem_id.clone(),
                format!("ValueSpace:{:?}", field.value_space),
            )
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;
    }

    // 4. Domain Association Hyperedge
    let dom_rel_id = RelationId(format!("rel:field_domain:{}", field.id));
    if hypergraph.get_relation(&dom_rel_id).is_none() {
        hypergraph
            .create_relation(dom_rel_id.clone(), "FieldDomainAssociation".to_string())
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;

        let inc_src = IncidenceId(format!("inc:fld_dom_src:{}", field.id));
        hypergraph
            .attach_incidence(
                inc_src,
                &field_elem_id,
                &dom_rel_id,
                Role::Source,
                Direction::Outgoing,
            )
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;

        let inc_tgt = IncidenceId(format!("inc:fld_dom_tgt:{}", field.id));
        hypergraph
            .attach_incidence(
                inc_tgt,
                &domain_elem_id,
                &dom_rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;
    }

    // 5. Value Space Association Hyperedge
    let val_rel_id = RelationId(format!("rel:field_valspace:{}", field.id));
    if hypergraph.get_relation(&val_rel_id).is_none() {
        hypergraph
            .create_relation(val_rel_id.clone(), "FieldValueSpaceAssociation".to_string())
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;

        let inc_src = IncidenceId(format!("inc:fld_val_src:{}", field.id));
        hypergraph
            .attach_incidence(
                inc_src,
                &field_elem_id,
                &val_rel_id,
                Role::Source,
                Direction::Outgoing,
            )
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;

        let inc_tgt = IncidenceId(format!("inc:fld_val_tgt:{}", field.id));
        hypergraph
            .attach_incidence(
                inc_tgt,
                &val_elem_id,
                &val_rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| FieldError::HypergraphMappingError(e.to_string()))?;
    }

    Ok(())
}
