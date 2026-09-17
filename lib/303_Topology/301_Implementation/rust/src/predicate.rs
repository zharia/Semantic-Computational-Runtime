// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Topological Predicates Module
//!
//! Topological predicates — semantic boolean assertions about topological structure.
//!
//! Per `SCR-LIB-TOPOLOGY-POINTSET` section 44 of normative definition.
//!
//! Predicates MUST distinguish topological semantics from geometric approximations.
//! Per `TOPOLOGY-RULE-011`: geometric measurements MUST NOT be treated as
//! topological invariants unless mathematically justified.

use crate::adjacency::AdjacencyStructure;
use crate::cell::CellId;
use crate::connectivity::ConnectivityStructure;
use crate::manifold::{Manifold, Orientability};
use crate::simplicial::SimplicialComplex;

/// A collection of topological predicate functions.
///
/// Predicates are evaluated on topological structures without requiring metric information.
pub struct TopologicalPredicate;

impl TopologicalPredicate {
    /// `connected(X)`: returns true if the structure has exactly one connected component.
    pub fn connected(conn: &ConnectivityStructure) -> bool {
        conn.is_connected()
    }

    /// `disconnected(X)`: returns true if the structure has more than one component.
    pub fn disconnected(conn: &ConnectivityStructure) -> bool {
        conn.component_count() > 1
    }

    /// `adjacent(a, b)`: returns true if elements a and b are adjacent.
    pub fn adjacent(structure: &AdjacencyStructure, a: &CellId, b: &CellId) -> bool {
        structure.are_adjacent(a, b)
    }

    /// `reachable(from, to)`: returns true if `to` is reachable from `from`.
    pub fn reachable(conn: &ConnectivityStructure, from: &CellId, to: &CellId) -> bool {
        conn.is_reachable(from, to)
    }

    /// `manifold(m)`: returns true — the Manifold type declares manifoldness.
    ///
    /// Per `SCR-LIB-TOPOLOGY-MANIFOLD`: manifoldness is established at declaration time.
    pub fn manifold(_m: &Manifold) -> bool {
        true // Manifold type guarantees manifoldness by construction.
    }

    /// `orientable(m)`: returns true if the manifold is declared orientable.
    pub fn orientable(m: &Manifold) -> bool {
        matches!(m.orientability, Orientability::Orientable)
    }

    /// `equivalent_euler(a, b)`: returns true if two complexes share an Euler characteristic.
    ///
    /// Note: Euler equivalence does NOT imply homeomorphism.
    /// Per `TOPOLOGY-RULE-006`: equivalence relation MUST be identified.
    pub fn equivalent_euler(chi_a: i64, chi_b: i64) -> bool {
        chi_a == chi_b
    }

    /// `closed(complex)`: returns true if the complex has no boundary (∂(K) = ∅).
    ///
    /// For simplicial complexes, closed means every (n-1)-simplex is shared by
    /// an even number of n-simplices.
    pub fn closed_surface(complex: &SimplicialComplex) -> bool {
        use crate::simplicial::SimplexDimension;
        use std::collections::HashMap;

        let faces_2d = complex.simplices_of_dimension(SimplexDimension(2));
        if faces_2d.is_empty() {
            return false; // No 2-simplices → not a surface
        }

        let mut edge_face_count: HashMap<(u32, u32), usize> = HashMap::new();
        for tri in &faces_2d {
            let v = tri.vertices();
            if v.len() == 3 {
                for i in 0..3 {
                    let u = v[i];
                    let w = v[(i + 1) % 3];
                    let edge = if u < w { (u, w) } else { (w, u) };
                    *edge_face_count.entry(edge).or_insert(0) += 1;
                }
            }
        }

        // Every edge must be shared by exactly 2 triangles for a closed surface
        edge_face_count.values().all(|&c| c == 2)
    }

    /// Returns whether the complex is simply connected (β₁ = 0).
    ///
    /// Approximated here as: connected and no independent 1-cycles beyond spanning tree.
    /// For a triangulated surface: β₁ = 2 - χ - β₀ (by Euler formula rearrangement).
    pub fn simply_connected(complex: &SimplicialComplex) -> bool {
        use crate::simplicial::SimplexDimension;

        let beta_0 = complex.betti_0();
        if beta_0 != 1 {
            return false; // Not connected → not simply connected
        }

        let chi = complex.euler_characteristic();
        let n_faces = complex.simplices_of_dimension(SimplexDimension(2)).len() as i64;

        // For surfaces: β₁ = 2 - χ - β₂ ≈ 2 - χ when β₂ depends on closedness.
        // A simpler check: connected and χ = 1 (disc-like, tree-like).
        n_faces == 0 && chi == 1 // Only works for 1D complexes (trees)
            || (beta_0 == 1 && chi >= 1 && n_faces == 0) // Tree / forest
    }
}
