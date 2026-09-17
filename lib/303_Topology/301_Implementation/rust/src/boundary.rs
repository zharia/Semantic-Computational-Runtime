// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Boundary Module
//!
//! Topological boundary — the structural transition between interior and exterior.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-BOUNDARY`.
//!
//! The fundamental axiom: ∂(∂(X)) = ∅  (boundary of boundary is empty).
//!
//! Per `TOPOLOGY-INV-004`: boundary semantics MUST remain consistent with
//! the declared topology.

use crate::cell::{CellDimension, CellId};
use crate::error::{TopologyError, TopologyResult};

/// A topological boundary — the collection of lower-dimensional elements
/// forming the boundary of a topological region.
///
/// Per `SCR-LIB-TOPOLOGY-BOUNDARY`: the boundary is itself a topological
/// structure and may possess its own boundary.
#[derive(Debug, Clone, PartialEq)]
pub struct Boundary {
    /// The region whose boundary this is.
    pub of_element: CellId,
    /// Dimension of the region (the boundary has dimension - 1).
    pub region_dimension: CellDimension,
    /// The boundary elements (cells of dimension - 1).
    pub boundary_elements: Vec<CellId>,
}

impl Boundary {
    /// Creates a boundary for a given element.
    ///
    /// Per `TOPOLOGY-INV-004`: boundary of a 0-cell (vertex) is empty.
    pub fn new(
        of_element: CellId,
        region_dimension: CellDimension,
        boundary_elements: Vec<CellId>,
    ) -> TopologyResult<Self> {
        if region_dimension.0 == 0 && !boundary_elements.is_empty() {
            return Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-004: Boundary of a 0-cell (vertex) must be empty".to_string(),
            ));
        }
        Ok(Self {
            of_element,
            region_dimension,
            boundary_elements,
        })
    }

    /// Creates an empty boundary (for closed structures or 0-cells).
    pub fn empty(of_element: CellId, region_dimension: CellDimension) -> Self {
        Self {
            of_element,
            region_dimension,
            boundary_elements: vec![],
        }
    }

    /// Returns the dimension of the boundary elements (region_dimension - 1).
    pub fn boundary_dimension(&self) -> Option<CellDimension> {
        if self.region_dimension.0 == 0 {
            None
        } else {
            Some(CellDimension(self.region_dimension.0 - 1))
        }
    }

    /// Returns whether this boundary is empty (closed region or 0-cell).
    pub fn is_empty(&self) -> bool {
        self.boundary_elements.is_empty()
    }

    /// Returns the number of boundary elements.
    pub fn len(&self) -> usize {
        self.boundary_elements.len()
    }
}

/// The boundary operator: maps a topological region to its boundary.
///
/// The boundary operator ∂ satisfies: ∂∘∂ = 0 (boundary of boundary is empty).
/// This is the fundamental axiom of the boundary operator in homology theory.
pub struct BoundaryOperator;

impl BoundaryOperator {
    /// Verifies the fundamental axiom ∂(∂(X)) = ∅.
    ///
    /// Given boundary elements (∂X), verifies their combined boundary is empty.
    /// This validates `TOPOLOGY-INV-004` at the chain level.
    pub fn verify_boundary_of_boundary(
        _boundary: &Boundary,
        boundary_boundaries: &[Boundary],
    ) -> TopologyResult<()> {
        // For the boundary-of-boundary axiom: the boundary elements appearing
        // in odd and even multiplicity should cancel. For a concrete check,
        // we verify that each boundary element's boundary appears twice
        // (once with each orientation), so they cancel in the chain group.

        // In an abstract/combinatorial sense: each codim-2 element appears
        // exactly 0 or 2 times in the boundary of the boundary — they cancel.
        use std::collections::HashMap;
        let mut face_counts: HashMap<String, usize> = HashMap::new();

        for bnd in boundary_boundaries {
            for elem in &bnd.boundary_elements {
                *face_counts.entry(elem.0.clone()).or_insert(0) += 1;
            }
        }

        // Every element must appear an even number of times (cancel in Z/2Z)
        for (elem, count) in &face_counts {
            if count % 2 != 0 {
                return Err(TopologyError::InvariantViolation(format!(
                    "TOPOLOGY-INV-004: Boundary-of-boundary axiom violated — element '{}' \
                     appears {} time(s) (must be even for cancellation)",
                    elem, count
                )));
            }
        }

        Ok(())
    }

    /// Applies the boundary operator conceptually: given a top-level element,
    /// returns the semantic boundary dimension expected.
    pub fn boundary_dimension(region_dim: CellDimension) -> Option<CellDimension> {
        if region_dim.0 == 0 {
            None
        } else {
            Some(CellDimension(region_dim.0 - 1))
        }
    }
}
