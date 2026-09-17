// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Canonical Hypergraph Projection — Morphology Domain
//!
//! Projects morphological structures, hierarchies, patterns, and features
//! into the canonical SCR Semantic Hypergraph (`SCR-LIB-HYPERGRAPH`).
//!
//! Conforms to `SCR-LIB-MORPHOLOGY` Section 53:
//! ```text
//! Morphology
//!  ├── HAS_PART        → Component
//!  ├── HAS_PATTERN     → Pattern
//!  ├── REALIZED_AS     → Geometry
//!  ├── CONSTRAINED_BY  → Topology
//!  ├── DERIVED_FROM    → Field
//!  ├── EVOLVES_BY      → Transformation
//!  └── MANIFESTED_BY   → Rendering
//! ```

use crate::error::{MorphologyError, MorphologyResult};
use crate::feature::MorphologicalFeature;
use crate::id::MorphologyId;
use crate::pattern::Pattern;
use crate::structure::PartWholeHierarchy;
use scr_hypergraph::{Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role};

/// Projects a complete morphological structure into the canonical hypergraph.
pub fn project_morphology_to_hypergraph(
    morphology_id: &MorphologyId,
    hierarchy: &PartWholeHierarchy,
    pattern: Option<&Pattern>,
    features: &[MorphologicalFeature],
    hypergraph: &mut Hypergraph,
) -> MorphologyResult<()> {
    // 1. Create root Morphology Element
    let morph_elem_id = ElementId(format!("elem:morph:{}", morphology_id));
    if hypergraph.get_element(&morph_elem_id).is_none() {
        hypergraph
            .create_element(
                morph_elem_id.clone(),
                format!("Morphology:{}", morphology_id),
            )
            .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;
    }

    // 2. Pass 1: Ensure all Component Elements exist
    for comp in hierarchy.components() {
        let comp_elem_id = ElementId(format!("elem:comp:{}", comp.id));
        if hypergraph.get_element(&comp_elem_id).is_none() {
            hypergraph
                .create_element(
                    comp_elem_id,
                    format!("Component:{}:lod={}", comp.name, comp.level_of_detail),
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;
        }
    }

    // 2. Pass 2: Project Part-Whole Relations
    for comp in hierarchy.components() {
        let comp_elem_id = ElementId(format!("elem:comp:{}", comp.id));

        // HAS_PART Relation from morphology or parent
        let (rel_id, source_elem) = if let Some(ref parent_id) = comp.parent {
            (
                RelationId(format!("rel:has_subpart:{}:{}", parent_id, comp.id)),
                ElementId(format!("elem:comp:{}", parent_id)),
            )
        } else {
            (
                RelationId(format!("rel:has_root_part:{}:{}", morphology_id, comp.id)),
                morph_elem_id.clone(),
            )
        };

        if hypergraph.get_relation(&rel_id).is_none() {
            hypergraph
                .create_relation(rel_id.clone(), "HAS_PART".to_string())
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:src", rel_id)),
                    &source_elem,
                    &rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:tgt", rel_id)),
                    &comp_elem_id,
                    &rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;
        }
    }

    // 3. Project Pattern relation if present
    if let Some(pat) = pattern {
        let pat_elem_id = ElementId(format!("elem:pattern:{}", pat.id));
        if hypergraph.get_element(&pat_elem_id).is_none() {
            hypergraph
                .create_element(
                    pat_elem_id.clone(),
                    format!("Pattern:{}:motif={}", pat.id, pat.motif_name),
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;
        }

        let pat_rel_id = RelationId(format!("rel:has_pattern:{}:{}", morphology_id, pat.id));
        if hypergraph.get_relation(&pat_rel_id).is_none() {
            hypergraph
                .create_relation(pat_rel_id.clone(), "HAS_PATTERN".to_string())
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:src", pat_rel_id)),
                    &morph_elem_id,
                    &pat_rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:tgt", pat_rel_id)),
                    &pat_elem_id,
                    &pat_rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;
        }
    }

    // 4. Project Features
    for feat in features {
        let feat_elem_id = ElementId(format!("elem:feat:{}", feat.id));
        if hypergraph.get_element(&feat_elem_id).is_none() {
            hypergraph
                .create_element(
                    feat_elem_id.clone(),
                    format!("Feature:{:?}:{}", feat.kind, feat.description),
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;
        }

        let feat_rel_id = RelationId(format!("rel:has_feature:{}:{}", feat.target_component, feat.id));
        if hypergraph.get_relation(&feat_rel_id).is_none() {
            let comp_elem = ElementId(format!("elem:comp:{}", feat.target_component));
            hypergraph
                .create_relation(feat_rel_id.clone(), "EXPRESSES_FEATURE".to_string())
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:src", feat_rel_id)),
                    &comp_elem,
                    &feat_rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:{}:tgt", feat_rel_id)),
                    &feat_elem_id,
                    &feat_rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| MorphologyError::HypergraphError(e.to_string()))?;
        }
    }

    Ok(())
}
