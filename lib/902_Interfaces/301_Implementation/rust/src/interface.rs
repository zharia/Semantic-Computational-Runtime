// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::collections::HashMap;

use crate::capability::CapabilitySet;
use crate::contract::InvariantContract;
use crate::identity::{InterfaceId, Namespace, SemanticVersion};
use crate::operation::OperationContract;

/// Lifecycle state of an Interface contract.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InterfaceLifecycle {
    Defined,
    Specified,
    Validated,
    Published,
    Implemented,
    Observed,
    Refined,
    Deprecated,
}

/// Canonical semantic interface model:
/// I = (N, O, T, C, B, S, E, R, K, V, P)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SemanticInterface {
    pub id: InterfaceId,
    pub namespace: Namespace,
    pub version: SemanticVersion,
    pub lifecycle: InterfaceLifecycle,
    pub operations: HashMap<String, OperationContract>,
    pub capabilities: CapabilitySet,
    pub invariants: Vec<InvariantContract>,
    pub metadata: HashMap<String, String>,
}

impl SemanticInterface {
    pub fn new(id: InterfaceId, namespace: Namespace, version: SemanticVersion) -> Self {
        Self {
            id,
            namespace,
            version,
            lifecycle: InterfaceLifecycle::Specified,
            operations: HashMap::new(),
            capabilities: CapabilitySet::new(),
            invariants: Vec::new(),
            metadata: HashMap::new(),
        }
    }

    pub fn add_operation(&mut self, op: OperationContract) {
        self.operations.insert(op.name.clone(), op);
    }

    pub fn add_invariant(&mut self, inv: InvariantContract) {
        self.invariants.push(inv);
    }

    pub fn get_operation(&self, name: &str) -> Option<&OperationContract> {
        self.operations.get(name)
    }
}
