// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_interfaces::{
    compose_interfaces, Capability, InterfaceId, Namespace, OperationContract, SemanticInterface,
    SemanticVersion, TypeContract,
};

#[test]
fn test_composition_and_conflict_handling() {
    let ns = Namespace::new("SCR::Composite");
    let ver = SemanticVersion::new(1, 0, 0);

    let mut intf_a = SemanticInterface::new(InterfaceId::new("IntfA"), ns.clone(), ver);
    intf_a.capabilities.insert(Capability::Streamable);
    intf_a.add_operation(OperationContract::new("stream_next", TypeContract::new("Element", "t/elem")));

    let mut intf_b = SemanticInterface::new(InterfaceId::new("IntfB"), ns.clone(), ver);
    intf_b.capabilities.insert(Capability::Observable);
    intf_b.add_operation(OperationContract::new("observe_metric", TypeContract::new("Metric", "t/metric")));

    // Successful composition
    let composed = compose_interfaces(
        InterfaceId::new("IntfAB"),
        ns.clone(),
        ver,
        &intf_a,
        &intf_b,
    ).unwrap();

    assert!(composed.capabilities.contains(Capability::Streamable));
    assert!(composed.capabilities.contains(Capability::Observable));
    assert_eq!(composed.operations.len(), 2);

    // Conflicting composition: intf_c has "stream_next" but with different output type!
    let mut intf_c = SemanticInterface::new(InterfaceId::new("IntfC"), ns.clone(), ver);
    intf_c.add_operation(OperationContract::new("stream_next", TypeContract::new("DifferentOutput", "t/diff")));

    let conflict = compose_interfaces(
        InterfaceId::new("IntfAC"),
        ns,
        ver,
        &intf_a,
        &intf_c,
    );
    assert!(conflict.is_err());
}
