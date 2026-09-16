use crate::coordinate::{GlobalIdentity, SidCoordinate};
use crate::error::IdentityError;
use crate::machine::IAMMachine;
use scr_hypergraph::{
    Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role,
};

/// Conversion of a Semantic Coordinate into a canonical Hypergraph Element ID.
pub fn to_element_id(root_id: &str, sid: &SidCoordinate) -> ElementId {
    ElementId(format!(
        "elem:sid:{}:{}:{}",
        root_id, sid.domain_id, sid.index
    ))
}

/// Conversion of a Global Identity into a canonical Hypergraph Element ID.
pub fn global_identity_to_element_id(id: &GlobalIdentity) -> ElementId {
    to_element_id(&id.root_id, &id.coordinate)
}

/// Projects identity address space entities, authorities, allocations, and bindings
/// into the canonical SCR Hypergraph.
pub fn project_identity_to_hypergraph(
    machine: &IAMMachine,
    root_id: &str,
    hypergraph: &mut Hypergraph,
) -> Result<(), IdentityError> {
    // 1. Root Authority Element
    let root_elem_id = ElementId(format!("elem:auth:root:{}", root_id));
    if hypergraph.get_element(&root_elem_id).is_none() {
        hypergraph
            .create_element(root_elem_id.clone(), format!("RootAuthority:{}", root_id))
            .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;
    }

    // 2. Project Domains (Pass 1: Create Elements)
    for (dom_id, domain) in &machine.state.d {
        let dom_elem_id = ElementId(format!("elem:domain:{}", dom_id));
        if hypergraph.get_element(&dom_elem_id).is_none() {
            hypergraph
                .create_element(
                    dom_elem_id.clone(),
                    format!("Domain:{}:region={}", dom_id, domain.region),
                )
                .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;
        }
    }

    // 2b. Project Domains (Pass 2: Link Subdomain Containment)
    for (dom_id, domain) in &machine.state.d {
        if let Some(parent_id) = &domain.parent {
            let dom_elem_id = ElementId(format!("elem:domain:{}", dom_id));
            let parent_elem_id = ElementId(format!("elem:domain:{}", parent_id));
            let sub_rel_id = RelationId(format!("rel:subdomain:{}:{}", parent_id, dom_id));
            if hypergraph.get_relation(&sub_rel_id).is_none() {
                hypergraph
                    .create_relation(sub_rel_id.clone(), "SubDomainContainment".to_string())
                    .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;

                let inc_p = IncidenceId(format!("inc:parent:{}_{}", parent_id, dom_id));
                hypergraph
                    .attach_incidence(
                        inc_p,
                        &parent_elem_id,
                        &sub_rel_id,
                        Role::Source,
                        Direction::Outgoing,
                    )
                    .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;

                let inc_c = IncidenceId(format!("inc:child:{}_{}", parent_id, dom_id));
                hypergraph
                    .attach_incidence(
                        inc_c,
                        &dom_elem_id,
                        &sub_rel_id,
                        Role::Target,
                        Direction::Ingoing,
                    )
                    .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;
            }
        }
    }

    // 3. Project Historical Allocated Coordinates and Semantic Bindings
    for sid in &machine.state.h {
        let sid_elem_id = to_element_id(root_id, sid);
        if hypergraph.get_element(&sid_elem_id).is_none() {
            hypergraph
                .create_element(sid_elem_id.clone(), format!("Coordinate:{}", sid))
                .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;
        }

        // If a semantic binding exists, project binding relationship
        if let Some(binding) = machine.state.b.get(sid) {
            let entity_elem_id = ElementId(format!("elem:entity:{}", binding.entity_id));
            if hypergraph.get_element(&entity_elem_id).is_none() {
                hypergraph
                    .create_element(
                        entity_elem_id.clone(),
                        format!("Entity:{}", binding.entity_id),
                    )
                    .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;
            }

            let bind_rel_id = RelationId(format!(
                "rel:binding:{}_{}",
                sid.to_u128(),
                binding.entity_id
            ));
            if hypergraph.get_relation(&bind_rel_id).is_none() {
                hypergraph
                    .create_relation(bind_rel_id.clone(), "SemanticBinding".to_string())
                    .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;

                let inc_coord = IncidenceId(format!("inc:bind_coord_{}", sid.to_u128()));
                hypergraph
                    .attach_incidence(
                        inc_coord,
                        &sid_elem_id,
                        &bind_rel_id,
                        Role::Source,
                        Direction::Outgoing,
                    )
                    .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;

                let inc_ent = IncidenceId(format!("inc:bind_entity_{}", sid.to_u128()));
                hypergraph
                    .attach_incidence(
                        inc_ent,
                        &entity_elem_id,
                        &bind_rel_id,
                        Role::Target,
                        Direction::Ingoing,
                    )
                    .map_err(|e| IdentityError::InvalidRequest(e.to_string()))?;
            }
        }
    }

    Ok(())
}
