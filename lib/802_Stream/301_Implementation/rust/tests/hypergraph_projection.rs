// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_hypergraph::{Hypergraph, RelationId};
use scr_stream::{
    project_stream_to_hypergraph, AvailabilityStatus, ElementPayload, OccurrenceRecord,
    OrderingSemantics, ProvenanceRecord, SemanticStream, StreamElement, StreamElementId,
    StreamKind, StreamState, VectorClock,
};

#[test]
fn test_hypergraph_stream_projection_and_nullary_relations() {
    let mut stream = SemanticStream::new("iot_telemetry", StreamKind::Observation, OrderingSemantics::Causal);
    stream.lifecycle.transition_to(StreamState::Active).unwrap();

    let elem = StreamElement::new(
        StreamElementId::new("reading-101"),
        "TemperatureReading",
        ElementPayload::Scalar(21.5),
        ProvenanceRecord::root("temp_sensor_01"),
    );

    let occ = OccurrenceRecord::new(5000)
        .with_observed(5010).unwrap()
        .with_published(5020).unwrap();

    let avail = AvailabilityStatus::Available {
        available_from: 5020,
        valid_until: None,
    };

    let mut vc = VectorClock::new();
    vc.increment("sensor_01");

    stream.append_element(elem, occ, avail, vc).unwrap();

    let mut hg = Hypergraph::new();
    project_stream_to_hypergraph(&stream, &mut hg).unwrap();

    // Verify stream element node
    let stream_node = hg.get_element(&scr_hypergraph::ElementId("elem:stream:iot_telemetry".into()));
    assert!(stream_node.is_some());

    // Verify element node
    let elem_node = hg.get_element(&scr_hypergraph::ElementId("elem:stream_elem:reading-101".into()));
    assert!(elem_node.is_some());

    // Verify membership relation
    let mem_rel = hg.get_relation(&RelationId("rel:stream_membership:iot_telemetry_reading-101".into()));
    assert!(mem_rel.is_some());

    // Verify ambient nullary relation (STREAM-INV-017)
    let nullary_rel = hg.get_relation(&RelationId("rel:ambient_stream_axiom:iot_telemetry".into())).unwrap();
    assert!(nullary_rel.is_nullary());
    assert_eq!(nullary_rel.cardinality(), 0);
}
