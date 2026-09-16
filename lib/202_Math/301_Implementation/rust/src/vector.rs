// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::ops::{Add, Mul, Sub};

use crate::error::{MathError, Result};

/// An N-dimensional mathematical vector over ℝ.
///
/// In accordance with MATH-INV-002:
/// A vector is an element of a vector space, not merely a flat array in memory.
#[derive(Debug, Clone, PartialEq)]
pub struct Vector {
    elements: Vec<f64>,
}

impl Vector {
    pub fn new(elements: Vec<f64>) -> Self {
        Self { elements }
    }

    pub fn zeros(dim: usize) -> Self {
        Self {
            elements: vec![0.0; dim],
        }
    }

    pub fn dim(&self) -> usize {
        self.elements.len()
    }

    pub fn get(&self, idx: usize) -> Option<f64> {
        self.elements.get(idx).copied()
    }

    pub fn as_slice(&self) -> &[f64] {
        &self.elements
    }

    /// Computes the Euclidean dot (inner) product ⟨u, v⟩.
    pub fn dot(&self, other: &Vector) -> Result<f64> {
        if self.dim() != other.dim() {
            return Err(MathError::DimensionMismatch {
                expected: format!("dim {}", self.dim()),
                actual: format!("dim {}", other.dim()),
            });
        }
        let sum: f64 = self
            .elements
            .iter()
            .zip(&other.elements)
            .map(|(a, b)| a * b)
            .sum();
        Ok(sum)
    }

    /// Computes the Euclidean norm (length) ||v||.
    pub fn norm(&self) -> f64 {
        self.elements.iter().map(|x| x * x).sum::<f64>().sqrt()
    }

    /// Normalizes the vector to a unit vector.
    pub fn normalize(&self) -> Result<Self> {
        let n = self.norm();
        if n == 0.0 {
            Err(MathError::DivisionByZero)
        } else {
            Ok(Self {
                elements: self.elements.iter().map(|x| x / n).collect(),
            })
        }
    }

    /// 3D Cross product u × v.
    pub fn cross_3d(&self, other: &Vector) -> Result<Vector> {
        if self.dim() != 3 || other.dim() != 3 {
            return Err(MathError::DimensionMismatch {
                expected: "3D vector".into(),
                actual: format!("dim {} and dim {}", self.dim(), other.dim()),
            });
        }
        let (u1, u2, u3) = (self.elements[0], self.elements[1], self.elements[2]);
        let (v1, v2, v3) = (other.elements[0], other.elements[1], other.elements[2]);

        Ok(Vector::new(vec![
            u2 * v3 - u3 * v2,
            u3 * v1 - u1 * v3,
            u1 * v2 - u2 * v1,
        ]))
    }
}

impl Add for Vector {
    type Output = Result<Self>;
    fn add(self, rhs: Self) -> Result<Self> {
        if self.dim() != rhs.dim() {
            return Err(MathError::DimensionMismatch {
                expected: format!("dim {}", self.dim()),
                actual: format!("dim {}", rhs.dim()),
            });
        }
        let res = self
            .elements
            .iter()
            .zip(&rhs.elements)
            .map(|(a, b)| a + b)
            .collect();
        Ok(Vector::new(res))
    }
}

impl Sub for Vector {
    type Output = Result<Self>;
    fn sub(self, rhs: Self) -> Result<Self> {
        if self.dim() != rhs.dim() {
            return Err(MathError::DimensionMismatch {
                expected: format!("dim {}", self.dim()),
                actual: format!("dim {}", rhs.dim()),
            });
        }
        let res = self
            .elements
            .iter()
            .zip(&rhs.elements)
            .map(|(a, b)| a - b)
            .collect();
        Ok(Vector::new(res))
    }
}

impl Mul<f64> for Vector {
    type Output = Self;
    fn mul(self, scalar: f64) -> Self {
        Self {
            elements: self.elements.into_iter().map(|x| x * scalar).collect(),
        }
    }
}
