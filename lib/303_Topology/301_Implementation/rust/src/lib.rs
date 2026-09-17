// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Topology Domain (`SCR-LIB-TOPOLOGY`)
//!
//! Authoritative normative semantic foundation for connectivity, continuity,
//! adjacency, neighbourhood, incidence, boundaries, structural relationships,
//! and properties preserved under permitted continuous transformations.
//!
//! Conforming to:
//! - `lib/303_Topology/101_definition.md` (`SCR-LIB-TOPOLOGY`, v0.1.0)
//! - `TOPOLOGY-INV-001` through `TOPOLOGY-INV-018`
//! - `TOPOLOGY-RULE-001` through `TOPOLOGY-RULE-015`
//!
//! Foundational governing principle:
//! ```text
//! Structural Meaning → Topological Semantics → Representation → Implementation → Execution
//! ```
//!
//! Fundamental distinctions:
//! ```text
//! Topology ≠ Geometry          (metric independence)
//! Topology ≠ Graph             (graph is one possible representation)
//! Topology ≠ Mesh Connectivity (mesh encodes but does not define topology)
//! Topology ≠ Adjacency Matrix  (a representation, not the semantics)
//! ```

pub mod adjacency;
pub mod boundary;
pub mod cell;
pub mod complex;
pub mod connectivity;
pub mod continuity;
pub mod delta;
pub mod error;
pub mod hypergraph;
pub mod invariants;
pub mod manifold;
pub mod neighbourhood;
pub mod orientation;
pub mod predicate;
pub mod simplicial;
pub mod space;
pub mod transformation;

pub use adjacency::{AdjacencyKind, AdjacencyRelation};
pub use boundary::{Boundary, BoundaryOperator};
pub use cell::{Cell, CellDimension, CellId};
pub use complex::{SimplicialComplex, TopologicalComplex};
pub use connectivity::{ConnectedComponent, ConnectivityStructure};
pub use continuity::ContinuityContract;
pub use delta::{TopologicalDelta, TopologicalDeltaKind};
pub use error::{TopologyError, TopologyResult};
pub use hypergraph::{project_topology_to_hypergraph, TopologicalId};
pub use invariants::*;
pub use manifold::{Manifold, ManifoldKind, Orientability};
pub use neighbourhood::NeighbourhoodSystem;
pub use orientation::Orientation;
pub use predicate::TopologicalPredicate;
pub use simplicial::{Simplex, SimplexDimension};
pub use space::{TopologicalSpace, TopologyKind};
pub use transformation::{TopologicalTransformation, TransformationClass};

pub mod prelude {
    pub use crate::adjacency::{AdjacencyKind, AdjacencyRelation};
    pub use crate::boundary::{Boundary, BoundaryOperator};
    pub use crate::cell::{Cell, CellDimension, CellId};
    pub use crate::complex::{SimplicialComplex, TopologicalComplex};
    pub use crate::connectivity::{ConnectedComponent, ConnectivityStructure};
    pub use crate::continuity::ContinuityContract;
    pub use crate::delta::{TopologicalDelta, TopologicalDeltaKind};
    pub use crate::error::{TopologyError, TopologyResult};
    pub use crate::hypergraph::{project_topology_to_hypergraph, TopologicalId};
    pub use crate::invariants::*;
    pub use crate::manifold::{Manifold, ManifoldKind, Orientability};
    pub use crate::neighbourhood::NeighbourhoodSystem;
    pub use crate::orientation::Orientation;
    pub use crate::predicate::TopologicalPredicate;
    pub use crate::simplicial::{Simplex, SimplexDimension};
    pub use crate::space::{TopologicalSpace, TopologyKind};
    pub use crate::transformation::{TopologicalTransformation, TransformationClass};
}
