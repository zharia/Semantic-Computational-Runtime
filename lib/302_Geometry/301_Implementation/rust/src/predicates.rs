// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Geometric Predicates & Intersections
//!
//! Containment, collision, and ray-casting intersections conforming to
//! GEOMETRY-INV-004 (Metric Integrity) and GEOMETRY-INV-006 (Transformation Integrity).

use crate::point::Point3D;
use crate::primitives::{AABB3D, Plane3D, Ray3D, Sphere3D, Triangle3D};

/// Checks if a point lies inside or on the boundary of a sphere.
pub fn point_in_sphere(p: &Point3D, sphere: &Sphere3D) -> bool {
    sphere.contains(p)
}

/// Checks if a point lies inside or on the boundary of an AABB.
pub fn point_in_aabb(p: &Point3D, aabb: &AABB3D) -> bool {
    aabb.contains(p)
}

/// Checks if a point lies inside a planar triangle using barycentric coordinates.
pub fn point_in_triangle(p: &Point3D, tri: &Triangle3D) -> bool {
    let v0 = tri.c - tri.a;
    let v1 = tri.b - tri.a;
    let v2 = *p - tri.a;

    let dot00 = v0.dot(&v0);
    let dot01 = v0.dot(&v1);
    let dot02 = v0.dot(&v2);
    let dot11 = v1.dot(&v1);
    let dot12 = v1.dot(&v2);

    let denom = dot00 * dot11 - dot01 * dot01;
    if denom.abs() < 1e-12 {
        return false;
    }

    let inv_denom = 1.0 / denom;
    let u = (dot11 * dot02 - dot01 * dot12) * inv_denom;
    let v = (dot00 * dot12 - dot01 * dot02) * inv_denom;

    u >= -1e-7 && v >= -1e-7 && (u + v) <= 1.0 + 1e-7
}

/// Computes the intersection of a ray with a sphere.
///
/// Returns the nearest positive ray parameter $t \ge 0$, or `None` if no hit.
pub fn intersect_ray_sphere(ray: &Ray3D, sphere: &Sphere3D) -> Option<f64> {
    let oc = ray.origin - sphere.center;
    let a = ray.direction.dot(&ray.direction); // == 1.0 for normalized dir
    let b = 2.0 * oc.dot(&ray.direction);
    let c = oc.dot(&oc) - sphere.radius * sphere.radius;
    let discriminant = b * b - 4.0 * a * c;

    if discriminant < 0.0 {
        return None;
    }

    let sqrt_d = discriminant.sqrt();
    let t0 = (-b - sqrt_d) / (2.0 * a);
    let t1 = (-b + sqrt_d) / (2.0 * a);

    if t0 >= 0.0 {
        Some(t0)
    } else if t1 >= 0.0 {
        Some(t1)
    } else {
        None
    }
}

/// Computes the intersection of a ray with an infinite plane.
///
/// Returns positive ray parameter $t \ge 0$, or `None` if parallel or pointing away.
pub fn intersect_ray_plane(ray: &Ray3D, plane: &Plane3D) -> Option<f64> {
    let denom = plane.normal.dot(&ray.direction);
    if denom.abs() < 1e-9 {
        return None; // Parallel
    }

    let p0_l0 = plane.point - ray.origin;
    let t = p0_l0.dot(&plane.normal) / denom;
    if t >= 0.0 {
        Some(t)
    } else {
        None
    }
}

/// Computes the intersection of a ray with an AABB using the slab method.
///
/// Returns $(t_{\min}, t_{\max})$ if the ray intersects the volume with $t_{\max} \ge 0$.
pub fn intersect_ray_aabb(ray: &Ray3D, aabb: &AABB3D) -> Option<(f64, f64)> {
    let mut tmin = (aabb.min.x - ray.origin.x) / ray.direction.x;
    let mut tmax = (aabb.max.x - ray.origin.x) / ray.direction.x;

    if tmin > tmax {
        std::mem::swap(&mut tmin, &mut tmax);
    }

    let mut tymin = (aabb.min.y - ray.origin.y) / ray.direction.y;
    let mut tymax = (aabb.max.y - ray.origin.y) / ray.direction.y;

    if tymin > tymax {
        std::mem::swap(&mut tymin, &mut tymax);
    }

    if (tmin > tymax) || (tymin > tmax) {
        return None;
    }

    if tymin > tmin {
        tmin = tymin;
    }
    if tymax < tmax {
        tmax = tymax;
    }

    let mut tzmin = (aabb.min.z - ray.origin.z) / ray.direction.z;
    let mut tzmax = (aabb.max.z - ray.origin.z) / ray.direction.z;

    if tzmin > tzmax {
        std::mem::swap(&mut tzmin, &mut tzmax);
    }

    if (tmin > tzmax) || (tzmin > tmax) {
        return None;
    }

    if tzmin > tmin {
        tmin = tzmin;
    }
    if tzmax < tmax {
        tmax = tzmax;
    }

    if tmax < 0.0 {
        return None;
    }

    Some((tmin.max(0.0), tmax))
}

/// Möller–Trumbore intersection algorithm between a ray and a 3D triangle.
///
/// Returns $(t, u, v)$ where $t$ is ray parameter and $(u, v)$ are barycentric coordinates
/// such that $P = (1 - u - v)A + u B + v C$.
pub fn intersect_ray_triangle(ray: &Ray3D, tri: &Triangle3D) -> Option<(f64, f64, f64)> {
    const EPSILON: f64 = 1e-8;
    let edge1 = tri.b - tri.a;
    let edge2 = tri.c - tri.a;

    let h = ray.direction.cross(&edge2);
    let a = edge1.dot(&h);

    if a.abs() < EPSILON {
        return None; // Ray is parallel to triangle
    }

    let f = 1.0 / a;
    let s = ray.origin - tri.a;
    let u = f * s.dot(&h);

    if u < 0.0 || u > 1.0 {
        return None;
    }

    let q = s.cross(&edge1);
    let v = f * ray.direction.dot(&q);

    if v < 0.0 || (u + v) > 1.0 {
        return None;
    }

    let t = f * edge2.dot(&q);
    if t > EPSILON {
        Some((t, u, v))
    } else {
        None
    }
}
