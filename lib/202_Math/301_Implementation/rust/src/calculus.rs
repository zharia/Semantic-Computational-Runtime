// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::dual::DualNumber;
use crate::error::Result;
use crate::precision::ToleranceContract;

/// Evaluates exact derivative of f at x using forward-mode automatic differentiation (Dual numbers).
pub fn eval_derivative_exact<F>(f: F, x: f64) -> f64
where
    F: Fn(DualNumber) -> DualNumber,
{
    let dual_x = DualNumber::var(x);
    let result = f(dual_x);
    result.der
}

/// Evaluates approximate derivative of f at x using central finite differences.
pub fn eval_derivative_finite_diff<F>(f: F, x: f64, h: f64) -> f64
where
    F: Fn(f64) -> f64,
{
    (f(x + h) - f(x - h)) / (2.0 * h)
}

/// Compares numerical approximation against exact derivative and certifies tolerance.
pub fn verify_derivative_approximation<F, FDual>(
    f_num: F,
    f_dual: FDual,
    x: f64,
    h: f64,
    tol: &ToleranceContract,
) -> Result<()>
where
    F: Fn(f64) -> f64,
    FDual: Fn(DualNumber) -> DualNumber,
{
    let exact = eval_derivative_exact(f_dual, x);
    let approx = eval_derivative_finite_diff(f_num, x, h);
    tol.verify(exact, approx)
}
