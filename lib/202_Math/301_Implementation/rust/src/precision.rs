// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{MathError, Result};

/// Declared numerical tolerance contract bounding acceptable approximation error.
///
/// In accordance with:
/// - MATH-INV-004: Exact mathematical semantics MUST remain distinguishable from approximation.
/// - MATH-INV-009: Approximation MUST NOT silently masquerade as exact mathematical computation.
/// - MATH-INV-010: Numerical error, precision, and convergence MUST remain within declared contracts.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ToleranceContract {
    pub absolute_tol: f64,
    pub relative_tol: f64,
}

impl ToleranceContract {
    pub fn new(absolute_tol: f64, relative_tol: f64) -> Self {
        Self {
            absolute_tol,
            relative_tol,
        }
    }

    pub fn exact() -> Self {
        Self {
            absolute_tol: 0.0,
            relative_tol: 0.0,
        }
    }

    pub fn is_within_tolerance(&self, exact_expected: f64, actual: f64) -> bool {
        let diff = (exact_expected - actual).abs();
        if diff <= self.absolute_tol {
            return true;
        }
        let rel_bound = self.relative_tol * exact_expected.abs().max(actual.abs());
        diff <= rel_bound
    }

    pub fn verify(&self, expected: f64, actual: f64) -> Result<()> {
        if self.is_within_tolerance(expected, actual) {
            Ok(())
        } else {
            let diff = (expected - actual).abs();
            Err(MathError::ToleranceExceeded {
                bound: self.absolute_tol.max(self.relative_tol * expected.abs()),
                actual: diff,
            })
        }
    }
}

/// A value that explicitly declares whether it is exact or approximate.
#[derive(Debug, Clone, PartialEq)]
pub enum NumericValue {
    ExactInteger(i128),
    ExactRational { numerator: i128, denominator: i128 },
    ApproximateReal { value: f64, uncertainty: f64 },
}

impl NumericValue {
    pub fn is_exact(&self) -> bool {
        matches!(self, NumericValue::ExactInteger(_) | NumericValue::ExactRational { .. })
    }

    pub fn to_f64(&self) -> f64 {
        match self {
            NumericValue::ExactInteger(i) => *i as f64,
            NumericValue::ExactRational { numerator, denominator } => {
                *numerator as f64 / *denominator as f64
            }
            NumericValue::ApproximateReal { value, .. } => *value,
        }
    }
}
