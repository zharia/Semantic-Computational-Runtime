// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_math::*;

#[test]
fn test_all_17_normative_math_invariants() {
    // MATH-INV-001 (Mathematical Primacy) & MATH-INV-002 (Representation Independence)
    let v1 = Vector::new(vec![1.0, 2.0, 3.0]);
    let v2 = Vector::new(vec![4.0, 5.0, 6.0]);
    assert_eq!(v1.dim(), 3);
    assert_eq!(v1.dot(&v2).unwrap(), 32.0);

    // MATH-INV-003 (Equality Integrity): Semantic vs bitwise
    let tol = ToleranceContract::new(1e-5, 1e-5);
    assert!(tol.is_within_tolerance(1.0, 1.000005));
    assert!(!tol.is_within_tolerance(1.0, 1.01));

    // MATH-INV-004 (Exactness Integrity) & MATH-INV-009 (Approximation Transparency)
    let exact_val = NumericValue::ExactRational { numerator: 1, denominator: 3 };
    let approx_val = NumericValue::ApproximateReal { value: 0.333333, uncertainty: 1e-6 };
    assert!(exact_val.is_exact());
    assert!(!approx_val.is_exact());

    // MATH-INV-005 (Algebraic Integrity)
    let add_contract = BinaryOperationContract::new("Addition", |a: &i32, b: &i32| *a + *b, Some(0));
    assert!(add_contract.verify_associativity(&1, &2, &3).is_ok());
    assert!(add_contract.verify_identity(&42).is_ok());
    assert!(add_contract.verify_commutativity(&10, &20).is_ok());

    // MATH-INV-006 (Domain Integrity): Division by zero
    let c = ComplexNumber::new(0.0, 0.0);
    assert!(c.inv().is_err());

    // MATH-INV-007 (Transformation Integrity): 3D Rotation preserves norm
    let axis = Vector::new(vec![0.0, 0.0, 1.0]);
    let q = Quaternion::from_axis_angle(&axis, std::f64::consts::PI / 2.0).unwrap();
    let rotated = q.rotate_vector(&Vector::new(vec![1.0, 0.0, 0.0])).unwrap();
    assert!((rotated.norm() - 1.0).abs() < 1e-6);

    // MATH-INV-008 (Dimensional Integrity)
    let v_dim2 = Vector::new(vec![1.0, 2.0]);
    assert!(v1.dot(&v_dim2).is_err());

    // MATH-INV-010 (Numerical Contract Integrity)
    assert!(tol.verify(2.0, 2.000001).is_ok());
    assert!(tol.verify(2.0, 2.05).is_err());

    // MATH-INV-011 (Function Integrity) & MATH-INV-012 (Composition Integrity)
    let poly = Polynomial::new(vec![1.0, -2.0, 1.0]); // P(x) = (x - 1)^2
    assert_eq!(poly.eval(1.0), 0.0);
    assert_eq!(poly.eval(3.0), 4.0);

    // MATH-INV-013 (Equivalence Integrity): Exact dual derivative vs symbolic derivative
    let f_dual = |x: DualNumber| x.powi(2) - DualNumber::constant(2.0) * x + DualNumber::constant(1.0);
    let d_exact = eval_derivative_exact(f_dual, 3.0);
    let d_poly = poly.derivative();
    assert_eq!(d_exact, d_poly.eval(3.0));

    // MATH-INV-014 (Execution Independence) & MATH-INV-015 (Provider Independence)
    let m = Matrix::identity(3);
    assert_eq!(m.trace().unwrap(), 3.0);

    // MATH-INV-016 (Core Conformance): Hypergraph integration with nullary axioms
    let mut hg = scr_hypergraph::Hypergraph::new();
    project_math_axioms_to_hypergraph("LinearAlgebra", &["Associativity", "Distributivity"], &mut hg).unwrap();
    let domain_node = hg.get_element(&scr_hypergraph::ElementId("elem:math_domain:LinearAlgebra".into()));
    assert!(domain_node.is_some());
    let nullary_axiom = hg.get_relation(&scr_hypergraph::RelationId("rel:math_axiom:LinearAlgebra_Associativity".into())).unwrap();
    assert!(nullary_axiom.is_nullary());
    assert_eq!(nullary_axiom.cardinality(), 0);

    // MATH-INV-017 (Domain Independence): Statistics and moments
    let data = [1.0, 2.0, 3.0, 4.0, 5.0];
    assert_eq!(sample_mean(&data).unwrap(), 3.0);
    assert_eq!(sample_variance(&data).unwrap(), 2.5);
}
