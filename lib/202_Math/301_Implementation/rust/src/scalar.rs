// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::ops::{Add, Div, Mul, Sub};

use crate::error::{MathError, Result};

/// A complex number z = a + bi in the field ℂ.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ComplexNumber {
    pub real: f64,
    pub imag: f64,
}

impl ComplexNumber {
    pub fn new(real: f64, imag: f64) -> Self {
        Self { real, imag }
    }

    pub fn real(real: f64) -> Self {
        Self { real, imag: 0.0 }
    }

    pub fn i() -> Self {
        Self { real: 0.0, imag: 1.0 }
    }

    pub fn norm_squared(&self) -> f64 {
        self.real * self.real + self.imag * self.imag
    }

    pub fn norm(&self) -> f64 {
        self.norm_squared().sqrt()
    }

    pub fn conjugate(&self) -> Self {
        Self {
            real: self.real,
            imag: -self.imag,
        }
    }

    pub fn inv(&self) -> Result<Self> {
        let n2 = self.norm_squared();
        if n2 == 0.0 {
            Err(MathError::DivisionByZero)
        } else {
            Ok(Self {
                real: self.real / n2,
                imag: -self.imag / n2,
            })
        }
    }
}

impl Add for ComplexNumber {
    type Output = Self;
    fn add(self, rhs: Self) -> Self {
        Self {
            real: self.real + rhs.real,
            imag: self.imag + rhs.imag,
        }
    }
}

impl Sub for ComplexNumber {
    type Output = Self;
    fn sub(self, rhs: Self) -> Self {
        Self {
            real: self.real - rhs.real,
            imag: self.imag - rhs.imag,
        }
    }
}

impl Mul for ComplexNumber {
    type Output = Self;
    fn mul(self, rhs: Self) -> Self {
        Self {
            real: self.real * rhs.real - self.imag * rhs.imag,
            imag: self.real * rhs.imag + self.imag * rhs.real,
        }
    }
}

impl Div for ComplexNumber {
    type Output = Self;
    fn div(self, rhs: Self) -> Self {
        let n2 = rhs.norm_squared();
        if n2 == 0.0 {
            panic!("Division by zero in ComplexNumber");
        }
        Self {
            real: (self.real * rhs.real + self.imag * rhs.imag) / n2,
            imag: (self.imag * rhs.real - self.real * rhs.imag) / n2,
        }
    }
}
