use scr_hypergraph::Hypergraph;
use scr_perception::*;

#[test]
fn test_inv_002_003_018_observation_boundary_and_non_exclusivity() {
    // PERCEPTION-INV-002: Observation must remain distinguishable from underlying state.
    // PERCEPTION-INV-018: Absence of observation must not imply absence of phenomenon.
    let obs = Observation::new(
        "obs:001",
        "scr://entities/drone-42",
        Modality::Visual,
        vec![1.0, 2.0, 3.0],
        1_000_000,
    );
    assert!(obs.is_observed());
    assert_eq!(obs.source_uri, "scr://entities/drone-42");
    assert_eq!(obs.modality, Modality::Visual);

    // Unobserved state due to occlusion
    let occluded = Observation::new_unobserved(
        "obs:002",
        "scr://entities/drone-42",
        Modality::Visual,
        ObservationStatus::Occluded {
            reason: "Obstacle in line of sight".into(),
        },
        1_050_000,
    );
    assert!(!occluded.is_observed());
    match &occluded.status {
        ObservationStatus::Occluded { reason } => assert_eq!(reason, "Obstacle in line of sight"),
        _ => panic!("Expected Occluded status"),
    }
}

#[test]
fn test_inv_007_008_uncertainty_and_ambiguity_integrity() {
    // PERCEPTION-INV-007: Uncertainty must not be silently converted into certainty.
    // PERCEPTION-INV-008: Material alternative hypotheses must remain representable.
    let conf_heuristic = Confidence::heuristic(0.85);
    assert!(!conf_heuristic.is_calibrated_probability());

    let conf_prob = Confidence::probability(0.85);
    assert!(conf_prob.is_calibrated_probability());

    // Multi-hypothesis ambiguity representation
    let mut hyp_set = HypothesisSet::new();
    hyp_set = hyp_set.with_hypothesis(
        "hyp:h1",
        "Drone",
        Confidence::probability(0.65),
        Uncertainty::Variance(0.05),
        "Acoustic and visual profile match UAV",
    );
    hyp_set = hyp_set.with_hypothesis(
        "hyp:h2",
        "Bird",
        Confidence::probability(0.35),
        Uncertainty::Variance(0.12),
        "Small radar cross section and erratic trajectory",
    );

    assert!(hyp_set.is_ambiguous());
    assert_eq!(hyp_set.len(), 2);

    // Dominant selection preserving alternatives
    let (dominant, alternatives) = hyp_set
        .select_dominant_preserving_alternatives()
        .expect("Selection should succeed");

    assert_eq!(dominant.id, "hyp:h1");
    assert_eq!(dominant.candidate, "Drone");
    assert_eq!(alternatives.len(), 1);
    assert_eq!(alternatives[0].id, "hyp:h2");
    assert_eq!(alternatives[0].candidate, "Bird");
}

#[test]
fn test_inv_010_identity_integrity() {
    // PERCEPTION-INV-010: Identification must remain distinct from similarity and classification.
    let prov = PerceptualProvenance::new("face_matcher_v2", "agent:camera_01");
    let ident = Identification::new(
        "ident:001",
        "scr://identity/person/craig_p",
        Confidence::heuristic(0.92),
        Uncertainty::Variance(0.02),
        prov,
    ).with_similarity(0.88);

    assert_eq!(ident.persistent_entity_id, "scr://identity/person/craig_p");
    assert_eq!(ident.appearance_similarity, Some(0.88));
    assert_ne!(ident.appearance_similarity.unwrap(), ident.confidence.value);
}

#[test]
fn test_inv_011_temporal_integrity() {
    // PERCEPTION-INV-011: Multi-clock distinction
    let mut temporal = TemporalIntegrity::new(100_000);
    temporal.event_time_ns = Some(95_000);
    temporal.simulation_time_ns = Some(120_000);
    temporal.processing_time_ns = Some(105_000);

    assert_ne!(temporal.observation_time_ns, temporal.event_time_ns.unwrap());
    assert_ne!(temporal.observation_time_ns, temporal.simulation_time_ns.unwrap());
    assert_ne!(temporal.observation_time_ns, temporal.processing_time_ns.unwrap());
}

#[test]
fn test_inv_023_019_nullary_relations_and_hypergraph_authority() {
    // PERCEPTION-INV-023: Nullary relations must be supported (|I(R)| = 0)
    // PERCEPTION-INV-019: Canonical hypergraph representation
    let mut rep = PerceptualRepresentation::empty("rep:global_scene");
    rep.nullary_assertions.push("PerceivedAmbientIlluminationLow".into());
    rep.nullary_assertions.push("GlobalPerceptualAnomalyDetected".into());

    let mut hg = Hypergraph::new();
    project_perception_to_hypergraph(&rep, &mut hg).expect("Projection should succeed");

    assert_eq!(hg.element_count(), 1); // 1 root representation element
    assert_eq!(hg.relation_count(), 2); // 2 nullary relations
    assert_eq!(hg.incidence_count(), 0); // Both nullary relations have |I(R)| = 0!
}

#[test]
fn test_inv_024_025_prediction_and_failure_integrity() {
    // PERCEPTION-INV-024: Predicted information != observed information
    let prov = PerceptualProvenance::new("kalman_tracker", "agent:radar");
    let track = Track::new("trk:001", "flying_object", prov)
        .with_observed_waypoint(1000, [0.0, 0.0, 10.0], Uncertainty::Certain)
        .with_observed_waypoint(2000, [1.0, 0.0, 10.0], Uncertainty::Certain)
        .with_predicted_waypoint(3000, [2.0, 0.0, 10.0], Uncertainty::Variance(0.5));

    assert_eq!(track.trajectory.len(), 3);
    assert!(!track.trajectory[0].is_predicted);
    assert!(!track.trajectory[1].is_predicted);
    assert!(track.trajectory[2].is_predicted);

    // PERCEPTION-INV-025: A failure must not silently become a valid observation
    let ctx = PerceptualContext::new("agent:observer", "anomaly_detection");
    let mut proc = PerceptualProcess::new(ctx, "faulty_transformer");

    let fail_result = proc.execute_transformation("fail_op", |_obs, _ctx, _k| {
        Err(PerceptionError::PerceptualFailure("Sensor disconnected".into()))
    });

    assert!(fail_result.is_err());
    match fail_result.err().unwrap() {
        PerceptionError::PerceptualFailure(msg) => {
            assert!(msg.contains("Sensor disconnected"));
        }
        _ => panic!("Expected PerceptualFailure"),
    }
}
