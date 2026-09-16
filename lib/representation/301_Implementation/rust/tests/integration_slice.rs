use scr_hypergraph::{
    Hypergraph, ElementId, RelationId, IncidenceId, Role, Direction,
};
use scr_representation::{
    HypergraphSerializer, TransportChannel, TransportAddress, EndpointId,
    Message, Envelope, Payload, MessageId, CorrelationId,
    PersistenceEngine, PersistentId,
};

/// End-to-end integration proving the complete vertical slice:
/// Semantic Hypergraph -> Serialization -> Transport -> Persistence -> Recovery -> Restoration
#[test]
fn test_end_to_end_representation_vertical_slice() {
    // ------------------------------------------------------------------------
    // Step 1: Instantiate Authoritative Semantic Hypergraph
    // ------------------------------------------------------------------------
    let mut original_hg = Hypergraph::new();

    let e_src = ElementId::new("node-sensor-01");
    let e_dst = ElementId::new("node-actuator-01");
    original_hg.create_element(e_src.clone(), "OpticalSensor").unwrap();
    original_hg.create_element(e_dst.clone(), "ServoActuator").unwrap();

    let r_control = RelationId::new("rel-feedback-loop");
    original_hg.create_relation(r_control.clone(), "FeedbackLoop").unwrap();
    original_hg.attach_incidence(
        IncidenceId::new("inc-sensor"),
        &e_src,
        &r_control,
        Role::Source,
        Direction::Outgoing,
    ).unwrap();
    original_hg.attach_incidence(
        IncidenceId::new("inc-actuator"),
        &e_dst,
        &r_control,
        Role::Target,
        Direction::Ingoing,
    ).unwrap();

    // Include a nullary relation (|I(R)| = 0) to ensure full HGT-001 preservation
    let r_ambient = RelationId::new("rel-ambient-temperature");
    original_hg.create_relation(r_ambient.clone(), "AmbientCondition").unwrap();

    assert_eq!(original_hg.element_count(), 2);
    assert_eq!(original_hg.relation_count(), 2);
    assert_eq!(original_hg.incidence_count(), 2);

    // ------------------------------------------------------------------------
    // Step 2: Serialization Domain (Canonical Deterministic Encoding)
    // ------------------------------------------------------------------------
    let serialized_bytes = HypergraphSerializer::to_bytes(&original_hg).unwrap();
    assert!(!serialized_bytes.is_empty());

    // ------------------------------------------------------------------------
    // Step 3: Transport Domain (Routing Across Computational Contexts)
    // ------------------------------------------------------------------------
    let mut channel = TransportChannel::new(TransportAddress::new("scr://cluster.node1"), 16);
    let ep_producer = EndpointId::new("ep-producer");
    let ep_consumer = EndpointId::new("ep-storage-node");

    channel.register_endpoint(ep_producer.clone());
    channel.register_endpoint(ep_consumer.clone());

    let msg_id = MessageId::new("msg-hg-state-v1");
    let envelope = Envelope::new(msg_id.clone(), ep_producer, ep_consumer.clone(), 100_000)
        .with_correlation(CorrelationId::new("job-42"))
        .with_header("payload-schema", "scr.representation.hypergraph");

    let message = Message::new(envelope, Payload::new(serialized_bytes));

    // Send across transport
    let send_receipt = channel.send(message).unwrap();
    assert_eq!(send_receipt.message_id, msg_id);

    // Receive at destination endpoint
    let received_message = channel.receive(&ep_consumer).unwrap().expect("Message delivered");
    assert_eq!(received_message.id(), &msg_id);

    // Acknowledge receipt
    let ack_receipt = channel.acknowledge(&msg_id).unwrap();
    assert!(ack_receipt.is_acknowledged());

    // ------------------------------------------------------------------------
    // Step 4: Persistence Domain (Atomic Commit Across Lifetime Boundaries)
    // ------------------------------------------------------------------------
    let mut persistence = PersistenceEngine::new();
    let persistent_id = PersistentId::new("persisted-hypergraph-state");

    // Take committed snapshot across SystemRestart boundary
    let commit_record = persistence.snapshot(
        persistent_id.clone(),
        1,
        received_message.payload.as_bytes().to_vec(),
    );
    assert_eq!(commit_record.id, persistent_id);

    // ------------------------------------------------------------------------
    // Step 5: Recovery and Restoration
    // ------------------------------------------------------------------------
    // Simulate host restart / recovery of raw bytes
    let restored_bytes = persistence.restore(&persistent_id).unwrap();

    // Deserialize recovered bytes back into Semantic Hypergraph
    let restored_hg = HypergraphSerializer::from_bytes(&restored_bytes).unwrap();

    // ------------------------------------------------------------------------
    // Step 6: Validate Equivalence
    // ------------------------------------------------------------------------
    assert_eq!(restored_hg.element_count(), original_hg.element_count());
    assert_eq!(restored_hg.relation_count(), original_hg.relation_count());
    assert_eq!(restored_hg.incidence_count(), original_hg.incidence_count());

    // Verify entities and relations
    assert!(restored_hg.get_element(&e_src).is_some());
    assert!(restored_hg.get_element(&e_dst).is_some());
    assert_eq!(restored_hg.get_element(&e_src).unwrap().name(), "OpticalSensor");

    let r_ctl_restored = restored_hg.get_relation(&r_control).unwrap();
    assert_eq!(r_ctl_restored.name(), "FeedbackLoop");
    assert_eq!(r_ctl_restored.cardinality(), 2);

    let r_amb_restored = restored_hg.get_relation(&r_ambient).unwrap();
    assert_eq!(r_amb_restored.name(), "AmbientCondition");
    assert!(r_amb_restored.is_nullary(), "Nullary relation preserved across entire vertical slice");

    let inc_sensor = restored_hg.get_incidence(&IncidenceId::new("inc-sensor")).unwrap();
    assert_eq!(inc_sensor.role(), &Role::Source);
    assert_eq!(inc_sensor.direction(), Direction::Outgoing);
}
