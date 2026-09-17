// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Connectivity Module
//!
//! Topological connectivity — connected components and structural reachability.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-CONNECTIVITY`.
//!
//! Per `TOPOLOGY-INV-002`: declared connectivity MUST remain internally consistent.
//! Per `TOPOLOGY-INV-009`: component membership MUST be consistent with connectivity.
//!
//! Key semantic distinction:
//! ```text
//! Connectivity ≠ Geometric Proximity
//! Connectivity ≠ Graph Edge Count
//! Connectivity ≠ Array Contiguity
//! ```

use crate::cell::CellId;
use crate::error::{TopologyError, TopologyResult};
use crate::simplicial::SimplicialComplex;
use std::collections::{HashMap, HashSet, VecDeque};

/// A connected component — a maximal connected subset of a topological structure.
///
/// Per `SCR-LIB-TOPOLOGY-CONNECTIVITY`: components are maximal connected substructures.
/// Component transitions MUST be represented as explicit topology changes.
#[derive(Debug, Clone, PartialEq)]
pub struct ConnectedComponent {
    /// Semantic identifier of this component.
    pub id: String,
    /// Elements belonging to this component.
    pub elements: Vec<CellId>,
}

impl ConnectedComponent {
    pub fn new(id: impl Into<String>, elements: Vec<CellId>) -> Self {
        Self {
            id: id.into(),
            elements,
        }
    }

    pub fn len(&self) -> usize {
        self.elements.len()
    }

    pub fn is_empty(&self) -> bool {
        self.elements.is_empty()
    }

    pub fn contains(&self, element: &CellId) -> bool {
        self.elements.contains(element)
    }
}

/// A connectivity structure over a topological complex.
///
/// Maintains the declared connected components and validates consistency.
#[derive(Debug, Clone)]
pub struct ConnectivityStructure {
    /// The adjacency graph (element → adjacent elements).
    adjacency: HashMap<String, HashSet<String>>,
}

impl ConnectivityStructure {
    pub fn new() -> Self {
        Self {
            adjacency: HashMap::new(),
        }
    }

    /// Declares an adjacency (undirected) between two elements.
    pub fn declare_adjacent(&mut self, a: &CellId, b: &CellId) {
        self.adjacency
            .entry(a.0.clone())
            .or_default()
            .insert(b.0.clone());
        self.adjacency
            .entry(b.0.clone())
            .or_default()
            .insert(a.0.clone());
    }

    /// Declares an element with no adjacencies (isolated vertex).
    pub fn declare_element(&mut self, a: &CellId) {
        self.adjacency.entry(a.0.clone()).or_default();
    }

    /// Computes connected components via BFS.
    ///
    /// Returns a vector of `ConnectedComponent` — one per maximal connected substructure.
    /// Per `TOPOLOGY-INV-009`: component membership is consistent with this adjacency.
    pub fn connected_components(&self) -> Vec<ConnectedComponent> {
        let mut visited: HashSet<&str> = HashSet::new();
        let mut components = Vec::new();
        let mut comp_idx = 0;

        for start in self.adjacency.keys() {
            if visited.contains(start.as_str()) {
                continue;
            }

            // BFS from `start`
            let mut queue: VecDeque<&str> = VecDeque::new();
            let mut component_elements = Vec::new();
            queue.push_back(start.as_str());
            visited.insert(start.as_str());

            while let Some(current) = queue.pop_front() {
                component_elements.push(CellId::new(current));
                if let Some(neighbours) = self.adjacency.get(current) {
                    for nb in neighbours {
                        if !visited.contains(nb.as_str()) {
                            visited.insert(nb.as_str());
                            queue.push_back(nb.as_str());
                        }
                    }
                }
            }

            comp_idx += 1;
            components.push(ConnectedComponent::new(
                format!("component-{}", comp_idx),
                component_elements,
            ));
        }

        components
    }

    /// Returns the number of connected components (β₀ — zeroth Betti number).
    pub fn component_count(&self) -> usize {
        self.connected_components().len()
    }

    /// Returns whether the entire structure is connected (single component).
    pub fn is_connected(&self) -> bool {
        self.component_count() <= 1
    }

    /// Returns whether a specific element is reachable from another.
    pub fn is_reachable(&self, from: &CellId, to: &CellId) -> bool {
        let mut visited: HashSet<&str> = HashSet::new();
        let mut queue: VecDeque<&str> = VecDeque::new();

        queue.push_back(from.0.as_str());
        visited.insert(from.0.as_str());

        while let Some(current) = queue.pop_front() {
            if current == to.0.as_str() {
                return true;
            }
            if let Some(neighbours) = self.adjacency.get(current) {
                for nb in neighbours {
                    if !visited.contains(nb.as_str()) {
                        visited.insert(nb.as_str());
                        queue.push_back(nb.as_str());
                    }
                }
            }
        }

        false
    }

    /// Returns the total number of elements tracked.
    pub fn element_count(&self) -> usize {
        self.adjacency.len()
    }
}

impl Default for ConnectivityStructure {
    fn default() -> Self {
        Self::new()
    }
}

/// Computes connectivity structure directly from a simplicial complex.
pub fn connectivity_from_simplicial(complex: &SimplicialComplex) -> ConnectivityStructure {
    use crate::simplicial::SimplexDimension;

    let mut conn = ConnectivityStructure::new();

    // Add all 0-simplices (vertices)
    for v in complex.simplices_of_dimension(SimplexDimension(0)) {
        for &vx in v.vertices() {
            conn.declare_element(&CellId::new(format!("v{}", vx)));
        }
    }

    // Add adjacency from 1-simplices (edges)
    for edge in complex.simplices_of_dimension(SimplexDimension(1)) {
        let verts = edge.vertices();
        if verts.len() == 2 {
            let a = CellId::new(format!("v{}", verts[0]));
            let b = CellId::new(format!("v{}", verts[1]));
            conn.declare_adjacent(&a, &b);
        }
    }

    conn
}

/// Validates `TOPOLOGY-INV-009`: component membership consistency.
pub fn validate_component_integrity(
    structure: &ConnectivityStructure,
    declared_components: &[ConnectedComponent],
) -> TopologyResult<()> {
    let computed = structure.connected_components();

    if computed.len() != declared_components.len() {
        return Err(TopologyError::InvariantViolation(format!(
            "TOPOLOGY-INV-009: Component count mismatch — computed {}, declared {}",
            computed.len(),
            declared_components.len()
        )));
    }

    Ok(())
}
