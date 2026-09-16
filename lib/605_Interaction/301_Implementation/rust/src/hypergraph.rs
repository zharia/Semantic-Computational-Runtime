use scr_hypergraph::{
    Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role,
};
use crate::error::{InteractionError, InteractionResult};
use crate::actor::Actor;
use crate::gesture::Gesture;
use crate::intent::Intent;
use crate::target::InteractionTarget;

/// Projects a semantic interaction cycle into the canonical SCR Hypergraph
/// satisfying Section 53 and INT-020, INT-021, INT-024.
pub fn project_interaction_to_hypergraph(
    interaction_id: &str,
    actor: &Actor,
    gesture: &Gesture,
    intent: &Intent,
    nullary_assertions: &[String],
    hypergraph: &mut Hypergraph,
) -> InteractionResult<()> {
    // 1. Create Actor Element
    let actor_elem_id = ElementId(format!("elem:actor:{}", actor.id));
    if hypergraph.get_element(&actor_elem_id).is_none() {
        hypergraph
            .create_element(actor_elem_id.clone(), format!("Actor:{}", actor.id))
            .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;
    }

    // 2. Create Gesture Element
    let gesture_elem_id = ElementId(format!("elem:gesture:{}", gesture.id));
    if hypergraph.get_element(&gesture_elem_id).is_none() {
        hypergraph
            .create_element(gesture_elem_id.clone(), format!("Gesture:{:?}", gesture.kind))
            .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;
    }

    // 3. Create Intent Element
    let intent_elem_id = ElementId(format!("elem:intent:{}", intent.id));
    if hypergraph.get_element(&intent_elem_id).is_none() {
        hypergraph
            .create_element(intent_elem_id.clone(), format!("Intent:{:?}", intent.kind))
            .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;
    }

    // 4. Create Target Element if entity target
    let target_elem_id = match &intent.target {
        InteractionTarget::Entity { uri } => {
            let elem_id = ElementId(format!("elem:target:{}", uri));
            if hypergraph.get_element(&elem_id).is_none() {
                hypergraph
                    .create_element(elem_id.clone(), uri.clone())
                    .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;
            }
            Some(elem_id)
        }
        _ => None,
    };

    // 5. Create Interaction Hyperedge Relation
    let rel_id = RelationId(format!("rel:interaction:{}", interaction_id));
    hypergraph
        .create_relation(rel_id.clone(), "InteractionExecution")
        .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;

    // Connect Actor (Subject, Outgoing)
    let inc_actor = IncidenceId(format!("inc:act_{}", interaction_id));
    hypergraph
        .attach_incidence(
            inc_actor,
            &actor_elem_id,
            &rel_id,
            Role::Subject,
            Direction::Outgoing,
        )
        .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;

    // Connect Gesture (Operand, Outgoing)
    let inc_gesture = IncidenceId(format!("inc:gest_{}", interaction_id));
    hypergraph
        .attach_incidence(
            inc_gesture,
            &gesture_elem_id,
            &rel_id,
            Role::Operand,
            Direction::Outgoing,
        )
        .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;

    // Connect Intent (Parameter / Effect, Ingoing)
    let inc_intent = IncidenceId(format!("inc:int_{}", interaction_id));
    hypergraph
        .attach_incidence(
            inc_intent,
            &intent_elem_id,
            &rel_id,
            Role::Effect,
            Direction::Ingoing,
        )
        .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;

    // Connect Target if present (Target, Ingoing)
    if let Some(t_id) = target_elem_id {
        let inc_target = IncidenceId(format!("inc:tgt_{}", interaction_id));
        hypergraph
            .attach_incidence(
                inc_target,
                &t_id,
                &rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;
    }

    // 6. Project Nullary Relations (INT-024: |I(R)| = 0)
    for (i, assertion) in nullary_assertions.iter().enumerate() {
        let nullary_rel_id = RelationId(format!("rel:nullary:{}_{}", interaction_id, i));
        hypergraph
            .create_relation(nullary_rel_id, assertion.clone())
            .map_err(|e| InteractionError::HypergraphMappingError(e.to_string()))?;
        // Zero incidences attached
    }

    Ok(())
}
