use scr_field::domain::FieldDomain;
use scr_field::level_set::{create_sphere_sdf, intersect_sdf, union_sdf, LevelSet};

#[test]
fn test_sphere_signed_distance_field_and_normals() {
    let domain = FieldDomain::new_3d("dom_sdf", -10.0, 10.0, -10.0, 10.0, -10.0, 10.0).unwrap();
    let sphere = create_sphere_sdf("sphere_5", [0.0, 0.0, 0.0], 5.0, domain);
    let level_set = LevelSet::new(sphere, 0.0).unwrap();

    // Inside sphere: distance is negative
    let d_inside = level_set.evaluate_distance(&[0.0, 0.0, 0.0]).unwrap();
    assert!((d_inside - (-5.0)).abs() < 1e-6);
    assert!(level_set.is_inside(&[0.0, 0.0, 0.0]).unwrap());

    // On surface: distance is zero
    let d_surface = level_set.evaluate_distance(&[5.0, 0.0, 0.0]).unwrap();
    assert!(d_surface.abs() < 1e-6);
    assert!(level_set.is_on_surface(&[5.0, 0.0, 0.0], 1e-4).unwrap());

    // Outside sphere: distance is positive
    let d_outside = level_set.evaluate_distance(&[8.0, 0.0, 0.0]).unwrap();
    assert!((d_outside - 3.0).abs() < 1e-6);
    assert!(!level_set.is_inside(&[8.0, 0.0, 0.0]).unwrap());

    // Outward unit normal at (5, 0, 0) should be (1, 0, 0)
    let normal = level_set.compute_surface_normal(&[5.0, 0.0, 0.0]).unwrap();
    assert!((normal[0] - 1.0).abs() < 1e-3, "Normal X = {}", normal[0]);
    assert!(normal[1].abs() < 1e-3, "Normal Y = {}", normal[1]);
    assert!(normal[2].abs() < 1e-3, "Normal Z = {}", normal[2]);
}

#[test]
fn test_csg_boolean_union_and_intersection() {
    let domain = FieldDomain::new_3d("dom_csg", -10.0, 10.0, -10.0, 10.0, -10.0, 10.0).unwrap();

    // Sphere A: center (-2, 0, 0), radius 3
    let s_a = create_sphere_sdf("sphere_a", [-2.0, 0.0, 0.0], 3.0, domain.clone());
    // Sphere B: center (+2, 0, 0), radius 3
    let s_b = create_sphere_sdf("sphere_b", [2.0, 0.0, 0.0], 3.0, domain);

    // Union: point inside either sphere is inside union
    let u = union_sdf(&s_a, &s_b).unwrap();
    let ls_u = LevelSet::new(u, 0.0).unwrap();
    assert!(ls_u.is_inside(&[-2.0, 0.0, 0.0]).unwrap());
    assert!(ls_u.is_inside(&[2.0, 0.0, 0.0]).unwrap());
    // (0, 0, 0) is dist 2 from both centers, radius is 3 -> dist = 2 - 3 = -1 (inside)
    assert!(ls_u.is_inside(&[0.0, 0.0, 0.0]).unwrap());
    // (10, 0, 0) is outside
    assert!(!ls_u.is_inside(&[10.0, 0.0, 0.0]).unwrap());

    // Intersection: point must be inside both spheres
    let inter = intersect_sdf(&s_a, &s_b).unwrap();
    let ls_inter = LevelSet::new(inter, 0.0).unwrap();
    assert!(ls_inter.is_inside(&[0.0, 0.0, 0.0]).unwrap());
    // (-4, 0, 0) is inside A (dist = |-4 - -2| = 2 < 3), but outside B (dist = |-4 - 2| = 6 > 3)
    assert!(!ls_inter.is_inside(&[-4.0, 0.0, 0.0]).unwrap());
}
