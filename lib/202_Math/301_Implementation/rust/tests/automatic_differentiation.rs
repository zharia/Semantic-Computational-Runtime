// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_math::{eval_derivative_exact, DualNumber};

#[test]
fn test_dual_number_forward_automatic_differentiation() {
    // 1. Polynomial f(x) = x^3 + 2x^2 - 5x + 3
    // Analytical derivative f'(x) = 3x^2 + 4x - 5
    let f_poly = |x: DualNumber| {
        x.powi(3) + DualNumber::constant(2.0) * x.powi(2) - DualNumber::constant(5.0) * x
            + DualNumber::constant(3.0)
    };

    let x0 = 2.0;
    let expected_df = 3.0 * x0 * x0 + 4.0 * x0 - 5.0; // 12 + 8 - 5 = 15.0
    let computed_df = eval_derivative_exact(f_poly, x0);
    assert!((computed_df - expected_df).abs() < 1e-12);

    // 2. Transcendental function g(x) = sin(x) * exp(x)
    // Analytical derivative g'(x) = exp(x) * (sin(x) + cos(x))
    let g_trans = |x: DualNumber| x.sin() * x.exp();
    let x1: f64 = 1.0;
    let expected_dg = x1.exp() * (x1.sin() + x1.cos());
    let computed_dg = eval_derivative_exact(g_trans, x1);
    assert!((computed_dg - expected_dg).abs() < 1e-12);
}
