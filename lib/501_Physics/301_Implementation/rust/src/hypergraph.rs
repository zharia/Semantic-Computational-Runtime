// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Canonical Hypergraph Projection — Physics Domain
//!
//! Projects physical entities, quantities, laws, and higher-order interactions
//! into the canonical SCR Semantic Hypergraph (`SCR-LIB-HYPERGRAPH`).
//!
//! Conforms to `SCR-LIB-PHYSICS` Section on Semantic Hypergraph Integration:
//! ```text
//! Interaction
//!  ├── participant: body_A
//!  ├── participant: body_B
//!  ├── medium: environment
//!  ├── force: F
//!  ├── location: x
//!  ├── time: t
//!  └── law: L
//! ```

use crate::body::PhysicalBody;
use crate::error::{PhysicsError, PhysicsResult};
use crate::id::PhysicsEntityId;
use crate::interaction::PhysicalInteraction;
use crate::law::PhysicalLaw;
use scr_hypergraph::{Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role};

/// Projects a complete physical interaction and participating bodies into the canonical hypergraph.
pub fn project_interaction_to_hypergraph(
    model_id: &PhysicsEntityId,
    bodies: &[PhysicalBody],
    interaction: &PhysicalInteraction,
    law: Option<&PhysicalLaw>,
    hypergraph: &mut Hypergraph,
) -> PhysicsResult<()> {
    // 1. Model Root Element
    let model_elem_id = ElementId(format!("elem:phys_model:{}", model_id));
    if hypergraph.get_element(&model_elem_id).is_none() {
        hypergraph
            .create_element(
                model_elem_id.clone(),
                format!("PhysicalModel:{}", model_id),
            )
            .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
    }

    // 2. Project Participating Bodies
    for body in bodies {
        let body_elem_id = ElementId(format!("elem:body:{}", body.id));
        if hypergraph.get_element(&body_elem_id).is_none() {
            hypergraph
                .create_element(
                    body_elem_id.clone(),
                    format!("PhysicalBody:{}:mass={}", body.id, body.mass),
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
        }

        let rel_body_id = RelationId(format!("rel:model_has_body:{}:{}", model_id, body.id));
        if hypergraph.get_relation(&rel_body_id).is_none() {
            hypergraph
                .create_relation(rel_body_id.clone(), "CONTAINS_BODY".to_string())
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:src", rel_body_id)),
                    &model_elem_id,
                    &rel_body_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:tgt", rel_body_id)),
                    &body_elem_id,
                    &rel_body_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
        }
    }

    // 3. Project Higher-Order Interaction Hyperedge
    let inter_rel_id = RelationId(format!("rel:interaction:{}", interaction.id));
    if hypergraph.get_relation(&inter_rel_id).is_none() {
        hypergraph
            .create_relation(
                inter_rel_id.clone(),
                format!("PhysicalInteraction:{:?}", interaction.kind),
            )
            .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;

        // Attach each participant with Role::Custom("Participant")
        for participant_id in &interaction.participants {
            let p_elem_id = ElementId(format!("elem:body:{}", participant_id));
            let inc_id = IncidenceId(format!("inc:{}:participant:{}", inter_rel_id, participant_id));
            hypergraph
                .attach_incidence(
                    inc_id,
                    &p_elem_id,
                    &inter_rel_id,
                    Role::Custom("Participant".to_string()),
                    Direction::Undirected,
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
        }

        // Project Force Magnitude Element
        let force_elem_id = ElementId(format!("elem:force:{}", interaction.id));
        if hypergraph.get_element(&force_elem_id).is_none() {
            hypergraph
                .create_element(
                    force_elem_id.clone(),
                    format!("ForceQuantity:{} {}", interaction.force.value, interaction.force.unit_name),
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
        }

        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:{}:force", inter_rel_id)),
                &force_elem_id,
                &inter_rel_id,
                Role::Custom("Force".to_string()),
                Direction::Ingoing,
            )
            .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
    }

    // 4. Project Governing Law if present
    if let Some(l) = law {
        let law_elem_id = ElementId(format!("elem:law:{}", l.id));
        if hypergraph.get_element(&law_elem_id).is_none() {
            hypergraph
                .create_element(
                    law_elem_id.clone(),
                    format!("PhysicalLaw:{}:validity={}", l.name, l.validity_domain),
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
        }

        let law_rel_id = RelationId(format!("rel:governs_interaction:{}:{}", l.id, interaction.id));
        if hypergraph.get_relation(&law_rel_id).is_none() {
            hypergraph
                .create_relation(law_rel_id.clone(), "GOVERNS".to_string())
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:law_src", law_rel_id)),
                    &law_elem_id,
                    &law_rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:inter_tgt", law_rel_id)),
                    &model_elem_id,
                    &law_rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| PhysicsError::HypergraphError(e.to_string()))?;
        }
    }

    Ok(())
}
