// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::ops::{Add, Mul, Sub};

use crate::error::{MathError, Result};
use crate::vector::Vector;

/// A quaternion q = w + xi + yj + zk in the hypercomplex division algebra ℍ.
///
/// In accordance with QAT-INV-001:
/// i² = j² = k² = ijk = -1.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Quaternion {
    pub w: f64,
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

impl Quaternion {
    pub fn new(w: f64, x: f64, y: f64, z: f64) -> Self {
        Self { w, x, y, z }
    }

    pub fn identity() -> Self {
        Self { w: 1.0, x: 0.0, y: 0.0, z: 0.0 }
    }

    pub fn norm_squared(&self) -> f64 {
        self.w * self.w + self.x * self.x + self.y * self.y + self.z * self.z
    }

    pub fn norm(&self) -> f64 {
        self.norm_squared().sqrt()
    }

    pub fn conjugate(&self) -> Self {
        Self {
            w: self.w,
            x: -self.x,
            y: -self.y,
            z: -self.z,
        }
    }

    pub fn normalize(&self) -> Result<Self> {
        let n = self.norm();
        if n == 0.0 {
            Err(MathError::DivisionByZero)
        } else {
            Ok(Self {
                w: self.w / n,
                x: self.x / n,
                y: self.y / n,
                z: self.z / n,
            })
        }
    }

    pub fn inverse(&self) -> Result<Self> {
        let n2 = self.norm_squared();
        if n2 == 0.0 {
            Err(MathError::DivisionByZero)
        } else {
            let conj = self.conjugate();
            Ok(Self {
                w: conj.w / n2,
                x: conj.x / n2,
                y: conj.y / n2,
                z: conj.z / n2,
            })
        }
    }

    /// Creates a unit quaternion representing rotation by `angle_rad` around `axis`.
    pub fn from_axis_angle(axis: &Vector, angle_rad: f64) -> Result<Self> {
        let norm_axis = axis.normalize()?;
        let half_angle = angle_rad * 0.5;
        let s = half_angle.sin();
        Ok(Self {
            w: half_angle.cos(),
            x: norm_axis.get(0).unwrap() * s,
            y: norm_axis.get(1).unwrap() * s,
            z: norm_axis.get(2).unwrap() * s,
        })
    }

    /// Rotates a 3D vector using the quaternion sandwich product: v' = q · v · q⁻¹.
    pub fn rotate_vector(&self, v: &Vector) -> Result<Vector> {
        if v.dim() != 3 {
            return Err(MathError::DimensionMismatch {
                expected: "3D vector".into(),
                actual: format!("dim {}", v.dim()),
            });
        }
        let p = Quaternion::new(0.0, v.get(0).unwrap(), v.get(1).unwrap(), v.get(2).unwrap());
        let q_inv = self.inverse()?;
        let rotated_q = (*self * p) * q_inv;

        Ok(Vector::new(vec![rotated_q.x, rotated_q.y, rotated_q.z]))
    }
}

impl Add for Quaternion {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        Self {
            w: self.w + rhs.w,
            x: self.x + rhs.x,
            y: self.y + rhs.y,
            z: self.z + rhs.z,
        }
    }
}

impl Sub for Quaternion {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        Self {
            w: self.w - rhs.w,
            x: self.x - rhs.x,
            y: self.y - rhs.y,
            z: self.z - rhs.z,
        }
    }
}

/// Hamilton product for quaternion multiplication.
impl Mul for Quaternion {
    type Output = Self;
    fn mul(self, rhs: Self) -> Self {
        Self {
            w: self.w * rhs.w - self.x * rhs.x - self.y * rhs.y - self.z * rhs.z,
            x: self.w * rhs.x + self.x * rhs.w + self.y * rhs.z - self.z * rhs.y,
            y: self.w * rhs.y - self.x * rhs.z + self.y * rhs.w + self.z * rhs.x,
            z: self.w * rhs.z + self.x * rhs.y - self.y * rhs.x + self.z * rhs.w,
        }
    }
}
