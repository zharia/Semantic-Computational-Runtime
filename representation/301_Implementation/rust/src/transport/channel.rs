use crate::error::RepresentationError;
use crate::transport::endpoint::{EndpointId, TransportAddress};
use crate::transport::message::{Message, MessageId};
use crate::transport::delivery::{DeliveryState, DeliveryReceipt};
use crate::transport::flow::FlowController;
use crate::transport::guarantee::Deduplicator;
use std::collections::{BTreeMap, VecDeque};

/// Carrier for moving messages between computational endpoints.
#[derive(Debug)]
pub struct TransportChannel {
    address: TransportAddress,
    flow: FlowController,
    endpoints: BTreeMap<EndpointId, VecDeque<Message>>,
    message_states: BTreeMap<MessageId, DeliveryState>,
    deduplicator: Deduplicator,
}

impl TransportChannel {
    pub fn new(address: TransportAddress, capacity: usize) -> Self {
        Self {
            address,
            flow: FlowController::new(capacity),
            endpoints: BTreeMap::new(),
            message_states: BTreeMap::new(),
            deduplicator: Deduplicator::new(),
        }
    }

    pub fn address(&self) -> &TransportAddress {
        &self.address
    }

    /// Register a participant endpoint in this transport channel.
    pub fn register_endpoint(&mut self, endpoint: EndpointId) {
        self.endpoints.entry(endpoint).or_insert_with(VecDeque::new);
    }

    /// Send a message to its destination endpoint.
    pub fn send(&mut self, message: Message) -> Result<DeliveryReceipt, RepresentationError> {
        let msg_id = message.id().clone();
        let dest = message.envelope.destination.clone();

        // 1. Deduplication check
        self.deduplicator.process_message(&msg_id)?;

        // 2. Backpressure / flow control check
        self.flow.acquire_credit()?;

        // 3. Destination existence check
        let queue = self.endpoints.get_mut(&dest).ok_or_else(|| {
            self.flow.release_credit();
            RepresentationError::EndpointNotFound(dest.0.clone())
        })?;

        // 4. Record state and enqueue
        self.message_states.insert(msg_id.clone(), DeliveryState::Delivered);
        queue.push_back(message);

        let receipt = DeliveryReceipt::new(msg_id, DeliveryState::Delivered, 100);
        Ok(receipt)
    }

    /// Receive/consume the next message queued for an endpoint.
    pub fn receive(&mut self, endpoint: &EndpointId) -> Result<Option<Message>, RepresentationError> {
        let queue = self.endpoints.get_mut(endpoint).ok_or_else(|| {
            RepresentationError::EndpointNotFound(endpoint.0.clone())
        })?;

        if let Some(msg) = queue.pop_front() {
            self.message_states.insert(msg.id().clone(), DeliveryState::Consumed);
            Ok(Some(msg))
        } else {
            Ok(None)
        }
    }

    /// Acknowledge consumption of a message, releasing transport flow credit.
    pub fn acknowledge(&mut self, message_id: &MessageId) -> Result<DeliveryReceipt, RepresentationError> {
        if let Some(state) = self.message_states.get_mut(message_id) {
            *state = DeliveryState::Acknowledged;
            self.flow.release_credit();
            Ok(DeliveryReceipt::new(message_id.clone(), DeliveryState::Acknowledged, 200))
        } else {
            Err(RepresentationError::TransportDeliveryFailed {
                message_id: message_id.0.clone(),
                reason: "Message ID not tracked in channel".into(),
            })
        }
    }

    pub fn get_message_state(&self, message_id: &MessageId) -> Option<&DeliveryState> {
        self.message_states.get(message_id)
    }
}
