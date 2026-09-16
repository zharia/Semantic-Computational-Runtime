// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_interfaces::{
    verify_substitutability, Capability, Effect, InterfaceId, Namespace, OperationContract,
    ParameterContract, SemanticInterface, SemanticVersion, TypeContract,
};

#[test]
fn test_substitutability_and_refinement() {
    let intf_id = InterfaceId::new("SCR::Data::Storage");
    let ns = Namespace::new("SCR::Data");
    let ver = SemanticVersion::new(1, 0, 0);

    let mut required = SemanticInterface::new(intf_id, ns.clone(), ver);
    required.capabilities.insert(Capability::Persistable);
    required.capabilities.insert(Capability::Deterministic);

    let op = OperationContract::new("write_record", TypeContract::new("Status", "types/bool"))
        .with_input(ParameterContract {
            name: "record_id".into(),
            type_contract: TypeContract::new("Id", "types/string"),
            is_required: true,
        })
        .with_effect(Effect::MutatesState("storage_wal".into()));
    required.add_operation(op);

    // Valid candidate: implements write_record, has required capabilities and adds Optimizable
    let mut candidate_valid = SemanticInterface::new(
        InterfaceId::new("SCR::Data::OptimizedStorage"),
        ns.clone(),
        SemanticVersion::new(1, 1, 0),
    );
    candidate_valid.capabilities.insert(Capability::Persistable);
    candidate_valid.capabilities.insert(Capability::Deterministic);
    candidate_valid.capabilities.insert(Capability::Optimizable); // Valid refinement!

    let op_candidate = OperationContract::new("write_record", TypeContract::new("Status", "types/bool"))
        .with_input(ParameterContract {
            name: "record_id".into(),
            type_contract: TypeContract::new("Id", "types/string"),
            is_required: true,
        })
        .with_effect(Effect::MutatesState("storage_wal".into()));
    candidate_valid.add_operation(op_candidate);

    assert!(verify_substitutability(&required, &candidate_valid).is_ok());

    // Invalid candidate: introduces undeclared side effect (e.g. ExternalIO when required didn't declare it)
    let mut candidate_invalid_effect = candidate_valid.clone();
    let op_leaky = OperationContract::new("write_record", TypeContract::new("Status", "types/bool"))
        .with_input(ParameterContract {
            name: "record_id".into(),
            type_contract: TypeContract::new("Id", "types/string"),
            is_required: true,
        })
        .with_effect(Effect::MutatesState("storage_wal".into()))
        .with_effect(Effect::ExternalIO("http://analytics.external.com".into())); // Leaky side effect!
    candidate_invalid_effect.add_operation(op_leaky);

    assert!(verify_substitutability(&required, &candidate_invalid_effect).is_err());
}
