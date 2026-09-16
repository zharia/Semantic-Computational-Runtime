// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Mathematical Semantic Bridge (`SCR-LIB-FIELDS` <-> `SCR-LIB-MATHEMATICS`)
//!
//! Bridges fields and continuous spaces with the normative mathematics domain:
//! - Exact directional differentiation via Dual Numbers (`scr_math::DualNumber`)
//! - Linear transformations of vector fields via `scr_math::Matrix`
//! - Verification of numerical approximations via `scr_math::ToleranceContract`
//! - Interoperability between `FieldValue` and `scr_math::Vector` / `scr_math::Matrix`

use crate::error::{FieldError, FieldResult};
use crate::field::Field;
use crate::value::{FieldValue, ValueSpace};
use scr_math::{DualNumber, Matrix, ToleranceContract, Vector};

/// Evaluates the exact directional derivative of an analytical field along direction `v` at point `p`
/// using forward-mode automatic differentiation (dual numbers).
///
/// For $f: \mathbb{R}^n \to \mathbb{R}$, calculates $\nabla f(p) \cdot v = \left.\frac{d}{dt} f(p + t v)\right|_{t=0}$.
pub fn directional_derivative_exact<F>(p: &[f64], v: &[f64], field_fn: F) -> f64
where
    F: Fn(&[DualNumber]) -> DualNumber,
{
    assert_eq!(p.len(), v.len(), "Point and direction vector must have identical dimensions");
    let t_dual = DualNumber::var(0.0);
    let p_dual: Vec<DualNumber> = p
        .iter()
        .zip(v.iter())
        .map(|(&pi, &vi)| DualNumber::constant(pi) + t_dual * DualNumber::constant(vi))
        .collect();
    let res = field_fn(&p_dual);
    res.der
}

/// Verifies whether a finite-difference derivative approximation satisfies the
/// normative tolerance contract relative to the exact derivative.
pub fn verify_differential_tolerance(
    approx_val: f64,
    exact_val: f64,
    tolerance: &ToleranceContract,
) -> bool {
    tolerance.is_within_tolerance(approx_val, exact_val)
}

/// Evaluates a field at `point` and returns the result as an authoritative `scr_math::Vector`.
pub fn evaluate_as_vector(field: &Field, point: &[f64]) -> FieldResult<Vector> {
    let val = field.evaluate(point)?;
    Vector::try_from(val)
}

/// Transforms a vector field by a linear transformation matrix $M \in \mathbb{R}^{m \times n}$.
///
/// For vector field $v(x) \in \mathbb{R}^n$, returns new field $w(x) = M \cdot v(x) \in \mathbb{R}^m$.
pub fn transform_vector_field(field: &Field, matrix: &Matrix) -> FieldResult<Field> {
    let input_dim = match field.value_space {
        ValueSpace::VectorSpace(d) => d,
        _ => {
            return Err(FieldError::OperatorError(
                "Linear transformation requires a vector field".to_string(),
            ))
        }
    };

    if matrix.cols != input_dim {
        return Err(FieldError::DimensionMismatch {
            expected: input_dim,
            found: matrix.cols,
        });
    }

    let out_dim = matrix.rows;
    let mat = matrix.clone();
    let src_field = field.clone();
    let id = format!("{}_transformed", field.id);
    let domain = field.domain.clone();
    let value_space = ValueSpace::VectorSpace(out_dim);

    let transformed = Field::new_analytic(id, domain, value_space, move |point: &[f64]| {
        let val = src_field.evaluate(point)?;
        let vec = Vector::try_from(val)?;
        let res_vec = mat
            .apply_vector(&vec)
            .map_err(|e| FieldError::OperatorError(e.to_string()))?;
        Ok(FieldValue::from(res_vec))
    });

    Ok(transformed)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::FieldDomain;

    #[test]
    fn test_directional_derivative_exact() {
        // f(x, y) = x^2 + 3*x*y + y^3
        // grad f = (2x + 3y, 3x + 3y^2)
        // at (1, 2): grad f = (2(1)+3(2), 3(1)+3(4)) = (8, 15)
        // along v = (1, 0) -> 8.0
        // along v = (0, 1) -> 15.0
        // along v = (1, 1) -> 23.0
        let f = |pt: &[DualNumber]| {
            let x = pt[0];
            let y = pt[1];
            x.powi(2) + x * y * DualNumber::constant(3.0) + y.powi(3)
        };

        let p = [1.0, 2.0];
        let v_x = [1.0, 0.0];
        let v_y = [0.0, 1.0];
        let v_diag = [1.0, 1.0];

        let df_dx = directional_derivative_exact(&p, &v_x, f);
        let df_dy = directional_derivative_exact(&p, &v_y, f);
        let df_diag = directional_derivative_exact(&p, &v_diag, f);

        assert!((df_dx - 8.0).abs() < 1e-12);
        assert!((df_dy - 15.0).abs() < 1e-12);
        assert!((df_diag - 23.0).abs() < 1e-12);
    }

    #[test]
    fn test_tolerance_verification() {
        let tol = ToleranceContract::new(1e-6, 1e-6);
        let exact = 8.0;
        let approx = 8.00000001;
        assert!(verify_differential_tolerance(approx, exact, &tol));

        let bad_approx = 8.1;
        assert!(!verify_differential_tolerance(bad_approx, exact, &tol));
    }

    #[test]
    fn test_transform_vector_field() {
        let domain = FieldDomain::new_2d("d2", -10.0, 10.0, -10.0, 10.0).unwrap();
        // v(x, y) = (x, y)
        let v_field = Field::new_analytic(
            "v",
            domain,
            ValueSpace::VectorSpace(2),
            |p| Ok(FieldValue::Vector2([p[0], p[1]])),
        );

        // Rotation by 90 degrees: [[0, -1], [1, 0]]
        let rot = Matrix::new(2, 2, vec![
            0.0, -1.0,
            1.0, 0.0,
        ]).unwrap();

        let transformed = transform_vector_field(&v_field, &rot).unwrap();
        let val = transformed.evaluate(&[2.0, 5.0]).unwrap();
        // (0*2 - 1*5, 1*2 + 0*5) = (-5, 2)
        match val {
            FieldValue::Vector2([rx, ry]) => {
                assert!((rx - (-5.0)).abs() < 1e-10);
                assert!((ry - 2.0).abs() < 1e-10);
            }
            _ => panic!("Expected Vector2"),
        }
    }
}
