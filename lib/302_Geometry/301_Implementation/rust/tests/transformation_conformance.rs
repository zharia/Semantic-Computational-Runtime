// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_geometry::point::{Point3D, Vector3D};
use scr_geometry::primitives::{AABB3D, Ray3D};
use scr_geometry::transform::Transform3D;
use scr_math::Quaternion;

#[test]
fn test_transform_point_and_vector() {
    // Rotation by 90 degrees around Z axis
    // In quaternion: w = cos(45 deg) = sqrt(2)/2, z = sin(45 deg) = sqrt(2)/2
    let half_angle = std::f64::consts::FRAC_PI_4;
    let rot_z_90 = Quaternion::new(half_angle.cos(), 0.0, 0.0, half_angle.sin());

    let trans = Transform3D::new(
        Vector3D::new(10.0, 0.0, 0.0), // Translation along X
        rot_z_90,
        Vector3D::new(1.0, 1.0, 1.0),
    );

    // Point at (1, 0, 0):
    // After rotation by 90 deg around Z: (0, 1, 0)
    // After translation: (10, 1, 0)
    let p = Point3D::new(1.0, 0.0, 0.0);
    let p_transformed = trans.apply_point(&p);
    assert!((p_transformed.x - 10.0).abs() < 1e-6);
    assert!((p_transformed.y - 1.0).abs() < 1e-6);
    assert_eq!(p_transformed.z, 0.0);

    // Vector along X (1, 0, 0):
    // Rotates to (0, 1, 0), invariant to translation!
    let v = Vector3D::UNIT_X;
    let v_transformed = trans.apply_vector(&v);
    assert!(v_transformed.x.abs() < 1e-6);
    assert!((v_transformed.y - 1.0).abs() < 1e-6);
    assert_eq!(v_transformed.z, 0.0);
}

#[test]
fn test_transform_inversion_roundtrip() {
    let trans = Transform3D::new(
        Vector3D::new(3.0, -4.0, 5.0),
        Quaternion::new(0.7071, 0.0, 0.7071, 0.0).normalize().unwrap(),
        Vector3D::new(2.0, 2.0, 2.0),
    );

    let inv = trans.inverse().unwrap();
    let p = Point3D::new(7.0, 11.0, -13.0);

    let p_trans = trans.apply_point(&p);
    let p_roundtrip = inv.apply_point(&p_trans);

    assert!((p_roundtrip.x - p.x).abs() < 1e-6);
    assert!((p_roundtrip.y - p.y).abs() < 1e-6);
    assert!((p_roundtrip.z - p.z).abs() < 1e-6);
}

#[test]
fn test_transform_ray_and_aabb() {
    let trans = Transform3D::from_translation(Vector3D::new(5.0, 5.0, 5.0));

    let ray = Ray3D::new(Point3D::ORIGIN, Vector3D::UNIT_Z).unwrap();
    let transformed_ray = trans.apply_ray(&ray).unwrap();
    assert_eq!(transformed_ray.origin, Point3D::new(5.0, 5.0, 5.0));
    assert_eq!(transformed_ray.direction, Vector3D::UNIT_Z);

    let aabb = AABB3D::new(Point3D::new(-1.0, -1.0, -1.0), Point3D::new(1.0, 1.0, 1.0)).unwrap();
    let transformed_aabb = trans.apply_aabb(&aabb).unwrap();
    assert_eq!(transformed_aabb.min, Point3D::new(4.0, 4.0, 4.0));
    assert_eq!(transformed_aabb.max, Point3D::new(6.0, 6.0, 6.0));
}
