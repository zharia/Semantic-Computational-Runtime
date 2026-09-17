// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_geometry::point::{Point3D, Vector3D};
use scr_geometry::predicates::*;
use scr_geometry::primitives::*;

#[test]
fn test_ray_sphere_intersection() {
    let sphere = Sphere3D::new(Point3D::new(0.0, 0.0, 10.0), 2.0).unwrap();

    // Ray pointing directly at sphere center
    let ray_hit = Ray3D::new(Point3D::ORIGIN, Vector3D::UNIT_Z).unwrap();
    let hit_t = intersect_ray_sphere(&ray_hit, &sphere);
    assert!(hit_t.is_some());
    // Sphere center at z=10, radius 2 -> nearest hit at z=8 (t=8.0)
    assert!((hit_t.unwrap() - 8.0).abs() < 1e-9);

    // Ray pointing away
    let ray_miss = Ray3D::new(Point3D::ORIGIN, -Vector3D::UNIT_Z).unwrap();
    assert!(intersect_ray_sphere(&ray_miss, &sphere).is_none());
}

#[test]
fn test_ray_plane_intersection() {
    // Plane z = 5
    let plane = Plane3D::new(Point3D::new(0.0, 0.0, 5.0), Vector3D::UNIT_Z).unwrap();
    let ray = Ray3D::new(Point3D::ORIGIN, Vector3D::UNIT_Z).unwrap();

    let hit_t = intersect_ray_plane(&ray, &plane);
    assert!(hit_t.is_some());
    assert!((hit_t.unwrap() - 5.0).abs() < 1e-9);
}

#[test]
fn test_ray_aabb_intersection() {
    let aabb = AABB3D::new(
        Point3D::new(-1.0, -1.0, 5.0),
        Point3D::new(1.0, 1.0, 7.0),
    ).unwrap();

    let ray = Ray3D::new(Point3D::ORIGIN, Vector3D::UNIT_Z).unwrap();
    let hit = intersect_ray_aabb(&ray, &aabb);
    assert!(hit.is_some());
    let (tmin, tmax) = hit.unwrap();
    assert!((tmin - 5.0).abs() < 1e-9);
    assert!((tmax - 7.0).abs() < 1e-9);
}

#[test]
fn test_ray_triangle_moller_trumbore() {
    // Triangle in z = 5 plane
    let tri = Triangle3D::new(
        Point3D::new(-1.0, -1.0, 5.0),
        Point3D::new(1.0, -1.0, 5.0),
        Point3D::new(0.0, 1.0, 5.0),
    );

    // Ray hitting triangle center
    let ray = Ray3D::new(Point3D::ORIGIN, Vector3D::UNIT_Z).unwrap();
    let hit = intersect_ray_triangle(&ray, &tri);
    assert!(hit.is_some());
    let (t, u, v) = hit.unwrap();
    assert!((t - 5.0).abs() < 1e-9);
    assert!(u >= 0.0 && v >= 0.0 && (u + v) <= 1.0);

    // Point in triangle predicate
    let p_inside = Point3D::new(0.0, 0.0, 5.0);
    assert!(point_in_triangle(&p_inside, &tri));

    let p_outside = Point3D::new(5.0, 5.0, 5.0);
    assert!(!point_in_triangle(&p_outside, &tri));
}
