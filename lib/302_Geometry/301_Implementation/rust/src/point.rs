// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Points vs Vectors (Affine Space Semantics)
//!
//! Conforming to Section 7 and GEOMETRY-INV-002:
//! - A point represents a spatial location without necessarily possessing extent.
//! - A vector represents a directed spatial displacement/direction.
//! - Point + Vector -> Point
//! - Point - Point -> Vector
//! - Point + Point is semantically invalid and disallowed.

use crate::error::{GeometryError, GeometryResult};
use std::ops::{Add, Div, Mul, Neg, Sub};

/// A point in 3D affine space $\mathbb{A}^3$ representing a definite spatial location.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Point3D {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

/// A displacement or direction in 3D linear vector space $\mathbb{R}^3$.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Vector3D {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

impl Point3D {
    pub const ORIGIN: Self = Self { x: 0.0, y: 0.0, z: 0.0 };

    pub fn new(x: f64, y: f64, z: f64) -> Self {
        Self { x, y, z }
    }

    pub fn coords(&self) -> [f64; 3] {
        [self.x, self.y, self.z]
    }

    /// Computes an affine combination of points: $P = \sum w_i P_i$ where $\sum w_i = 1$.
    ///
    /// Preserves affine invariance without violating the Point + Point prohibition.
    pub fn affine_combination(weighted_points: &[(f64, Point3D)]) -> GeometryResult<Self> {
        let weight_sum: f64 = weighted_points.iter().map(|(w, _)| *w).sum();
        if (weight_sum - 1.0).abs() > 1e-6 {
            return Err(GeometryError::InvalidOperation(format!(
                "Affine combination weights must sum to 1.0, got {}",
                weight_sum
            )));
        }

        let mut x = 0.0;
        let mut y = 0.0;
        let mut z = 0.0;
        for (w, p) in weighted_points {
            x += w * p.x;
            y += w * p.y;
            z += w * p.z;
        }

        Ok(Self { x, y, z })
    }

    /// Distance squared to another point.
    pub fn distance_squared(&self, other: &Point3D) -> f64 {
        let dx = self.x - other.x;
        let dy = self.y - other.y;
        let dz = self.z - other.z;
        dx * dx + dy * dy + dz * dz
    }

    /// Euclidean distance to another point.
    pub fn distance(&self, other: &Point3D) -> f64 {
        self.distance_squared(other).sqrt()
    }

    /// Displacement vector from other to self: other -> self.
    pub fn to(&self, target: &Point3D) -> Vector3D {
        *target - *self
    }
}

impl Vector3D {
    pub const ZERO: Self = Self { x: 0.0, y: 0.0, z: 0.0 };
    pub const UNIT_X: Self = Self { x: 1.0, y: 0.0, z: 0.0 };
    pub const UNIT_Y: Self = Self { x: 0.0, y: 1.0, z: 0.0 };
    pub const UNIT_Z: Self = Self { x: 0.0, y: 0.0, z: 1.0 };

    pub fn new(x: f64, y: f64, z: f64) -> Self {
        Self { x, y, z }
    }

    pub fn dot(&self, other: &Vector3D) -> f64 {
        self.x * other.x + self.y * other.y + self.z * other.z
    }

    pub fn cross(&self, other: &Vector3D) -> Vector3D {
        Vector3D {
            x: self.y * other.z - self.z * other.y,
            y: self.z * other.x - self.x * other.z,
            z: self.x * other.y - self.y * other.x,
        }
    }

    pub fn norm_squared(&self) -> f64 {
        self.x * self.x + self.y * self.y + self.z * self.z
    }

    pub fn norm(&self) -> f64 {
        self.norm_squared().sqrt()
    }

    pub fn normalize(&self) -> GeometryResult<Self> {
        let n = self.norm();
        if n == 0.0 {
            Err(GeometryError::DegenerateEntity(
                "Cannot normalize zero-length vector".to_string(),
            ))
        } else {
            Ok(Self {
                x: self.x / n,
                y: self.y / n,
                z: self.z / n,
            })
        }
    }
}

// Point + Vector -> Point
impl Add<Vector3D> for Point3D {
    type Output = Point3D;
    fn add(self, v: Vector3D) -> Point3D {
        Point3D {
            x: self.x + v.x,
            y: self.y + v.y,
            z: self.z + v.z,
        }
    }
}

// Point - Vector -> Point
impl Sub<Vector3D> for Point3D {
    type Output = Point3D;
    fn sub(self, v: Vector3D) -> Point3D {
        Point3D {
            x: self.x - v.x,
            y: self.y - v.y,
            z: self.z - v.z,
        }
    }
}

// Point - Point -> Vector
impl Sub<Point3D> for Point3D {
    type Output = Vector3D;
    fn sub(self, other: Point3D) -> Vector3D {
        Vector3D {
            x: self.x - other.x,
            y: self.y - other.y,
            z: self.z - other.z,
        }
    }
}

// Vector + Vector -> Vector
impl Add<Vector3D> for Vector3D {
    type Output = Vector3D;
    fn add(self, rhs: Vector3D) -> Vector3D {
        Vector3D {
            x: self.x + rhs.x,
            y: self.y + rhs.y,
            z: self.z + rhs.z,
        }
    }
}

// Vector - Vector -> Vector
impl Sub<Vector3D> for Vector3D {
    type Output = Vector3D;
    fn sub(self, rhs: Vector3D) -> Vector3D {
        Vector3D {
            x: self.x - rhs.x,
            y: self.y - rhs.y,
            z: self.z - rhs.z,
        }
    }
}

// Vector negation
impl Neg for Vector3D {
    type Output = Vector3D;
    fn neg(self) -> Vector3D {
        Vector3D {
            x: -self.x,
            y: -self.y,
            z: -self.z,
        }
    }
}

// Vector * scalar -> Vector
impl Mul<f64> for Vector3D {
    type Output = Vector3D;
    fn mul(self, rhs: f64) -> Vector3D {
        Vector3D {
            x: self.x * rhs,
            y: self.y * rhs,
            z: self.z * rhs,
        }
    }
}

// scalar * Vector -> Vector
impl Mul<Vector3D> for f64 {
    type Output = Vector3D;
    fn mul(self, rhs: Vector3D) -> Vector3D {
        rhs * self
    }
}

// Vector / scalar -> Vector
impl Div<f64> for Vector3D {
    type Output = Vector3D;
    fn div(self, rhs: f64) -> Vector3D {
        Vector3D {
            x: self.x / rhs,
            y: self.y / rhs,
            z: self.z / rhs,
        }
    }
}

// Conversions with scr_math::Vector
impl From<Vector3D> for scr_math::Vector {
    fn from(v: Vector3D) -> Self {
        scr_math::Vector::new(vec![v.x, v.y, v.z])
    }
}

impl TryFrom<scr_math::Vector> for Vector3D {
    type Error = GeometryError;
    fn try_from(v: scr_math::Vector) -> Result<Self, Self::Error> {
        if v.dim() != 3 {
            return Err(GeometryError::DimensionMismatch {
                expected: 3,
                found: v.dim(),
            });
        }
        let s = v.as_slice();
        Ok(Vector3D::new(s[0], s[1], s[2]))
    }
}

impl From<Point3D> for scr_math::Vector {
    fn from(p: Point3D) -> Self {
        scr_math::Vector::new(vec![p.x, p.y, p.z])
    }
}

impl TryFrom<scr_math::Vector> for Point3D {
    type Error = GeometryError;
    fn try_from(v: scr_math::Vector) -> Result<Self, Self::Error> {
        if v.dim() != 3 {
            return Err(GeometryError::DimensionMismatch {
                expected: 3,
                found: v.dim(),
            });
        }
        let s = v.as_slice();
        Ok(Point3D::new(s[0], s[1], s[2]))
    }
}
