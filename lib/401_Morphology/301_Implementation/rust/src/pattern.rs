// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Pattern-Morphology Bidirectional Semantics
//!
//! Enforces MORPHOLOGY-INV-004 (Pattern Integrity) and MORPHOLOGY-INV-005 (Bidirectional Consistency).
//!
//! Patterns generate, constrain, and emerge from morphological structures.

use crate::error::{MorphologyError, MorphologyResult};
use crate::id::{ComponentId, PatternId};
use crate::structure::PartWholeHierarchy;

/// Pattern representation generating or derived from morphology.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Pattern {
    pub id: PatternId,
    pub motif_name: String,
    pub expected_repetitions: usize,
    pub symmetry_group: Option<String>,
}

impl Pattern {
    pub fn new(id: PatternId, motif_name: impl Into<String>, repetitions: usize) -> Self {
        Self {
            id,
            motif_name: motif_name.into(),
            expected_repetitions: repetitions,
            symmetry_group: None,
        }
    }

    pub fn with_symmetry(mut self, group: impl Into<String>) -> Self {
        self.symmetry_group = Some(group.into());
        self
    }
}

/// Bidirectional consistency contract between patterns and morphological structures.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PatternContract {
    pub pattern_id: PatternId,
    pub mapped_components: Vec<ComponentId>,
    pub is_bidirectional: bool,
}

impl PatternContract {
    pub fn new(pattern_id: PatternId, is_bidirectional: bool) -> Self {
        Self {
            pattern_id,
            mapped_components: Vec::new(),
            is_bidirectional,
        }
    }

    pub fn map_component(&mut self, component_id: ComponentId) {
        if !self.mapped_components.contains(&component_id) {
            self.mapped_components.push(component_id);
        }
    }

    /// Verifies that the pattern-derived morphology preserves the declared pattern interpretation (MORPHOLOGY-INV-004)
    /// and satisfies bidirectional consistency where required (MORPHOLOGY-INV-005).
    pub fn verify_consistency(
        &self,
        pattern: &Pattern,
        hierarchy: &PartWholeHierarchy,
    ) -> MorphologyResult<()> {
        if self.pattern_id != pattern.id {
            return Err(MorphologyError::PatternMismatch(format!(
                "Contract pattern ID {} does not match provided pattern ID {}",
                self.pattern_id, pattern.id
            )));
        }

        // Verify all mapped components exist in the hierarchy
        for comp_id in &self.mapped_components {
            if hierarchy.get_component(comp_id).is_none() {
                return Err(MorphologyError::PatternMismatch(format!(
                    "Component {} declared in pattern contract does not exist in hierarchy",
                    comp_id
                )));
            }
        }

        // If bidirectional consistency is required, the number of instantiated components
        // must match the expected repetitions of the pattern motif.
        if self.is_bidirectional {
            if self.mapped_components.len() != pattern.expected_repetitions {
                return Err(MorphologyError::PatternMismatch(format!(
                    "Bidirectional consistency failure: expected {} instances of motif '{}', found {}",
                    pattern.expected_repetitions,
                    pattern.motif_name,
                    self.mapped_components.len()
                )));
            }
        }

        Ok(())
    }
}
