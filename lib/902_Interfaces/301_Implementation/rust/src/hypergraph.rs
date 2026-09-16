// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{InterfaceError, Result};
use crate::interface::SemanticInterface;
use crate::provider::ProviderBinding;
use scr_hypergraph::{Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role};

/// Projects an interface, its operations, capabilities, and provider bindings
/// into the canonical SCR Semantic Hypergraph.
pub fn project_interface_to_hypergraph(
    interface: &SemanticInterface,
    providers: &[ProviderBinding],
    hypergraph: &mut Hypergraph,
) -> Result<()> {
    // 1. Interface Element Node
    let intf_elem_id = ElementId(format!("elem:intf:{}", interface.id.as_str()));
    if hypergraph.get_element(&intf_elem_id).is_none() {
        hypergraph
            .create_element(intf_elem_id.clone(), format!("Interface:{}", interface.id.as_str()))
            .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
    }

    // 2. Project Operations and InterfaceOperationExposure relations
    for (op_name, _op) in &interface.operations {
        let op_elem_id = ElementId(format!("elem:op:{}_{}", interface.id.as_str(), op_name));
        if hypergraph.get_element(&op_elem_id).is_none() {
            hypergraph
                .create_element(op_elem_id.clone(), format!("Operation:{}", op_name))
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
        }

        let rel_id = RelationId(format!("rel:intf_op:{}_{}", interface.id.as_str(), op_name));
        if hypergraph.get_relation(&rel_id).is_none() {
            hypergraph
                .create_relation(rel_id.clone(), "InterfaceOperationExposure".to_string())
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;

            let inc_intf = IncidenceId(format!("inc:intf_{}_{}", interface.id.as_str(), op_name));
            hypergraph
                .attach_incidence(inc_intf, &intf_elem_id, &rel_id, Role::Source, Direction::Outgoing)
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;

            let inc_op = IncidenceId(format!("inc:op_{}_{}", interface.id.as_str(), op_name));
            hypergraph
                .attach_incidence(inc_op, &op_elem_id, &rel_id, Role::Target, Direction::Ingoing)
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
        }
    }

    // 3. Project Capabilities and InterfaceCapabilityDeclaration relations
    for cap in interface.capabilities.iter() {
        let cap_name = cap.name();
        let cap_elem_id = ElementId(format!("elem:cap:{}", cap_name));
        if hypergraph.get_element(&cap_elem_id).is_none() {
            hypergraph
                .create_element(cap_elem_id.clone(), format!("Capability:{}", cap_name))
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
        }

        let rel_id = RelationId(format!("rel:intf_cap:{}_{}", interface.id.as_str(), cap_name));
        if hypergraph.get_relation(&rel_id).is_none() {
            hypergraph
                .create_relation(rel_id.clone(), "InterfaceCapabilityDeclaration".to_string())
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;

            let inc_intf = IncidenceId(format!("inc:intf_cap_{}_{}", interface.id.as_str(), cap_name));
            hypergraph
                .attach_incidence(inc_intf, &intf_elem_id, &rel_id, Role::Source, Direction::Outgoing)
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;

            let inc_cap = IncidenceId(format!("inc:cap_{}_{}", interface.id.as_str(), cap_name));
            hypergraph
                .attach_incidence(inc_cap, &cap_elem_id, &rel_id, Role::Target, Direction::Ingoing)
                .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
        }
    }

    // 4. Project Providers and ProviderRealization relations
    for prov in providers {
        if prov.interface_id == interface.id {
            let prov_elem_id = ElementId(format!("elem:prov:{}", prov.provider_id));
            if hypergraph.get_element(&prov_elem_id).is_none() {
                hypergraph
                    .create_element(prov_elem_id.clone(), format!("Provider:{}", prov.provider_id))
                    .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
            }

            let rel_id = RelationId(format!("rel:prov_intf:{}_{}", prov.provider_id, interface.id.as_str()));
            if hypergraph.get_relation(&rel_id).is_none() {
                hypergraph
                    .create_relation(rel_id.clone(), "ProviderRealization".to_string())
                    .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;

                let inc_prov = IncidenceId(format!("inc:prov_{}", prov.provider_id));
                hypergraph
                    .attach_incidence(inc_prov, &prov_elem_id, &rel_id, Role::Source, Direction::Outgoing)
                    .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;

                let inc_intf = IncidenceId(format!("inc:intf_real_{}", prov.provider_id));
                hypergraph
                    .attach_incidence(inc_intf, &intf_elem_id, &rel_id, Role::Target, Direction::Ingoing)
                    .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
            }
        }
    }

    // 5. Nullary Relation: Ambient Contract Invariant Axiom (0 incidences)
    let nullary_rel_id = RelationId(format!("rel:ambient_interface_axiom:{}", interface.id.as_str()));
    if hypergraph.get_relation(&nullary_rel_id).is_none() {
        hypergraph
            .create_relation(nullary_rel_id, "AmbientInterfaceContractAxiom".to_string())
            .map_err(|e| InterfaceError::SemanticInvalidity(e.to_string()))?;
    }

    Ok(())
}
