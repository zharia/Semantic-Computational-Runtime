// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Dynamics Hypergraph Projection Tests
//!
//! Verifies canonical hypergraph projection of dynamical systems and trajectories.

use scr_dynamics::hypergraph::project_system_to_hypergraph;
use scr_dynamics::id::{StateId, SystemId, TrajectoryId, TransitionId};
use scr_dynamics::state::{DynamicalState, StateSpace};
use scr_dynamics::system::{DynamicalSystem, Trajectory};
use scr_dynamics::transition::{EvolutionLaw, StateDelta, StateTransition};
use scr_hypergraph::Hypergraph;

#[test]
fn test_project_dynamical_system_to_hypergraph() {
    let mut hg = Hypergraph::new();

    let s0 = DynamicalState::new(StateId::new("s0"), 0.0, vec![1.0, 0.0]);
    let s1 = DynamicalState::new(StateId::new("s1"), 0.1, vec![0.9, 0.1]);

    let mut traj = Trajectory::new(TrajectoryId::new("traj_demo"), s0.clone());
    traj.append(s1.clone()).unwrap();

    let mut sys = DynamicalSystem::new(
        SystemId::new("dyn_sys:flow"),
        StateSpace::unconstrained(2),
        EvolutionLaw::new("DampedOscillator", true, "Linear damped oscillation"),
        true,
    );
    sys.add_trajectory(traj).unwrap();

    let delta = StateDelta::between(&s0, &s1).unwrap();
    let transition = StateTransition::new(TransitionId::new("t01"), s0.id, s1.id, delta, true);

    project_system_to_hypergraph(&sys, &[transition], &mut hg).unwrap();

    // Verify elements: system (1) + trajectory (1) + states (2) = 4
    assert!(hg.elements().count() >= 4);

    // Verify relations: has_trajectory (1) + transitions_to (1) = 2
    assert!(hg.relations().count() >= 2);
}

#[test]
fn test_idempotent_dynamics_projection() {
    let mut hg = Hypergraph::new();

    let s0 = DynamicalState::new(StateId::new("s_init"), 0.0, vec![0.0]);
    let traj = Trajectory::new(TrajectoryId::new("t_single"), s0);

    let mut sys = DynamicalSystem::new(
        SystemId::new("sys_simple"),
        StateSpace::unconstrained(1),
        EvolutionLaw::new("Identity", true, "dx/dt = 0"),
        true,
    );
    sys.add_trajectory(traj).unwrap();

    // Project once
    project_system_to_hypergraph(&sys, &[], &mut hg).unwrap();
    let elem_count_1 = hg.elements().count();
    let rel_count_1 = hg.relations().count();

    // Project again
    project_system_to_hypergraph(&sys, &[], &mut hg).unwrap();
    let elem_count_2 = hg.elements().count();
    let rel_count_2 = hg.relations().count();

    assert_eq!(elem_count_1, elem_count_2);
    assert_eq!(rel_count_1, rel_count_2);
}
