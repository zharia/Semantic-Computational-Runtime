// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Simplicial Complex Conformance Tests
//!
//! Tests the abstract simplicial complex, Euler characteristic,
//! Betti numbers, and connectivity derived from complexes.

use scr_topology::connectivity::connectivity_from_simplicial;
use scr_topology::predicate::TopologicalPredicate;
use scr_topology::simplicial::{Simplex, SimplicialComplex, SimplexDimension};
use scr_topology::invariants::{verify_euler_characteristic, verify_genus_from_euler};

/// Build a triangle complex (topological disk-like structure).
/// Vertices: 0,1,2. Edges: 01,12,02. Face: 012.
fn triangle_complex() -> SimplicialComplex {
    let mut k = SimplicialComplex::new();
    k.insert(Simplex::triangle(0, 1, 2).unwrap());
    k
}

/// Build a tetrahedron complex (solid tetrahedron).
/// Vertices: 0,1,2,3. All edges, all faces, and one 3-simplex.
fn tetrahedron_complex() -> SimplicialComplex {
    let mut k = SimplicialComplex::new();
    k.insert(Simplex::tetrahedron(0, 1, 2, 3).unwrap());
    k
}

/// Build a triangle mesh of a topological sphere (octahedron boundary).
/// 6 vertices, 12 edges, 8 triangles → χ = 6 - 12 + 8 = 2.
fn sphere_complex() -> SimplicialComplex {
    let mut k = SimplicialComplex::new();
    // Top face triangles (vertex 4 = "north pole")
    k.insert(Simplex::triangle(0, 1, 4).unwrap());
    k.insert(Simplex::triangle(1, 2, 4).unwrap());
    k.insert(Simplex::triangle(2, 3, 4).unwrap());
    k.insert(Simplex::triangle(3, 0, 4).unwrap());
    // Bottom face triangles (vertex 5 = "south pole")
    k.insert(Simplex::triangle(0, 1, 5).unwrap());
    k.insert(Simplex::triangle(1, 2, 5).unwrap());
    k.insert(Simplex::triangle(2, 3, 5).unwrap());
    k.insert(Simplex::triangle(3, 0, 5).unwrap());
    k
}

/// Build two disjoint edges → 2 connected components.
fn two_disjoint_edges() -> SimplicialComplex {
    let mut k = SimplicialComplex::new();
    k.insert(Simplex::edge(0, 1).unwrap()); // component A
    k.insert(Simplex::edge(2, 3).unwrap()); // component B
    k
}

// ─── Simplex Construction ─────────────────────────────────────────────────────

#[test]
fn test_simplex_dimensions() {
    assert_eq!(Simplex::vertex(0).dimension(), SimplexDimension(0));
    assert_eq!(Simplex::edge(0, 1).unwrap().dimension(), SimplexDimension(1));
    assert_eq!(Simplex::triangle(0, 1, 2).unwrap().dimension(), SimplexDimension(2));
    assert_eq!(Simplex::tetrahedron(0, 1, 2, 3).unwrap().dimension(), SimplexDimension(3));
}

#[test]
fn test_simplex_faces() {
    let tri = Simplex::triangle(0, 1, 2).unwrap();
    let faces = tri.faces();
    // A triangle has 3 edges as faces
    assert_eq!(faces.len(), 3);
    for f in &faces {
        assert_eq!(f.dimension(), SimplexDimension(1));
    }
}

#[test]
fn test_simplex_deduplicates_vertices() {
    // Duplicate vertices reduce to a simplex of lower dimension
    let degenerate = Simplex::new(vec![0, 0, 1]).unwrap();
    assert_eq!(degenerate.dimension(), SimplexDimension(1)); // Only 2 unique vertices
}

#[test]
fn test_empty_simplex_rejected() {
    assert!(Simplex::new(vec![]).is_err());
}

// ─── Simplicial Complex Closure ───────────────────────────────────────────────

#[test]
fn test_complex_closed_under_faces() {
    let k = triangle_complex();
    // Complex must contain all faces of the triangle
    let edge_01 = Simplex::edge(0, 1).unwrap();
    let edge_12 = Simplex::edge(1, 2).unwrap();
    let edge_02 = Simplex::edge(0, 2).unwrap();
    let v0 = Simplex::vertex(0);
    let v1 = Simplex::vertex(1);
    let v2 = Simplex::vertex(2);

    assert!(k.contains(&edge_01), "Complex must contain edge 0-1");
    assert!(k.contains(&edge_12), "Complex must contain edge 1-2");
    assert!(k.contains(&edge_02), "Complex must contain edge 0-2");
    assert!(k.contains(&v0));
    assert!(k.contains(&v1));
    assert!(k.contains(&v2));
}

// ─── Euler Characteristic ─────────────────────────────────────────────────────

#[test]
fn test_triangle_euler_characteristic() {
    // Single triangle (filled): V=3, E=3, F=1 → χ = 3-3+1 = 1
    let k = triangle_complex();
    let chi = k.euler_characteristic();
    assert_eq!(chi, 1, "Filled triangle has χ = 1");
}

#[test]
fn test_tetrahedron_euler_characteristic() {
    // Solid tetrahedron: V=4, E=6, F=4, C=1 → χ = 4-6+4-1 = 1
    let k = tetrahedron_complex();
    let chi = k.euler_characteristic();
    assert_eq!(chi, 1, "Solid tetrahedron has χ = 1");
}

#[test]
fn test_sphere_euler_characteristic() {
    // Octahedron boundary (2-sphere): V=6, E=12, F=8 → χ = 6-12+8 = 2
    let k = sphere_complex();
    let chi = k.euler_characteristic();
    assert_eq!(chi, 2, "Topological 2-sphere has χ = 2");
}

#[test]
fn test_sphere_euler_invariant_verification() {
    let k = sphere_complex();
    // Verify with normative invariant check
    let chi = verify_euler_characteristic(&k, Some(2)).unwrap();
    assert_eq!(chi, 2);
}

#[test]
fn test_sphere_genus_zero() {
    let chi = 2; // sphere
    let genus = verify_genus_from_euler(chi, Some(0)).unwrap();
    assert_eq!(genus, 0, "Sphere has genus 0");
}

#[test]
fn test_torus_genus_one() {
    let chi = 0; // torus
    let genus = verify_genus_from_euler(chi, Some(1)).unwrap();
    assert_eq!(genus, 1, "Torus has genus 1");
}

#[test]
fn test_double_torus_genus_two() {
    let chi = -2; // double torus
    let genus = verify_genus_from_euler(chi, Some(2)).unwrap();
    assert_eq!(genus, 2, "Double torus has genus 2");
}

// ─── Connectivity / Betti β₀ ─────────────────────────────────────────────────

#[test]
fn test_connected_complex_betti_0() {
    let k = sphere_complex();
    assert_eq!(k.betti_0(), 1, "Sphere complex is connected (β₀ = 1)");
}

#[test]
fn test_two_components_betti_0() {
    let k = two_disjoint_edges();
    assert_eq!(k.betti_0(), 2, "Two disjoint edges have β₀ = 2");
}

#[test]
fn test_connectivity_derived_from_complex() {
    let k = sphere_complex();
    let conn = connectivity_from_simplicial(&k);
    assert!(TopologicalPredicate::connected(&conn));
}

#[test]
fn test_disconnected_complex() {
    let k = two_disjoint_edges();
    let conn = connectivity_from_simplicial(&k);
    assert!(TopologicalPredicate::disconnected(&conn));
    assert_eq!(conn.component_count(), 2);
}

// ─── Closed Surface Predicate ─────────────────────────────────────────────────

#[test]
fn test_sphere_is_closed_surface() {
    let k = sphere_complex();
    assert!(
        TopologicalPredicate::closed_surface(&k),
        "Sphere must be a closed surface"
    );
}

#[test]
fn test_single_triangle_is_not_closed() {
    let k = triangle_complex();
    // A single triangle has boundary edges → not closed
    assert!(
        !TopologicalPredicate::closed_surface(&k),
        "Single triangle has boundary — not closed"
    );
}
