// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

/// A univariate polynomial P(x) = a_0 + a_1 x + a_2 x^2 + ... + a_n x^n.
#[derive(Debug, Clone, PartialEq)]
pub struct Polynomial {
    /// Coefficients in ascending power: a_0, a_1, ..., a_n.
    pub coeffs: Vec<f64>,
}

impl Polynomial {
    pub fn new(coeffs: Vec<f64>) -> Self {
        Self { coeffs }
    }

    pub fn degree(&self) -> usize {
        if self.coeffs.is_empty() {
            0
        } else {
            self.coeffs.len() - 1
        }
    }

    /// Evaluates P(x) using Horner's method: P(x) = a_0 + x(a_1 + x(a_2 + ...)).
    pub fn eval(&self, x: f64) -> f64 {
        let mut result = 0.0;
        for c in self.coeffs.iter().rev() {
            result = result * x + *c;
        }
        result
    }

    /// Computes the formal derivative P'(x) = a_1 + 2 a_2 x + ... + n a_n x^{n-1}.
    pub fn derivative(&self) -> Self {
        if self.coeffs.len() <= 1 {
            Self::new(vec![0.0])
        } else {
            let d_coeffs = self
                .coeffs
                .iter()
                .enumerate()
                .skip(1)
                .map(|(i, c)| (i as f64) * c)
                .collect();
            Self::new(d_coeffs)
        }
    }
}
