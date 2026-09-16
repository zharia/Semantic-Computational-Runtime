use crate::transport::message::MessageId;
use crate::error::RepresentationError;

/// Explicit delivery lifecycle states of a transport message.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum DeliveryState {
    Created,
    Sent,
    InTransit,
    Delivered,
    Consumed,
    Acknowledged,
    Failed(String),
    DeadLettered(String),
}

/// Delivery receipt confirming delivery status and timestamp.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DeliveryReceipt {
    pub message_id: MessageId,
    pub state: DeliveryState,
    pub timestamp_ns: u64,
}

impl DeliveryReceipt {
    pub fn new(message_id: MessageId, state: DeliveryState, timestamp_ns: u64) -> Self {
        Self {
            message_id,
            state,
            timestamp_ns,
        }
    }

    pub fn is_acknowledged(&self) -> bool {
        matches!(self.state, DeliveryState::Acknowledged)
    }

    pub fn is_terminal(&self) -> bool {
        matches!(
            self.state,
            DeliveryState::Acknowledged | DeliveryState::Failed(_) | DeliveryState::DeadLettered(_)
        )
    }
}

/// Validates that a message state transition is semantically valid according to TRANSPORT-I002.
pub fn validate_transition(current: &DeliveryState, next: &DeliveryState) -> Result<(), RepresentationError> {
    let valid = match (current, next) {
        (DeliveryState::Created, DeliveryState::Sent) => true,
        (DeliveryState::Sent, DeliveryState::InTransit) => true,
        (DeliveryState::InTransit, DeliveryState::Delivered) => true,
        (DeliveryState::Delivered, DeliveryState::Consumed) => true,
        (DeliveryState::Consumed, DeliveryState::Acknowledged) => true,
        // Any non-terminal state can transition to Failed or DeadLettered
        (DeliveryState::Created | DeliveryState::Sent | DeliveryState::InTransit | DeliveryState::Delivered, DeliveryState::Failed(_)) => true,
        (DeliveryState::Created | DeliveryState::Sent | DeliveryState::InTransit | DeliveryState::Delivered | DeliveryState::Failed(_), DeliveryState::DeadLettered(_)) => true,
        _ => false,
    };

    if valid {
        Ok(())
    } else {
        Err(RepresentationError::TransportDeliveryFailed {
            message_id: "unknown".into(),
            reason: format!("Illegal delivery state transition from {:?} to {:?}", current, next),
        })
    }
}
