// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_math::{Quaternion, Vector};

#[test]
fn test_quaternion_so3_rotations() {
    // 90 degrees (pi / 2) rotation around Z axis [0, 0, 1]
    let z_axis = Vector::new(vec![0.0, 0.0, 1.0]);
    let q_rot_z_90 = Quaternion::from_axis_angle(&z_axis, std::f64::consts::PI / 2.0).unwrap();

    // Vector along X axis [1, 0, 0] rotated by 90 degrees around Z should become [0, 1, 0] along Y axis
    let v_x = Vector::new(vec![1.0, 0.0, 0.0]);
    let v_rotated = q_rot_z_90.rotate_vector(&v_x).unwrap();

    let x = v_rotated.get(0).unwrap();
    let y = v_rotated.get(1).unwrap();
    let z = v_rotated.get(2).unwrap();

    assert!(x.abs() < 1e-10);
    assert!((y - 1.0).abs() < 1e-10);
    assert!(z.abs() < 1e-10);

    // Rotating by 360 degrees (2*pi) returns to original vector
    let q_rot_360 = Quaternion::from_axis_angle(&z_axis, 2.0 * std::f64::consts::PI).unwrap();
    let v_full_turn = q_rot_360.rotate_vector(&v_x).unwrap();
    assert!((v_full_turn.get(0).unwrap() - 1.0).abs() < 1e-10);
    assert!(v_full_turn.get(1).unwrap().abs() < 1e-10);
    assert!(v_full_turn.get(2).unwrap().abs() < 1e-10);
}
