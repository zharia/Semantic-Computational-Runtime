// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Neighbourhood Module
//!
//! Topological neighbourhoods — local structural context of elements.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-NEIGHBOURHOOD`.
//!
//! Key distinction:
//! ```text
//! Neighbourhood ≠ Radius
//! Neighbourhood ≠ Bounding Box
//! Neighbourhood ≠ Pixel Window
//! ```
//!
//! A metric may provide one representation of neighbourhood semantics,
//! but topology does not require a metric.

use crate::cell::CellId;
use std::collections::{HashMap, HashSet};

/// A neighbourhood system for a topological structure.
///
/// For each element, tracks the set of elements forming its neighbourhood.
/// Per `SCR-LIB-TOPOLOGY-NEIGHBOURHOOD`: neighbourhood structure is fundamental
/// to continuity, convergence, adjacency, and local structure.
#[derive(Debug, Clone, Default)]
pub struct NeighbourhoodSystem {
    /// Maps each element to the set of elements in its neighbourhood.
    neighbourhoods: HashMap<String, HashSet<String>>,
}

impl NeighbourhoodSystem {
    pub fn new() -> Self {
        Self::default()
    }

    /// Declares the neighbourhood of an element.
    ///
    /// A neighbourhood of x must contain x itself (standard axiom).
    pub fn declare_neighbourhood(&mut self, element: &CellId, neighbourhood: Vec<CellId>) {
        let mut nb_set: HashSet<String> = neighbourhood.into_iter().map(|c| c.0).collect();
        // x must belong to its own neighbourhood
        nb_set.insert(element.0.clone());
        self.neighbourhoods.insert(element.0.clone(), nb_set);
    }

    /// Returns the neighbourhood of an element.
    pub fn neighbourhood_of(&self, element: &CellId) -> Vec<CellId> {
        self.neighbourhoods
            .get(&element.0)
            .map(|set| set.iter().map(|s| CellId::new(s.clone())).collect())
            .unwrap_or_default()
    }

    /// Checks whether `candidate` is in the neighbourhood of `element`.
    pub fn is_in_neighbourhood(&self, element: &CellId, candidate: &CellId) -> bool {
        self.neighbourhoods
            .get(&element.0)
            .map(|set| set.contains(&candidate.0))
            .unwrap_or(false)
    }

    /// Returns the neighbourhood size of an element.
    pub fn neighbourhood_size(&self, element: &CellId) -> usize {
        self.neighbourhoods
            .get(&element.0)
            .map(|s| s.len())
            .unwrap_or(0)
    }

    /// Derives a neighbourhood system from an adjacency structure.
    ///
    /// The neighbourhood of x = {x} ∪ {elements adjacent to x}.
    pub fn from_adjacency(adjacency: &HashMap<String, HashSet<String>>) -> Self {
        let mut system = Self::new();
        for (element, adj) in adjacency {
            let mut nb = adj.clone();
            nb.insert(element.clone()); // x ∈ N(x)
            system.neighbourhoods.insert(element.clone(), nb);
        }
        system
    }

    /// Verifies the basic neighbourhood axioms:
    /// 1. x ∈ N(x) for all x (self-membership).
    /// 2. If N ∈ N(x) and N ⊆ M, then M ∈ N(x) — (not checkable combinatorially in general).
    pub fn verify_self_membership(&self) -> bool {
        for (element, nb) in &self.neighbourhoods {
            if !nb.contains(element) {
                return false;
            }
        }
        true
    }

    /// Total number of elements with declared neighbourhoods.
    pub fn len(&self) -> usize {
        self.neighbourhoods.len()
    }

    pub fn is_empty(&self) -> bool {
        self.neighbourhoods.is_empty()
    }
}
