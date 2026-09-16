// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_hypergraph::{ElementId, Hypergraph, RelationId};
use scr_interfaces::{
    project_interface_to_hypergraph, Capability, InterfaceId, Namespace, OperationContract,
    ProviderBinding, ProviderSubstrate, SemanticInterface, SemanticVersion, TypeContract,
};

#[test]
fn test_hypergraph_interface_projection() {
    let mut intf = SemanticInterface::new(
        InterfaceId::new("SCR::Field::SdfEvaluator"),
        Namespace::new("SCR::Field"),
        SemanticVersion::new(1, 0, 0),
    );
    intf.capabilities.insert(Capability::Differentiable);
    intf.capabilities.insert(Capability::Spatial);

    let op = OperationContract::new("sample_distance", TypeContract::new("f64", "types/f64"));
    intf.add_operation(op);

    let provider = ProviderBinding::new(
        "mojo_field_kernel",
        intf.id.clone(),
        ProviderSubstrate::MojoNative,
        "evaluate_sdf_kernel",
    );

    let mut hg = Hypergraph::new();
    project_interface_to_hypergraph(&intf, &[provider], &mut hg).unwrap();

    // Verify Interface element
    assert!(hg.get_element(&ElementId("elem:intf:SCR::Field::SdfEvaluator".into())).is_some());

    // Verify Operation element
    assert!(hg.get_element(&ElementId("elem:op:SCR::Field::SdfEvaluator_sample_distance".into())).is_some());

    // Verify Capability element
    assert!(hg.get_element(&ElementId("elem:cap:Differentiable".into())).is_some());
    assert!(hg.get_element(&ElementId("elem:cap:Spatial".into())).is_some());

    // Verify Provider element
    assert!(hg.get_element(&ElementId("elem:prov:mojo_field_kernel".into())).is_some());

    // Verify ambient nullary relation (INTERFACE-INV-018)
    let nullary_rel = hg.get_relation(&RelationId("rel:ambient_interface_axiom:SCR::Field::SdfEvaluator".into())).unwrap();
    assert!(nullary_rel.is_nullary());
    assert_eq!(nullary_rel.cardinality(), 0);
}
