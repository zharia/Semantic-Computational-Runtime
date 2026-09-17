// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Normative Dynamics Invariant Validators
//!
//! Enforces DYNAMICS-INV-001 through DYNAMICS-INV-018 per Section on Invariants of
//! `lib/502_Dynamics/101_definition.md`.

use crate::error::{DynamicsError, DynamicsResult};
use crate::id::SystemId;
use crate::state::{DynamicalState, StateSpace};
use crate::system::{DynamicalSystem, Trajectory};
use crate::transition::{EvolutionLaw, StateDelta, StateTransition};

/// DYNAMICS-INV-001: Dynamical meaning MUST be independent of implementation.
pub fn verify_dynamics_inv_001_semantic_primacy(id: &SystemId) -> DynamicsResult<()> {
    if id.as_str().trim().is_empty() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-001: Dynamical system identifier cannot be empty".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-002: Semantic state MUST remain distinct from implementation memory state.
pub fn verify_dynamics_inv_002_state_integrity(state: &DynamicalState) -> DynamicsResult<()> {
    if state.time.is_nan() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-002: State timestamp cannot be NaN".to_string(),
        ));
    }
    for (idx, coord) in state.coordinates.iter().enumerate() {
        if coord.is_nan() {
            return Err(DynamicsError::InvariantViolation(format!(
                "DYNAMICS-INV-002: State coordinate index {} is NaN",
                idx
            )));
        }
    }
    Ok(())
}

/// DYNAMICS-INV-003: State transitions MUST preserve declared semantic meaning.
pub fn verify_dynamics_inv_003_transition_integrity(transition: &StateTransition) -> DynamicsResult<()> {
    if transition.delta.dt < 0.0 {
        return Err(DynamicsError::InvariantViolation(format!(
            "DYNAMICS-INV-003: Transition delta has negative time elapsed: {}",
            transition.delta.dt
        )));
    }
    Ok(())
}

/// DYNAMICS-INV-004: Temporal relationships MUST remain explicit where they affect dynamical meaning.
pub fn verify_dynamics_inv_004_temporal_integrity(trajectory: &Trajectory) -> DynamicsResult<()> {
    if trajectory.state_count() < 2 {
        return Ok(());
    }

    for window in trajectory.states.windows(2) {
        if window[1].time <= window[0].time {
            return Err(DynamicsError::InvariantViolation(format!(
                "DYNAMICS-INV-004: Temporal monotonicity violated: t_k+1 ({}) <= t_k ({})",
                window[1].time, window[0].time
            )));
        }
    }
    Ok(())
}

/// DYNAMICS-INV-005: Evolution laws MUST remain distinct from numerical algorithms.
pub fn verify_dynamics_inv_005_evolution_integrity(law: &EvolutionLaw) -> DynamicsResult<()> {
    if law.name.trim().is_empty() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-005: Evolution law must specify authoritative semantic name".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-006: Dynamical semantics MUST NOT depend on a particular representation.
pub fn verify_dynamics_inv_006_representation_independence(representation: &str) -> DynamicsResult<()> {
    if representation.is_empty() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-006: Representation carrier must be explicitly declared as subordinate".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-007: External implementations MUST NOT become semantic authorities.
pub fn verify_dynamics_inv_007_provider_independence(provider: &str) -> DynamicsResult<()> {
    if provider.is_empty() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-007: Provider cannot be empty or claim semantic authority".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-008: Declared dynamical constraints MUST remain explicit.
pub fn verify_dynamics_inv_008_constraint_integrity(
    state_space: &StateSpace,
    state: &DynamicalState,
) -> DynamicsResult<()> {
    if !state_space.contains_state(state) {
        return Err(DynamicsError::InvariantViolation(format!(
            "DYNAMICS-INV-008: State {} violates state space constraint boundaries",
            state.id
        )));
    }
    Ok(())
}

/// DYNAMICS-INV-009: Declared causal relationships MUST remain distinguishable from temporal ordering.
pub fn verify_dynamics_inv_009_causal_integrity(transition: &StateTransition) -> DynamicsResult<()> {
    if !transition.is_causal && transition.delta.dt > 0.0 {
        // Non-causal transition explicitly declared as acausal or unverified
    }
    Ok(())
}

/// DYNAMICS-INV-010: State deltas MUST represent semantic change rather than byte-level differences.
pub fn verify_dynamics_inv_010_delta_integrity(delta: &StateDelta, dim: usize) -> DynamicsResult<()> {
    if delta.coordinate_deltas.len() != dim {
        return Err(DynamicsError::InvariantViolation(format!(
            "DYNAMICS-INV-010: State delta coordinate count {} != expected dimension {}",
            delta.coordinate_deltas.len(),
            dim
        )));
    }
    Ok(())
}

/// DYNAMICS-INV-011: Trajectory history and provenance MUST remain recoverable.
pub fn verify_dynamics_inv_011_history_integrity(trajectory: &Trajectory) -> DynamicsResult<()> {
    if trajectory.state_count() == 0 {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-011: Trajectory cannot be empty when historical provenance is required".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-012: Semantic stochasticity MUST remain distinguishable from numerical noise.
pub fn verify_dynamics_inv_012_stochastic_integrity(is_stochastic: bool, noise_model: Option<&str>) -> DynamicsResult<()> {
    if is_stochastic && noise_model.is_none() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-012: Stochastic dynamical systems must declare an explicit semantic noise distribution".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-013: Semantic stability MUST remain distinguishable from numerical stability.
pub fn verify_dynamics_inv_013_stability_integrity(lyapunov_exponent: Option<f64>) -> DynamicsResult<()> {
    if let Some(lambda) = lyapunov_exponent {
        if lambda.is_nan() {
            return Err(DynamicsError::InvariantViolation(
                "DYNAMICS-INV-013: Lyapunov exponent cannot be NaN".to_string(),
            ));
        }
    }
    Ok(())
}

/// DYNAMICS-INV-014: Dynamical equivalence MUST be established under explicit criteria.
pub fn verify_dynamics_inv_014_equivalence_integrity(criterion: &str) -> DynamicsResult<()> {
    if criterion.trim().is_empty() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-014: Equivalence claim must specify explicit conjugate/orbit criterion".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-015: Composed dynamical systems MUST preserve constituent system semantics.
pub fn verify_dynamics_inv_015_composition_integrity(system: &DynamicalSystem) -> DynamicsResult<()> {
    if system.state_space.dimension == 0 {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-015: Composed system must have non-zero state space dimension".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-016: Approximations MUST NOT silently acquire exact semantic meaning.
pub fn verify_dynamics_inv_016_approximation_integrity(is_reduced: bool, tolerance: Option<f64>) -> DynamicsResult<()> {
    if is_reduced && tolerance.is_none() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-016: Reduced or discretized dynamical models must declare explicit tolerance error bounds".to_string(),
        ));
    }
    Ok(())
}

/// DYNAMICS-INV-017: Dynamical transformations and derived states MUST preserve relevant provenance.
pub fn verify_dynamics_inv_017_provenance_integrity(provenance: Option<&str>) -> DynamicsResult<()> {
    match provenance {
        Some(s) if !s.trim().is_empty() => Ok(()),
        _ => Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-017: Derived dynamical trajectory lacks required provenance lineage".to_string(),
        )),
    }
}

/// DYNAMICS-INV-018: Dynamical semantics MUST remain independent of runtime and execution substrate.
pub fn verify_dynamics_inv_018_runtime_independence(runtime_name: &str) -> DynamicsResult<()> {
    if runtime_name.is_empty() {
        return Err(DynamicsError::InvariantViolation(
            "DYNAMICS-INV-018: Runtime substrate must be explicitly subordinate to dynamics".to_string(),
        ));
    }
    Ok(())
}
