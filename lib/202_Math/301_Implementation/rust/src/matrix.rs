// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{MathError, Result};
use crate::vector::Vector;

/// An M x N matrix representing a linear transformation between vector spaces.
#[derive(Debug, Clone, PartialEq)]
pub struct Matrix {
    pub rows: usize,
    pub cols: usize,
    data: Vec<f64>,
}

impl Matrix {
    pub fn new(rows: usize, cols: usize, data: Vec<f64>) -> Result<Self> {
        if data.len() != rows * cols {
            return Err(MathError::DimensionMismatch {
                expected: format!("{} elements", rows * cols),
                actual: format!("{} elements", data.len()),
            });
        }
        Ok(Self { rows, cols, data })
    }

    pub fn identity(n: usize) -> Self {
        let mut data = vec![0.0; n * n];
        for i in 0..n {
            data[i * n + i] = 1.0;
        }
        Self { rows: n, cols: n, data }
    }

    pub fn get(&self, r: usize, c: usize) -> Option<f64> {
        if r < self.rows && c < self.cols {
            Some(self.data[r * self.cols + c])
        } else {
            None
        }
    }

    pub fn transpose(&self) -> Self {
        let mut t_data = vec![0.0; self.rows * self.cols];
        for r in 0..self.rows {
            for c in 0..self.cols {
                t_data[c * self.rows + r] = self.data[r * self.cols + c];
            }
        }
        Self {
            rows: self.cols,
            cols: self.rows,
            data: t_data,
        }
    }

    pub fn trace(&self) -> Result<f64> {
        if self.rows != self.cols {
            return Err(MathError::DimensionMismatch {
                expected: "square matrix".into(),
                actual: format!("{}x{}", self.rows, self.cols),
            });
        }
        let tr: f64 = (0..self.rows).map(|i| self.data[i * self.cols + i]).sum();
        Ok(tr)
    }

    /// Matrix-matrix multiplication A · B.
    pub fn matmul(&self, other: &Matrix) -> Result<Matrix> {
        if self.cols != other.rows {
            return Err(MathError::DimensionMismatch {
                expected: format!("cols(A) == rows(B) ({} == {})", self.cols, other.rows),
                actual: format!("A is {}x{}, B is {}x{}", self.rows, self.cols, other.rows, other.cols),
            });
        }
        let mut res = vec![0.0; self.rows * other.cols];
        for r in 0..self.rows {
            for c in 0..other.cols {
                let mut sum = 0.0;
                for k in 0..self.cols {
                    sum += self.data[r * self.cols + k] * other.data[k * other.cols + c];
                }
                res[r * other.cols + c] = sum;
            }
        }
        Matrix::new(self.rows, other.cols, res)
    }

    /// Matrix-vector multiplication A · v.
    pub fn apply_vector(&self, v: &Vector) -> Result<Vector> {
        if self.cols != v.dim() {
            return Err(MathError::DimensionMismatch {
                expected: format!("vector dim {}", self.cols),
                actual: format!("vector dim {}", v.dim()),
            });
        }
        let mut out = Vec::with_capacity(self.rows);
        for r in 0..self.rows {
            let mut sum = 0.0;
            for c in 0..self.cols {
                sum += self.data[r * self.cols + c] * v.get(c).unwrap();
            }
            out.push(sum);
        }
        Ok(Vector::new(out))
    }

    /// Determinant for 2x2 or 3x3 matrices.
    pub fn determinant(&self) -> Result<f64> {
        if self.rows != self.cols {
            return Err(MathError::DimensionMismatch {
                expected: "square matrix".into(),
                actual: format!("{}x{}", self.rows, self.cols),
            });
        }
        if self.rows == 2 {
            Ok(self.data[0] * self.data[3] - self.data[1] * self.data[2])
        } else if self.rows == 3 {
            let d = &self.data;
            let det = d[0] * (d[4] * d[8] - d[5] * d[7])
                - d[1] * (d[3] * d[8] - d[5] * d[6])
                + d[2] * (d[3] * d[7] - d[4] * d[6]);
            Ok(det)
        } else {
            Err(MathError::SemanticInvalidity(
                "Determinant implemented for 2x2 and 3x3 in carrier crate".into(),
            ))
        }
    }
}
