// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Morphology Invariant Conformance Tests
//!
//! Specification tests verifying MORPHOLOGY-INV-001 through MORPHOLOGY-INV-018.

use scr_morphology::id::{ComponentId, MorphologyId, PatternId};
use scr_morphology::invariants::*;
use scr_morphology::pattern::{Pattern, PatternContract};
use scr_morphology::structure::PartWholeHierarchy;
use scr_morphology::transformation::{
    MorphologicalDelta, MorphologicalTransformation, PreservationContract, TransformationKind,
};

#[test]
fn test_inv_001_identity() {
    let valid_id = MorphologyId::new("morph:tree:oak_001");
    assert!(verify_morphology_inv_001_identity(&valid_id).is_ok());

    let empty_id = MorphologyId::new("   ");
    assert!(verify_morphology_inv_001_identity(&empty_id).is_err());
}

#[test]
fn test_inv_002_003_structural_and_part_whole_integrity() {
    let mut hierarchy = PartWholeHierarchy::new();
    let root = ComponentId::new("tree");
    let trunk = ComponentId::new("trunk");
    let branch = ComponentId::new("branch");

    hierarchy.add_root(root.clone(), "Tree Root").unwrap();
    hierarchy.add_child(&root, trunk.clone(), "Trunk").unwrap();
    hierarchy.add_child(&trunk, branch.clone(), "Branch").unwrap();

    assert!(verify_morphology_inv_002_structural_integrity(&hierarchy).is_ok());
    assert!(verify_morphology_inv_003_part_whole_integrity(&hierarchy).is_ok());

    // Cycle attempt: adding root as child of branch
    let cycle_res = hierarchy.add_child(&branch, root.clone(), "Illegal Cycle");
    assert!(cycle_res.is_err());
}

#[test]
fn test_inv_004_005_pattern_and_bidirectional_consistency() {
    let pat_id = PatternId::new("pat:branching_bifurcation");
    let pattern = Pattern::new(pat_id.clone(), "bifurcation", 2);

    let mut hierarchy = PartWholeHierarchy::new();
    let root = ComponentId::new("root");
    let c1 = ComponentId::new("branch_left");
    let c2 = ComponentId::new("branch_right");

    hierarchy.add_root(root.clone(), "Base").unwrap();
    hierarchy.add_child(&root, c1.clone(), "Left").unwrap();
    hierarchy.add_child(&root, c2.clone(), "Right").unwrap();

    let mut contract = PatternContract::new(pat_id.clone(), true);
    contract.map_component(c1.clone());
    contract.map_component(c2.clone());

    // 004: Pattern integrity passes
    assert!(verify_morphology_inv_004_pattern_integrity(&pattern, &contract, &hierarchy).is_ok());

    // 005: Bidirectional consistency passes
    assert!(verify_morphology_inv_005_bidirectional_consistency(&pattern, &contract, &hierarchy).is_ok());

    // Mismatched expected count in bidirectional mode fails
    let pat_wrong = Pattern::new(pat_id.clone(), "trifurcation", 3);
    assert!(verify_morphology_inv_005_bidirectional_consistency(&pat_wrong, &contract, &hierarchy).is_err());
}

#[test]
fn test_inv_006_topological_integrity() {
    let topo_preserving = MorphologicalTransformation::new(
        TransformationKind::Deformation,
        PreservationContract::TOPOLOGY_PRESERVING,
        "Rubber-sheet continuous deformation",
    );

    // Euler characteristic preserved
    assert!(verify_morphology_inv_006_topological_integrity(&topo_preserving, 2, 2).is_ok());
    // Euler characteristic changed under topology-preserving claim must fail
    assert!(verify_morphology_inv_006_topological_integrity(&topo_preserving, 2, 0).is_err());

    // Topology changing transformation allows Euler characteristic change
    let topo_changing = MorphologicalTransformation::new(
        TransformationKind::Fracture,
        PreservationContract::TOPOLOGY_CHANGING,
        "Mechanical fracture into fragments",
    );
    assert!(verify_morphology_inv_006_topological_integrity(&topo_changing, 2, 4).is_ok());
}

#[test]
fn test_inv_007_geometric_integrity() {
    let rigid_trans = MorphologicalTransformation::new(
        TransformationKind::Deformation,
        PreservationContract::RIGID,
        "Rigid spatial transformation",
    );

    assert!(verify_morphology_inv_007_geometric_integrity(&rigid_trans, 10.0, 10.0).is_ok());
    assert!(verify_morphology_inv_007_geometric_integrity(&rigid_trans, 10.0, 12.5).is_err());
}

#[test]
fn test_inv_008_scale_integrity() {
    let mut hierarchy = PartWholeHierarchy::new();
    let root = ComponentId::new("organism");
    hierarchy.add_root(root.clone(), "Organism").unwrap();

    assert!(verify_morphology_inv_008_scale_integrity(&hierarchy).is_ok());
}

#[test]
fn test_inv_009_transformation_integrity() {
    let mut hierarchy = PartWholeHierarchy::new();
    let root = ComponentId::new("body");
    hierarchy.add_root(root.clone(), "Body").unwrap();

    let growth = MorphologicalTransformation::new(
        TransformationKind::Growth,
        PreservationContract::TOPOLOGY_PRESERVING,
        "Biomass accretion",
    );
    assert!(verify_morphology_inv_009_transformation_integrity(&growth, &hierarchy).is_ok());

    // Fracture claiming hierarchy preservation is an invalid transformation
    let invalid_fracture = MorphologicalTransformation::new(
        TransformationKind::Fracture,
        PreservationContract::RIGID,
        "Illegal rigid fracture",
    );
    assert!(verify_morphology_inv_009_transformation_integrity(&invalid_fracture, &hierarchy).is_err());
}

#[test]
fn test_inv_010_composition_integrity() {
    let mut hierarchy = PartWholeHierarchy::new();
    let root = ComponentId::new("composite");
    hierarchy.add_root(root.clone(), "Composite Root").unwrap();
    hierarchy.add_child(&root, ComponentId::new("sub1"), "Subpart 1").unwrap();

    assert!(verify_morphology_inv_010_composition_integrity(&hierarchy, 2).is_ok());
    assert!(verify_morphology_inv_010_composition_integrity(&hierarchy, 5).is_err());
}

#[test]
fn test_inv_011_equivalence_integrity() {
    assert!(verify_morphology_inv_011_equivalence_integrity("IsomorphicBranchingEquivalence").is_ok());
    assert!(verify_morphology_inv_011_equivalence_integrity("   ").is_err());
}

#[test]
fn test_inv_012_013_state_and_delta_integrity() {
    let mut hierarchy = PartWholeHierarchy::new();
    let root = ComponentId::new("leaf");
    hierarchy.add_root(root.clone(), "Leaf").unwrap();

    assert!(verify_morphology_inv_012_state_integrity(&hierarchy).is_ok());

    let delta_valid = MorphologicalDelta::AddComponent {
        parent: Some(root.clone()),
        child: ComponentId::new("vein_primary"),
        name: "Primary Vein".to_string(),
    };
    assert!(verify_morphology_inv_013_delta_integrity(&delta_valid, &hierarchy).is_ok());

    let delta_nonexistent_parent = MorphologicalDelta::AddComponent {
        parent: Some(ComponentId::new("nonexistent")),
        child: ComponentId::new("leaf_secondary"),
        name: "Secondary".to_string(),
    };
    assert!(verify_morphology_inv_013_delta_integrity(&delta_nonexistent_parent, &hierarchy).is_err());
}

#[test]
fn test_inv_014_provenance_integrity() {
    assert!(verify_morphology_inv_014_provenance_integrity(Some("scr://provenance/gen_step_42")).is_ok());
    assert!(verify_morphology_inv_014_provenance_integrity(None).is_err());
    assert!(verify_morphology_inv_014_provenance_integrity(Some("")).is_err());
}

#[test]
fn test_inv_015_uncertainty_integrity() {
    assert!(verify_morphology_inv_015_uncertainty_integrity(Some(0.85)).is_ok());
    assert!(verify_morphology_inv_015_uncertainty_integrity(Some(1.2)).is_err());
    assert!(verify_morphology_inv_015_uncertainty_integrity(None).is_err());
}

#[test]
fn test_inv_016_017_018_independence_invariants() {
    assert!(verify_morphology_inv_016_representation_independence("OctreeCarrier").is_ok());
    assert!(verify_morphology_inv_016_representation_independence("").is_err());

    assert!(verify_morphology_inv_017_provider_independence("ProviderOpenVDB").is_ok());
    assert!(verify_morphology_inv_017_provider_independence("").is_err());

    assert!(verify_morphology_inv_018_rendering_independence("RayTracedRenderer").is_ok());
    assert!(verify_morphology_inv_018_rendering_independence("").is_err());
}
