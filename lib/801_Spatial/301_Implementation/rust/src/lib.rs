//! # Semantic Computational Runtime (SCR) — Spatial Domain
//!
//! Authoritative normative spatial foundation conforming to:
//! `lib/801_Spatial/101_definition.md` (`SCR-LIB-SPATIAL`, v0.1.0).
//!
//! Spatial semantics describe **where things are, how they relate spatially,
//! how spatial context is established, and how spatial structure participates
//! in computation**.

pub mod error;
pub mod domain;
pub mod frame;
pub mod position;
pub mod metric;
pub mod region;
pub mod relationship;
pub mod transformation;
pub mod query;
pub mod dynamic;
pub mod uncertainty;
pub mod hypergraph;

pub use error::{SpatialError, SpatialResult};
pub use domain::{Dimensionality, SpatialDomain, SpatialDomainKind};
pub use frame::{CoordinateSystem, ReferenceFrame};
pub use position::{Coordinates, Position};
pub use metric::{compute_distance, Distance, DistanceMetric, Proximity};
pub use region::{BoundingBox, SpatialRegion, SphereRegion, VoxelExtent};
pub use relationship::SpatialRelationship;
pub use transformation::{SpatialTransform, SpatialTransformKind};
pub use query::SpatialQuery;
pub use dynamic::{DynamicSpatialState, SpatialVelocity, TrajectoryWaypoint};
pub use uncertainty::SpatialUncertainty;
pub use hypergraph::project_spatial_relationship_to_hypergraph;
