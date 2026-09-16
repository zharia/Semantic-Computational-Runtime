// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_stream::{CausalRelation, VectorClock};

#[test]
fn test_vector_clock_causality_and_concurrency() {
    let mut v1 = VectorClock::new();
    let mut v2 = VectorClock::new();

    // Initially equal
    assert_eq!(v1.compare(&v2), CausalRelation::Equal);

    // v1 advances: v1 = { A: 1 }
    v1.increment("A");
    assert_eq!(v1.compare(&v2), CausalRelation::Succeeds);
    assert_eq!(v2.compare(&v1), CausalRelation::Precedes);

    // v2 advances independently: v2 = { B: 1 }
    v2.increment("B");
    assert_eq!(v1.compare(&v2), CausalRelation::Concurrent);
    assert_eq!(v2.compare(&v1), CausalRelation::Concurrent);

    // Message sent from v1 to v2: v2 merges v1
    v2.merge(&v1); // v2 = { A: 1, B: 1 }
    v2.increment("B"); // v2 = { A: 1, B: 2 }
    assert_eq!(v2.compare(&v1), CausalRelation::Succeeds);
    assert_eq!(v1.compare(&v2), CausalRelation::Precedes);
}
