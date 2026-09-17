// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_geometry::dimension::GeometricDimension;
use scr_geometry::invariants::*;
use scr_geometry::point::{Point3D, Vector3D};
use scr_geometry::primitives::AABB3D;
use scr_geometry::transform::Transform3D;
use scr_geometry::hypergraph::GeometricId;
use scr_math::{Quaternion, ToleranceContract};

#[test]
fn test_all_18_geometry_invariants() {
    // 001 - Identity
    let id = GeometricId::new("sphere_001");
    assert!(verify_geometry_inv_001_identity(&id).is_ok());

    // 002 - Dimensional Integrity
    assert!(verify_geometry_inv_002_dimensional_integrity(
        GeometricDimension::Dim3D,
        GeometricDimension::Dim3D
    ).is_ok());
    assert!(verify_geometry_inv_002_dimensional_integrity(
        GeometricDimension::Dim2D,
        GeometricDimension::Dim3D
    ).is_err());

    // 003 - Coordinate Integrity
    let p = Point3D::new(1.0, 2.0, 3.0);
    let trans = Transform3D::new(
        Vector3D::new(5.0, -2.0, 1.0),
        Quaternion::identity(),
        Vector3D::new(2.0, 2.0, 2.0),
    );
    let tol = ToleranceContract::new(1e-6, 1e-6);
    assert!(verify_geometry_inv_003_coordinate_integrity(&p, &trans, &tol).is_ok());

    // 004 - Metric Integrity (Triangle Inequality)
    let p1 = Point3D::new(0.0, 0.0, 0.0);
    let p2 = Point3D::new(1.0, 0.0, 0.0);
    let p3 = Point3D::new(1.0, 1.0, 0.0);
    assert!(verify_geometry_inv_004_metric_integrity(&p1, &p2, &p3).is_ok());

    // 005 - Boundary Integrity
    let valid_aabb = AABB3D::new(Point3D::new(-1.0, -1.0, -1.0), Point3D::new(1.0, 1.0, 1.0)).unwrap();
    assert!(verify_geometry_inv_005_boundary_integrity(&valid_aabb).is_ok());

    // 006 - Transformation Integrity (Isometry)
    let rigid = Transform3D::from_translation(Vector3D::new(10.0, 20.0, 30.0));
    assert!(verify_geometry_inv_006_transformation_integrity(&p1, &p2, &rigid).is_ok());

    // 007 - Topological Integrity (Euler Characteristic)
    assert!(verify_geometry_inv_007_topological_integrity(2, 2).is_ok());
    assert!(verify_geometry_inv_007_topological_integrity(2, 0).is_err());

    // 008 - Approximation Integrity
    assert!(verify_geometry_inv_008_approximation_integrity(3.1415, std::f64::consts::PI, 1e-3).is_ok());
    assert!(verify_geometry_inv_008_approximation_integrity(3.1, std::f64::consts::PI, 1e-3).is_err());

    // 009 - Composition Integrity
    let pt = Point3D::new(0.5, 0.5, 0.5);
    assert!(verify_geometry_inv_009_composition_integrity(&pt, true, false, true).is_ok());
    assert!(verify_geometry_inv_009_composition_integrity(&pt, false, false, false).is_ok());

    // 010 - Measurement Integrity
    assert!(verify_geometry_inv_010_measurement_integrity(42.0, "surface_area").is_ok());
    assert!(verify_geometry_inv_010_measurement_integrity(-1.0, "volume").is_err());

    // 011 - Provenance Integrity
    assert!(verify_geometry_inv_011_provenance_integrity("CSG:Union(Sphere, Box)").is_ok());
    assert!(verify_geometry_inv_011_provenance_integrity("   ").is_err());

    // 012 - Delta Integrity
    let valid_delta = Vector3D::new(0.1, 0.2, -0.3);
    assert!(verify_geometry_inv_012_delta_integrity(&valid_delta).is_ok());
    let nan_delta = Vector3D::new(f64::NAN, 0.0, 0.0);
    assert!(verify_geometry_inv_012_delta_integrity(&nan_delta).is_err());

    // 013..018 - Authority Invariants
    assert!(verify_geometry_authority_invariants("OpenGL Vertex Buffer", false).is_ok());
    assert!(verify_geometry_authority_invariants("Direct3D", true).is_err());
    assert!(verify_geometry_authority_invariants("OBJ File", true).is_err());
}
