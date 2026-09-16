use scr_hypergraph::Hypergraph;
use scr_spatial::*;

#[test]
fn test_inv_002_003_reference_explicitness_and_dimensionality() {
    // SPATIAL-INV-002: Coordinates must be interpreted within an explicit declared reference frame.
    // SPATIAL-INV-003: Dimensionality must be semantically explicit.
    let domain_3d = SpatialDomain::new(
        "dom:euclidean3d",
        SpatialDomainKind::ContinuousEuclidean,
        Dimensionality::Dim3D,
    );
    assert_eq!(domain_3d.dimensionality.dimensions(), 3);

    let frame = ReferenceFrame::new(
        "frame:local_base",
        &domain_3d.id,
        CoordinateSystem::Cartesian3D,
    );
    assert_eq!(frame.coordinate_system, CoordinateSystem::Cartesian3D);

    let coords = Coordinates::new(&frame.id, vec![1.0, 2.0, 3.0]);
    assert_eq!(coords.dim(), 3);
    assert_eq!(coords.as_3d().unwrap(), [1.0, 2.0, 3.0]);

    // 2D access on 3D coordinates must fail explicitly
    assert!(coords.as_2d().is_err());
}

#[test]
fn test_inv_004_position_distinction() {
    // SPATIAL-INV-004: Position must remain distinguishable from its coordinate representation.
    let coords_cartesian = Coordinates::new("frame:local", vec![10.0, 20.0, 0.0]);
    let position = Position::new("scr://entities/drone-01", coords_cartesian)
        .with_landmark("Helipad-Alpha");

    assert_eq!(position.entity_uri, "scr://entities/drone-01");
    assert_eq!(position.landmark_label, Some("Helipad-Alpha".into()));
    assert_eq!(position.coordinates.values, vec![10.0, 20.0, 0.0]);
}

#[test]
fn test_inv_006_metric_integrity() {
    // SPATIAL-INV-006: Distance semantics must retain the metric from which they derive.
    let c1 = Coordinates::new("frame:grid", vec![0.0, 0.0]);
    let c2 = Coordinates::new("frame:grid", vec![3.0, 4.0]);

    // Euclidean: sqrt(3^2 + 4^2) = 5.0
    let dist_euc = compute_distance(&c1, &c2, DistanceMetric::Euclidean).unwrap();
    assert_eq!(dist_euc.metric, DistanceMetric::Euclidean);
    assert!((dist_euc.value - 5.0).abs() < 1e-6);

    // Manhattan: 3 + 4 = 7.0
    let dist_man = compute_distance(&c1, &c2, DistanceMetric::Manhattan).unwrap();
    assert_eq!(dist_man.metric, DistanceMetric::Manhattan);
    assert!((dist_man.value - 7.0).abs() < 1e-6);

    // Chebyshev: max(3, 4) = 4.0
    let dist_cheb = compute_distance(&c1, &c2, DistanceMetric::Chebyshev).unwrap();
    assert_eq!(dist_cheb.metric, DistanceMetric::Chebyshev);
    assert!((dist_cheb.value - 4.0).abs() < 1e-6);

    // Cross-frame distance must fail with IncompatibleReferenceFrame
    let c_other = Coordinates::new("frame:other", vec![3.0, 4.0]);
    let fail_res = compute_distance(&c1, &c_other, DistanceMetric::Euclidean);
    assert!(fail_res.is_err());
    match fail_res.err().unwrap() {
        SpatialError::IncompatibleReferenceFrame { source_frame, target_frame } => {
            assert_eq!(source_frame, "frame:grid");
            assert_eq!(target_frame, "frame:other");
        }
        _ => panic!("Expected IncompatibleReferenceFrame"),
    }
}

#[test]
fn test_inv_011_temporal_explicitness_and_trajectories() {
    // SPATIAL-INV-011: Dynamic spatial state must remain distinguishable from static representation.
    let initial_pos = Position::new(
        "scr://entities/satellite-01",
        Coordinates::new("frame:eci", vec![7000.0, 0.0, 0.0]),
    );

    let velocity = SpatialVelocity {
        reference_frame_id: "frame:eci".into(),
        linear: vec![0.0, 7.5, 0.0],
        angular: None,
    };

    let mut dyn_state = DynamicSpatialState::new(
        "scr://entities/satellite-01",
        initial_pos,
        1_000_000_000,
    ).with_velocity(velocity);

    dyn_state.record_waypoint(1_000_001_000, Coordinates::new("frame:eci", vec![7000.0, 7.5, 0.0]));
    dyn_state.record_waypoint(1_000_002_000, Coordinates::new("frame:eci", vec![6999.0, 15.0, 0.0]));

    assert_eq!(dyn_state.trajectory.len(), 2);
    assert_eq!(dyn_state.timestamp_ns, 1_000_002_000);
    assert!(dyn_state.velocity.is_some());
}

#[test]
fn test_inv_012_transformation_integrity() {
    // SPATIAL-INV-012: Spatial transformations must explicitly identify source and target contexts.
    let transform = SpatialTransform::translation(
        "tf:base_to_sensor",
        "frame:base",
        "frame:sensor",
        vec![0.5, 0.2, 1.2],
    );

    let pt_base = Coordinates::new("frame:base", vec![1.0, 1.0, 1.0]);
    let pt_sensor = transform.apply(&pt_base).expect("Transform should succeed");

    assert_eq!(pt_sensor.reference_frame_id, "frame:sensor");
    assert_eq!(pt_sensor.values, vec![1.5, 1.2, 2.2]);

    // Applying to wrong frame must error
    let pt_wrong = Coordinates::new("frame:world", vec![1.0, 1.0, 1.0]);
    assert!(transform.apply(&pt_wrong).is_err());
}

#[test]
fn test_inv_014_index_independence_and_spatial_queries() {
    // SPATIAL-INV-014: Spatial index is an implementation mechanism, not spatial truth.
    // Query semantics evaluate faithfully over candidates.
    let center = Coordinates::new("frame:world", vec![0.0, 0.0]);
    let p1 = Position::new("p1", Coordinates::new("frame:world", vec![1.0, 1.0])); // dist = sqrt(2) ~ 1.414
    let p2 = Position::new("p2", Coordinates::new("frame:world", vec![3.0, 3.0])); // dist = sqrt(18) ~ 4.242
    let p3 = Position::new("p3", Coordinates::new("frame:world", vec![0.5, 0.5])); // dist = sqrt(0.5) ~ 0.707

    let candidates = vec![p1, p2, p3];

    let query_radius = SpatialQuery::WithinRadius {
        center: center.clone(),
        radius: 2.0,
        metric: DistanceMetric::Euclidean,
    };
    let results = query_radius.evaluate(&candidates).unwrap();
    assert_eq!(results.len(), 2);
    assert_eq!(results[0].entity_uri, "p1");
    assert_eq!(results[1].entity_uri, "p3");

    let query_knn = SpatialQuery::KNearestNeighbors {
        center,
        k: 2,
        metric: DistanceMetric::Euclidean,
    };
    let knn_results = query_knn.evaluate(&candidates).unwrap();
    assert_eq!(knn_results.len(), 2);
    assert_eq!(knn_results[0].entity_uri, "p3"); // closest (0.707)
    assert_eq!(knn_results[1].entity_uri, "p1"); // second closest (1.414)
}

#[test]
fn test_inv_015_uncertainty_preservation() {
    // SPATIAL-INV-015: Declared spatial uncertainty must not be silently discarded.
    let u_certain = SpatialUncertainty::Certain;
    assert!(u_certain.is_certain());

    let u_radius = SpatialUncertainty::ErrorRadius(2.5);
    assert!(!u_radius.is_certain());

    let cov = vec![
        vec![0.1, 0.0],
        vec![0.0, 0.1],
    ];
    let u_cov = SpatialUncertainty::Covariance(cov);
    assert!(!u_cov.is_certain());
}

#[test]
fn test_hypergraph_projection_with_nullary_relations() {
    // Canonical hypergraph projection and nullary relations
    let p_src = Position::new(
        "scr://buildings/library",
        Coordinates::new("frame:campus", vec![100.0, 50.0]),
    );
    let p_tgt = Position::new(
        "scr://buildings/laboratory",
        Coordinates::new("frame:campus", vec![120.0, 50.0]),
    );

    let nullary_assertions = vec![
        "SpatialContinuumHomogeneous".into(),
        "ReferenceFrameCalibrated".into(),
    ];

    let mut hg = Hypergraph::new();
    project_spatial_relationship_to_hypergraph(
        "rel:spatial_01",
        &p_src,
        &p_tgt,
        SpatialRelationship::Adjacent,
        &nullary_assertions,
        &mut hg,
    )
    .expect("Hypergraph projection must succeed");

    // Elements: 2 position elements
    assert_eq!(hg.element_count(), 2);
    // Relations: 1 Spatial relationship + 2 Nullary relations = 3 relations
    assert_eq!(hg.relation_count(), 3);
    // Incidences: 2 directed incidences on the spatial relation; 0 on nullary relations
    assert_eq!(hg.incidence_count(), 2);
}
