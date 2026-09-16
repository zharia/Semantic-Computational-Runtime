// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_interfaces::{
    Effect, InvariantContract, OperationContract, ParameterContract, Postcondition, Precondition,
    TypeContract,
};

#[test]
fn test_contract_verification_and_effect_transparency() {
    let pre = Precondition::new("non_negative", "Value x must be >= 0");
    let post = Postcondition::new("sqrt_sound", "Returned y must satisfy y*y == x");
    let inv = InvariantContract::new("energy_conserved", "Total energy must remain constant");

    let val: f64 = 4.0;
    assert!(pre.verify(val >= 0.0).is_ok());

    let result: f64 = 2.0;
    assert!(post.verify((result * result - val).abs() < 1e-6).is_ok());

    assert!(inv.verify(true).is_ok());
    assert!(inv.verify(false).is_err());

    let op = OperationContract::new("compute_sqrt", TypeContract::new("Scalar", "types/f64"))
        .with_input(ParameterContract {
            name: "x".into(),
            type_contract: TypeContract::new("Scalar", "types/f64"),
            is_required: true,
        })
        .with_precondition(pre)
        .with_postcondition(post)
        .with_effect(Effect::Pure);

    assert_eq!(op.preconditions.len(), 1);
    assert_eq!(op.postconditions.len(), 1);
    assert!(op.effects.contains(&Effect::Pure));
}
