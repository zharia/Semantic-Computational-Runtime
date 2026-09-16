use scr_identity::coordinate::{CoordinateRegion, GlobalIdentity, SidCoordinate};

#[test]
fn test_coordinate_128bit_packing_roundtrip() {
    let domain_id = 0x1234_5678_9abc_def0_u64;
    let index = 0x4242_1337_u32;
    let generation = 0x0000_0007_u32;

    let coord = SidCoordinate::new(domain_id, index, generation);
    let packed = coord.to_u128();

    let unpacked = SidCoordinate::from_u128(packed);
    assert_eq!(coord, unpacked);
    assert_eq!(unpacked.domain_id, domain_id);
    assert_eq!(unpacked.index, index);
    assert_eq!(unpacked.generation, generation);

    let bytes = coord.to_bytes();
    let from_bytes = SidCoordinate::from_bytes(bytes);
    assert_eq!(coord, from_bytes);
}

#[test]
fn test_coordinate_uri_roundtrip() {
    let root_id = "root-us-east-1";
    let coord = SidCoordinate::new(1001, 42, 3);

    let uri = coord.to_uri(root_id);
    assert_eq!(uri, "sid://root-us-east-1/1001/42?gen=3");

    let (parsed_root, parsed_coord) = SidCoordinate::from_uri(&uri).expect("Failed to parse URI");
    assert_eq!(parsed_root, root_id);
    assert_eq!(parsed_coord, coord);
}

#[test]
fn test_multi_root_scoped_identity_model_b() {
    // Under Rule IAM-R019, roots are external contexts and do NOT contaminate coordinate bits.
    let root_a = "auth-root-alpha";
    let root_b = "auth-root-beta";

    let coord = SidCoordinate::new(5, 10, 1);

    let gid_a = GlobalIdentity::new(root_a, coord);
    let gid_b = GlobalIdentity::new(root_b, coord);

    // Identical coordinate values across distinct roots
    assert_eq!(gid_a.coordinate, gid_b.coordinate);
    // Distinct global identities
    assert_ne!(gid_a, gid_b);
    assert_eq!(gid_a.to_uri(), "sid://auth-root-alpha/5/10?gen=1");
    assert_eq!(gid_b.to_uri(), "sid://auth-root-beta/5/10?gen=1");
}

#[test]
fn test_coordinate_region_geometry() {
    let parent_reg = CoordinateRegion::new(0, 1000).unwrap();
    let child_a = CoordinateRegion::new(0, 500).unwrap();
    let child_b = CoordinateRegion::new(500, 1000).unwrap();
    let overlapping_reg = CoordinateRegion::new(400, 600).unwrap();

    // Containment
    assert!(child_a.is_subset_of(&parent_reg));
    assert!(child_b.is_subset_of(&parent_reg));
    assert!(!parent_reg.is_subset_of(&child_a));

    // Disjointness
    assert!(!child_a.overlaps(&child_b));
    assert!(child_a.overlaps(&overlapping_reg));
    assert!(child_b.overlaps(&overlapping_reg));

    // Intersection
    assert_eq!(child_a.intersection(&child_b), None);
    let inter = child_a.intersection(&overlapping_reg).unwrap();
    assert_eq!(inter, CoordinateRegion::new(400, 500).unwrap());

    // Coordinate point containment
    assert!(child_a.contains(0));
    assert!(child_a.contains(499));
    assert!(!child_a.contains(500));
}
