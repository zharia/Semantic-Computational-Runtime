// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{InterfaceError, Result};
use crate::identity::{InterfaceId, Namespace, SemanticVersion};
use crate::interface::SemanticInterface;

/// Composes two interfaces into a unified composite interface.
///
/// In accordance with INTERFACE-INV-013:
/// Interface composition MUST preserve component guarantees.
/// Conflicting operations with identical names but differing signatures or contracts
/// are rejected to preserve soundness.
pub fn compose_interfaces(
    composite_id: InterfaceId,
    namespace: Namespace,
    version: SemanticVersion,
    a: &SemanticInterface,
    b: &SemanticInterface,
) -> Result<SemanticInterface> {
    let mut composite = SemanticInterface::new(composite_id, namespace, version);

    // 1. Union of capabilities
    for cap in a.capabilities.iter() {
        composite.capabilities.insert(*cap);
    }
    for cap in b.capabilities.iter() {
        composite.capabilities.insert(*cap);
    }

    // 2. Add operations from A
    for (_name, op) in &a.operations {
        composite.add_operation(op.clone());
    }

    // 3. Add operations from B, ensuring no contract contradiction
    for (name, op) in &b.operations {
        if let Some(existing) = composite.get_operation(name) {
            if existing != op {
                return Err(InterfaceError::IncompatibleInterface(format!(
                    "Cannot compose: conflicting definitions for operation '{}'",
                    name
                )));
            }
        } else {
            composite.add_operation(op.clone());
        }
    }

    // 4. Union of invariants
    for inv in &a.invariants {
        composite.add_invariant(inv.clone());
    }
    for inv in &b.invariants {
        composite.add_invariant(inv.clone());
    }

    Ok(composite)
}
