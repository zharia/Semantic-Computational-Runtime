// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Dynamics Invariant Conformance Tests
//!
//! Specification tests verifying DYNAMICS-INV-001 through DYNAMICS-INV-018.

use scr_dynamics::id::{StateId, SystemId, TrajectoryId, TransitionId};
use scr_dynamics::invariants::*;
use scr_dynamics::state::{DynamicalState, StateSpace};
use scr_dynamics::system::{DynamicalSystem, Trajectory};
use scr_dynamics::transition::{EvolutionLaw, StateDelta, StateTransition};

#[test]
fn test_inv_001_semantic_primacy() {
    let valid_id = SystemId::new("dyn_sys:lorenz_attractor");
    assert!(verify_dynamics_inv_001_semantic_primacy(&valid_id).is_ok());

    let empty_id = SystemId::new("   ");
    assert!(verify_dynamics_inv_001_semantic_primacy(&empty_id).is_err());
}

#[test]
fn test_inv_002_state_integrity() {
    let state = DynamicalState::new(StateId::new("s0"), 0.0, vec![1.0, -2.5, 0.0]);
    assert!(verify_dynamics_inv_002_state_integrity(&state).is_ok());

    let state_nan_coord = DynamicalState::new(StateId::new("s_nan"), 0.0, vec![1.0, f64::NAN]);
    assert!(verify_dynamics_inv_002_state_integrity(&state_nan_coord).is_err());

    let state_nan_time = DynamicalState::new(StateId::new("s_nan_t"), f64::NAN, vec![1.0, 2.0]);
    assert!(verify_dynamics_inv_002_state_integrity(&state_nan_time).is_err());
}

#[test]
fn test_inv_003_004_transition_and_temporal_integrity() {
    let s0 = DynamicalState::new(StateId::new("s0"), 0.0, vec![0.0]);
    let s1 = DynamicalState::new(StateId::new("s1"), 0.1, vec![0.5]);

    let delta = StateDelta::between(&s0, &s1).unwrap();
    let transition = StateTransition::new(TransitionId::new("t0"), s0.id.clone(), s1.id.clone(), delta, true);
    assert!(verify_dynamics_inv_003_transition_integrity(&transition).is_ok());

    let mut trajectory = Trajectory::new(TrajectoryId::new("traj0"), s0);
    assert!(trajectory.append(s1).is_ok());
    assert!(verify_dynamics_inv_004_temporal_integrity(&trajectory).is_ok());

    // Non-monotonic time append must be rejected
    let s_backwards = DynamicalState::new(StateId::new("s_bad"), 0.05, vec![0.3]);
    assert!(trajectory.append(s_backwards).is_err());
}

#[test]
fn test_inv_005_evolution_integrity() {
    let law = EvolutionLaw::new("HarmonicOscillator", true, "dx/dt = v, dv/dt = -k*x");
    assert!(verify_dynamics_inv_005_evolution_integrity(&law).is_ok());

    let empty_law = EvolutionLaw::new("", true, "Undefined");
    assert!(verify_dynamics_inv_005_evolution_integrity(&empty_law).is_err());
}

#[test]
fn test_inv_006_007_independence_invariants() {
    assert!(verify_dynamics_inv_006_representation_independence("DenseCoordinateArray").is_ok());
    assert!(verify_dynamics_inv_006_representation_independence("").is_err());

    assert!(verify_dynamics_inv_007_provider_independence("SundialsCVODE").is_ok());
    assert!(verify_dynamics_inv_007_provider_independence("").is_err());
}

#[test]
fn test_inv_008_constraint_integrity() {
    let space = StateSpace::bounded(vec![-10.0, -10.0], vec![10.0, 10.0]).unwrap();
    let valid_state = DynamicalState::new(StateId::new("s_valid"), 0.0, vec![5.0, -3.0]);
    assert!(verify_dynamics_inv_008_constraint_integrity(&space, &valid_state).is_ok());

    let invalid_state = DynamicalState::new(StateId::new("s_out"), 0.0, vec![15.0, 0.0]);
    assert!(verify_dynamics_inv_008_constraint_integrity(&space, &invalid_state).is_err());
}

#[test]
fn test_inv_009_010_causal_and_delta_integrity() {
    let s0 = DynamicalState::new(StateId::new("s0"), 0.0, vec![1.0, 2.0]);
    let s1 = DynamicalState::new(StateId::new("s1"), 0.5, vec![1.5, 2.5]);
    let delta = StateDelta::between(&s0, &s1).unwrap();

    let trans = StateTransition::new(TransitionId::new("tr0"), s0.id, s1.id, delta.clone(), true);
    assert!(verify_dynamics_inv_009_causal_integrity(&trans).is_ok());

    assert!(verify_dynamics_inv_010_delta_integrity(&delta, 2).is_ok());
    assert!(verify_dynamics_inv_010_delta_integrity(&delta, 3).is_err());
}

#[test]
fn test_inv_011_history_integrity() {
    let s0 = DynamicalState::new(StateId::new("s0"), 0.0, vec![0.0]);
    let traj = Trajectory::new(TrajectoryId::new("traj_hist"), s0);
    assert!(verify_dynamics_inv_011_history_integrity(&traj).is_ok());
}

#[test]
fn test_inv_012_stochastic_integrity() {
    assert!(verify_dynamics_inv_012_stochastic_integrity(false, None).is_ok());
    assert!(verify_dynamics_inv_012_stochastic_integrity(true, Some("WienerProcess(sigma=0.1)")).is_ok());
    assert!(verify_dynamics_inv_012_stochastic_integrity(true, None).is_err());
}

#[test]
fn test_inv_013_stability_integrity() {
    assert!(verify_dynamics_inv_013_stability_integrity(Some(-0.85)).is_ok());
    assert!(verify_dynamics_inv_013_stability_integrity(Some(f64::NAN)).is_err());
    assert!(verify_dynamics_inv_013_stability_integrity(None).is_ok());
}

#[test]
fn test_inv_014_015_016_017_018_remaining_invariants() {
    assert!(verify_dynamics_inv_014_equivalence_integrity("TopologicalConjugacy").is_ok());
    assert!(verify_dynamics_inv_014_equivalence_integrity("   ").is_err());

    let sys = DynamicalSystem::new(
        SystemId::new("composed_system"),
        StateSpace::unconstrained(3),
        EvolutionLaw::new("Flow", true, "Linear vector field"),
        true,
    );
    assert!(verify_dynamics_inv_015_composition_integrity(&sys).is_ok());

    assert!(verify_dynamics_inv_016_approximation_integrity(true, Some(1e-5)).is_ok());
    assert!(verify_dynamics_inv_016_approximation_integrity(true, None).is_err());

    assert!(verify_dynamics_inv_017_provenance_integrity(Some("run://dynamo_step_100")).is_ok());
    assert!(verify_dynamics_inv_017_provenance_integrity(None).is_err());

    assert!(verify_dynamics_inv_018_runtime_independence("NativeCpuRuntime").is_ok());
    assert!(verify_dynamics_inv_018_runtime_independence("").is_err());
}
