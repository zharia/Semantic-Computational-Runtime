use scr_hypergraph::{
    Hypergraph, ElementId, RelationId, IncidenceId, Role, Direction, HypergraphError,
};
use std::sync::{Arc, RwLock};
use std::thread;

// ============================================================================
// HYPERGRAPH CONFORMANCE SUITE (C001 - C020)
// ============================================================================

/// HYPERGRAPH-C001: Element identity
/// Semantic identity is independent of memory layout, address, or name.
#[test]
fn test_c001_element_identity() {
    let mut hg = Hypergraph::new();
    let e1_id = ElementId::new("elem-001");
    let e2_id = ElementId::new("elem-002");

    hg.create_element(e1_id.clone(), "SameName").unwrap();
    hg.create_element(e2_id.clone(), "SameName").unwrap();

    let e1 = hg.get_element(&e1_id).unwrap();
    let e2 = hg.get_element(&e2_id).unwrap();

    assert_ne!(e1.id(), e2.id(), "Elements with same name must maintain distinct identities");
    assert_eq!(e1.name(), "SameName");
    assert_eq!(e2.name(), "SameName");
}

/// HYPERGRAPH-C002: Relation identity
/// Distinct relations remain distinct even when connecting identical participant sets.
#[test]
fn test_c002_relation_identity() {
    let mut hg = Hypergraph::new();
    let r1_id = RelationId::new("rel-001");
    let r2_id = RelationId::new("rel-002");

    hg.create_relation(r1_id.clone(), "Transfer").unwrap();
    hg.create_relation(r2_id.clone(), "Transfer").unwrap();

    let r1 = hg.get_relation(&r1_id).unwrap();
    let r2 = hg.get_relation(&r2_id).unwrap();

    assert_ne!(r1.id(), r2.id(), "Distinct relations must have distinct identities");
}

/// HYPERGRAPH-C003: Incidence identity
/// Incidences are first-class semantic objects with independent identity.
#[test]
fn test_c003_incidence_identity() {
    let mut hg = Hypergraph::new();
    let e = ElementId::new("elem-001");
    let r = RelationId::new("rel-001");
    let i1 = IncidenceId::new("inc-001");
    let i2 = IncidenceId::new("inc-002");

    hg.create_element(e.clone(), "Node").unwrap();
    hg.create_relation(r.clone(), "Edge").unwrap();

    hg.attach_incidence(i1.clone(), &e, &r, Role::Input, Direction::Ingoing).unwrap();
    hg.attach_incidence(i2.clone(), &e, &r, Role::Output, Direction::Outgoing).unwrap();

    let inc1 = hg.get_incidence(&i1).unwrap();
    let inc2 = hg.get_incidence(&i2).unwrap();

    assert_ne!(inc1.id(), inc2.id());
    assert_eq!(inc1.element(), &e);
    assert_eq!(inc2.element(), &e);
    assert_eq!(inc1.role(), &Role::Input);
    assert_eq!(inc2.role(), &Role::Output);
}

/// HYPERGRAPH-C004: Arbitrary relation cardinality
/// Relations support 0, 1, 2, 3, 5, and arbitrary numbers of participants.
#[test]
fn test_c004_arbitrary_relation_cardinality() {
    let mut hg = Hypergraph::new();
    let r = RelationId::new("rel-n-ary");
    hg.create_relation(r.clone(), "N-ary Relation").unwrap();

    // 0: nullary
    assert_eq!(hg.get_relation(&r).unwrap().cardinality(), 0);
    assert!(hg.get_relation(&r).unwrap().is_nullary());

    // 1: unary
    let e0 = ElementId::new("e-0");
    hg.create_element(e0.clone(), "e0").unwrap();
    hg.attach_incidence(IncidenceId::new("i-0"), &e0, &r, Role::Operand, Direction::Undirected).unwrap();
    assert_eq!(hg.get_relation(&r).unwrap().cardinality(), 1);
    assert!(hg.get_relation(&r).unwrap().is_unary());

    // 5-ary
    for idx in 1..5 {
        let eid = ElementId::new(format!("e-{}", idx));
        let iid = IncidenceId::new(format!("i-{}", idx));
        hg.create_element(eid.clone(), format!("e{}", idx)).unwrap();
        hg.attach_incidence(iid, &eid, &r, Role::Operand, Direction::Undirected).unwrap();
    }
    assert_eq!(hg.get_relation(&r).unwrap().cardinality(), 5);
}

/// HYPERGRAPH-C005: Multiple relations with identical participants
/// Two relations connecting the exact same elements remain distinct entities.
#[test]
fn test_c005_multiple_relations_identical_participants() {
    let mut hg = Hypergraph::new();
    let e1 = ElementId::new("e1");
    let e2 = ElementId::new("e2");
    hg.create_element(e1.clone(), "A").unwrap();
    hg.create_element(e2.clone(), "B").unwrap();

    let r1 = RelationId::new("r-road");
    let r2 = RelationId::new("r-telecom");
    hg.create_relation(r1.clone(), "RoadConnection").unwrap();
    hg.create_relation(r2.clone(), "FiberConnection").unwrap();

    // r1 connects e1, e2
    hg.attach_incidence(IncidenceId::new("i1-1"), &e1, &r1, Role::Source, Direction::Outgoing).unwrap();
    hg.attach_incidence(IncidenceId::new("i1-2"), &e2, &r1, Role::Target, Direction::Ingoing).unwrap();

    // r2 connects e1, e2 identically
    hg.attach_incidence(IncidenceId::new("i2-1"), &e1, &r2, Role::Source, Direction::Outgoing).unwrap();
    hg.attach_incidence(IncidenceId::new("i2-2"), &e2, &r2, Role::Target, Direction::Ingoing).unwrap();

    assert_ne!(r1, r2);
    assert_eq!(hg.relation_count(), 2);
    assert_eq!(hg.incidence_count(), 4);

    // Deleting r1 must leave r2 intact
    hg.remove_relation(&r1).unwrap();
    assert!(hg.get_relation(&r1).is_none());
    assert!(hg.get_relation(&r2).is_some());
    assert_eq!(hg.get_relation(&r2).unwrap().cardinality(), 2);
}

/// HYPERGRAPH-C006: Directed / role-bearing incidence
#[test]
fn test_c006_directed_role_bearing_incidence() {
    let mut hg = Hypergraph::new();
    let e = ElementId::new("param1");
    let r = RelationId::new("op1");
    let i = IncidenceId::new("inc1");

    hg.create_element(e.clone(), "Weight").unwrap();
    hg.create_relation(r.clone(), "Convolution").unwrap();
    hg.attach_incidence(i.clone(), &e, &r, Role::Parameter, Direction::Ingoing).unwrap();

    let inc = hg.get_incidence(&i).unwrap();
    assert_eq!(inc.role(), &Role::Parameter);
    assert_eq!(inc.direction(), Direction::Ingoing);
}

/// HYPERGRAPH-C007: Self-incidence
/// An element can be incident to the same relation multiple times with distinct roles.
#[test]
fn test_c007_self_incidence() {
    let mut hg = Hypergraph::new();
    let e = ElementId::new("e-self");
    let r = RelationId::new("r-recurrent");
    hg.create_element(e.clone(), "Cell").unwrap();
    hg.create_relation(r.clone(), "Recurrence").unwrap();

    hg.attach_incidence(IncidenceId::new("i-src"), &e, &r, Role::Source, Direction::Outgoing).unwrap();
    hg.attach_incidence(IncidenceId::new("i-tgt"), &e, &r, Role::Target, Direction::Ingoing).unwrap();

    let rel = hg.get_relation(&r).unwrap();
    assert_eq!(rel.cardinality(), 2);

    let elem = hg.get_element(&e).unwrap();
    assert_eq!(elem.incidences().len(), 2);
}

/// HYPERGRAPH-C008: Unary relations
#[test]
fn test_c008_unary_relations() {
    let mut hg = Hypergraph::new();
    let e = ElementId::new("e1");
    let r = RelationId::new("r-unary");
    hg.create_element(e.clone(), "Vertex").unwrap();
    hg.create_relation(r.clone(), "IsAnchor").unwrap();

    hg.attach_incidence(IncidenceId::new("i1"), &e, &r, Role::Subject, Direction::Undirected).unwrap();

    let rel = hg.get_relation(&r).unwrap();
    assert!(rel.is_unary());
    assert_eq!(rel.cardinality(), 1);
}

/// HYPERGRAPH-C009: Nullary relation validity
/// Zero incidences (|I(R)| = 0) is valid semantic SCR state.
#[test]
fn test_c009_nullary_relation_validity() {
    let mut hg = Hypergraph::new();
    let r_id = RelationId::new("r-nullary");
    let rel = hg.create_relation(r_id.clone(), "GlobalConstraint").unwrap();

    assert!(rel.is_nullary());
    assert_eq!(rel.cardinality(), 0);
    assert_eq!(rel.incidences().len(), 0);
}

/// HYPERGRAPH-C010: Nullary relation identity
/// Two nullary relations are distinct entities despite empty participant sets.
#[test]
fn test_c010_nullary_relation_identity() {
    let mut hg = Hypergraph::new();
    let r1 = RelationId::new("r-global-gravity");
    let r2 = RelationId::new("r-global-lighting");

    hg.create_relation(r1.clone(), "Gravity").unwrap();
    hg.create_relation(r2.clone(), "Lighting").unwrap();

    assert_ne!(r1, r2);
    assert_eq!(hg.relation_count(), 2);
    assert_eq!(hg.get_relation(&r1).unwrap().cardinality(), 0);
    assert_eq!(hg.get_relation(&r2).unwrap().cardinality(), 0);
}

/// HYPERGRAPH-C011: Nullary transition
/// A nullary relation can transition to unary/binary without changing its identity.
#[test]
fn test_c011_nullary_transition() {
    let mut hg = Hypergraph::new();
    let r = RelationId::new("r-transition");
    hg.create_relation(r.clone(), "EvolvingFact").unwrap();

    assert!(hg.get_relation(&r).unwrap().is_nullary());

    let e1 = ElementId::new("e1");
    hg.create_element(e1.clone(), "A").unwrap();
    hg.attach_incidence(IncidenceId::new("i1"), &e1, &r, Role::Subject, Direction::Undirected).unwrap();

    let rel_after = hg.get_relation(&r).unwrap();
    assert_eq!(rel_after.id(), &r, "RelationId must not change upon attaching incidence");
    assert_eq!(rel_after.cardinality(), 1);
    assert!(rel_after.is_unary());
}

/// HYPERGRAPH-C012: Emptying relation
/// Detaching all incidences leaves the relation in a valid nullary state with identical RelationId.
#[test]
fn test_c012_emptying_relation() {
    let mut hg = Hypergraph::new();
    let e = ElementId::new("e1");
    let r = RelationId::new("r1");
    let i = IncidenceId::new("i1");

    hg.create_element(e.clone(), "A").unwrap();
    hg.create_relation(r.clone(), "Association").unwrap();
    hg.attach_incidence(i.clone(), &e, &r, Role::Subject, Direction::Undirected).unwrap();

    assert_eq!(hg.get_relation(&r).unwrap().cardinality(), 1);

    hg.detach_incidence(&i).unwrap();

    let rel = hg.get_relation(&r).unwrap();
    assert!(rel.is_nullary(), "Relation must cleanly become nullary");
    assert_eq!(rel.id(), &r, "RelationId must be preserved when emptied");
    assert_eq!(hg.get_element(&e).unwrap().incidences().len(), 0);
}

/// HYPERGRAPH-C013: Incidence deletion
/// Deleting an incidence removes the connection but preserves both the element and relation.
#[test]
fn test_c013_incidence_deletion() {
    let mut hg = Hypergraph::new();
    let e = ElementId::new("e1");
    let r = RelationId::new("r1");
    let i = IncidenceId::new("i1");

    hg.create_element(e.clone(), "Node").unwrap();
    hg.create_relation(r.clone(), "Edge").unwrap();
    hg.attach_incidence(i.clone(), &e, &r, Role::Operand, Direction::Undirected).unwrap();

    assert_eq!(hg.incidence_count(), 1);
    let detached = hg.detach_incidence(&i).unwrap();
    assert_eq!(detached.id(), &i);

    assert_eq!(hg.incidence_count(), 0);
    assert!(hg.get_element(&e).is_some(), "Element must survive incidence deletion");
    assert!(hg.get_relation(&r).is_some(), "Relation must survive incidence deletion");
}

/// HYPERGRAPH-C014: Relation deletion cascade
/// Deleting a relation removes all its incidences, but all participating elements survive.
#[test]
fn test_c014_relation_deletion_cascade() {
    let mut hg = Hypergraph::new();
    let e1 = ElementId::new("e1");
    let e2 = ElementId::new("e2");
    let r = RelationId::new("r1");
    let i1 = IncidenceId::new("i1");
    let i2 = IncidenceId::new("i2");

    hg.create_element(e1.clone(), "E1").unwrap();
    hg.create_element(e2.clone(), "E2").unwrap();
    hg.create_relation(r.clone(), "R1").unwrap();
    hg.attach_incidence(i1.clone(), &e1, &r, Role::Input, Direction::Ingoing).unwrap();
    hg.attach_incidence(i2.clone(), &e2, &r, Role::Output, Direction::Outgoing).unwrap();

    assert_eq!(hg.incidence_count(), 2);

    hg.remove_relation(&r).unwrap();

    assert!(hg.get_relation(&r).is_none());
    assert_eq!(hg.incidence_count(), 0, "Incidences must cascade delete with relation");
    assert!(hg.get_element(&e1).is_some(), "Element E1 must survive");
    assert!(hg.get_element(&e2).is_some(), "Element E2 must survive");
    assert_eq!(hg.get_element(&e1).unwrap().incidences().len(), 0);
    assert_eq!(hg.get_element(&e2).unwrap().incidences().len(), 0);
}

/// HYPERGRAPH-C015: Element deletion cascade
/// Deleting an element cascades to remove its incidences; relations survive.
#[test]
fn test_c015_element_deletion_cascade() {
    let mut hg = Hypergraph::new();
    let e1 = ElementId::new("e1");
    let e2 = ElementId::new("e2");
    let r = RelationId::new("r1");
    let i1 = IncidenceId::new("i1");
    let i2 = IncidenceId::new("i2");

    hg.create_element(e1.clone(), "E1").unwrap();
    hg.create_element(e2.clone(), "E2").unwrap();
    hg.create_relation(r.clone(), "BinaryRel").unwrap();
    hg.attach_incidence(i1.clone(), &e1, &r, Role::Input, Direction::Ingoing).unwrap();
    hg.attach_incidence(i2.clone(), &e2, &r, Role::Output, Direction::Outgoing).unwrap();

    assert_eq!(hg.get_relation(&r).unwrap().cardinality(), 2);

    hg.remove_element(&e1).unwrap();

    assert!(hg.get_element(&e1).is_none());
    assert!(hg.get_element(&e2).is_some());
    assert!(hg.get_incidence(&i1).is_none(), "Incidence i1 must be cascaded");
    assert!(hg.get_incidence(&i2).is_some(), "Incidence i2 must survive");

    let r_survived = hg.get_relation(&r).unwrap();
    assert_eq!(r_survived.cardinality(), 1, "Relation transitions from binary to unary");
}

/// HYPERGRAPH-C016: Reference stability
/// Mutating unrelated elements/relations does not alter existing IDs or references.
#[test]
fn test_c016_reference_stability() {
    let mut hg = Hypergraph::new();
    let stable_e = ElementId::new("stable-e");
    let stable_r = RelationId::new("stable-r");
    hg.create_element(stable_e.clone(), "Stable").unwrap();
    hg.create_relation(stable_r.clone(), "StableRel").unwrap();

    // Create and delete ephemeral entities
    for idx in 0..50 {
        let ephem_e = ElementId::new(format!("ephem-e-{}", idx));
        let ephem_r = RelationId::new(format!("ephem-r-{}", idx));
        hg.create_element(ephem_e.clone(), "Temp").unwrap();
        hg.create_relation(ephem_r.clone(), "TempRel").unwrap();
        hg.remove_element(&ephem_e).unwrap();
        hg.remove_relation(&ephem_r).unwrap();
    }

    assert_eq!(hg.element_count(), 1);
    assert_eq!(hg.relation_count(), 1);
    assert_eq!(hg.get_element(&stable_e).unwrap().name(), "Stable");
    assert_eq!(hg.get_relation(&stable_r).unwrap().name(), "StableRel");
}

/// HYPERGRAPH-C017: Deleted reference handling
/// Operations on non-existent or deleted entities return clean errors, never panic.
#[test]
fn test_c017_deleted_reference_error() {
    let mut hg = Hypergraph::new();
    let ghost_e = ElementId::new("ghost-e");
    let ghost_r = RelationId::new("ghost-r");
    let ghost_i = IncidenceId::new("ghost-i");

    // Looking up ghost returns None
    assert!(hg.get_element(&ghost_e).is_none());
    assert!(hg.get_relation(&ghost_r).is_none());
    assert!(hg.get_incidence(&ghost_i).is_none());

    // Removing ghost returns structured error
    match hg.remove_element(&ghost_e) {
        Err(HypergraphError::ElementNotFound(id)) => assert_eq!(id, "ghost-e"),
        _ => panic!("Expected ElementNotFound"),
    }

    match hg.remove_relation(&ghost_r) {
        Err(HypergraphError::RelationNotFound(id)) => assert_eq!(id, "ghost-r"),
        _ => panic!("Expected RelationNotFound"),
    }

    match hg.detach_incidence(&ghost_i) {
        Err(HypergraphError::IncidenceNotFound(id)) => assert_eq!(id, "ghost-i"),
        _ => panic!("Expected IncidenceNotFound"),
    }
}

/// HYPERGRAPH-C018: Concurrent access and thread safety
/// Hypergraph carrier is Send + Sync, allowing concurrent traversal or synchronization across threads.
#[test]
fn test_c018_concurrent_access_and_thread_safety() {
    let mut hg = Hypergraph::new();
    for i in 0..10 {
        let e = ElementId::new(format!("e-{}", i));
        hg.create_element(e, format!("E{}", i)).unwrap();
    }

    let shared_hg = Arc::new(RwLock::new(hg));
    let mut handles = Vec::new();

    for thread_idx in 0..4 {
        let hg_ref = Arc::clone(&shared_hg);
        handles.push(thread::spawn(move || {
            let read_guard = hg_ref.read().unwrap();
            assert_eq!(read_guard.element_count(), 10);
            let elem_id = ElementId::new(format!("e-{}", thread_idx));
            assert!(read_guard.get_element(&elem_id).is_some());
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }
}

/// HYPERGRAPH-C019: Projections & information loss disclosure
#[test]
fn test_c019_projections() {
    let mut hg = Hypergraph::new();
    let e1 = ElementId::new("e1");
    let e2 = ElementId::new("e2");
    let e3 = ElementId::new("e3");
    let r_ternary = RelationId::new("r-ternary");

    hg.create_element(e1.clone(), "E1").unwrap();
    hg.create_element(e2.clone(), "E2").unwrap();
    hg.create_element(e3.clone(), "E3").unwrap();
    hg.create_relation(r_ternary.clone(), "Triangle").unwrap();

    hg.attach_incidence(IncidenceId::new("i1"), &e1, &r_ternary, Role::Operand, Direction::Undirected).unwrap();
    hg.attach_incidence(IncidenceId::new("i2"), &e2, &r_ternary, Role::Operand, Direction::Undirected).unwrap();
    hg.attach_incidence(IncidenceId::new("i3"), &e3, &r_ternary, Role::Operand, Direction::Undirected).unwrap();

    // 1. Ordinary graph projection must fail because ternary != binary
    match hg.to_ordinary_graph() {
        Err(HypergraphError::InvalidCardinality { expected, found }) => {
            assert_eq!(expected, 2);
            assert_eq!(found, 3);
        }
        _ => panic!("Expected InvalidCardinality"),
    }

    // 2. Bipartite graph projection succeeds isomorphically
    let bg = hg.to_bipartite_graph();
    assert_eq!(bg.element_vertices.len(), 3);
    assert_eq!(bg.relation_vertices.len(), 1);
    assert_eq!(bg.incidences.len(), 3);

    // 3. Clique expansion succeeds and formally discloses information loss
    let cg = hg.to_clique_expansion();
    assert_eq!(cg.vertices.len(), 3);
    assert_eq!(cg.edges.len(), 3, "Ternary edge expands to 3 pairwise edges in 2-clique");
    assert!(!cg.information_lost.is_empty(), "Information loss must be formally disclosed");
}

/// HYPERGRAPH-C020: Deterministic traversal
/// Traversal order is fully deterministic and invariant to internal insertion sequence.
#[test]
fn test_c020_deterministic_traversal() {
    let mut hg = Hypergraph::new();
    let e1 = ElementId::new("e-1");
    let e2 = ElementId::new("e-2");
    let e3 = ElementId::new("e-3");
    let r1 = RelationId::new("r-1-2");
    let r2 = RelationId::new("r-2-3");

    hg.create_element(e1.clone(), "1").unwrap();
    hg.create_element(e2.clone(), "2").unwrap();
    hg.create_element(e3.clone(), "3").unwrap();
    hg.create_relation(r1.clone(), "R1").unwrap();
    hg.create_relation(r2.clone(), "R2").unwrap();

    hg.attach_incidence(IncidenceId::new("i1"), &e1, &r1, Role::Source, Direction::Outgoing).unwrap();
    hg.attach_incidence(IncidenceId::new("i2"), &e2, &r1, Role::Target, Direction::Ingoing).unwrap();
    hg.attach_incidence(IncidenceId::new("i3"), &e2, &r2, Role::Source, Direction::Outgoing).unwrap();
    hg.attach_incidence(IncidenceId::new("i4"), &e3, &r2, Role::Target, Direction::Ingoing).unwrap();

    let order1 = hg.bfs(&e1).unwrap();
    let order2 = hg.bfs(&e1).unwrap();

    assert_eq!(order1, order2, "BFS traversal must be deterministic");
    assert_eq!(order1, vec![e1, e2, e3]);
}

// ============================================================================
// PATHOLOGICAL CASES
// ============================================================================

/// Pathological: Empty Hypergraph
#[test]
fn test_pathological_empty_hypergraph() {
    let hg = Hypergraph::new();
    assert!(hg.is_empty());
    assert_eq!(hg.element_count(), 0);
    assert_eq!(hg.relation_count(), 0);
    assert_eq!(hg.incidence_count(), 0);

    let ordinary = hg.to_ordinary_graph().unwrap();
    assert!(ordinary.vertices.is_empty());
    assert!(ordinary.edges.is_empty());

    let bipartite = hg.to_bipartite_graph();
    assert!(bipartite.element_vertices.is_empty());
    assert!(bipartite.relation_vertices.is_empty());

    let clique = hg.to_clique_expansion();
    assert!(clique.vertices.is_empty());
    assert!(clique.edges.is_empty());
}

/// Pathological: Large Relation Cardinality (500 participants)
#[test]
fn test_pathological_large_cardinality() {
    let mut hg = Hypergraph::new();
    let rel_id = RelationId::new("megarel");
    hg.create_relation(rel_id.clone(), "Massive Relation").unwrap();

    const COUNT: usize = 500;
    for i in 0..COUNT {
        let eid = ElementId::new(format!("elem-{}", i));
        let iid = IncidenceId::new(format!("inc-{}", i));
        hg.create_element(eid.clone(), format!("E{}", i)).unwrap();
        hg.attach_incidence(iid, &eid, &rel_id, Role::Operand, Direction::Undirected).unwrap();
    }

    assert_eq!(hg.element_count(), COUNT);
    assert_eq!(hg.incidence_count(), COUNT);
    assert_eq!(hg.get_relation(&rel_id).unwrap().cardinality(), COUNT);

    // Cascade deletion of massive relation
    hg.remove_relation(&rel_id).unwrap();
    assert_eq!(hg.relation_count(), 0);
    assert_eq!(hg.incidence_count(), 0);
    assert_eq!(hg.element_count(), COUNT, "All elements must survive cascade");
}

/// Pathological: Duplicate Key Rejection
#[test]
fn test_pathological_duplicate_keys() {
    let mut hg = Hypergraph::new();
    let e = ElementId::new("elem-dup");
    let r = RelationId::new("rel-dup");
    let i = IncidenceId::new("inc-dup");

    hg.create_element(e.clone(), "A").unwrap();
    match hg.create_element(e.clone(), "A-again") {
        Err(HypergraphError::DuplicateElement(id)) => assert_eq!(id, "elem-dup"),
        _ => panic!("Expected DuplicateElement"),
    }

    hg.create_relation(r.clone(), "R").unwrap();
    match hg.create_relation(r.clone(), "R-again") {
        Err(HypergraphError::DuplicateRelation(id)) => assert_eq!(id, "rel-dup"),
        _ => panic!("Expected DuplicateRelation"),
    }

    hg.attach_incidence(i.clone(), &e, &r, Role::Input, Direction::Ingoing).unwrap();
    match hg.attach_incidence(i.clone(), &e, &r, Role::Output, Direction::Outgoing) {
        Err(HypergraphError::DuplicateIncidence(id)) => assert_eq!(id, "inc-dup"),
        _ => panic!("Expected DuplicateIncidence"),
    }
}
