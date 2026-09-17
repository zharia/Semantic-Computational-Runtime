// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Cell Complex Module
//!
//! Cells are the atomic building blocks of topological complexes.
//! Conforming to `SCR-LIB-TOPOLOGY-CELL` and `SCR-LIB-TOPOLOGY-COMPLEX`.
//!
//! A cell of dimension n is homeomorphic to an open n-ball.
//! ```text
//! 0-cell → vertex
//! 1-cell → edge / arc
//! 2-cell → face / disk
//! 3-cell → volume / ball
//! ```

use crate::error::{TopologyError, TopologyResult};
use std::collections::HashMap;

/// The topological dimension of a cell.
///
/// Dimension is a semantic property per `TOPOLOGY-INV-014`:
/// it MUST NOT change merely because of a representation choice.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct CellDimension(pub usize);

impl std::fmt::Display for CellDimension {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// A stable semantic identifier for a cell.
///
/// Per `TOPOLOGY-INV-001`: persistent topological structures MUST have
/// stable semantic identity. Cell identity is NOT a memory address.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CellId(pub String);

impl CellId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl std::fmt::Display for CellId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// A topological cell — an n-dimensional topological building block.
///
/// A cell carries:
/// - its stable semantic identity (`CellId`);
/// - its topological dimension;
/// - references to its boundary cells (lower-dimensional).
///
/// Per `TOPOLOGY-INV-003`: incidence relationships MUST remain semantically valid.
/// Per `TOPOLOGY-INV-004`: boundary cells MUST be of dimension (n-1).
#[derive(Debug, Clone, PartialEq)]
pub struct Cell {
    pub id: CellId,
    pub dimension: CellDimension,
    /// Boundary cells (one dimension lower).
    pub boundary: Vec<CellId>,
}

impl Cell {
    /// Creates a 0-cell (vertex) with no boundary.
    pub fn vertex(id: impl Into<String>) -> Self {
        Self {
            id: CellId::new(id),
            dimension: CellDimension(0),
            boundary: vec![],
        }
    }

    /// Creates an n-cell with declared boundary cells.
    ///
    /// Per `TOPOLOGY-INV-004`: all boundary cells MUST be of dimension n-1.
    pub fn new(
        id: impl Into<String>,
        dimension: CellDimension,
        boundary: Vec<CellId>,
    ) -> TopologyResult<Self> {
        let id = CellId::new(id);
        if id.as_str().trim().is_empty() {
            return Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-001: Cell identity cannot be empty".to_string(),
            ));
        }
        // 0-cells have no boundary
        if dimension.0 == 0 && !boundary.is_empty() {
            return Err(TopologyError::StructuralInconsistency(
                "TOPOLOGY-INV-004: 0-cells (vertices) cannot have boundary elements".to_string(),
            ));
        }
        Ok(Self {
            id,
            dimension,
            boundary,
        })
    }

    /// Returns the dimension of this cell.
    pub fn dimension(&self) -> CellDimension {
        self.dimension
    }

    /// Returns whether this cell is a vertex (0-cell).
    pub fn is_vertex(&self) -> bool {
        self.dimension.0 == 0
    }
}

/// A collection of cells organised as a cell complex.
///
/// A cell complex is a representation of topological structure.
/// It is NOT the definition of topology itself — per `TOPOLOGY-INV-014`.
#[derive(Debug, Clone)]
pub struct CellComplex {
    cells: HashMap<CellId, Cell>,
}

impl CellComplex {
    pub fn new() -> Self {
        Self {
            cells: HashMap::new(),
        }
    }

    /// Inserts a cell into the complex.
    ///
    /// Per `TOPOLOGY-INV-003`: incidence integrity must be maintained.
    pub fn insert(&mut self, cell: Cell) -> TopologyResult<()> {
        // Verify boundary cells exist (if any declared)
        for bnd_id in &cell.boundary {
            if !self.cells.contains_key(bnd_id) {
                return Err(TopologyError::StructuralInconsistency(format!(
                    "TOPOLOGY-INV-003: Boundary cell '{}' not found in complex",
                    bnd_id
                )));
            }
        }
        self.cells.insert(cell.id.clone(), cell);
        Ok(())
    }

    /// Inserts a cell without boundary validation (for batch construction).
    pub fn insert_unchecked(&mut self, cell: Cell) {
        self.cells.insert(cell.id.clone(), cell);
    }

    /// Returns a cell by its ID.
    pub fn get(&self, id: &CellId) -> Option<&Cell> {
        self.cells.get(id)
    }

    /// Returns cells of a given dimension.
    pub fn cells_of_dimension(&self, dim: CellDimension) -> Vec<&Cell> {
        self.cells.values().filter(|c| c.dimension == dim).collect()
    }

    /// Returns all cells.
    pub fn all_cells(&self) -> impl Iterator<Item = &Cell> {
        self.cells.values()
    }

    /// Returns the maximum dimension present.
    pub fn max_dimension(&self) -> Option<CellDimension> {
        self.cells.values().map(|c| c.dimension).max()
    }

    /// Computes the Euler characteristic: χ = Σ (-1)^n |C_n|.
    ///
    /// Per `SCR-LIB-TOPOLOGY-EULER`: χ is a topological invariant.
    pub fn euler_characteristic(&self) -> i64 {
        let max_dim = match self.max_dimension() {
            Some(d) => d.0,
            None => return 0,
        };
        let mut chi: i64 = 0;
        for d in 0..=max_dim {
            let count = self.cells_of_dimension(CellDimension(d)).len() as i64;
            if d % 2 == 0 {
                chi += count;
            } else {
                chi -= count;
            }
        }
        chi
    }

    /// Counts cells at each dimension.
    pub fn cell_count_by_dimension(&self) -> Vec<(CellDimension, usize)> {
        let max_dim = match self.max_dimension() {
            Some(d) => d.0,
            None => return vec![],
        };
        (0..=max_dim)
            .map(|d| {
                let dim = CellDimension(d);
                (dim, self.cells_of_dimension(dim).len())
            })
            .collect()
    }

    /// Total number of cells.
    pub fn len(&self) -> usize {
        self.cells.len()
    }

    pub fn is_empty(&self) -> bool {
        self.cells.is_empty()
    }
}

impl Default for CellComplex {
    fn default() -> Self {
        Self::new()
    }
}
