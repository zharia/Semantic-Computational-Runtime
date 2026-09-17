// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

/// Semantic spatial dimension conforming to GEOMETRY-INV-002:
/// Dimensional Integrity: Geometric dimension MUST be preserved unless explicitly transformed.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum GeometricDimension {
    Dim0D, // Points, discrete particles
    Dim1D, // Curves, lines, segments, rays
    Dim2D, // Surfaces, polygons, planes, 2-manifolds
    Dim3D, // Solids, volumes, polyhedra, 3-manifolds
    DimND(usize), // Generalized n-dimensional geometric structures
}

impl GeometricDimension {
    pub fn as_usize(&self) -> usize {
        match self {
            Self::Dim0D => 0,
            Self::Dim1D => 1,
            Self::Dim2D => 2,
            Self::Dim3D => 3,
            Self::DimND(d) => *d,
        }
    }

    pub fn is_compatible(&self, other: &Self) -> bool {
        self.as_usize() == other.as_usize()
    }
}

impl fmt::Display for GeometricDimension {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Dim0D => write!(f, "0D"),
            Self::Dim1D => write!(f, "1D"),
            Self::Dim2D => write!(f, "2D"),
            Self::Dim3D => write!(f, "3D"),
            Self::DimND(n) => write!(f, "{}D", n),
        }
    }
}
