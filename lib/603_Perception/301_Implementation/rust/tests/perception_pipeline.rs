use scr_hypergraph::Hypergraph;
use scr_perception::*;

#[test]
fn test_end_to_end_perception_pipeline_with_hypergraph_projection() {
    // 1. Establish Context (PERCEPTION-INV-006 & PERCEPTION-INV-012)
    let ctx = PerceptualContext::new("observer:robot_01", "room_inspection")
        .with_spatial_reference(SpatialReference::Euclidean3D {
            frame_id: "robot_base_link".into(),
        })
        .with_invariant("PERCEPTION-INV-001")
        .with_env("lighting", "indoor_fluorescent");

    // 2. Form Conceptual Process P = (O, C, K, T, R, U, X) (Section 3)
    let mut process = PerceptualProcess::new(ctx, "pipeline_orchestrator_v1");

    // Add Multimodal Observations (Visual and Spatial/LiDAR)
    let obs_visual = Observation::new(
        "obs:cam_left",
        "scr://sensors/camera_left",
        Modality::Visual,
        vec![255.0, 128.0, 64.0],
        1_700_000_000,
    );
    let obs_spatial = Observation::new(
        "obs:lidar_front",
        "scr://sensors/lidar_front",
        Modality::Spatial,
        vec![1.5, 0.2, 0.8], // 3D coordinates in meters
        1_700_000_010,
    );
    process.add_observation(obs_visual);
    process.add_observation(obs_spatial);
    process.add_prior_knowledge("room_type", "laboratory");
    process.set_uncertainty(Uncertainty::Interval {
        lower: 0.01,
        upper: 0.05,
    });

    // 3. Execute Transformation T -> Resulting Representation R
    let representation = process
        .execute_transformation("multimodal_fusion_and_scene_understanding", |obs, ctx, _k| {
            let mut rep = PerceptualRepresentation::empty("rep:scene_001");

            // Feature extraction
            let feat_prov = PerceptualProvenance::new("edge_extractor", &ctx.observer_id)
                .with_source_observation(&obs[0].id);
            let feature = Feature::new("linear_edge_density", vec![0.74], feat_prov)
                .with_invariance("scale-invariant");
            rep.features.push(feature);

            // Detection
            let det_prov = PerceptualProvenance::new("yolo_v10_semantic", &ctx.observer_id)
                .with_source_observation(&obs[0].id);
            let detection = Detection::new(
                "det:box_01",
                "Object:Container",
                RegionExtent::BoundingBox {
                    min: [1.2, 0.0, 0.5],
                    max: [1.8, 0.4, 1.1],
                },
                Confidence::probability(0.91),
                Uncertainty::Variance(0.03),
                det_prov,
            );
            rep.detections.push(detection);

            // Classification
            let class_prov = PerceptualProvenance::new("material_classifier", &ctx.observer_id);
            let classification = Classification::new(
                "cls:001",
                "det:box_01",
                "scr://taxonomies/materials",
                vec![
                    ScoredLabel {
                        label: "Polymer".into(),
                        confidence: Confidence::probability(0.85),
                    },
                    ScoredLabel {
                        label: "Composite".into(),
                        confidence: Confidence::probability(0.15),
                    },
                ],
                Uncertainty::Variance(0.04),
                class_prov,
            );
            rep.classifications.push(classification);

            // Persistent Identification (INV-010)
            let ident_prov = PerceptualProvenance::new("rfid_barcode_fuser", &ctx.observer_id)
                .with_source_observation(&obs[1].id);
            let identification = Identification::new(
                "ident:item_crate",
                "scr://inventory/crates/CRATE-9921",
                Confidence::probability(0.99),
                Uncertainty::Certain,
                ident_prov,
            ).with_similarity(0.95);
            rep.identifications.push(identification);

            // Nullary Relation assertion (Section 43 & INV-023: |I(R)| = 0)
            rep.nullary_assertions.push("SafetyPerimeterClear".into());

            Ok(rep)
        })
        .expect("Perceptual transformation should succeed");

    assert_eq!(representation.id, "rep:scene_001");
    assert_eq!(representation.features.len(), 1);
    assert_eq!(representation.detections.len(), 1);
    assert_eq!(representation.classifications.len(), 1);
    assert_eq!(representation.identifications.len(), 1);
    assert_eq!(representation.nullary_assertions.len(), 1);

    // 4. Project into Canonical Hypergraph (Section 41 & PERCEPTION-INV-019)
    let mut hypergraph = Hypergraph::new();
    project_perception_to_hypergraph(&representation, &mut hypergraph)
        .expect("Projection to canonical hypergraph must succeed");

    // Root perception element + Candidate element + Identified persistent entity element
    assert_eq!(hypergraph.element_count(), 3);
    // Detection relation + Identification relation + Nullary relation
    assert_eq!(hypergraph.relation_count(), 3);
    // Detection incidences (2) + Identification incidences (2) + Nullary incidences (0) = 4
    assert_eq!(hypergraph.incidence_count(), 4);
}
