// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::ops::{Add, Div, Mul, Sub};

/// A dual number x + y*ε where ε != 0 and ε² = 0.
///
/// Dual numbers provide exact forward-mode automatic differentiation:
/// For any analytic function f(x), evaluating f(x + ε) yields f(x) + f'(x)ε
/// with zero truncation error and without numerical finite-difference approximation.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct DualNumber {
    pub val: f64,
    pub der: f64,
}

impl DualNumber {
    pub fn new(val: f64, der: f64) -> Self {
        Self { val, der }
    }

    /// Creates an independent variable x with derivative 1.0 (seed for forward AD).
    pub fn var(val: f64) -> Self {
        Self { val, der: 1.0 }
    }

    /// Creates a constant c with derivative 0.0.
    pub fn constant(val: f64) -> Self {
        Self { val, der: 0.0 }
    }

    pub fn sin(self) -> Self {
        Self {
            val: self.val.sin(),
            der: self.der * self.val.cos(),
        }
    }

    pub fn cos(self) -> Self {
        Self {
            val: self.val.cos(),
            der: -self.der * self.val.sin(),
        }
    }

    pub fn exp(self) -> Self {
        let e = self.val.exp();
        Self {
            val: e,
            der: self.der * e,
        }
    }

    pub fn ln(self) -> Self {
        Self {
            val: self.val.ln(),
            der: self.der / self.val,
        }
    }

    pub fn powi(self, n: i32) -> Self {
        Self {
            val: self.val.powi(n),
            der: (n as f64) * self.val.powi(n - 1) * self.der,
        }
    }
}

impl Add for DualNumber {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        Self {
            val: self.val + rhs.val,
            der: self.der + rhs.der,
        }
    }
}

impl Sub for DualNumber {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        Self {
            val: self.val - rhs.val,
            der: self.der - rhs.der,
        }
    }
}

impl Mul for DualNumber {
    type Output = Self;
    fn mul(self, rhs: Self) -> Self {
        // (a + bε)(c + dε) = ac + (ad + bc)ε  (since ε² = 0)
        Self {
            val: self.val * rhs.val,
            der: self.val * rhs.der + self.der * rhs.val,
        }
    }
}

impl Div for DualNumber {
    type Output = Self;
    fn div(self, rhs: Self) -> Self {
        // (a + bε)/(c + dε) = a/c + (bc - ad)/c² ε
        let c = rhs.val;
        Self {
            val: self.val / c,
            der: (self.der * c - self.val * rhs.der) / (c * c),
        }
    }
}
