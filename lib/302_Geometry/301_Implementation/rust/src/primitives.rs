// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Standard Geometric Primitives
//!
//! Normative representations of 0D, 1D, 2D, and 3D geometric primitives conforming to
//! GEOMETRY-INV-002 (Dimensional Integrity) and GEOMETRY-INV-005 (Boundary Integrity).

use crate::error::{GeometryError, GeometryResult};
use crate::point::{Point3D, Vector3D};

/// A bounded 1D line segment between two endpoints.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct LineSegment3D {
    pub start: Point3D,
    pub end: Point3D,
}

impl LineSegment3D {
    pub fn new(start: Point3D, end: Point3D) -> Self {
        Self { start, end }
    }

    pub fn length(&self) -> f64 {
        self.start.distance(&self.end)
    }

    pub fn midpoint(&self) -> Point3D {
        Point3D::new(
            0.5 * (self.start.x + self.end.x),
            0.5 * (self.start.y + self.end.y),
            0.5 * (self.start.z + self.end.z),
        )
    }

    pub fn direction(&self) -> GeometryResult<Vector3D> {
        (self.end - self.start).normalize()
    }
}

/// A semi-infinite 1D ray defined by origin and unit direction vector.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Ray3D {
    pub origin: Point3D,
    pub direction: Vector3D,
}

impl Ray3D {
    pub fn new(origin: Point3D, direction: Vector3D) -> GeometryResult<Self> {
        let dir = direction.normalize()?;
        Ok(Self { origin, direction: dir })
    }

    pub fn point_at(&self, t: f64) -> Point3D {
        self.origin + self.direction * t
    }
}

/// An infinite 2D plane defined by a point on the plane and a unit normal vector.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Plane3D {
    pub point: Point3D,
    pub normal: Vector3D,
}

impl Plane3D {
    pub fn new(point: Point3D, normal: Vector3D) -> GeometryResult<Self> {
        let norm = normal.normalize()?;
        Ok(Self { point, normal: norm })
    }

    pub fn signed_distance(&self, p: &Point3D) -> f64 {
        let v = *p - self.point;
        v.dot(&self.normal)
    }
}

/// A 3D solid sphere defined by center point and radius.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Sphere3D {
    pub center: Point3D,
    pub radius: f64,
}

impl Sphere3D {
    pub fn new(center: Point3D, radius: f64) -> GeometryResult<Self> {
        if radius < 0.0 {
            return Err(GeometryError::InvalidOperation(
                "Sphere radius cannot be negative".to_string(),
            ));
        }
        Ok(Self { center, radius })
    }

    pub fn volume(&self) -> f64 {
        (4.0 / 3.0) * std::f64::consts::PI * self.radius.powi(3)
    }

    pub fn surface_area(&self) -> f64 {
        4.0 * std::f64::consts::PI * self.radius.powi(2)
    }

    pub fn contains(&self, p: &Point3D) -> bool {
        self.center.distance_squared(p) <= self.radius * self.radius
    }
}

/// An Axis-Aligned Bounding Box (AABB) in 3D.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct AABB3D {
    pub min: Point3D,
    pub max: Point3D,
}

impl AABB3D {
    pub fn new(min: Point3D, max: Point3D) -> GeometryResult<Self> {
        if min.x > max.x || min.y > max.y || min.z > max.z {
            return Err(GeometryError::InvalidOperation(
                "AABB min coordinates must be <= max coordinates".to_string(),
            ));
        }
        Ok(Self { min, max })
    }

    pub fn center(&self) -> Point3D {
        Point3D::new(
            0.5 * (self.min.x + self.max.x),
            0.5 * (self.min.y + self.max.y),
            0.5 * (self.min.z + self.max.z),
        )
    }

    pub fn extents(&self) -> Vector3D {
        Vector3D::new(
            self.max.x - self.min.x,
            self.max.y - self.min.y,
            self.max.z - self.min.z,
        )
    }

    pub fn volume(&self) -> f64 {
        let e = self.extents();
        e.x * e.y * e.z
    }

    pub fn contains(&self, p: &Point3D) -> bool {
        p.x >= self.min.x && p.x <= self.max.x
            && p.y >= self.min.y && p.y <= self.max.y
            && p.z >= self.min.z && p.z <= self.max.z
    }

    pub fn intersects(&self, other: &AABB3D) -> bool {
        self.min.x <= other.max.x && self.max.x >= other.min.x
            && self.min.y <= other.max.y && self.max.y >= other.min.y
            && self.min.z <= other.max.z && self.max.z >= other.min.z
    }
}

/// A planar 2D triangle embedded in 3D space.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Triangle3D {
    pub a: Point3D,
    pub b: Point3D,
    pub c: Point3D,
}

impl Triangle3D {
    pub fn new(a: Point3D, b: Point3D, c: Point3D) -> Self {
        Self { a, b, c }
    }

    pub fn normal(&self) -> GeometryResult<Vector3D> {
        let ab = self.b - self.a;
        let ac = self.c - self.a;
        ab.cross(&ac).normalize()
    }

    pub fn area(&self) -> f64 {
        let ab = self.b - self.a;
        let ac = self.c - self.a;
        0.5 * ab.cross(&ac).norm()
    }

    pub fn centroid(&self) -> Point3D {
        Point3D::new(
            (self.a.x + self.b.x + self.c.x) / 3.0,
            (self.a.y + self.b.y + self.c.y) / 3.0,
            (self.a.z + self.b.z + self.c.z) / 3.0,
        )
    }
}
