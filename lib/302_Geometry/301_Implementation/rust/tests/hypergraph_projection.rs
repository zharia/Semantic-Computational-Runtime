// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_geometry::dimension::GeometricDimension;
use scr_geometry::hypergraph::{
    project_geometric_relationship_to_hypergraph, project_geometry_to_hypergraph, GeometricId,
};
use scr_geometry::point::Point3D;
use scr_geometry::primitives::AABB3D;
use scr_hypergraph::Hypergraph;

#[test]
fn test_geometry_hypergraph_projection() {
    let mut hg = Hypergraph::new();

    let sphere_id = GeometricId::new("sphere_alpha");
    let box_id = GeometricId::new("box_beta");

    let aabb = AABB3D::new(Point3D::new(-2.0, -2.0, -2.0), Point3D::new(2.0, 2.0, 2.0)).unwrap();

    project_geometry_to_hypergraph(
        &sphere_id,
        GeometricDimension::Dim3D,
        Some(&aabb),
        &mut hg,
    ).unwrap();

    project_geometry_to_hypergraph(
        &box_id,
        GeometricDimension::Dim3D,
        None,
        &mut hg,
    ).unwrap();

    // Verify elements created
    assert!(hg.elements().count() >= 3);
    assert!(hg.relations().count() >= 2);

    // Project relationship: Box contains Sphere
    project_geometric_relationship_to_hypergraph(
        &box_id,
        &sphere_id,
        "GeometricContainment",
        &mut hg,
    ).unwrap();

    assert!(hg.relations().count() >= 3);
}
