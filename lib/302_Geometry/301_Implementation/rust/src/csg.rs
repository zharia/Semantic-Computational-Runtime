// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Constructive Solid Geometry (CSG)
//!
//! Boolean composition operations conforming to GEOMETRY-INV-009 (Composition Integrity).

use crate::point::Point3D;
use crate::primitives::AABB3D;

/// Standard boolean union of two SDF values: $A \cup B$.
pub fn csg_union_sdf(d1: f64, d2: f64) -> f64 {
    d1.min(d2)
}

/// Standard boolean intersection of two SDF values: $A \cap B$.
pub fn csg_intersection_sdf(d1: f64, d2: f64) -> f64 {
    d1.max(d2)
}

/// Standard boolean difference of two SDF values: $A \setminus B$.
pub fn csg_difference_sdf(d1: f64, d2: f64) -> f64 {
    d1.max(-d2)
}

/// Polynomial smooth minimum for blending CSG unions with blending radius `k`.
pub fn csg_smooth_union_sdf(d1: f64, d2: f64, k: f64) -> f64 {
    if k <= 0.0 {
        return csg_union_sdf(d1, d2);
    }
    let h = (0.5 + 0.5 * (d2 - d1) / k).clamp(0.0, 1.0);
    let mix = (1.0 - h) * d2 + h * d1;
    mix - k * h * (1.0 - h)
}

/// Polynomial smooth intersection for blending CSG intersections with blending radius `k`.
pub fn csg_smooth_intersection_sdf(d1: f64, d2: f64, k: f64) -> f64 {
    if k <= 0.0 {
        return csg_intersection_sdf(d1, d2);
    }
    let h = (0.5 - 0.5 * (d2 - d1) / k).clamp(0.0, 1.0);
    let mix = (1.0 - h) * d1 + h * d2;
    mix + k * h * (1.0 - h)
}

/// Polynomial smooth difference for blending CSG differences with blending radius `k`.
pub fn csg_smooth_difference_sdf(d1: f64, d2: f64, k: f64) -> f64 {
    csg_smooth_intersection_sdf(d1, -d2, k)
}

/// Computes the bounding box enclosing the union of two AABBs.
pub fn aabb_union(a: &AABB3D, b: &AABB3D) -> AABB3D {
    AABB3D {
        min: Point3D::new(
            a.min.x.min(b.min.x),
            a.min.y.min(b.min.y),
            a.min.z.min(b.min.z),
        ),
        max: Point3D::new(
            a.max.x.max(b.max.x),
            a.max.y.max(b.max.y),
            a.max.z.max(b.max.z),
        ),
    }
}

/// Computes the intersection of two AABBs, returning `None` if they do not overlap.
pub fn aabb_intersection(a: &AABB3D, b: &AABB3D) -> Option<AABB3D> {
    let min_x = a.min.x.max(b.min.x);
    let min_y = a.min.y.max(b.min.y);
    let min_z = a.min.z.max(b.min.z);

    let max_x = a.max.x.min(b.max.x);
    let max_y = a.max.y.min(b.max.y);
    let max_z = a.max.z.min(b.max.z);

    if min_x <= max_x && min_y <= max_y && min_z <= max_z {
        Some(AABB3D {
            min: Point3D::new(min_x, min_y, min_z),
            max: Point3D::new(max_x, max_y, max_z),
        })
    } else {
        None
    }
}
