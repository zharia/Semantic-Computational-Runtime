use scr_hypergraph::Hypergraph;
use scr_identity::coordinate::CoordinateRegion;
use scr_identity::hypergraph::{project_identity_to_hypergraph, to_element_id};
use scr_identity::machine::IAMMachine;

#[test]
fn test_hypergraph_identity_projection() {
    let mut machine = IAMMachine::new("GENESIS-SCR-001");
    let root_id = "root_hg";
    machine.create_root(root_id).unwrap();

    let space_reg = CoordinateRegion::new(0, 1000).unwrap();
    machine.create_space("space_hg", root_id, space_reg).unwrap();

    let reg_a = CoordinateRegion::new(0, 500).unwrap();
    machine
        .reserve_domain("dom_root_space_hg", "dom_hg", 42, reg_a)
        .unwrap();

    machine
        .create_authority("auth_hg", root_id, "cred://auth_hg/v1", None)
        .unwrap();
    machine.delegate_domain("dom_hg", "auth_hg").unwrap();
    machine.activate_domain("dom_hg").unwrap();

    // Allocate coordinate
    let sid = machine.reserve_sid("dom_hg", 7, "auth_hg", 1, "tx_hg_1").unwrap();
    machine.commit_sid("tx_hg_1").unwrap();
    machine.bind_sid(sid, "entity_hyper_sensor").unwrap();

    // Project onto Hypergraph
    let mut graph = Hypergraph::new();
    project_identity_to_hypergraph(&machine, root_id, &mut graph).unwrap();

    // Verify Root element exists
    let root_elem = scr_hypergraph::ElementId(format!("elem:auth:root:{}", root_id));
    assert!(graph.get_element(&root_elem).is_some());

    // Verify Domain element exists
    let dom_elem = scr_hypergraph::ElementId("elem:domain:dom_hg".to_string());
    assert!(graph.get_element(&dom_elem).is_some());

    // Verify Coordinate element exists
    let sid_elem = to_element_id(root_id, &sid);
    assert!(graph.get_element(&sid_elem).is_some());

    // Verify Entity element and binding relation exist
    let entity_elem = scr_hypergraph::ElementId("elem:entity:entity_hyper_sensor".to_string());
    assert!(graph.get_element(&entity_elem).is_some());

    let bind_rel = scr_hypergraph::RelationId(format!(
        "rel:binding:{}_entity_hyper_sensor",
        sid.to_u128()
    ));
    assert!(graph.get_relation(&bind_rel).is_some());
}
