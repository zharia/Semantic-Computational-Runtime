// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Structural & Feature Conformance Tests
//!
//! Tests for hierarchical part-whole organization and morphological features.

use scr_morphology::feature::{FeatureKind, MorphologicalFeature, Skeleton};
use scr_morphology::id::{ComponentId, FeatureId};
use scr_morphology::structure::PartWholeHierarchy;

#[test]
fn test_deep_hierarchical_organization() {
    let mut hierarchy = PartWholeHierarchy::new();

    let organism = ComponentId::new("organism");
    let limb_l = ComponentId::new("limb_left");
    let limb_r = ComponentId::new("limb_right");
    let hand_l = ComponentId::new("hand_left");
    let digit_l1 = ComponentId::new("digit_left_1");

    hierarchy.add_root(organism.clone(), "Organism Body").unwrap();
    hierarchy.add_child(&organism, limb_l.clone(), "Left Limb").unwrap();
    hierarchy.add_child(&organism, limb_r.clone(), "Right Limb").unwrap();
    hierarchy.add_child(&limb_l, hand_l.clone(), "Left Hand").unwrap();
    hierarchy.add_child(&hand_l, digit_l1.clone(), "Digit 1").unwrap();

    assert_eq!(hierarchy.component_count(), 5);

    let ancestors = hierarchy.get_ancestors(&digit_l1);
    assert_eq!(ancestors.len(), 3);
    assert!(ancestors.contains(&hand_l));
    assert!(ancestors.contains(&limb_l));
    assert!(ancestors.contains(&organism));

    let digit_comp = hierarchy.get_component(&digit_l1).unwrap();
    assert_eq!(digit_comp.level_of_detail, 3);
}

#[test]
fn test_morphological_features_and_skeleton() {
    let comp = ComponentId::new("trunk");
    let feat_sym = MorphologicalFeature::new(
        FeatureId::new("feat:sym_plane_01"),
        FeatureKind::SymmetryBilateral,
        comp.clone(),
        "Sagittal symmetry plane",
    );
    assert_eq!(feat_sym.kind, FeatureKind::SymmetryBilateral);

    let mut skeleton = Skeleton::new();
    let n1 = FeatureId::new("joint:base");
    let n2 = FeatureId::new("joint:junction");
    let n3 = FeatureId::new("joint:branch_a");
    let n4 = FeatureId::new("joint:branch_b");

    skeleton.add_bone(&n1, &n2);
    skeleton.add_bone(&n2, &n3);
    skeleton.add_bone(&n2, &n4);

    assert_eq!(skeleton.node_degree(&n1), 1);
    assert_eq!(skeleton.node_degree(&n2), 3);
    assert!(skeleton.is_branching(&n2));
    assert!(!skeleton.is_branching(&n1));
}
