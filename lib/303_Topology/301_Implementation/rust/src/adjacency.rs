// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Adjacency Module
//!
//! Topological adjacency — local structural neighbourhood relationships
//! between topological elements sharing a boundary.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-ADJACENCY`.
//!
//! Per `TOPOLOGY-RULE-004`: adjacency MUST be semantically explicit.
//! Per `TOPOLOGY-RULE-003`: adjacency does NOT require a metric.

use crate::cell::CellId;
use crate::error::{TopologyError, TopologyResult};
use std::collections::{HashMap, HashSet};

/// The kind of adjacency relationship.
///
/// Adjacency type must be declared explicitly per `TOPOLOGY-RULE-004`.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum AdjacencyKind {
    /// Two vertices share an edge (vertex-vertex adjacency).
    VertexVertex,
    /// Two edges share a vertex (edge-edge adjacency).
    EdgeEdge,
    /// Two faces share an edge (face-face adjacency).
    FaceFace,
    /// Two volumes share a face (volume-volume adjacency).
    VolumeVolume,
    /// Two k-cells share a (k-1)-face (general cell-cell adjacency).
    CellCell { dimension: usize },
    /// Custom declared adjacency kind.
    Custom(String),
}

impl std::fmt::Display for AdjacencyKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::VertexVertex => write!(f, "VertexVertex"),
            Self::EdgeEdge => write!(f, "EdgeEdge"),
            Self::FaceFace => write!(f, "FaceFace"),
            Self::VolumeVolume => write!(f, "VolumeVolume"),
            Self::CellCell { dimension } => write!(f, "CellCell(dim={})", dimension),
            Self::Custom(s) => write!(f, "Custom({})", s),
        }
    }
}

/// A directed or undirected adjacency relationship between two topological elements.
///
/// Per `SCR-LIB-TOPOLOGY-ADJACENCY`:
/// - adjacency ≠ geometric proximity;
/// - adjacency type MUST be explicitly declared.
#[derive(Debug, Clone, PartialEq)]
pub struct AdjacencyRelation {
    /// First element in the adjacency.
    pub element_a: CellId,
    /// Second element in the adjacency.
    pub element_b: CellId,
    /// The declared type of adjacency.
    pub kind: AdjacencyKind,
    /// Whether the relationship is directed (a → b) or undirected (a ↔ b).
    pub directed: bool,
}

impl AdjacencyRelation {
    /// Creates an undirected adjacency relation.
    pub fn undirected(a: CellId, b: CellId, kind: AdjacencyKind) -> TopologyResult<Self> {
        if a == b {
            return Err(TopologyError::StructuralInconsistency(
                "Adjacency relation cannot be self-referential (a ≠ b required)".to_string(),
            ));
        }
        Ok(Self {
            element_a: a,
            element_b: b,
            kind,
            directed: false,
        })
    }

    /// Creates a directed adjacency relation (a → b).
    pub fn directed(a: CellId, b: CellId, kind: AdjacencyKind) -> TopologyResult<Self> {
        if a == b {
            return Err(TopologyError::StructuralInconsistency(
                "Directed adjacency cannot be self-referential".to_string(),
            ));
        }
        Ok(Self {
            element_a: a,
            element_b: b,
            kind,
            directed: true,
        })
    }

    /// Returns whether this relation connects the two given elements.
    pub fn connects(&self, a: &CellId, b: &CellId) -> bool {
        if self.directed {
            &self.element_a == a && &self.element_b == b
        } else {
            (&self.element_a == a && &self.element_b == b)
                || (&self.element_a == b && &self.element_b == a)
        }
    }
}

/// A collection of adjacency relations forming an adjacency structure.
///
/// An adjacency structure is NOT an adjacency matrix — it is a semantic
/// collection of declared adjacency relationships.
#[derive(Debug, Clone, Default)]
pub struct AdjacencyStructure {
    relations: Vec<AdjacencyRelation>,
    /// Index: element → adjacent elements (for fast lookup).
    index: HashMap<String, HashSet<String>>,
}

impl AdjacencyStructure {
    pub fn new() -> Self {
        Self::default()
    }

    /// Inserts an adjacency relation.
    pub fn insert(&mut self, rel: AdjacencyRelation) {
        let a = rel.element_a.0.clone();
        let b = rel.element_b.0.clone();
        self.index.entry(a.clone()).or_default().insert(b.clone());
        if !rel.directed {
            self.index.entry(b).or_default().insert(a);
        }
        self.relations.push(rel);
    }

    /// Returns all elements adjacent to the given element.
    pub fn adjacent_to(&self, element: &CellId) -> Vec<CellId> {
        self.index
            .get(&element.0)
            .map(|set| set.iter().map(|s| CellId::new(s.clone())).collect())
            .unwrap_or_default()
    }

    /// Returns whether two elements are adjacent.
    pub fn are_adjacent(&self, a: &CellId, b: &CellId) -> bool {
        self.index
            .get(&a.0)
            .map(|set| set.contains(&b.0))
            .unwrap_or(false)
    }

    /// Returns the number of adjacency relations.
    pub fn len(&self) -> usize {
        self.relations.len()
    }

    pub fn is_empty(&self) -> bool {
        self.relations.is_empty()
    }

    /// Returns all adjacency relations.
    pub fn relations(&self) -> &[AdjacencyRelation] {
        &self.relations
    }

    /// Returns the adjacency degree of an element (number of adjacent elements).
    pub fn degree(&self, element: &CellId) -> usize {
        self.index.get(&element.0).map(|s| s.len()).unwrap_or(0)
    }
}
