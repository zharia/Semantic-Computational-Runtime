// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Morphological Features & Skeletons
//!
//! Distinct morphological traits, symmetries, branching networks, and medial axis skeletons.

use crate::id::{ComponentId, FeatureId};
use std::collections::HashMap;

/// Semantic kind of morphological feature.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FeatureKind {
    SymmetryBilateral,
    SymmetryRadial,
    BranchingJunction,
    Protrusion,
    Cavity,
    Ridge,
    SkeletonJoint,
}

/// A distinct morphological feature attached to a component.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MorphologicalFeature {
    pub id: FeatureId,
    pub kind: FeatureKind,
    pub target_component: ComponentId,
    pub description: String,
}

impl MorphologicalFeature {
    pub fn new(
        id: FeatureId,
        kind: FeatureKind,
        target_component: ComponentId,
        description: impl Into<String>,
    ) -> Self {
        Self {
            id,
            kind,
            target_component,
            description: description.into(),
        }
    }
}

/// A structural skeleton / medial axis graph abstracting morphological form.
#[derive(Debug, Clone, Default)]
pub struct Skeleton {
    pub nodes: Vec<FeatureId>,
    pub adjacency: HashMap<FeatureId, Vec<FeatureId>>,
}

impl Skeleton {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn add_node(&mut self, node: FeatureId) {
        if !self.adjacency.contains_key(&node) {
            self.adjacency.insert(node.clone(), Vec::new());
            self.nodes.push(node);
        }
    }

    pub fn add_bone(&mut self, from: &FeatureId, to: &FeatureId) {
        self.add_node(from.clone());
        self.add_node(to.clone());

        if let Some(neighbors) = self.adjacency.get_mut(from) {
            if !neighbors.contains(to) {
                neighbors.push(to.clone());
            }
        }
        if let Some(neighbors) = self.adjacency.get_mut(to) {
            if !neighbors.contains(from) {
                neighbors.push(from.clone());
            }
        }
    }

    pub fn node_degree(&self, node: &FeatureId) -> usize {
        self.adjacency.get(node).map_or(0, |adj| adj.len())
    }

    /// Determines if a node is a branching junction (degree >= 3).
    pub fn is_branching(&self, node: &FeatureId) -> bool {
        self.node_degree(node) >= 3
    }
}
