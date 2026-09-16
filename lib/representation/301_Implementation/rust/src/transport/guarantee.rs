use crate::transport::message::MessageId;
use crate::error::RepresentationError;
use std::collections::BTreeSet;

/// Semantic delivery guarantee levels.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum DeliveryGuarantee {
    /// Message is sent without retry; may be lost under failure.
    AtMostOnce,
    /// Message is retransmitted until acknowledged; may produce duplicates.
    AtLeastOnce,
    /// Message is delivered exactly once within a bounded epoch context using deduplication.
    ExactlyOnceInContext,
}

/// Deduplicator tracking message identities to enforce idempotence and exactly-once-in-context semantics.
#[derive(Debug, Default)]
pub struct Deduplicator {
    seen_ids: BTreeSet<MessageId>,
}

impl Deduplicator {
    pub fn new() -> Self {
        Self::default()
    }

    /// Check if a message has already been processed. If not, record it.
    pub fn process_message(&mut self, message_id: &MessageId) -> Result<(), RepresentationError> {
        if self.seen_ids.contains(message_id) {
            Err(RepresentationError::DuplicateMessage(message_id.0.clone()))
        } else {
            self.seen_ids.insert(message_id.clone());
            Ok(())
        }
    }

    pub fn is_duplicate(&self, message_id: &MessageId) -> bool {
        self.seen_ids.contains(message_id)
    }

    pub fn clear(&mut self) {
        self.seen_ids.clear();
    }
}
