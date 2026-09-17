// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Hypergraph Projection Conformance Tests
//!
//! Tests that topological entities are correctly projected into the SCR
//! semantic hypergraph, per section 51 of `101_definition.md`.

use scr_hypergraph::Hypergraph;
use scr_topology::adjacency::{AdjacencyKind, AdjacencyRelation};
use scr_topology::cell::{CellDimension, CellId};
use scr_topology::hypergraph::{project_adjacency_to_hypergraph, project_topology_to_hypergraph, TopologicalId};

#[test]
fn test_project_topological_entity_to_hypergraph() {
    let mut hg = Hypergraph::new();
    let id = TopologicalId::new("sphere-01");

    let result = project_topology_to_hypergraph(
        &id,
        CellDimension(2),
        Some(2),     // χ = 2 (sphere)
        Some(1),     // 1 connected component
        &mut hg,
    );

    assert!(result.is_ok(), "Topology projection should succeed: {:?}", result);
    // Entity element must exist
    assert!(
        hg.get_element(&scr_hypergraph::ElementId("elem:topo:sphere-01".to_string())).is_some(),
        "Topological entity element must be in hypergraph"
    );
    // Euler characteristic element must exist
    assert!(
        hg.get_element(&scr_hypergraph::ElementId("elem:topo_chi:sphere-01".to_string())).is_some(),
        "Euler characteristic element must be in hypergraph"
    );
    // Component count element must exist
    assert!(
        hg.get_element(&scr_hypergraph::ElementId("elem:topo_comp:sphere-01".to_string())).is_some(),
        "Component count element must be in hypergraph"
    );
}

#[test]
fn test_project_adjacency_to_hypergraph() {
    let mut hg = Hypergraph::new();

    // First register both elements
    hg.create_element(
        scr_hypergraph::ElementId("elem:topo:v0".to_string()),
        "Vertex:v0".to_string(),
    ).unwrap();
    hg.create_element(
        scr_hypergraph::ElementId("elem:topo:v1".to_string()),
        "Vertex:v1".to_string(),
    ).unwrap();

    let rel = AdjacencyRelation::undirected(
        CellId::new("v0"),
        CellId::new("v1"),
        AdjacencyKind::VertexVertex,
    )
    .unwrap();

    let result = project_adjacency_to_hypergraph(&rel, &mut hg);
    assert!(result.is_ok(), "Adjacency projection should succeed: {:?}", result);

    // Adjacency relation must exist
    let rel_id = scr_hypergraph::RelationId("rel:adjacent:v0:v1".to_string());
    assert!(
        hg.get_relation(&rel_id).is_some(),
        "Adjacency relation must be in hypergraph"
    );
}

#[test]
fn test_project_topology_without_euler_chi() {
    let mut hg = Hypergraph::new();
    let id = TopologicalId::new("abstract-space-01");

    let result = project_topology_to_hypergraph(
        &id,
        CellDimension(3),
        None,  // Euler characteristic unknown
        None,  // component count unknown
        &mut hg,
    );

    assert!(result.is_ok());
    // Only the entity and dimension elements should be present
    assert!(
        hg.get_element(&scr_hypergraph::ElementId(
            "elem:topo:abstract-space-01".to_string()
        ))
        .is_some()
    );
    // Euler characteristic element should NOT be present
    assert!(
        hg.get_element(&scr_hypergraph::ElementId(
            "elem:topo_chi:abstract-space-01".to_string()
        ))
        .is_none()
    );
}

#[test]
fn test_idempotent_projection() {
    let mut hg = Hypergraph::new();
    let id = TopologicalId::new("torus-01");

    // Project twice — should be idempotent (no duplicates)
    project_topology_to_hypergraph(&id, CellDimension(2), Some(0), Some(1), &mut hg).unwrap();
    let result = project_topology_to_hypergraph(&id, CellDimension(2), Some(0), Some(1), &mut hg);
    assert!(result.is_ok(), "Idempotent projection must not error");
}
