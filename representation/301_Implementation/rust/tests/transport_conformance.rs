use scr_representation::{
    EndpointId, TransportAddress, Message, Envelope, Payload, MessageId,
    CorrelationId, TransportChannel, DeliveryState, RepresentationError,
    validate_transition,
};

#[test]
fn test_transport_message_envelope_creation() {
    let src = EndpointId::new("runtime.node-1");
    let dst = EndpointId::new("runtime.node-2");
    let msg_id = MessageId::new("msg-1001");
    let corr_id = CorrelationId::new("corr-555");

    let envelope = Envelope::new(msg_id.clone(), src.clone(), dst.clone(), 1_000_000)
        .with_correlation(corr_id.clone())
        .with_header("content-type", "application/scr-canonical");

    let payload = Payload::new(b"Semantic Payload Data".to_vec());
    let message = Message::new(envelope, payload);

    assert_eq!(message.id(), &msg_id);
    assert_eq!(message.envelope.source, src);
    assert_eq!(message.envelope.destination, dst);
    assert_eq!(message.envelope.correlation_id, Some(corr_id));
    assert_eq!(message.envelope.headers.get("content-type").unwrap(), "application/scr-canonical");
    assert_eq!(message.payload.as_bytes(), b"Semantic Payload Data");
}

#[test]
fn test_transport_delivery_lifecycle_and_acknowledgement() {
    let mut channel = TransportChannel::new(TransportAddress::new("scr://bus.local"), 10);
    let src = EndpointId::new("node-A");
    let dst = EndpointId::new("node-B");

    channel.register_endpoint(src.clone());
    channel.register_endpoint(dst.clone());

    let msg_id = MessageId::new("msg-2001");
    let envelope = Envelope::new(msg_id.clone(), src, dst.clone(), 1_000);
    let payload = Payload::new(vec![1, 2, 3, 4]);
    let message = Message::new(envelope, payload);

    // 1. Send
    let receipt = channel.send(message).unwrap();
    assert_eq!(receipt.state, DeliveryState::Delivered);
    assert_eq!(channel.get_message_state(&msg_id), Some(&DeliveryState::Delivered));

    // 2. Receive / Consume
    let consumed_msg = channel.receive(&dst).unwrap().expect("Message should be queued");
    assert_eq!(consumed_msg.id(), &msg_id);
    assert_eq!(channel.get_message_state(&msg_id), Some(&DeliveryState::Consumed));

    // 3. Acknowledge
    let ack_receipt = channel.acknowledge(&msg_id).unwrap();
    assert!(ack_receipt.is_acknowledged());
    assert_eq!(channel.get_message_state(&msg_id), Some(&DeliveryState::Acknowledged));
}

#[test]
fn test_transport_deduplication_and_idempotence() {
    let mut channel = TransportChannel::new(TransportAddress::new("scr://bus.local"), 10);
    let src = EndpointId::new("node-1");
    let dst = EndpointId::new("node-2");
    channel.register_endpoint(dst.clone());

    let msg_id = MessageId::new("msg-dedup-test");
    let msg1 = Message::new(
        Envelope::new(msg_id.clone(), src.clone(), dst.clone(), 1_000),
        Payload::new(vec![10, 20]),
    );
    let msg2 = Message::new(
        Envelope::new(msg_id.clone(), src, dst, 1_001),
        Payload::new(vec![10, 20]),
    );

    // First send succeeds
    assert!(channel.send(msg1).is_ok());

    // Second send with same ID must be rejected as duplicate
    match channel.send(msg2) {
        Err(RepresentationError::DuplicateMessage(id)) => assert_eq!(id, "msg-dedup-test"),
        _ => panic!("Expected DuplicateMessage error"),
    }
}

#[test]
fn test_transport_flow_control_and_backpressure() {
    const CAPACITY: usize = 2;
    let mut channel = TransportChannel::new(TransportAddress::new("scr://bus.local"), CAPACITY);
    let src = EndpointId::new("producer");
    let dst = EndpointId::new("consumer");
    channel.register_endpoint(dst);

    let m1 = Message::new(
        Envelope::new(MessageId::new("m1"), src.clone(), EndpointId::new("consumer"), 1),
        Payload::new(vec![]),
    );
    let m2 = Message::new(
        Envelope::new(MessageId::new("m2"), src.clone(), EndpointId::new("consumer"), 2),
        Payload::new(vec![]),
    );
    let m3 = Message::new(
        Envelope::new(MessageId::new("m3"), src, EndpointId::new("consumer"), 3),
        Payload::new(vec![]),
    );

    assert!(channel.send(m1).is_ok());
    assert!(channel.send(m2).is_ok());

    // Third message exceeds capacity of 2 -> BackpressureExceeded
    match channel.send(m3) {
        Err(RepresentationError::BackpressureExceeded { capacity, current }) => {
            assert_eq!(capacity, 2);
            assert_eq!(current, 2);
        }
        _ => panic!("Expected BackpressureExceeded error"),
    }

    // Acknowledging m1 releases credit
    channel.acknowledge(&MessageId::new("m1")).unwrap();

    // Now send succeeds
    let m4 = Message::new(
        Envelope::new(MessageId::new("m4"), EndpointId::new("producer"), EndpointId::new("consumer"), 4),
        Payload::new(vec![]),
    );
    assert!(channel.send(m4).is_ok());
}

#[test]
fn test_delivery_state_transitions() {
    assert!(validate_transition(&DeliveryState::Created, &DeliveryState::Sent).is_ok());
    assert!(validate_transition(&DeliveryState::Sent, &DeliveryState::InTransit).is_ok());
    assert!(validate_transition(&DeliveryState::InTransit, &DeliveryState::Delivered).is_ok());
    assert!(validate_transition(&DeliveryState::Delivered, &DeliveryState::Consumed).is_ok());
    assert!(validate_transition(&DeliveryState::Consumed, &DeliveryState::Acknowledged).is_ok());

    // Illegal jump from Created directly to Acknowledged
    assert!(validate_transition(&DeliveryState::Created, &DeliveryState::Acknowledged).is_err());
}
