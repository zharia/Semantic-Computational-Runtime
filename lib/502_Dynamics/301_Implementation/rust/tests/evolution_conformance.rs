// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Evolution & State Space Conformance Tests
//!
//! Tests for state space metrics, trajectory temporal evolution, and equilibrium stability.

use scr_dynamics::id::{StateId, SystemId, TrajectoryId};
use scr_dynamics::stability::{EquilibriumPoint, StabilityKind};
use scr_dynamics::state::{DynamicalState, StateSpace};
use scr_dynamics::system::{DynamicalSystem, Trajectory};
use scr_dynamics::transition::{EvolutionLaw, StateDelta};

#[test]
fn test_state_space_and_distance() {
    let s1 = DynamicalState::new(StateId::new("s1"), 0.0, vec![0.0, 0.0, 0.0]);
    let s2 = DynamicalState::new(StateId::new("s2"), 1.0, vec![3.0, 4.0, 0.0]);

    let dist = s1.distance_to(&s2).unwrap();
    assert!((dist - 5.0).abs() < 1e-9);

    let space = StateSpace::bounded(vec![-5.0, -5.0, -5.0], vec![5.0, 5.0, 5.0]).unwrap();
    assert!(space.contains_state(&s1));
    assert!(space.contains_state(&s2));

    let s_outside = DynamicalState::new(StateId::new("s_out"), 2.0, vec![6.0, 0.0, 0.0]);
    assert!(!space.contains_state(&s_outside));
}

#[test]
fn test_trajectory_evolution_and_delta() {
    let s0 = DynamicalState::new(StateId::new("s0"), 0.0, vec![1.0, 0.0]);
    let s1 = DynamicalState::new(StateId::new("s1"), 0.5, vec![0.8, 0.6]);
    let s2 = DynamicalState::new(StateId::new("s2"), 1.0, vec![0.5, 0.866]);

    let mut traj = Trajectory::new(TrajectoryId::new("unit_circle_flow"), s0.clone());
    traj.append(s1.clone()).unwrap();
    traj.append(s2.clone()).unwrap();

    assert_eq!(traj.state_count(), 3);
    assert_eq!(traj.duration(), 1.0);

    let delta = StateDelta::between(&s0, &s1).unwrap();
    assert_eq!(delta.dt, 0.5);
    assert!((delta.coordinate_deltas[0] - (-0.2)).abs() < 1e-9);
    assert!((delta.coordinate_deltas[1] - 0.6).abs() < 1e-9);

    let mut sys = DynamicalSystem::new(
        SystemId::new("rotational_system"),
        StateSpace::unconstrained(2),
        EvolutionLaw::new("CircularRotation", true, "Rotational flow on unit circle"),
        true,
    );
    assert!(sys.add_trajectory(traj).is_ok());
}

#[test]
fn test_equilibrium_detection() {
    let origin_state = DynamicalState::new(StateId::new("origin"), 0.0, vec![0.0, 0.0]);
    let eq = EquilibriumPoint::new(origin_state, StabilityKind::AsymptoticallyStable, 1e-6);

    // Vanishing velocity is stationary
    let v_zero = [0.0, 0.0];
    assert!(eq.is_stationary(&v_zero));

    // Small numerical jitter within tolerance is stationary
    let v_jitter = [1e-7, -1e-7];
    assert!(eq.is_stationary(&v_jitter));

    // Non-zero velocity is not stationary
    let v_moving = [0.1, 0.0];
    assert!(!eq.is_stationary(&v_moving));
}
