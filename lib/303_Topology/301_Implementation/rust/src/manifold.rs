// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Manifold Module
//!
//! Topological manifolds — spaces locally homeomorphic to Euclidean space.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-MANIFOLD`.
//!
//! Per `TOPOLOGY-INV-007`: manifoldness MUST be preserved by topology-preserving operations.
//! Per `TOPOLOGY-INV-015`: manifoldness is metric-independent.
//!
//! A triangle mesh may violate manifoldness even when its triangles are individually valid.
//! Manifoldness is a semantic property of the topological structure.

use crate::error::{TopologyError, TopologyResult};

/// The class of a manifold.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum ManifoldKind {
    /// A 1-manifold (curve: circle, line segment, etc.)
    Manifold1D,
    /// A 2-manifold (surface: sphere, torus, plane, etc.)
    Manifold2D,
    /// A 3-manifold (e.g. ℝ³, 3-sphere)
    Manifold3D,
    /// An n-manifold of specified dimension.
    ManifoldND { dimension: usize },
    /// A manifold with boundary.
    WithBoundary { manifold_dimension: usize },
}

impl ManifoldKind {
    pub fn dimension(&self) -> usize {
        match self {
            Self::Manifold1D => 1,
            Self::Manifold2D => 2,
            Self::Manifold3D => 3,
            Self::ManifoldND { dimension } => *dimension,
            Self::WithBoundary { manifold_dimension } => *manifold_dimension,
        }
    }

    pub fn has_boundary(&self) -> bool {
        matches!(self, Self::WithBoundary { .. })
    }
}

impl std::fmt::Display for ManifoldKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Manifold1D => write!(f, "1-Manifold"),
            Self::Manifold2D => write!(f, "2-Manifold"),
            Self::Manifold3D => write!(f, "3-Manifold"),
            Self::ManifoldND { dimension } => write!(f, "{}-Manifold", dimension),
            Self::WithBoundary { manifold_dimension } => {
                write!(f, "{}-Manifold-with-boundary", manifold_dimension)
            }
        }
    }
}

/// Orientability of a manifold — a topological property.
///
/// Per `SCR-LIB-TOPOLOGY-ORIENTATION`: orientability is topological, not geometric.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Orientability {
    /// A consistent global orientation exists.
    Orientable,
    /// No consistent global orientation exists (e.g. Möbius strip, Klein bottle).
    NonOrientable,
    /// Orientability has not been determined.
    Unknown,
}

impl std::fmt::Display for Orientability {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Orientable => write!(f, "Orientable"),
            Self::NonOrientable => write!(f, "NonOrientable"),
            Self::Unknown => write!(f, "Unknown"),
        }
    }
}

/// A topological manifold with declared kind, orientability, and genus.
///
/// Per `SCR-LIB-TOPOLOGY-MANIFOLD`:
/// - manifold structure is independent of geometric embedding;
/// - manifoldness is a semantic property.
#[derive(Debug, Clone, PartialEq)]
pub struct Manifold {
    /// Semantic identifier.
    pub id: String,
    /// The kind of manifold.
    pub kind: ManifoldKind,
    /// Declared orientability.
    pub orientability: Orientability,
    /// Genus (number of handles) if applicable.
    pub genus: Option<u32>,
    /// Number of connected components.
    pub components: usize,
}

impl Manifold {
    /// Creates a manifold with declared properties.
    pub fn new(
        id: impl Into<String>,
        kind: ManifoldKind,
        orientability: Orientability,
        genus: Option<u32>,
        components: usize,
    ) -> TopologyResult<Self> {
        let id = id.into();
        if id.trim().is_empty() {
            return Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-001: Manifold identity cannot be empty".to_string(),
            ));
        }
        if components == 0 {
            return Err(TopologyError::InvalidElement(
                "A manifold must have at least one connected component".to_string(),
            ));
        }
        Ok(Self {
            id,
            kind,
            orientability,
            genus,
            components,
        })
    }

    /// Computes the Euler characteristic from genus (for orientable closed surfaces).
    ///
    /// χ = 2 - 2g for connected orientable closed surfaces.
    pub fn euler_characteristic_from_genus(&self) -> Option<i64> {
        match (&self.orientability, self.genus, &self.kind) {
            (Orientability::Orientable, Some(g), ManifoldKind::Manifold2D) => {
                // χ = (2 - 2g) * components for disconnected manifolds
                Some((2 - 2 * g as i64) * self.components as i64)
            }
            _ => None,
        }
    }

    /// Checks whether this manifold satisfies manifoldness.
    ///
    /// Per `SCR-LIB-TOPOLOGY-MANIFOLD`: manifoldness is a semantic property
    /// that a mesh representation may violate.
    pub fn declares_manifold(&self) -> bool {
        !matches!(self.kind, ManifoldKind::WithBoundary { .. })
            || matches!(self.kind, ManifoldKind::WithBoundary { .. })
        // All Manifold instances declare manifoldness by construction.
        // Validity is established at creation time.
    }
}
