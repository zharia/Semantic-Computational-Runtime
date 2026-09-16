//! # Semantic Computational Runtime (SCR) — Perception Domain
//!
//! Authoritative normative perception foundation conforming to:
//! `lib/603_Perception/101_definition.md` (`SCR-LIB-PERCEPTION`, v0.2.0).
//!
//! Perception is the semantic computational domain concerned with the
//! **transformation of available observations and information into representations
//! that are meaningful to a declared perceiving system, process, agent, or computational context**.

pub mod error;
pub mod observation;
pub mod context;
pub mod uncertainty;
pub mod provenance;
pub mod features;
pub mod detection;
pub mod classification;
pub mod identification;
pub mod segmentation;
pub mod tracking;
pub mod process;
pub mod hypergraph;

pub use error::{PerceptionError, PerceptionResult};
pub use observation::{Modality, Observation, ObservationBoundary, ObservationStatus, TemporalIntegrity};
pub use context::{PerceptualContext, SpatialReference};
pub use uncertainty::{Confidence, ConfidenceMetric, Hypothesis, HypothesisSet, Uncertainty};
pub use provenance::PerceptualProvenance;
pub use features::Feature;
pub use detection::{Detection, RegionExtent};
pub use classification::{Classification, ScoredLabel};
pub use identification::Identification;
pub use segmentation::{Segmentation, SegmentationDomain, SegmentRegion};
pub use tracking::{Track, TrackWaypoint};
pub use process::{PerceptualProcess, PerceptualRepresentation};
pub use hypergraph::project_perception_to_hypergraph;
