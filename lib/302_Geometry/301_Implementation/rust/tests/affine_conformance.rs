// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_geometry::point::{Point3D, Vector3D};

#[test]
fn test_affine_point_vector_operations() {
    let p = Point3D::new(1.0, 2.0, 3.0);
    let v = Vector3D::new(4.0, 5.0, 6.0);

    // Point + Vector -> Point
    let p2 = p + v;
    assert_eq!(p2, Point3D::new(5.0, 7.0, 9.0));

    // Point - Vector -> Point
    let p_back = p2 - v;
    assert_eq!(p_back, p);

    // Point - Point -> Vector
    let disp = p2 - p;
    assert_eq!(disp, v);

    // Vector operations
    let v2 = Vector3D::new(1.0, -1.0, 0.0);
    let v_sum = v + v2;
    assert_eq!(v_sum, Vector3D::new(5.0, 4.0, 6.0));

    let dot = v.dot(&v2);
    assert_eq!(dot, 4.0 * 1.0 + 5.0 * (-1.0) + 6.0 * 0.0); // -1.0

    let cross = Vector3D::UNIT_X.cross(&Vector3D::UNIT_Y);
    assert_eq!(cross, Vector3D::UNIT_Z);
}

#[test]
fn test_affine_combinations() {
    let p1 = Point3D::new(0.0, 0.0, 0.0);
    let p2 = Point3D::new(10.0, 0.0, 0.0);
    let p3 = Point3D::new(0.0, 10.0, 0.0);

    // Centroid: w1 = 1/3, w2 = 1/3, w3 = 1/3
    let centroid = Point3D::affine_combination(&[
        (1.0 / 3.0, p1),
        (1.0 / 3.0, p2),
        (1.0 / 3.0, p3),
    ]).unwrap();

    assert!((centroid.x - 10.0 / 3.0).abs() < 1e-9);
    assert!((centroid.y - 10.0 / 3.0).abs() < 1e-9);
    assert_eq!(centroid.z, 0.0);

    // Invalid weights (sum != 1.0) rejected
    let invalid = Point3D::affine_combination(&[
        (0.5, p1),
        (0.2, p2),
    ]);
    assert!(invalid.is_err());
}

#[test]
fn test_math_vector_interoperability() {
    let v_geom = Vector3D::new(1.5, -2.5, 3.5);
    let math_vec: scr_math::Vector = v_geom.into();
    assert_eq!(math_vec.dim(), 3);
    assert_eq!(math_vec.as_slice(), &[1.5, -2.5, 3.5]);

    let roundtrip_geom = Vector3D::try_from(math_vec).unwrap();
    assert_eq!(roundtrip_geom, v_geom);
}
