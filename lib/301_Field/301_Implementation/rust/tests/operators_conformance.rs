use scr_field::domain::FieldDomain;
use scr_field::field::Field;
use scr_field::operators::{advection, curl, divergence, gradient, laplacian};
use scr_field::value::{FieldValue, ValueSpace};

#[test]
fn test_gradient_operator() {
    // f(x, y) = x² + 2y²
    // ∇f = (2x, 4y)
    let domain = FieldDomain::new_2d("dom_grad", -10.0, 10.0, -10.0, 10.0).unwrap();
    let f = Field::new_analytic("f", domain, ValueSpace::ScalarSpace, |p: &[f64]| {
        Ok(FieldValue::Scalar(p[0] * p[0] + 2.0 * p[1] * p[1]))
    });

    let grad_f = gradient(&f, None).unwrap();
    let p = [2.0, 3.0];
    let grad_val = grad_f.evaluate(&p).unwrap();

    match grad_val {
        FieldValue::Vector2([gx, gy]) => {
            assert!((gx - 4.0).abs() < 1e-4, "Expected gx ≈ 4.0, got {}", gx);
            assert!((gy - 12.0).abs() < 1e-4, "Expected gy ≈ 12.0, got {}", gy);
        }
        other => panic!("Expected Vector2, got {:?}", other),
    }
}

#[test]
fn test_divergence_operator() {
    // v(x, y, z) = (2x, 3y, 4z)
    // ∇ · v = 2 + 3 + 4 = 9
    let domain = FieldDomain::new_3d("dom_div", -10.0, 10.0, -10.0, 10.0, -10.0, 10.0).unwrap();
    let v = Field::new_analytic(
        "v",
        domain,
        ValueSpace::VectorSpace(3),
        |p: &[f64]| Ok(FieldValue::Vector3([2.0 * p[0], 3.0 * p[1], 4.0 * p[2]])),
    );

    let div_v = divergence(&v, None).unwrap();
    let div_val = div_v.evaluate(&[1.0, 2.0, 3.0]).unwrap().as_scalar().unwrap();
    assert!((div_val - 9.0).abs() < 1e-4, "Expected 9.0, got {}", div_val);
}

#[test]
fn test_curl_of_gradient_is_zero_vector() {
    // Identity: ∇ × (∇φ) = 0 for any scalar field φ
    // Let φ(x, y, z) = x²y + y²z + z²x
    let domain = FieldDomain::new_3d("dom_curl", -5.0, 5.0, -5.0, 5.0, -5.0, 5.0).unwrap();
    let phi = Field::new_analytic("phi", domain, ValueSpace::ScalarSpace, |p: &[f64]| {
        let x = p[0];
        let y = p[1];
        let z = p[2];
        Ok(FieldValue::Scalar(x * x * y + y * y * z + z * z * x))
    });

    let grad_phi = gradient(&phi, None).unwrap();
    let curl_grad = curl(&grad_phi, None).unwrap();

    let p = [1.5, -2.0, 0.5];
    let curl_val = curl_grad.evaluate(&p).unwrap().as_vector3().unwrap();

    assert!(curl_val[0].abs() < 1e-3, "Curl X = {} != 0", curl_val[0]);
    assert!(curl_val[1].abs() < 1e-3, "Curl Y = {} != 0", curl_val[1]);
    assert!(curl_val[2].abs() < 1e-3, "Curl Z = {} != 0", curl_val[2]);
}

#[test]
fn test_laplacian_operator() {
    // φ(x, y) = x³ + y³
    // ∂²φ/∂x² = 6x, ∂²φ/∂y² = 6y => ∇²φ = 6x + 6y
    // At (1.0, 2.0) => 6(1) + 6(2) = 18.0
    let domain = FieldDomain::new_2d("dom_lap", -5.0, 5.0, -5.0, 5.0).unwrap();
    let phi = Field::new_analytic("phi_lap", domain, ValueSpace::ScalarSpace, |p: &[f64]| {
        Ok(FieldValue::Scalar(p[0].powi(3) + p[1].powi(3)))
    });

    let lap_phi = laplacian(&phi, None).unwrap();
    let val = lap_phi.evaluate(&[1.0, 2.0]).unwrap().as_scalar().unwrap();
    assert!((val - 18.0).abs() < 1e-3, "Expected 18.0, got {}", val);
}

#[test]
fn test_advection_operator() {
    // Initial profile φ(x, y) = x
    // Constant velocity field u = (2.0, 0.0)
    // Time step dt = 1.5
    // Advected profile: φ_next(x, y) = φ(x - 2.0*1.5, y) = x - 3.0
    let domain = FieldDomain::new_2d("dom_adv", -10.0, 10.0, -10.0, 10.0).unwrap();
    let phi = Field::new_analytic("phi", domain.clone(), ValueSpace::ScalarSpace, |p: &[f64]| {
        Ok(FieldValue::Scalar(p[0]))
    });

    let u = Field::new_analytic("velocity", domain, ValueSpace::VectorSpace(2), |_| {
        Ok(FieldValue::Vector2([2.0, 0.0]))
    });

    let advected = advection(&phi, &u, 1.5).unwrap();
    let val = advected.evaluate(&[5.0, 0.0]).unwrap().as_scalar().unwrap();
    // At x = 5.0, backtracked point is 5.0 - 3.0 = 2.0 -> φ(2.0) = 2.0
    assert!((val - 2.0).abs() < 1e-6, "Expected 2.0, got {}", val);
}
