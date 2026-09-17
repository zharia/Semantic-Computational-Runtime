// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Metric Distances & Signed Distance Fields
//!
//! Conforming to GEOMETRY-INV-004 (Metric Integrity):
//! Metric assumptions MUST remain explicit and consistent.

use crate::point::Point3D;
use crate::primitives::{AABB3D, LineSegment3D, Plane3D, Sphere3D};

/// Euclidean metric distance between two points in $\mathbb{R}^3$.
pub fn distance_point_point(a: &Point3D, b: &Point3D) -> f64 {
    a.distance(b)
}

/// Manhattan ($L_1$) metric distance between two points in $\mathbb{R}^3$.
pub fn distance_point_point_manhattan(a: &Point3D, b: &Point3D) -> f64 {
    (a.x - b.x).abs() + (a.y - b.y).abs() + (a.z - b.z).abs()
}

/// Chebyshev ($L_\infty$) metric distance between two points in $\mathbb{R}^3$.
pub fn distance_point_point_chebyshev(a: &Point3D, b: &Point3D) -> f64 {
    (a.x - b.x).abs().max((a.y - b.y).abs()).max((a.z - b.z).abs())
}

/// Signed orthogonal distance from point `p` to a plane:
/// Positive in direction of normal, negative behind normal.
pub fn distance_point_plane_signed(p: &Point3D, plane: &Plane3D) -> f64 {
    plane.signed_distance(p)
}

/// Signed distance from point `p` to a sphere:
/// Negative inside sphere, zero on boundary, positive outside sphere.
pub fn distance_point_sphere_sdf(p: &Point3D, sphere: &Sphere3D) -> f64 {
    p.distance(&sphere.center) - sphere.radius
}

/// Signed distance from point `p` to an AABB.
pub fn distance_point_aabb_sdf(p: &Point3D, aabb: &AABB3D) -> f64 {
    let center = aabb.center();
    let half_extents = aabb.extents() * 0.5;

    let dx = (p.x - center.x).abs() - half_extents.x;
    let dy = (p.y - center.y).abs() - half_extents.y;
    let dz = (p.z - center.z).abs() - half_extents.z;

    let outside_x = dx.max(0.0);
    let outside_y = dy.max(0.0);
    let outside_z = dz.max(0.0);
    let outside_dist = (outside_x * outside_x + outside_y * outside_y + outside_z * outside_z).sqrt();

    let inside_dist = dx.max(dy).max(dz).min(0.0);

    outside_dist + inside_dist
}

/// Minimum distance from point `p` to a 1D line segment.
pub fn distance_point_segment(p: &Point3D, seg: &LineSegment3D) -> f64 {
    let ab = seg.end - seg.start;
    let ap = *p - seg.start;
    let ab_len_sq = ab.norm_squared();

    if ab_len_sq < 1e-12 {
        return p.distance(&seg.start);
    }

    let t = (ap.dot(&ab) / ab_len_sq).clamp(0.0, 1.0);
    let closest = seg.start + ab * t;
    p.distance(&closest)
}
