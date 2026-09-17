// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Physical Laws & Conservation Principles
//!
//! Enforces PHYSICS-INV-003 (Law Integrity), PHYSICS-INV-006 (Conservation Integrity),
//! and PHYSICS-INV-007 (Model Validity).

use crate::error::{PhysicsError, PhysicsResult};
use crate::id::LawId;

/// Conserved quantity categories in physical models.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ConservationKind {
    Energy,
    LinearMomentum,
    AngularMomentum,
    Mass,
    Charge,
}

/// A conservation law contract tracking exact conservation across physical states.
#[derive(Debug, Clone, PartialEq)]
pub struct ConservationContract {
    pub kind: ConservationKind,
    pub tolerance: f64,
}

impl ConservationContract {
    pub fn new(kind: ConservationKind, tolerance: f64) -> Self {
        Self { kind, tolerance }
    }

    /// Verifies that a conserved quantity remains invariant within the declared tolerance (PHYSICS-INV-006).
    pub fn verify_conservation(&self, initial_value: f64, current_value: f64) -> PhysicsResult<()> {
        let delta = (initial_value - current_value).abs();
        if delta > self.tolerance {
            return Err(PhysicsError::ConservationViolation(format!(
                "PHYSICS-INV-006: Conservation of {:?} violated: |{} - {}| = {} exceeds tolerance {}",
                self.kind, initial_value, current_value, delta, self.tolerance
            )));
        }
        Ok(())
    }
}

/// A formal physical law specification.
#[derive(Debug, Clone, PartialEq)]
pub struct PhysicalLaw {
    pub id: LawId,
    pub name: String,
    pub validity_domain: String,
    pub conservation_contracts: Vec<ConservationContract>,
}

impl PhysicalLaw {
    pub fn new(id: LawId, name: impl Into<String>, validity_domain: impl Into<String>) -> Self {
        Self {
            id,
            name: name.into(),
            validity_domain: validity_domain.into(),
            conservation_contracts: Vec::new(),
        }
    }

    pub fn with_conservation(mut self, contract: ConservationContract) -> Self {
        self.conservation_contracts.push(contract);
        self
    }
}
