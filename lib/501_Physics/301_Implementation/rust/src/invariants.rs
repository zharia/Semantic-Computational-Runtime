// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Normative Physics Invariant Validators
//!
//! Enforces PHYSICS-INV-001 through PHYSICS-INV-018 per Section on Invariants of
//! `lib/501_Physics/101_definition.md`.

use crate::body::PhysicalBody;
use crate::constraint::PhysicalConstraint;
use crate::error::{PhysicsError, PhysicsResult};
use crate::id::PhysicsEntityId;
use crate::interaction::PhysicalInteraction;
use crate::law::{ConservationContract, PhysicalLaw};
use crate::quantity::{Dimension, Quantity};
use scr_geometry::point::Point3D;

/// PHYSICS-INV-001: Physical meaning MUST be independent of implementation.
pub fn verify_physics_inv_001_semantic_primacy(id: &PhysicsEntityId) -> PhysicsResult<()> {
    if id.as_str().trim().is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-001: Physical entity identifier cannot be empty".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-002: Physical quantities MUST retain their dimensional and unit semantics.
pub fn verify_physics_inv_002_quantity_integrity(q: &Quantity) -> PhysicsResult<()> {
    if q.unit_name.trim().is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-002: Quantity must possess explicit unit semantics".to_string(),
        ));
    }
    if q.value.is_nan() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-002: Quantity value cannot be NaN".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-003: Physical laws MUST remain distinct from numerical implementations.
pub fn verify_physics_inv_003_law_integrity(law: &PhysicalLaw) -> PhysicsResult<()> {
    if law.name.trim().is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-003: Physical law must specify authoritative semantic name".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-004: Physical state MUST remain distinguishable from implementation state.
pub fn verify_physics_inv_004_state_integrity(body: &PhysicalBody) -> PhysicsResult<()> {
    if body.mass <= 0.0 {
        return Err(PhysicsError::InvariantViolation(format!(
            "PHYSICS-INV-004: Physical body must have positive real mass, found {}",
            body.mass
        )));
    }
    if body.state.position.x.is_nan() || body.state.velocity.x.is_nan() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-004: Kinematic state cannot contain NaN coordinates".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-005: Physical constraints MUST remain explicit and semantically identifiable.
pub fn verify_physics_inv_005_constraint_integrity(
    constraint: &PhysicalConstraint,
    pos_a: &Point3D,
    pos_b: Option<&Point3D>,
    tolerance: f64,
) -> PhysicsResult<()> {
    if let Some(pb) = pos_b {
        if !constraint.is_distance_satisfied(pos_a, pb, tolerance) {
            return Err(PhysicsError::InvariantViolation(format!(
                "PHYSICS-INV-005: Distance joint constraint {} not satisfied within tolerance {}",
                constraint.id, tolerance
            )));
        }
    }
    Ok(())
}

/// PHYSICS-INV-006: Declared conservation relationships MUST be representable independently of implementation.
pub fn verify_physics_inv_006_conservation_integrity(
    contract: &ConservationContract,
    initial: f64,
    current: f64,
) -> PhysicsResult<()> {
    contract.verify_conservation(initial, current)
}

/// PHYSICS-INV-007: Physical models MUST be associated with their applicable assumptions and validity domains.
pub fn verify_physics_inv_007_model_validity(law: &PhysicalLaw) -> PhysicsResult<()> {
    if law.validity_domain.trim().is_empty() {
        return Err(PhysicsError::InvariantViolation(format!(
            "PHYSICS-INV-007: Physical law {} lacks explicit validity domain assumptions",
            law.id
        )));
    }
    Ok(())
}

/// PHYSICS-INV-008: Physical semantics MUST NOT depend upon a particular representation.
pub fn verify_physics_inv_008_representation_independence(representation_name: &str) -> PhysicsResult<()> {
    if representation_name.is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-008: Representation carrier must be explicitly declared as subordinate".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-009: External physics implementations MUST NOT become semantic authorities.
pub fn verify_physics_inv_009_provider_independence(provider_name: &str) -> PhysicsResult<()> {
    if provider_name.is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-009: Provider must be explicitly declared as subordinate implementation".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-010: Reference-frame and coordinate semantics MUST remain explicit.
pub fn verify_physics_inv_010_reference_integrity(frame_name: &str) -> PhysicsResult<()> {
    if frame_name.trim().is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-010: Reference frame must be explicitly specified for physical coordinates".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-011: Physical state evolution MUST preserve explicit temporal semantics.
pub fn verify_physics_inv_011_temporal_integrity(dt: f64) -> PhysicsResult<()> {
    if dt <= 0.0 || dt.is_nan() {
        return Err(PhysicsError::InvariantViolation(format!(
            "PHYSICS-INV-011: Temporal time-step dt must be positive non-zero, found {}",
            dt
        )));
    }
    Ok(())
}

/// PHYSICS-INV-012: Physical uncertainty MUST remain distinguishable from numerical error.
pub fn verify_physics_inv_012_uncertainty_integrity(q: &Quantity) -> PhysicsResult<()> {
    if let Some(u) = q.uncertainty {
        if u < 0.0 || u.is_nan() {
            return Err(PhysicsError::InvariantViolation(format!(
                "PHYSICS-INV-012: Physical uncertainty must be non-negative real, found {}",
                u
            )));
        }
    }
    Ok(())
}

/// PHYSICS-INV-013: Approximations MUST NOT silently acquire exact physical meaning.
pub fn verify_physics_inv_013_approximation_integrity(is_approximate: bool, error_bound: Option<f64>) -> PhysicsResult<()> {
    if is_approximate && error_bound.is_none() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-013: Approximations must declare explicit error bounds".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-014: Physically meaningful equations MUST preserve required dimensional consistency.
pub fn verify_physics_inv_014_dimensional_integrity(dim_a: &Dimension, dim_b: &Dimension) -> PhysicsResult<()> {
    if dim_a != dim_b {
        return Err(PhysicsError::InvariantViolation(format!(
            "PHYSICS-INV-014: Dimensional inconsistency in physical equality: {:?} vs {:?}",
            dim_a, dim_b
        )));
    }
    Ok(())
}

/// PHYSICS-INV-015: Higher-order physical interactions MUST remain representable without mandatory binary reduction.
pub fn verify_physics_inv_015_interaction_integrity(interaction: &PhysicalInteraction) -> PhysicsResult<()> {
    if interaction.participants.is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-015: Higher-order interaction must declare participating bodies".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-016: Physical models and derived results MUST preserve relevant provenance.
pub fn verify_physics_inv_016_provenance_integrity(provenance: Option<&str>) -> PhysicsResult<()> {
    match provenance {
        Some(s) if !s.trim().is_empty() => Ok(()),
        _ => Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-016: Derived physical model lacks required provenance trace".to_string(),
        )),
    }
}

/// PHYSICS-INV-017: Semantic equivalence MUST be established under explicit applicable conditions.
pub fn verify_physics_inv_017_equivalence_integrity(condition: &str) -> PhysicsResult<()> {
    if condition.trim().is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-017: Physical equivalence claim must specify explicit condition domain".to_string(),
        ));
    }
    Ok(())
}

/// PHYSICS-INV-018: Physical semantics MUST remain independent of runtime and execution substrate.
pub fn verify_physics_inv_018_runtime_independence(substrate: &str) -> PhysicsResult<()> {
    if substrate.is_empty() {
        return Err(PhysicsError::InvariantViolation(
            "PHYSICS-INV-018: Runtime substrate must be explicitly declared as subordinate".to_string(),
        ));
    }
    Ok(())
}
