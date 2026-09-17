// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Topological Transformation Module
//!
//! Topological transformations — continuous maps, homeomorphisms, homotopies,
//! and topology-changing operations.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-TRANSFORMATION` and `SCR-LIB-TOPOLOGY-PRESERVATION`.
//!
//! Per `TOPOLOGY-RULE-005`: transformations MUST declare whether relevant
//! topological properties are preserved or changed.
//! Per `TOPOLOGY-INV-008`: transformation integrity — transformations MUST
//! satisfy their declared semantic effects.

use crate::error::{TopologyError, TopologyResult};

/// The mathematical class of a topological transformation.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum TransformationClass {
    /// A continuous map (open sets preserved under preimage).
    ContinuousMap,
    /// A homeomorphism (topological equivalence).
    Homeomorphism,
    /// A homotopy (continuous family of maps parameterised by [0,1]).
    Homotopy,
    /// A deformation retract (topology-preserving shrink to subspace).
    DeformationRetract,
    /// An embedding (injective continuous map with continuous left inverse).
    Embedding,
    /// An isotopy (homotopy through embeddings).
    Isotopy,
    /// A quotient map (topology-changing collapse).
    QuotientMap,
    /// An explicit topology-changing operation (e.g. merge, split, drill, fill).
    TopologyChanging {
        /// Human-readable description of the change (e.g. "merge-components").
        description: String,
    },
}

impl TransformationClass {
    /// Returns whether this transformation class is declared as topology-preserving.
    pub fn is_topology_preserving(&self) -> bool {
        matches!(
            self,
            Self::ContinuousMap
                | Self::Homeomorphism
                | Self::Homotopy
                | Self::DeformationRetract
                | Self::Embedding
                | Self::Isotopy
        )
    }

    /// Returns whether this transformation explicitly changes topology.
    pub fn is_topology_changing(&self) -> bool {
        matches!(self, Self::TopologyChanging { .. } | Self::QuotientMap)
    }
}

impl std::fmt::Display for TransformationClass {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::ContinuousMap => write!(f, "ContinuousMap"),
            Self::Homeomorphism => write!(f, "Homeomorphism"),
            Self::Homotopy => write!(f, "Homotopy"),
            Self::DeformationRetract => write!(f, "DeformationRetract"),
            Self::Embedding => write!(f, "Embedding"),
            Self::Isotopy => write!(f, "Isotopy"),
            Self::QuotientMap => write!(f, "QuotientMap"),
            Self::TopologyChanging { description } => {
                write!(f, "TopologyChanging({})", description)
            }
        }
    }
}

/// A declared topological transformation.
///
/// Per `SCR-LIB-TOPOLOGY-TRANSFORMATION`:
/// - transformations are first-class semantic objects;
/// - the class MUST be declared explicitly;
/// - topology-changing operations MUST be labelled.
///
/// Per `TOPOLOGY-RULE-005`: the transformation MUST declare preservation/change.
#[derive(Debug, Clone, PartialEq)]
pub struct TopologicalTransformation {
    /// Semantic identifier.
    pub id: String,
    /// The class of this transformation.
    pub class: TransformationClass,
    /// Declared invariants preserved by this transformation.
    pub preserved_invariants: Vec<String>,
    /// Description of what topological properties change (if topology-changing).
    pub change_description: Option<String>,
}

impl TopologicalTransformation {
    /// Creates a topology-preserving transformation.
    pub fn preserving(
        id: impl Into<String>,
        class: TransformationClass,
        preserved_invariants: Vec<String>,
    ) -> TopologyResult<Self> {
        if class.is_topology_changing() {
            return Err(TopologyError::InvalidOperation(format!(
                "TOPOLOGY-RULE-005: Transformation class '{}' is topology-changing, \
                 not topology-preserving",
                class
            )));
        }
        let id = id.into();
        if id.trim().is_empty() {
            return Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-001: Transformation identity cannot be empty".to_string(),
            ));
        }
        Ok(Self {
            id,
            class,
            preserved_invariants,
            change_description: None,
        })
    }

    /// Creates an explicit topology-changing transformation.
    ///
    /// Per `TOPOLOGY-RULE-008`: topology-changing state transitions MUST be explicit.
    pub fn topology_changing(
        id: impl Into<String>,
        description: impl Into<String>,
        change_description: impl Into<String>,
    ) -> TopologyResult<Self> {
        let id = id.into();
        if id.trim().is_empty() {
            return Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-001: Transformation identity cannot be empty".to_string(),
            ));
        }
        Ok(Self {
            id,
            class: TransformationClass::TopologyChanging {
                description: description.into(),
            },
            preserved_invariants: vec![],
            change_description: Some(change_description.into()),
        })
    }

    /// Returns whether this transformation preserves declared topology.
    pub fn is_topology_preserving(&self) -> bool {
        self.class.is_topology_preserving()
    }

    /// Returns whether this transformation changes topology.
    pub fn is_topology_changing(&self) -> bool {
        self.class.is_topology_changing()
    }

    /// Asserts that a given invariant is declared as preserved.
    pub fn assert_preserves(&self, invariant: &str) -> TopologyResult<()> {
        if !self.preserved_invariants.iter().any(|i| i == invariant) {
            Err(TopologyError::InvariantViolation(format!(
                "TOPOLOGY-INV-007: Transformation '{}' does not declare preservation of invariant '{}'",
                self.id, invariant
            )))
        } else {
            Ok(())
        }
    }
}
