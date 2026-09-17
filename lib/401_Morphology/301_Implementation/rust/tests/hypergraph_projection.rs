// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Morphology Hypergraph Projection Tests
//!
//! Verifies canonical hypergraph projection conforming to Section 53 of `101_definition.md`.

use scr_hypergraph::Hypergraph;
use scr_morphology::feature::{FeatureKind, MorphologicalFeature};
use scr_morphology::hypergraph::project_morphology_to_hypergraph;
use scr_morphology::id::{ComponentId, FeatureId, MorphologyId, PatternId};
use scr_morphology::pattern::Pattern;
use scr_morphology::structure::PartWholeHierarchy;

#[test]
fn test_morphology_hypergraph_projection() {
    let mut hg = Hypergraph::new();

    let morph_id = MorphologyId::new("morph:leaf_structure");
    let mut hierarchy = PartWholeHierarchy::new();

    let blade = ComponentId::new("blade");
    let petiole = ComponentId::new("petiole");
    let vein = ComponentId::new("vein_midrib");

    hierarchy.add_root(blade.clone(), "Leaf Blade").unwrap();
    hierarchy.add_child(&blade, petiole.clone(), "Petiole").unwrap();
    hierarchy.add_child(&blade, vein.clone(), "Midrib Vein").unwrap();

    let pat_id = PatternId::new("pat:venation_pattern");
    let pattern = Pattern::new(pat_id.clone(), "reticulate_venation", 1);

    let feat = MorphologicalFeature::new(
        FeatureId::new("feat:apex_symmetry"),
        FeatureKind::SymmetryBilateral,
        blade.clone(),
        "Apex bilateral symmetry",
    );

    project_morphology_to_hypergraph(
        &morph_id,
        &hierarchy,
        Some(&pattern),
        &[feat],
        &mut hg,
    )
    .unwrap();

    // Verify elements: morphology (1) + components (3) + pattern (1) + feature (1) = 6
    assert!(hg.elements().count() >= 6);

    // Verify relations: has_root_part (1) + has_subparts (2) + has_pattern (1) + expresses_feature (1) = 5
    assert!(hg.relations().count() >= 5);
}

#[test]
fn test_idempotent_projection() {
    let mut hg = Hypergraph::new();

    let morph_id = MorphologyId::new("morph:simple");
    let mut hierarchy = PartWholeHierarchy::new();
    hierarchy.add_root(ComponentId::new("c1"), "Root Component").unwrap();

    // Project once
    project_morphology_to_hypergraph(&morph_id, &hierarchy, None, &[], &mut hg).unwrap();
    let elem_count_1 = hg.elements().count();
    let rel_count_1 = hg.relations().count();

    // Project again into same hypergraph
    project_morphology_to_hypergraph(&morph_id, &hierarchy, None, &[], &mut hg).unwrap();
    let elem_count_2 = hg.elements().count();
    let rel_count_2 = hg.relations().count();

    assert_eq!(elem_count_1, elem_count_2);
    assert_eq!(rel_count_1, rel_count_2);
}
