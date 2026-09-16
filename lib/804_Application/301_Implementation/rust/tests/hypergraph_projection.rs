use scr_application::hypergraph::project_module_to_hypergraph;
use scr_application::module::ApplicationModule;
use scr_application::port::{ApplicationPort, PortKind};
use scr_application::service::ApplicationService;
use scr_hypergraph::{ElementId, Hypergraph, RelationId};

#[test]
fn test_hypergraph_application_module_projection() {
    let mut module = ApplicationModule::new("mod_windowing", "WindowingModule");

    let srv = ApplicationService::new("srv_window", "WindowService");
    module.register_service(srv);

    let port = ApplicationPort::new_inbound(
        "port_win_events",
        "WindowEventsPort",
        PortKind::Event,
        "wayland_xdg_shell_v1",
    );
    module.register_port(port);

    let mut graph = Hypergraph::new();
    project_module_to_hypergraph(&module, &mut graph).unwrap();

    // Verify Module Element exists
    let mod_elem = ElementId("elem:app_mod:mod_windowing".to_string());
    assert!(graph.get_element(&mod_elem).is_some());

    // Verify Service Element exists
    let srv_elem = ElementId("elem:app_srv:srv_window".to_string());
    assert!(graph.get_element(&srv_elem).is_some());

    // Verify Port Element exists
    let port_elem = ElementId("elem:app_port:port_win_events".to_string());
    assert!(graph.get_element(&port_elem).is_some());

    // Verify Relationships
    let rel_srv = RelationId("rel:mod_srv:mod_windowing_srv_window".to_string());
    assert!(graph.get_relation(&rel_srv).is_some());

    let rel_port = RelationId("rel:mod_port:mod_windowing_port_win_events".to_string());
    assert!(graph.get_relation(&rel_port).is_some());
}
