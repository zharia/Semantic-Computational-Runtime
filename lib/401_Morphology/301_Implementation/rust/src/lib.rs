// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Morphology Foundation (`SCR-LIB-MORPHOLOGY`)
//!
//! Authoritative Normative Morphology Semantic Domain implementation for SCR.
//!
//! Conforms to `lib/401_Morphology/101_definition.md`.

pub mod error;
pub mod feature;
pub mod hypergraph;
pub mod id;
pub mod invariants;
pub mod pattern;
pub mod structure;
pub mod transformation;

pub use error::{MorphologyError, MorphologyResult};
pub use feature::{FeatureKind, MorphologicalFeature, Skeleton};
pub use hypergraph::project_morphology_to_hypergraph;
pub use id::{ComponentId, FeatureId, MorphologyId, PatternId};
pub use pattern::{Pattern, PatternContract};
pub use structure::{Component, PartWholeHierarchy};
pub use transformation::{
    MorphologicalDelta, MorphologicalTransformation, PreservationContract, TransformationKind,
};
