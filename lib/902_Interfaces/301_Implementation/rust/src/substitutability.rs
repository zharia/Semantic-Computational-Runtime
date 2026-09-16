// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{InterfaceError, Result};
use crate::interface::SemanticInterface;

/// Verifies whether candidate interface B can substitute for required interface A.
///
/// In accordance with:
/// - INTERFACE-INV-011 (Substitutability): Substitution MUST preserve the relevant interface contract.
/// - INTERFACE-INV-012 (Refinement Integrity): Refinement MUST preserve declared compatibility guarantees.
///
/// Formal criteria (Liskov / behavioral subtyping for semantic contracts):
/// 1. Candidate B must implement all operations required by A.
/// 2. Candidate B must possess at least all capabilities declared by A (capabilities(B) >= capabilities(A)).
/// 3. For every operation in A:
///    - Candidate B's inputs and outputs must match A's type contracts.
///    - Candidate B's effects must not introduce undeclared side effects absent from A.
pub fn verify_substitutability(
    required: &SemanticInterface,
    candidate: &SemanticInterface,
) -> Result<()> {
    // 1. Verify capabilities
    if !candidate.capabilities.is_superset(&required.capabilities) {
        return Err(InterfaceError::SubstitutabilityViolation(format!(
            "Candidate '{}' lacks required capabilities of '{}'",
            candidate.id.as_str(),
            required.id.as_str()
        )));
    }

    // 2. Verify all operations in required interface exist in candidate
    for (op_name, req_op) in &required.operations {
        let cand_op = match candidate.operations.get(op_name) {
            Some(op) => op,
            None => {
                return Err(InterfaceError::SubstitutabilityViolation(format!(
                    "Candidate '{}' lacks required operation '{}'",
                    candidate.id.as_str(),
                    op_name
                )));
            }
        };

        // Output type compatibility
        if req_op.output != cand_op.output {
            return Err(InterfaceError::SubstitutabilityViolation(format!(
                "Operation '{}' output mismatch: required {:?}, candidate {:?}",
                op_name, req_op.output, cand_op.output
            )));
        }

        // Input parameter count and types
        if req_op.inputs.len() != cand_op.inputs.len() {
            return Err(InterfaceError::SubstitutabilityViolation(format!(
                "Operation '{}' input parameter count mismatch",
                op_name
            )));
        }

        for (req_in, cand_in) in req_op.inputs.iter().zip(cand_op.inputs.iter()) {
            if req_in.type_contract != cand_in.type_contract {
                return Err(InterfaceError::SubstitutabilityViolation(format!(
                    "Operation '{}' input parameter '{}' type mismatch",
                    op_name, req_in.name
                )));
            }
        }

        // Effect safety: candidate must not perform effects not permitted by required contract
        for cand_effect in &cand_op.effects {
            if !req_op.effects.contains(cand_effect) {
                return Err(InterfaceError::SubstitutabilityViolation(format!(
                    "Operation '{}' introduces undeclared side effect {:?}",
                    op_name, cand_effect
                )));
            }
        }
    }

    Ok(())
}
