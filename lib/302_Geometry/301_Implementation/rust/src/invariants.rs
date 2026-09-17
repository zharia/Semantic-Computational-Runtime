// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Normative Geometry Invariants
//!
//! Conforming to Section 51 of `lib/302_Geometry/101_definition.md` (`GEOMETRY-INV-001` - `018`).

use crate::dimension::GeometricDimension;
use crate::error::{GeometryError, GeometryResult};
use crate::hypergraph::GeometricId;
use crate::point::{Point3D, Vector3D};
use crate::primitives::AABB3D;
use crate::transform::Transform3D;
use scr_math::ToleranceContract;

/// Verifies GEOMETRY-INV-001 (Identity): Geometric entities MUST have stable semantic identity.
pub fn verify_geometry_inv_001_identity(id: &GeometricId) -> GeometryResult<()> {
    if id.as_str().trim().is_empty() {
        return Err(GeometryError::InvariantViolation(
            "GEOMETRY-INV-001: Entity ID cannot be empty".to_string(),
        ));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-002 (Dimensional Integrity): Geometric dimension MUST be preserved.
pub fn verify_geometry_inv_002_dimensional_integrity(
    before: GeometricDimension,
    after: GeometricDimension,
) -> GeometryResult<()> {
    if !before.is_compatible(&after) {
        return Err(GeometryError::InvariantViolation(format!(
            "GEOMETRY-INV-002: Dimension altered from {} to {} without explicit projection",
            before, after
        )));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-003 (Coordinate Integrity): Coordinate transformations preserve declared reference semantics.
pub fn verify_geometry_inv_003_coordinate_integrity(
    original_point: &Point3D,
    transform: &Transform3D,
    tolerance: &ToleranceContract,
) -> GeometryResult<()> {
    let inv_t = transform.inverse()?;
    let transformed = transform.apply_point(original_point);
    let roundtrip = inv_t.apply_point(&transformed);

    if !tolerance.is_within_tolerance(original_point.x, roundtrip.x)
        || !tolerance.is_within_tolerance(original_point.y, roundtrip.y)
        || !tolerance.is_within_tolerance(original_point.z, roundtrip.z)
    {
        return Err(GeometryError::InvariantViolation(
            "GEOMETRY-INV-003: Invertible coordinate transform failed roundtrip identity".to_string(),
        ));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-004 (Metric Integrity): Metric assumptions MUST remain explicit and consistent.
pub fn verify_geometry_inv_004_metric_integrity(
    p1: &Point3D,
    p2: &Point3D,
    p3: &Point3D,
) -> GeometryResult<()> {
    let d12 = p1.distance(p2);
    let d23 = p2.distance(p3);
    let d13 = p1.distance(p3);

    // Triangle inequality: d(x, z) <= d(x, y) + d(y, z)
    if d13 > d12 + d23 + 1e-9 {
        return Err(GeometryError::InvariantViolation(
            "GEOMETRY-INV-004: Metric violated triangle inequality".to_string(),
        ));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-005 (Boundary Integrity): Declared boundaries MUST remain semantically valid.
pub fn verify_geometry_inv_005_boundary_integrity(aabb: &AABB3D) -> GeometryResult<()> {
    if aabb.min.x > aabb.max.x || aabb.min.y > aabb.max.y || aabb.min.z > aabb.max.z {
        return Err(GeometryError::InvariantViolation(
            "GEOMETRY-INV-005: Boundary min coordinates exceed max coordinates".to_string(),
        ));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-006 (Transformation Integrity): Rigid transformations preserve Euclidean distance.
pub fn verify_geometry_inv_006_transformation_integrity(
    p1: &Point3D,
    p2: &Point3D,
    rigid_transform: &Transform3D,
) -> GeometryResult<()> {
    if !rigid_transform.is_rigid() {
        return Err(GeometryError::InvariantViolation(
            "GEOMETRY-INV-006: Expected rigid transformation".to_string(),
        ));
    }

    let orig_dist = p1.distance(p2);
    let t_p1 = rigid_transform.apply_point(p1);
    let t_p2 = rigid_transform.apply_point(p2);
    let trans_dist = t_p1.distance(&t_p2);

    if (orig_dist - trans_dist).abs() > 1e-6 {
        return Err(GeometryError::InvariantViolation(format!(
            "GEOMETRY-INV-006: Isometry distance violated: before={}, after={}",
            orig_dist, trans_dist
        )));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-007 (Topological Integrity): Operations claiming topology preservation preserve Euler characteristic.
pub fn verify_geometry_inv_007_topological_integrity(
    initial_chi: i64,
    final_chi: i64,
) -> GeometryResult<()> {
    if initial_chi != final_chi {
        return Err(GeometryError::InvariantViolation(format!(
            "GEOMETRY-INV-007: Euler characteristic altered from {} to {}",
            initial_chi, final_chi
        )));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-008 (Approximation Integrity): Approximations MUST remain within declared error bounds.
pub fn verify_geometry_inv_008_approximation_integrity(
    approx_val: f64,
    exact_val: f64,
    max_error: f64,
) -> GeometryResult<()> {
    let err = (approx_val - exact_val).abs();
    if err > max_error {
        return Err(GeometryError::ToleranceExceeded {
            expected: max_error,
            actual: err,
        });
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-009 (Composition Integrity): Constituents preserved under boolean union.
pub fn verify_geometry_inv_009_composition_integrity(
    pt: &Point3D,
    in_a: bool,
    in_b: bool,
    in_union: bool,
) -> GeometryResult<()> {
    let expected = in_a || in_b;
    if in_union != expected {
        return Err(GeometryError::InvariantViolation(format!(
            "GEOMETRY-INV-009: Point {:?} in_union={}, expected in_a || in_b = {}",
            pt, in_union, expected
        )));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-010 (Measurement Integrity): Measurements are non-negative and finite.
pub fn verify_geometry_inv_010_measurement_integrity(val: f64, name: &str) -> GeometryResult<()> {
    if val < 0.0 || val.is_nan() || val.is_infinite() {
        return Err(GeometryError::InvariantViolation(format!(
            "GEOMETRY-INV-010: Measurement {} has invalid value {}",
            name, val
        )));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-011 (Provenance Integrity): Provenance metadata is non-empty.
pub fn verify_geometry_inv_011_provenance_integrity(provenance: &str) -> GeometryResult<()> {
    if provenance.trim().is_empty() {
        return Err(GeometryError::InvariantViolation(
            "GEOMETRY-INV-011: Geometric entity missing required provenance".to_string(),
        ));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-012 (Delta Integrity): State transitions produce valid geometric structures.
pub fn verify_geometry_inv_012_delta_integrity(displacement: &Vector3D) -> GeometryResult<()> {
    if displacement.x.is_nan() || displacement.y.is_nan() || displacement.z.is_nan() {
        return Err(GeometryError::InvariantViolation(
            "GEOMETRY-INV-012: Geometric delta contains NaN components".to_string(),
        ));
    }
    Ok(())
}

/// Verifies GEOMETRY-INV-013 through 018: Metaphysical and technological independence invariants.
pub fn verify_geometry_authority_invariants(
    claimant_system: &str,
    is_authoritative: bool,
) -> GeometryResult<()> {
    if is_authoritative {
        return Err(GeometryError::InvariantViolation(format!(
            "GEOMETRY-INV-013..018: External subsystem '{}' cannot claim semantic geometric authority",
            claimant_system
        )));
    }
    Ok(())
}
