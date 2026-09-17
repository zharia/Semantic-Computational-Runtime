// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Canonical Hypergraph Projection — Dynamics Domain
//!
//! Projects dynamical systems, states, transitions, and trajectories into the
//! canonical SCR Semantic Hypergraph (`SCR-LIB-HYPERGRAPH`).

use crate::error::{DynamicsError, DynamicsResult};
use crate::system::DynamicalSystem;
use crate::transition::StateTransition;
use scr_hypergraph::{Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role};

/// Projects a dynamical system and its trajectories into the canonical hypergraph.
pub fn project_system_to_hypergraph(
    system: &DynamicalSystem,
    transitions: &[StateTransition],
    hypergraph: &mut Hypergraph,
) -> DynamicsResult<()> {
    // 1. Dynamical System Element
    let sys_elem_id = ElementId(format!("elem:dyn_sys:{}", system.id));
    if hypergraph.get_element(&sys_elem_id).is_none() {
        hypergraph
            .create_element(
                sys_elem_id.clone(),
                format!("DynamicalSystem:{}:dim={}", system.id, system.state_space.dimension),
            )
            .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;
    }

    // 2. Project Trajectories and States
    for traj in &system.trajectories {
        let traj_elem_id = ElementId(format!("elem:traj:{}", traj.id));
        if hypergraph.get_element(&traj_elem_id).is_none() {
            hypergraph
                .create_element(
                    traj_elem_id.clone(),
                    format!("Trajectory:{}:states={}", traj.id, traj.state_count()),
                )
                .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;
        }

        let rel_traj_id = RelationId(format!("rel:sys_has_traj:{}:{}", system.id, traj.id));
        if hypergraph.get_relation(&rel_traj_id).is_none() {
            hypergraph
                .create_relation(rel_traj_id.clone(), "HAS_TRAJECTORY".to_string())
                .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:src", rel_traj_id)),
                    &sys_elem_id,
                    &rel_traj_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:tgt", rel_traj_id)),
                    &traj_elem_id,
                    &rel_traj_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;
        }

        // Project states
        for state in &traj.states {
            let state_elem_id = ElementId(format!("elem:state:{}", state.id));
            if hypergraph.get_element(&state_elem_id).is_none() {
                hypergraph
                    .create_element(
                        state_elem_id.clone(),
                        format!("State:{}:t={}", state.id, state.time),
                    )
                    .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;
            }
        }
    }

    // 3. Project State Transitions
    for trans in transitions {
        let from_elem = ElementId(format!("elem:state:{}", trans.from_state));
        let to_elem = ElementId(format!("elem:state:{}", trans.to_state));

        let trans_rel_id = RelationId(format!("rel:transition:{}", trans.id));
        if hypergraph.get_relation(&trans_rel_id).is_none() {
            hypergraph
                .create_relation(
                    trans_rel_id.clone(),
                    format!("TRANSITIONS_TO:dt={}", trans.delta.dt),
                )
                .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:from", trans_rel_id)),
                    &from_elem,
                    &trans_rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:to", trans_rel_id)),
                    &to_elem,
                    &trans_rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| DynamicsError::HypergraphError(e.to_string()))?;
        }
    }

    Ok(())
}
