// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_geometry::point::Point3D;
use scr_geometry::surface::TriangleMesh;

#[test]
fn test_tetrahedron_mesh_topology_and_euler_characteristic() {
    // 4 vertices of a regular tetrahedron
    let vertices = vec![
        Point3D::new(1.0, 1.0, 1.0),
        Point3D::new(-1.0, -1.0, 1.0),
        Point3D::new(-1.0, 1.0, -1.0),
        Point3D::new(1.0, -1.0, -1.0),
    ];

    // 4 triangular faces
    let indices = vec![
        [0, 1, 2],
        [0, 3, 1],
        [0, 2, 3],
        [1, 3, 2],
    ];

    let mesh = TriangleMesh::new(vertices, indices).unwrap();

    assert_eq!(mesh.vertex_count(), 4);
    assert_eq!(mesh.face_count(), 4);
    assert_eq!(mesh.edge_count(), 6);

    // Euler characteristic for sphere-homeomorphic closed 2-manifold: chi = V - E + F = 4 - 6 + 4 = 2
    assert_eq!(mesh.euler_characteristic(), 2);

    // Bounding box
    let aabb = mesh.compute_bounding_box().unwrap();
    assert_eq!(aabb.min, Point3D::new(-1.0, -1.0, -1.0));
    assert_eq!(aabb.max, Point3D::new(1.0, 1.0, 1.0));

    // Area must be positive
    let area = mesh.total_surface_area();
    assert!(area > 0.0);

    // Face normals
    let normals = mesh.compute_face_normals().unwrap();
    assert_eq!(normals.len(), 4);
    for n in normals {
        assert!((n.norm() - 1.0).abs() < 1e-6);
    }
}

#[test]
fn test_mesh_out_of_bounds_rejection() {
    let vertices = vec![
        Point3D::new(0.0, 0.0, 0.0),
        Point3D::new(1.0, 0.0, 0.0),
        Point3D::new(0.0, 1.0, 0.0),
    ];
    // Face references index 5 which does not exist
    let invalid_indices = vec![[0, 1, 5]];
    assert!(TriangleMesh::new(vertices, invalid_indices).is_err());
}
