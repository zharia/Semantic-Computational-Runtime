//! # Semantic Computational Runtime (SCR) — Hypergraph Foundation
//!
//! Implements the normative hypergraph carrier $\mathcal{H} = (E, R, I, \rho)$
//! conforming to HGT-001.

pub mod error;
pub mod identity;
pub mod role;
pub mod element;
pub mod incidence;
pub mod relation;
pub mod hypergraph;
pub mod projection;
pub mod traversal;

pub use error::HypergraphError;
pub use identity::{ElementId, RelationId, IncidenceId};
pub use role::{Role, Direction};
pub use element::Element;
pub use incidence::Incidence;
pub use relation::Relation;
pub use hypergraph::Hypergraph;
pub use projection::{BipartiteGraph, CliqueGraph, OrdinaryGraph};
