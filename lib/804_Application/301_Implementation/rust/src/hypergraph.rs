use crate::error::{ApplicationError, ApplicationResult};
use crate::module::ApplicationModule;
use scr_hypergraph::{
    Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role,
};

/// Projects an application module and its constituent services and ports into
/// the canonical SCR Hypergraph.
pub fn project_module_to_hypergraph(
    module: &ApplicationModule,
    hypergraph: &mut Hypergraph,
) -> ApplicationResult<()> {
    // 1. Module Element
    let mod_elem_id = ElementId(format!("elem:app_mod:{}", module.id));
    if hypergraph.get_element(&mod_elem_id).is_none() {
        hypergraph
            .create_element(mod_elem_id.clone(), format!("Module:{}", module.name))
            .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;
    }

    // 2. Project Services & ModuleServiceContainment relations
    for (srv_id, srv) in &module.services {
        let srv_elem_id = ElementId(format!("elem:app_srv:{}", srv_id));
        if hypergraph.get_element(&srv_elem_id).is_none() {
            hypergraph
                .create_element(srv_elem_id.clone(), format!("Service:{}", srv.name))
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;
        }

        let rel_id = RelationId(format!("rel:mod_srv:{}_{}", module.id, srv_id));
        if hypergraph.get_relation(&rel_id).is_none() {
            hypergraph
                .create_relation(rel_id.clone(), "ModuleServiceContainment".to_string())
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;

            let inc_mod = IncidenceId(format!("inc:mod_{}_{}", module.id, srv_id));
            hypergraph
                .attach_incidence(
                    inc_mod,
                    &mod_elem_id,
                    &rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;

            let inc_srv = IncidenceId(format!("inc:srv_{}_{}", module.id, srv_id));
            hypergraph
                .attach_incidence(
                    inc_srv,
                    &srv_elem_id,
                    &rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;
        }
    }

    // 3. Project Ports & ModulePortBoundary relations
    for (port_id, port) in &module.ports {
        let port_elem_id = ElementId(format!("elem:app_port:{}", port_id));
        if hypergraph.get_element(&port_elem_id).is_none() {
            hypergraph
                .create_element(
                    port_elem_id.clone(),
                    format!("Port:{}:dir={:?}", port.name, port.direction),
                )
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;
        }

        let rel_id = RelationId(format!("rel:mod_port:{}_{}", module.id, port_id));
        if hypergraph.get_relation(&rel_id).is_none() {
            hypergraph
                .create_relation(rel_id.clone(), "ModulePortBoundary".to_string())
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;

            let inc_mod = IncidenceId(format!("inc:mod_p_{}_{}", module.id, port_id));
            hypergraph
                .attach_incidence(
                    inc_mod,
                    &mod_elem_id,
                    &rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;

            let inc_port = IncidenceId(format!("inc:port_{}_{}", module.id, port_id));
            hypergraph
                .attach_incidence(
                    inc_port,
                    &port_elem_id,
                    &rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| ApplicationError::HypergraphMappingError(e.to_string()))?;
        }
    }

    Ok(())
}
