// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Simplicial Complex Module
//!
//! Simplices and simplicial complexes — the canonical discrete topological
//! structures built from vertices, edges, triangles, tetrahedra, and higher.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-SIMPLICIAL`.
//!
//! An abstract simplicial complex (ASC) is purely combinatorial:
//! topology is determined by the combinatorial structure, not any geometry.

use crate::cell::{CellDimension, CellId};
use crate::error::{TopologyError, TopologyResult};
use std::collections::{HashMap, HashSet};

/// The dimension of a simplex.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct SimplexDimension(pub usize);

impl std::fmt::Display for SimplexDimension {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<SimplexDimension> for CellDimension {
    fn from(s: SimplexDimension) -> Self {
        CellDimension(s.0)
    }
}

/// An abstract simplex identified by its vertex set.
///
/// A k-simplex is determined by exactly (k+1) vertices.
/// Geometry is NOT required — vertices are abstract identifiers.
///
/// Per `TOPOLOGY-INV-014`: topology is independent of geometric embedding.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Simplex {
    /// Sorted vertex identifiers (canonical form ensures uniqueness).
    vertices: Vec<u32>,
}

impl Simplex {
    /// Creates a simplex from a vertex set.
    ///
    /// Per `TOPOLOGY-INV-003`: vertex count must be consistent with dimension.
    pub fn new(mut vertices: Vec<u32>) -> TopologyResult<Self> {
        if vertices.is_empty() {
            return Err(TopologyError::InvalidElement(
                "A simplex must have at least one vertex (0-simplex)".to_string(),
            ));
        }
        vertices.sort_unstable();
        vertices.dedup();
        Ok(Self { vertices })
    }

    /// Creates a 0-simplex (vertex).
    pub fn vertex(v: u32) -> Self {
        Self { vertices: vec![v] }
    }

    /// Creates a 1-simplex (edge).
    pub fn edge(u: u32, v: u32) -> TopologyResult<Self> {
        Self::new(vec![u, v])
    }

    /// Creates a 2-simplex (triangle).
    pub fn triangle(u: u32, v: u32, w: u32) -> TopologyResult<Self> {
        Self::new(vec![u, v, w])
    }

    /// Creates a 3-simplex (tetrahedron).
    pub fn tetrahedron(a: u32, b: u32, c: u32, d: u32) -> TopologyResult<Self> {
        Self::new(vec![a, b, c, d])
    }

    /// Returns the dimension of this simplex (vertex count - 1).
    pub fn dimension(&self) -> SimplexDimension {
        SimplexDimension(self.vertices.len() - 1)
    }

    /// Returns the vertex identifiers.
    pub fn vertices(&self) -> &[u32] {
        &self.vertices
    }

    /// Returns all faces of this simplex (codimension-1 subsimplices).
    ///
    /// The face of an n-simplex is obtained by removing one vertex.
    pub fn faces(&self) -> Vec<Simplex> {
        if self.vertices.len() == 1 {
            return vec![];
        }
        (0..self.vertices.len())
            .map(|i| {
                let face_vertices: Vec<u32> = self
                    .vertices
                    .iter()
                    .enumerate()
                    .filter(|&(j, _)| j != i)
                    .map(|(_, &v)| v)
                    .collect();
                Simplex { vertices: face_vertices }
            })
            .collect()
    }

    /// Returns all sub-simplices (faces of all dimensions).
    pub fn all_faces(&self) -> Vec<Simplex> {
        let n = self.vertices.len();
        let mut result = Vec::new();
        // Power set (excluding empty set)
        for mask in 1..(1u64 << n) {
            let face_verts: Vec<u32> = (0..n)
                .filter(|&i| (mask >> i) & 1 == 1)
                .map(|i| self.vertices[i])
                .collect();
            if face_verts.len() < self.vertices.len() {
                result.push(Simplex { vertices: face_verts });
            }
        }
        result
    }

    /// Returns a stable cell identifier for this simplex.
    pub fn cell_id(&self) -> CellId {
        let label = self
            .vertices
            .iter()
            .map(|v| v.to_string())
            .collect::<Vec<_>>()
            .join(",");
        CellId::new(format!("σ[{}]", label))
    }
}

/// An abstract simplicial complex.
///
/// An ASC is a collection of simplices closed under taking faces:
/// if σ ∈ K and τ ≤ σ (τ is a face of σ), then τ ∈ K.
///
/// Per `TOPOLOGY-INV-003`: incidence integrity is maintained by closure.
/// Per `TOPOLOGY-INV-014`: topology is independent of geometric realisation.
#[derive(Debug, Clone)]
pub struct SimplicialComplex {
    simplices: HashSet<Simplex>,
}

impl SimplicialComplex {
    pub fn new() -> Self {
        Self {
            simplices: HashSet::new(),
        }
    }

    /// Inserts a simplex and all its faces (closure property).
    ///
    /// Per `SCR-LIB-TOPOLOGY-SIMPLICIAL`: ASC is closed under face maps.
    pub fn insert(&mut self, simplex: Simplex) {
        // Insert all sub-faces first (closure)
        for face in simplex.all_faces() {
            self.simplices.insert(face);
        }
        self.simplices.insert(simplex);
    }

    /// Checks whether the complex contains a given simplex.
    pub fn contains(&self, simplex: &Simplex) -> bool {
        self.simplices.contains(simplex)
    }

    /// Returns all simplices of a given dimension.
    pub fn simplices_of_dimension(&self, dim: SimplexDimension) -> Vec<&Simplex> {
        self.simplices
            .iter()
            .filter(|s| s.dimension() == dim)
            .collect()
    }

    /// Returns the maximum dimension present.
    pub fn max_dimension(&self) -> Option<SimplexDimension> {
        self.simplices.iter().map(|s| s.dimension()).max()
    }

    /// Number of simplices at each dimension.
    pub fn counts_by_dimension(&self) -> HashMap<usize, usize> {
        let mut counts: HashMap<usize, usize> = HashMap::new();
        for s in &self.simplices {
            *counts.entry(s.dimension().0).or_insert(0) += 1;
        }
        counts
    }

    /// Computes the Euler characteristic: χ = Σ (-1)^n |K_n|.
    ///
    /// Per `SCR-LIB-TOPOLOGY-EULER`: a topological invariant.
    pub fn euler_characteristic(&self) -> i64 {
        let counts = self.counts_by_dimension();
        let max_dim = counts.keys().copied().max().unwrap_or(0);
        let mut chi: i64 = 0;
        for d in 0..=max_dim {
            let count = counts.get(&d).copied().unwrap_or(0) as i64;
            if d % 2 == 0 {
                chi += count;
            } else {
                chi -= count;
            }
        }
        chi
    }

    /// Computes the Betti number β₀ (number of connected components).
    ///
    /// Uses a union-find over the 0-skeleton and 1-skeleton.
    pub fn betti_0(&self) -> usize {
        let vertices: Vec<u32> = self
            .simplices_of_dimension(SimplexDimension(0))
            .iter()
            .flat_map(|s| s.vertices().iter().copied())
            .collect();

        if vertices.is_empty() {
            return 0;
        }

        // Union-find
        let mut parent: HashMap<u32, u32> = vertices.iter().map(|&v| (v, v)).collect();

        fn find(parent: &mut HashMap<u32, u32>, x: u32) -> u32 {
            let p = *parent.get(&x).unwrap_or(&x);
            if p != x {
                let root = find(parent, p);
                parent.insert(x, root);
                root
            } else {
                x
            }
        }

        for edge in self.simplices_of_dimension(SimplexDimension(1)) {
            let verts = edge.vertices();
            if verts.len() == 2 {
                let u = find(&mut parent, verts[0]);
                let v = find(&mut parent, verts[1]);
                if u != v {
                    parent.insert(u, v);
                }
            }
        }

        // Count distinct roots
        let roots: HashSet<u32> = vertices
            .iter()
            .map(|&v| find(&mut parent, v))
            .collect();
        roots.len()
    }

    /// Total number of simplices.
    pub fn len(&self) -> usize {
        self.simplices.len()
    }

    pub fn is_empty(&self) -> bool {
        self.simplices.is_empty()
    }
}

impl Default for SimplicialComplex {
    fn default() -> Self {
        Self::new()
    }
}

/// A generic interface for topological complexes (simplicial, cubical, cellular).
///
/// Per `SCR-LIB-TOPOLOGY-COMPLEX`: a complex is a representation, not the definition.
pub trait TopologicalComplex {
    /// Euler characteristic of the complex.
    fn euler_characteristic(&self) -> i64;
    /// Maximum dimension.
    fn max_dimension(&self) -> Option<CellDimension>;
    /// Total element count.
    fn len(&self) -> usize;
    fn is_empty(&self) -> bool;
}

impl TopologicalComplex for SimplicialComplex {
    fn euler_characteristic(&self) -> i64 {
        self.euler_characteristic()
    }

    fn max_dimension(&self) -> Option<CellDimension> {
        self.max_dimension().map(CellDimension::from)
    }

    fn len(&self) -> usize {
        self.len()
    }

    fn is_empty(&self) -> bool {
        self.is_empty()
    }
}
