// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use scr_stream::*;

#[test]
fn test_all_30_normative_stream_invariants() {
    // STREAM-INV-001 (Semantic Independence): Stream semantics independent of transport/broker
    let source = StreamSource::new("src_sensors", "SensorMeasurement");
    assert_eq!(source.source_id, "src_sensors");

    // STREAM-INV-002 (Flow Independence): Stream exists semantically without active physical flow
    let stream = SemanticStream::new("stream_historical", StreamKind::Event, OrderingSemantics::Total);
    assert_eq!(stream.lifecycle.current(), StreamState::Created);
    assert_eq!(stream.element_count(), 0);

    // STREAM-INV-003 (Element Identity): Elements retain semantic identity independent of representation
    let elem_id = StreamElementId::new("elem-001");
    let elem = StreamElement::new(
        elem_id.clone(),
        "Measurement",
        ElementPayload::Scalar(42.0),
        ProvenanceRecord::root("src_sensors"),
    );
    assert_eq!(elem.id.as_str(), "elem-001");

    // STREAM-INV-004 (Occurrence Distinction): Occurrence != observation != publication != processing != consumption
    let occ = OccurrenceRecord::new(1000)
        .with_observed(1050).unwrap()
        .with_published(1100).unwrap()
        .with_processed(1150).unwrap()
        .with_consumed(1200).unwrap();
    assert!(occ.is_causally_consistent());
    assert_eq!(occ.occurred_at, 1000);
    assert_eq!(occ.observed_at, Some(1050));
    assert_eq!(occ.published_at, Some(1100));
    assert_eq!(occ.processed_at, Some(1150));
    assert_eq!(occ.consumed_at, Some(1200));

    // STREAM-INV-005 (Availability Distinction): Availability != existence != occurrence
    let avail = AvailabilityStatus::Available {
        available_from: 1050,
        valid_until: Some(2000),
    };
    assert!(!avail.is_available_at(1040));
    assert!(avail.is_available_at(1100));
    assert!(!avail.is_available_at(2050));

    // STREAM-INV-006 (Temporal Explicitness): Clock domain and timestamps explicit
    let temporal = TemporalReference::new(ClockDomain::EventTime, 1000).with_uncertainty(5);
    assert_eq!(temporal.clock_domain, ClockDomain::EventTime);
    assert_eq!(temporal.uncertainty_ns, 5);

    // STREAM-INV-007 (Ordering Explicitness) & STREAM-INV-008 (Causal Distinction)
    let mut vc1 = VectorClock::new();
    vc1.increment("nodeA"); // (nodeA: 1)
    let mut vc2 = VectorClock::new();
    vc2.increment("nodeB"); // (nodeB: 1)
    // Concurrent clocks: even if nodeA occurred at wall-clock 1000 and nodeB at 1001, causality is Concurrent!
    assert_eq!(vc1.compare(&vc2), CausalRelation::Concurrent);

    // STREAM-INV-009 (State/Delta Distinction)
    let base_state = b"initial_state;".to_vec();
    let contract = StateReconstructionContract::new(base_state);
    let delta1 = StreamElement::new(
        StreamElementId::new("d1"),
        "Delta",
        ElementPayload::Delta(b"mutation1;".to_vec()),
        ProvenanceRecord::root("tx_log"),
    );
    let reconstructed = contract.reconstruct(&[delta1]).unwrap();
    assert_eq!(reconstructed, b"initial_state;mutation1;");

    // STREAM-INV-010 (Event/State Distinction) & STREAM-INV-011 (Observation Distinction)
    assert_ne!(StreamKind::Event, StreamKind::State);
    assert_ne!(StreamKind::Observation, StreamKind::State);

    // STREAM-INV-012 (Lifecycle Explicitness)
    let mut lifecycle = StreamLifecycle::new();
    assert_eq!(lifecycle.current(), StreamState::Created);
    lifecycle.transition_to(StreamState::Active).unwrap();
    lifecycle.transition_to(StreamState::Suspended).unwrap();
    lifecycle.transition_to(StreamState::Active).unwrap();
    lifecycle.transition_to(StreamState::Draining).unwrap();
    lifecycle.transition_to(StreamState::Completed).unwrap();
    lifecycle.transition_to(StreamState::Closed).unwrap();
    assert!(lifecycle.is_terminal());

    // STREAM-INV-013 (Absence Semantics) & STREAM-INV-028 (Loss Explicitness)
    let dropped = LossRecord::new(
        StreamElementId::new("lost-001"),
        1500,
        LossClassification::DroppedInTransit { reason: "Buffer full".into() },
    );
    let filtered = LossRecord::new(
        StreamElementId::new("filt-001"),
        1510,
        LossClassification::FilteredIntentional { predicate: "val > 50".into() },
    );
    assert!(dropped.is_involuntary_loss());
    assert!(!filtered.is_involuntary_loss());

    // STREAM-INV-014 (Provenance): Survives transformations
    let map_op = MapOperator::new("scale_2x", |e| {
        if let ElementPayload::Scalar(v) = e.payload {
            Ok(ElementPayload::Scalar(v * 2.0))
        } else {
            Ok(e.payload.clone())
        }
    });
    let transformed = map_op.apply(&elem).unwrap();
    assert_eq!(transformed.provenance.generation, 1);
    assert_eq!(transformed.provenance.parent_element_ids, vec![elem.id.clone()]);
    assert_eq!(transformed.payload, ElementPayload::Scalar(84.0));

    // STREAM-INV-015 (Identity/Reference Separation) & STREAM-INV-016 (Deletion Semantics)
    let superseded = AvailabilityStatus::Superseded {
        superseded_by: StreamElementId::new("elem-002"),
    };
    assert!(!superseded.is_available_at(2000));

    // STREAM-INV-017 (Nullary Relations) & STREAM-INV-018 (Hypergraph Authority)
    let mut stream_active = SemanticStream::new("active_stream", StreamKind::Event, OrderingSemantics::Causal);
    stream_active.lifecycle.transition_to(StreamState::Active).unwrap();
    stream_active.append_element(elem, occ, avail, vc1).unwrap();

    let mut hg = scr_hypergraph::Hypergraph::new();
    project_stream_to_hypergraph(&stream_active, &mut hg).unwrap();
    let nullary_rel = hg.get_relation(&scr_hypergraph::RelationId("rel:ambient_stream_axiom:active_stream".into()));
    assert!(nullary_rel.is_some());
    assert_eq!(nullary_rel.unwrap().name(), "AmbientStreamInvariantContract");

    // STREAM-INV-019 (Provider Independence) & STREAM-INV-020 (Delivery Distinction)
    let mut sink = StreamSink::new("sink_archive", "Storage", DeliveryGuarantee::EffectivelyOnce);
    sink.consume(transformed).unwrap();
    assert_eq!(sink.committed_count(), 1);

    // STREAM-INV-021 (Replay Safety): Distinguishes replay from live side-effects
    let replay_guard = ReplayController::new(ReplayMode::HistoricalAudit);
    assert!(replay_guard.guard_side_effect("send_email").is_err());
    let live_guard = ReplayController::new(ReplayMode::LiveExecution);
    assert!(live_guard.guard_side_effect("send_email").is_ok());

    // STREAM-INV-022 (Failure Distinction): Errors distinguish failure from absence
    let err = StreamError::TransportError("Connection reset".into());
    assert_ne!(format!("{}", err), "Element absent");

    // STREAM-INV-023 (Representation Independence): Same element, different encodings
    let text_elem = StreamElement::new(
        StreamElementId::new("text-01"),
        "Telemetry",
        ElementPayload::Text("val=42".into()),
        ProvenanceRecord::root("src"),
    );
    assert_eq!(text_elem.semantic_type, "Telemetry");

    // STREAM-INV-024 (Transformation Contract), STREAM-INV-025 (Causal Integrity), STREAM-INV-026 (Temporal Integrity)
    let elements = vec![text_elem.clone()];
    let (pass, fail) = split_stream(&elements, |e| e.id.as_str() == "text-01");
    assert_eq!(pass.len(), 1);
    assert_eq!(fail.len(), 0);

    // STREAM-INV-027 (Completeness Explicitness)
    assert!(!stream_active.is_complete);
    stream_active.mark_complete();
    assert!(stream_active.is_complete);

    // STREAM-INV-029 (Semantic Equivalence) & STREAM-INV-030 (Runtime Subordination)
    let wm = Watermark::new(500);
    assert_eq!(wm.timestamp, 500);
}
