// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Complex Module (re-export and composition)
//!
//! Topological complexes — the discrete computational representations
//! of topological spaces.
//!
//! Per `SCR-LIB-TOPOLOGY-COMPLEX`: a complex is a representation of topological
//! structure, not the definition of topology itself.

// Re-export the core types from simplicial and cell modules
pub use crate::cell::CellComplex;
pub use crate::simplicial::{SimplicialComplex, TopologicalComplex};
