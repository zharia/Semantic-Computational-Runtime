// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_math::{BinaryOperationContract, ComplexNumber};

#[test]
fn test_complex_field_algebraic_laws() {
    let add_contract = BinaryOperationContract::new(
        "ComplexAddition",
        |a: &ComplexNumber, b: &ComplexNumber| *a + *b,
        Some(ComplexNumber::new(0.0, 0.0)),
    );

    let z1 = ComplexNumber::new(1.0, 2.0);
    let z2 = ComplexNumber::new(-3.0, 4.0);
    let z3 = ComplexNumber::new(5.0, -6.0);

    // Associativity
    assert!(add_contract.verify_associativity(&z1, &z2, &z3).is_ok());

    // Identity
    assert!(add_contract.verify_identity(&z1).is_ok());

    // Commutativity
    assert!(add_contract.verify_commutativity(&z1, &z2).is_ok());

    // Multiplication
    let mul_contract = BinaryOperationContract::new(
        "ComplexMultiplication",
        |a: &ComplexNumber, b: &ComplexNumber| *a * *b,
        Some(ComplexNumber::new(1.0, 0.0)),
    );

    assert!(mul_contract.verify_associativity(&z1, &z2, &z3).is_ok());
    assert!(mul_contract.verify_identity(&z1).is_ok());
    assert!(mul_contract.verify_commutativity(&z1, &z2).is_ok());
}
