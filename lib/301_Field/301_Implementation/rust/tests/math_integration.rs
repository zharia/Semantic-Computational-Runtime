// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_field::domain::FieldDomain;
use scr_field::field::Field;
use scr_field::math_bridge::{
    directional_derivative_exact, evaluate_as_vector, transform_vector_field,
    verify_differential_tolerance,
};
use scr_field::operators::gradient;
use scr_field::value::{FieldValue, ValueSpace};
use scr_math::{DualNumber, Matrix, ToleranceContract, Vector};

#[test]
fn test_field_value_math_conversions() {
    // Vector2 conversion
    let v2_field = FieldValue::Vector2([1.5, -2.5]);
    let v2_math: Vector = (&v2_field).try_into().unwrap();
    assert_eq!(v2_math.dim(), 2);
    assert_eq!(v2_math.as_slice()[0], 1.5);
    assert_eq!(v2_math.as_slice()[1], -2.5);

    let roundtrip_v2 = FieldValue::from(v2_math);
    assert_eq!(roundtrip_v2, v2_field);

    // Vector3 conversion
    let v3_field = FieldValue::Vector3([1.0, 2.0, 3.0]);
    let v3_math: Vector = (&v3_field).try_into().unwrap();
    assert_eq!(v3_math.dim(), 3);
    assert_eq!(v3_math.as_slice()[2], 3.0);

    let roundtrip_v3 = FieldValue::from(v3_math);
    assert_eq!(roundtrip_v3, v3_field);

    // Matrix / Tensor3x3 conversion
    let tensor_field = FieldValue::Tensor3x3([
        [1.0, 0.0, 0.0],
        [0.0, 2.0, 0.0],
        [0.0, 0.0, 3.0],
    ]);
    let mat: Matrix = (&tensor_field).try_into().unwrap();
    assert_eq!(mat.rows, 3);
    assert_eq!(mat.cols, 3);
    assert_eq!(mat.get(1, 1).unwrap(), 2.0);
}

#[test]
fn test_dual_number_exact_directional_derivative_vs_finite_difference() {
    // φ(x, y, z) = x^2 + 2*y^2 + z^3
    // ∇φ = (2x, 4y, 3z^2)
    // at p = (1, 1, 1), ∇φ = (2, 4, 3)
    // Direction v = (1, 0, 0): directional derivative along x = 2.0
    // Direction v = (0, 1, 0): directional derivative along y = 4.0
    // Direction v = (0, 0, 1): directional derivative along z = 3.0
    // Direction v = (1, 1, 1): 2 + 4 + 3 = 9.0

    let phi_dual = |pt: &[DualNumber]| {
        let x = pt[0];
        let y = pt[1];
        let z = pt[2];
        x.powi(2) + y.powi(2) * DualNumber::constant(2.0) + z.powi(3)
    };

    let p = [1.0, 1.0, 1.0];
    let v_x = [1.0, 0.0, 0.0];
    let v_y = [0.0, 1.0, 0.0];
    let v_z = [0.0, 0.0, 1.0];
    let v_all = [1.0, 1.0, 1.0];

    let exact_dx = directional_derivative_exact(&p, &v_x, phi_dual);
    let exact_dy = directional_derivative_exact(&p, &v_y, phi_dual);
    let exact_dz = directional_derivative_exact(&p, &v_z, phi_dual);
    let exact_dall = directional_derivative_exact(&p, &v_all, phi_dual);

    assert!((exact_dx - 2.0).abs() < 1e-12);
    assert!((exact_dy - 4.0).abs() < 1e-12);
    assert!((exact_dz - 3.0).abs() < 1e-12);
    assert!((exact_dall - 9.0).abs() < 1e-12);

    // Compare with finite difference gradient
    let domain = FieldDomain::new_3d("dom_comp", -5.0, 5.0, -5.0, 5.0, -5.0, 5.0).unwrap();
    let phi_field = Field::new_analytic("phi", domain, ValueSpace::ScalarSpace, |pt: &[f64]| {
        Ok(FieldValue::Scalar(pt[0] * pt[0] + 2.0 * pt[1] * pt[1] + pt[2].powi(3)))
    });

    let grad_phi = gradient(&phi_field, Some(1e-6)).unwrap();
    let grad_at_p = grad_phi.evaluate(&p).unwrap();

    let tol = ToleranceContract::new(1e-4, 1e-4);
    if let FieldValue::Vector3([gx, gy, gz]) = grad_at_p {
        assert!(verify_differential_tolerance(gx, exact_dx, &tol));
        assert!(verify_differential_tolerance(gy, exact_dy, &tol));
        assert!(verify_differential_tolerance(gz, exact_dz, &tol));
    } else {
        panic!("Expected Vector3 gradient");
    }
}

#[test]
fn test_evaluate_as_vector() {
    let domain = FieldDomain::new_3d("dom_vec", -5.0, 5.0, -5.0, 5.0, -5.0, 5.0).unwrap();
    let v_field = Field::new_analytic(
        "v_field",
        domain,
        ValueSpace::VectorSpace(3),
        |p: &[f64]| Ok(FieldValue::Vector3([p[0] * 2.0, p[1] * 3.0, p[2] * 4.0])),
    );

    let math_vec = evaluate_as_vector(&v_field, &[1.0, 2.0, 3.0]).unwrap();
    assert_eq!(math_vec.dim(), 3);
    assert_eq!(math_vec.as_slice()[0], 2.0);
    assert_eq!(math_vec.as_slice()[1], 6.0);
    assert_eq!(math_vec.as_slice()[2], 12.0);
    assert!((math_vec.norm() - (4.0 + 36.0 + 144.0_f64).sqrt()).abs() < 1e-10);
}

#[test]
fn test_transform_vector_field_with_matrix() {
    let domain = FieldDomain::new_3d("dom_trans", -10.0, 10.0, -10.0, 10.0, -10.0, 10.0).unwrap();
    // v(p) = (1, 2, 3)
    let const_field = Field::new_analytic(
        "const_vec",
        domain,
        ValueSpace::VectorSpace(3),
        |_| Ok(FieldValue::Vector3([1.0, 2.0, 3.0])),
    );

    // Diagonal scaling matrix: diag(2, -1, 3)
    let diag_mat = Matrix::new(3, 3, vec![
        2.0, 0.0, 0.0,
        0.0, -1.0, 0.0,
        0.0, 0.0, 3.0,
    ]).unwrap();

    let transformed = transform_vector_field(&const_field, &diag_mat).unwrap();
    let res = transformed.evaluate(&[0.0, 0.0, 0.0]).unwrap();

    match res {
        FieldValue::Vector3([x, y, z]) => {
            assert_eq!(x, 2.0);
            assert_eq!(y, -2.0);
            assert_eq!(z, 9.0);
        }
        other => panic!("Expected Vector3, got {:?}", other),
    }
}
