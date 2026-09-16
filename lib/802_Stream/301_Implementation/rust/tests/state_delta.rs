// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_stream::{
    ElementPayload, ProvenanceRecord, StateReconstructionContract, StreamElement, StreamElementId,
};

#[test]
fn test_state_reconstruction_from_deltas() {
    let base = b"state_v0;".to_vec();
    let contract = StateReconstructionContract::new(base);

    let deltas = vec![
        StreamElement::new(
            StreamElementId::new("d1"),
            "Delta",
            ElementPayload::Delta(b"action_insert;".to_vec()),
            ProvenanceRecord::root("db_log"),
        ),
        StreamElement::new(
            StreamElementId::new("d2"),
            "Delta",
            ElementPayload::Delta(b"action_update;".to_vec()),
            ProvenanceRecord::root("db_log"),
        ),
    ];

    let reconstructed = contract.reconstruct(&deltas).unwrap();
    assert_eq!(reconstructed, b"state_v0;action_insert;action_update;");
}
