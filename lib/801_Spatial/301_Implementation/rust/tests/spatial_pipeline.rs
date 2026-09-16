use scr_hypergraph::Hypergraph;
use scr_spatial::*;

#[test]
fn test_end_to_end_spatial_pipeline() {
    // 1. Spatial Domain D (Section 1)
    let domain = SpatialDomain::new(
        "dom:robotics_lab",
        SpatialDomainKind::ContinuousEuclidean,
        Dimensionality::Dim3D,
    )
    .with_description("3D continuous indoor robotic space");

    // 2. Reference Frames C (Section 4)
    let world_frame = ReferenceFrame::new(
        "frame:world",
        &domain.id,
        CoordinateSystem::Cartesian3D,
    );
    let robot_frame = ReferenceFrame::new(
        "frame:robot_base",
        &domain.id,
        CoordinateSystem::Cartesian3D,
    )
    .with_parent("frame:world", vec![2.0, 3.0, 0.0]);

    // 3. Positions P (Section 2)
    let pos_dock = Position::new(
        "scr://facilities/docking_station",
        Coordinates::new(&world_frame.id, vec![0.0, 0.0, 0.0]),
    )
    .with_landmark("HomeBase");

    let pos_robot = Position::new(
        "scr://agents/mobile_robot_01",
        Coordinates::new(&world_frame.id, vec![2.0, 3.0, 0.0]),
    );

    let pos_obstacle = Position::new(
        "scr://obstacles/crate_44",
        Coordinates::new(&world_frame.id, vec![2.5, 3.5, 0.0]),
    );

    // 4. Metrics & Distances M (Section 9)
    let dist_robot_dock = compute_distance(
        &pos_robot.coordinates,
        &pos_dock.coordinates,
        DistanceMetric::Euclidean,
    )
    .expect("Euclidean distance computation must succeed");
    // sqrt(2^2 + 3^2) = sqrt(13) ~ 3.6055
    assert!((dist_robot_dock.value - 3.60555).abs() < 1e-4);

    // 5. Spatial Regions R (Section 6)
    let lab_bounds = BoundingBox::new(vec![-5.0, -5.0, 0.0], vec![5.0, 5.0, 3.0]);
    assert!(lab_bounds.contains_point(&pos_robot.coordinates.values));

    // 6. Spatial Transformation X (Section 20)
    // Transform from world to robot base: T(p) = p - [2, 3, 0]
    let transform_to_robot = SpatialTransform::translation(
        "tf:world_to_robot",
        &world_frame.id,
        &robot_frame.id,
        vec![-2.0, -3.0, 0.0],
    );
    let obs_in_robot_frame = transform_to_robot
        .apply(&pos_obstacle.coordinates)
        .expect("Frame transformation must succeed");
    assert_eq!(obs_in_robot_frame.reference_frame_id, robot_frame.id);
    assert_eq!(obs_in_robot_frame.values, vec![0.5, 0.5, 0.0]);

    // 7. Spatial Query Q (Section 15)
    let candidates = vec![pos_dock.clone(), pos_robot.clone(), pos_obstacle.clone()];
    let proximity_query = SpatialQuery::WithinRadius {
        center: pos_robot.coordinates.clone(),
        radius: 1.0,
        metric: DistanceMetric::Euclidean,
    };
    let near_robot = proximity_query.evaluate(&candidates).unwrap();
    // pos_robot itself (dist 0) and pos_obstacle (dist sqrt(0.5^2 + 0.5^2) = sqrt(0.5) ~ 0.707)
    assert_eq!(near_robot.len(), 2);

    // 8. Dynamic Spatial Trajectory (Section 25)
    let mut robot_dyn = DynamicSpatialState::new(
        &pos_robot.entity_uri,
        pos_robot.clone(),
        1_700_000_000,
    );
    robot_dyn.record_waypoint(1_700_000_100, Coordinates::new(&world_frame.id, vec![2.1, 3.1, 0.0]));
    robot_dyn.record_waypoint(1_700_000_200, Coordinates::new(&world_frame.id, vec![2.2, 3.2, 0.0]));
    assert_eq!(robot_dyn.trajectory.len(), 2);

    // 9. Canonical Hypergraph Projection (Section 33)
    let mut hypergraph = Hypergraph::new();
    let nullary_assertions = vec!["ContinuousCoordinateTrackingCalibrated".into()];

    project_spatial_relationship_to_hypergraph(
        "rel:spatial_proximity",
        &pos_robot,
        &pos_obstacle,
        SpatialRelationship::Adjacent,
        &nullary_assertions,
        &mut hypergraph,
    )
    .expect("Projection to canonical hypergraph must succeed");

    assert_eq!(hypergraph.element_count(), 2);
    assert_eq!(hypergraph.relation_count(), 2); // 1 spatial relation + 1 nullary relation
    assert_eq!(hypergraph.incidence_count(), 2);
}
