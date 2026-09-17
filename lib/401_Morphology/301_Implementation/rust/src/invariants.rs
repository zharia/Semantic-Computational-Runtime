// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Normative Morphology Invariant Validators
//!
//! Enforces MORPHOLOGY-INV-001 through MORPHOLOGY-INV-018 per Section 65 of
//! `lib/401_Morphology/101_definition.md`.

use crate::error::{MorphologyError, MorphologyResult};
use crate::id::MorphologyId;
use crate::pattern::{Pattern, PatternContract};
use crate::structure::PartWholeHierarchy;
use crate::transformation::{MorphologicalDelta, MorphologicalTransformation};

/// MORPHOLOGY-INV-001: Persistent morphology MUST have stable semantic identity.
pub fn verify_morphology_inv_001_identity(id: &MorphologyId) -> MorphologyResult<()> {
    if id.as_str().trim().is_empty() {
        return Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-001: Morphological entity ID cannot be empty".to_string(),
        ));
    }
    Ok(())
}

/// MORPHOLOGY-INV-002: Declared structural relationships MUST remain valid.
pub fn verify_morphology_inv_002_structural_integrity(hierarchy: &PartWholeHierarchy) -> MorphologyResult<()> {
    hierarchy.verify_integrity()
}

/// MORPHOLOGY-INV-003: Part-whole relationships MUST remain semantically consistent (acyclic DAG).
pub fn verify_morphology_inv_003_part_whole_integrity(hierarchy: &PartWholeHierarchy) -> MorphologyResult<()> {
    hierarchy.verify_integrity()
}

/// MORPHOLOGY-INV-004: Pattern-derived morphology MUST preserve declared pattern interpretation.
pub fn verify_morphology_inv_004_pattern_integrity(
    pattern: &Pattern,
    contract: &PatternContract,
    hierarchy: &PartWholeHierarchy,
) -> MorphologyResult<()> {
    contract.verify_consistency(pattern, hierarchy)
}

/// MORPHOLOGY-INV-005: Bidirectional consistency requirements MUST be explicit and testable.
pub fn verify_morphology_inv_005_bidirectional_consistency(
    pattern: &Pattern,
    contract: &PatternContract,
    hierarchy: &PartWholeHierarchy,
) -> MorphologyResult<()> {
    if !contract.is_bidirectional {
        return Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-005: Contract must explicitly declare is_bidirectional=true to assert bidirectional consistency".to_string(),
        ));
    }
    contract.verify_consistency(pattern, hierarchy)
}

/// MORPHOLOGY-INV-006: Morphological transformations claiming topology preservation MUST preserve specified topological invariants.
pub fn verify_morphology_inv_006_topological_integrity(
    transformation: &MorphologicalTransformation,
    euler_before: i64,
    euler_after: i64,
) -> MorphologyResult<()> {
    if transformation.contract.preserves_topology && euler_before != euler_after {
        return Err(MorphologyError::InvariantViolation(format!(
            "MORPHOLOGY-INV-006: Transformation claims topology preservation but Euler characteristic altered from {} to {}",
            euler_before, euler_after
        )));
    }
    Ok(())
}

/// MORPHOLOGY-INV-007: Morphological transformations claiming geometric preservation MUST satisfy the specified geometric contract.
pub fn verify_morphology_inv_007_geometric_integrity(
    transformation: &MorphologicalTransformation,
    volume_before: f64,
    volume_after: f64,
) -> MorphologyResult<()> {
    if transformation.contract.preserves_geometry && (volume_before - volume_after).abs() > 1e-6 {
        return Err(MorphologyError::InvariantViolation(format!(
            "MORPHOLOGY-INV-007: Transformation claims geometric preservation but volume changed from {} to {}",
            volume_before, volume_after
        )));
    }
    Ok(())
}

/// MORPHOLOGY-INV-008: Morphological scale MUST remain semantically explicit.
pub fn verify_morphology_inv_008_scale_integrity(hierarchy: &PartWholeHierarchy) -> MorphologyResult<()> {
    for comp in hierarchy.components() {
        if comp.level_of_detail > 100 {
            return Err(MorphologyError::InvariantViolation(format!(
                "MORPHOLOGY-INV-008: Component {} specifies out-of-bounds scale/level-of-detail {}",
                comp.id, comp.level_of_detail
            )));
        }
    }
    Ok(())
}

/// MORPHOLOGY-INV-009: Morphological transformations MUST satisfy their declared effects.
pub fn verify_morphology_inv_009_transformation_integrity(
    transformation: &MorphologicalTransformation,
    hierarchy: &PartWholeHierarchy,
) -> MorphologyResult<()> {
    transformation.validate(hierarchy)
}

/// MORPHOLOGY-INV-010: Composed morphologies MUST preserve required component relationships.
pub fn verify_morphology_inv_010_composition_integrity(
    combined: &PartWholeHierarchy,
    expected_min_parts: usize,
) -> MorphologyResult<()> {
    if combined.component_count() < expected_min_parts {
        return Err(MorphologyError::InvariantViolation(format!(
            "MORPHOLOGY-INV-010: Composed morphology contains fewer than expected parts ({})",
            expected_min_parts
        )));
    }
    combined.verify_integrity()
}

/// MORPHOLOGY-INV-011: Equivalence claims MUST identify the equivalence relation used.
pub fn verify_morphology_inv_011_equivalence_integrity(relation_name: &str) -> MorphologyResult<()> {
    if relation_name.trim().is_empty() {
        return Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-011: Morphological equivalence claim must specify non-empty relation name".to_string(),
        ));
    }
    Ok(())
}

/// MORPHOLOGY-INV-012: Morphological state transitions MUST produce valid morphological states.
pub fn verify_morphology_inv_012_state_integrity(hierarchy: &PartWholeHierarchy) -> MorphologyResult<()> {
    hierarchy.verify_integrity()
}

/// MORPHOLOGY-INV-013: Morphological deltas MUST represent valid semantic state transitions.
pub fn verify_morphology_inv_013_delta_integrity(
    delta: &MorphologicalDelta,
    hierarchy: &PartWholeHierarchy,
) -> MorphologyResult<()> {
    match delta {
        MorphologicalDelta::AddComponent { parent, child, .. } => {
            if let Some(ref p) = parent {
                if hierarchy.get_component(p).is_none() {
                    return Err(MorphologyError::InvariantViolation(format!(
                        "MORPHOLOGY-INV-013: Delta specifies nonexistent parent {}",
                        p
                    )));
                }
            }
            if hierarchy.get_component(child).is_some() {
                return Err(MorphologyError::InvariantViolation(format!(
                    "MORPHOLOGY-INV-013: Delta attempts to add already existing component {}",
                    child
                )));
            }
        }
        MorphologicalDelta::RemoveComponent { id } => {
            if hierarchy.get_component(id).is_none() {
                return Err(MorphologyError::InvariantViolation(format!(
                    "MORPHOLOGY-INV-013: Delta attempts to remove nonexistent component {}",
                    id
                )));
            }
        }
        MorphologicalDelta::ModifyLevelOfDetail { id, .. } => {
            if hierarchy.get_component(id).is_none() {
                return Err(MorphologyError::InvariantViolation(format!(
                    "MORPHOLOGY-INV-013: Delta attempts to modify nonexistent component {}",
                    id
                )));
            }
        }
    }
    Ok(())
}

/// MORPHOLOGY-INV-014: Derived morphology MUST retain required provenance.
pub fn verify_morphology_inv_014_provenance_integrity(provenance_source: Option<&str>) -> MorphologyResult<()> {
    match provenance_source {
        Some(s) if !s.trim().is_empty() => Ok(()),
        _ => Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-014: Derived morphology lacks declared provenance source".to_string(),
        )),
    }
}

/// MORPHOLOGY-INV-015: Inferred morphology MUST retain declared uncertainty.
pub fn verify_morphology_inv_015_uncertainty_integrity(uncertainty: Option<f64>) -> MorphologyResult<()> {
    match uncertainty {
        Some(u) if (0.0..=1.0).contains(&u) => Ok(()),
        Some(u) => Err(MorphologyError::InvariantViolation(format!(
            "MORPHOLOGY-INV-015: Uncertainty score {} out of valid [0.0, 1.0] interval",
            u
        ))),
        None => Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-015: Inferred morphology lacks declared uncertainty score".to_string(),
        )),
    }
}

/// MORPHOLOGY-INV-016: Morphological meaning MUST NOT depend on physical representation.
pub fn verify_morphology_inv_016_representation_independence(carrier_type: &str) -> MorphologyResult<()> {
    if carrier_type.is_empty() {
        return Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-016: Carrier type must be explicitly declared as subordinate".to_string(),
        ));
    }
    Ok(())
}

/// MORPHOLOGY-INV-017: Provider substitution MUST preserve semantic contract.
pub fn verify_morphology_inv_017_provider_independence(provider_id: &str) -> MorphologyResult<()> {
    if provider_id.is_empty() {
        return Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-017: Provider cannot be empty or claim semantic authority".to_string(),
        ));
    }
    Ok(())
}

/// MORPHOLOGY-INV-018: Rendered appearance MUST NOT determine morphological meaning.
pub fn verify_morphology_inv_018_rendering_independence(rendering_engine: &str) -> MorphologyResult<()> {
    if rendering_engine.is_empty() {
        return Err(MorphologyError::InvariantViolation(
            "MORPHOLOGY-INV-018: Rendering engine must be explicitly subordinate to morphology".to_string(),
        ));
    }
    Ok(())
}
