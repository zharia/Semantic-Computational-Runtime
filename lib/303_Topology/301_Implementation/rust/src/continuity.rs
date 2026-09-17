// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Continuity Module
//!
//! Topological continuity contracts for maps between topological spaces.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-CONTINUITY`.
//!
//! Per `TOPOLOGY-INV-005`: operations claiming continuity MUST satisfy their declared contract.
//!
//! Key semantic distinction:
//! ```text
//! Continuity ≠ Numerical Smoothness
//! Continuity ≠ C^k Differentiability
//! Continuity ≠ Lipschitz Condition
//! ```
//!
//! All of the above may provide continuity under specific topologies, but
//! continuity is defined by the topological structure, not by any numerical measure.

use crate::error::{TopologyError, TopologyResult};
use crate::space::{TopologicalSpace, TopologyKind};

/// The class of continuity being declared.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum ContinuityClass {
    /// A continuous map (preimage of open sets is open).
    Continuous,
    /// A homeomorphism (continuous bijection with continuous inverse).
    Homeomorphism,
    /// A homotopy (continuous deformation between maps, parameterised by [0,1]).
    Homotopy,
    /// A homotopy equivalence (spaces related by a homotopy inverse pair).
    HomotopyEquivalence,
    /// An embedding (continuous injective map with continuous left inverse).
    Embedding,
    /// An isotopy (homotopy through embeddings).
    Isotopy,
}

impl std::fmt::Display for ContinuityClass {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Continuous => write!(f, "Continuous"),
            Self::Homeomorphism => write!(f, "Homeomorphism"),
            Self::Homotopy => write!(f, "Homotopy"),
            Self::HomotopyEquivalence => write!(f, "HomotopyEquivalence"),
            Self::Embedding => write!(f, "Embedding"),
            Self::Isotopy => write!(f, "Isotopy"),
        }
    }
}

/// A declared continuity contract between two topological spaces.
///
/// Per `TOPOLOGY-INV-005`: operations claiming continuity MUST satisfy their contract.
/// A contract must declare:
/// 1. The domain topology.
/// 2. The codomain topology.
/// 3. The class of continuity asserted.
#[derive(Debug, Clone, PartialEq)]
pub struct ContinuityContract {
    /// Identifier for this continuity contract.
    pub id: String,
    /// The domain topological space.
    pub domain: TopologicalSpace,
    /// The codomain topological space.
    pub codomain: TopologicalSpace,
    /// The class of continuity being asserted.
    pub continuity_class: ContinuityClass,
    /// Whether this contract has been verified.
    pub verified: bool,
}

impl ContinuityContract {
    /// Creates a new continuity contract (unverified).
    pub fn new(
        id: impl Into<String>,
        domain: TopologicalSpace,
        codomain: TopologicalSpace,
        continuity_class: ContinuityClass,
    ) -> TopologyResult<Self> {
        let id = id.into();
        if id.trim().is_empty() {
            return Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-001: Continuity contract identity cannot be empty".to_string(),
            ));
        }
        Ok(Self {
            id,
            domain,
            codomain,
            continuity_class,
            verified: false,
        })
    }

    /// Marks the contract as verified.
    ///
    /// Per `TOPOLOGY-INV-005`: the contract must be explicitly verified.
    pub fn mark_verified(&mut self) {
        self.verified = true;
    }

    /// Returns whether the contract has been verified.
    pub fn is_verified(&self) -> bool {
        self.verified
    }

    /// Asserts that the contract is verified, returning an error if not.
    pub fn assert_verified(&self) -> TopologyResult<()> {
        if !self.verified {
            Err(TopologyError::ContinuityViolation(format!(
                "TOPOLOGY-INV-005: Continuity contract '{}' ({}) has not been verified",
                self.id, self.continuity_class
            )))
        } else {
            Ok(())
        }
    }

    /// Returns whether this contract asserts homeomorphism (bidirectional continuity).
    pub fn is_homeomorphism(&self) -> bool {
        matches!(self.continuity_class, ContinuityClass::Homeomorphism)
    }

    /// Returns whether this is a purely metric-based contract.
    ///
    /// Per `TOPOLOGY-RULE-003`: metric MUST NOT be assumed without declaration.
    pub fn is_metric_based(&self) -> bool {
        matches!(self.domain.topology_kind(), TopologyKind::Metric)
            && matches!(self.codomain.topology_kind(), TopologyKind::Metric)
    }
}
