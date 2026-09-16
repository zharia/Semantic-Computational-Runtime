use crate::transport::endpoint::EndpointId;
use std::collections::BTreeMap;
use std::fmt;

/// Unique identifier for a transport message.
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct MessageId(pub String);

impl MessageId {
    pub fn new<S: Into<String>>(s: S) -> Self {
        Self(s.into())
    }
}

impl fmt::Display for MessageId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Correlation identifier for request-response and causal tracing.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct CorrelationId(pub String);

impl CorrelationId {
    pub fn new<S: Into<String>>(s: S) -> Self {
        Self(s.into())
    }
}

impl fmt::Display for CorrelationId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Transport envelope carrying routing, provenance, and delivery metadata.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Envelope {
    pub message_id: MessageId,
    pub source: EndpointId,
    pub destination: EndpointId,
    pub correlation_id: Option<CorrelationId>,
    pub timestamp_ns: u64,
    pub priority: u8,
    pub headers: BTreeMap<String, String>,
}

impl Envelope {
    pub fn new(
        message_id: MessageId,
        source: EndpointId,
        destination: EndpointId,
        timestamp_ns: u64,
    ) -> Self {
        Self {
            message_id,
            source,
            destination,
            correlation_id: None,
            timestamp_ns,
            priority: 0,
            headers: BTreeMap::new(),
        }
    }

    pub fn with_correlation(mut self, correlation_id: CorrelationId) -> Self {
        self.correlation_id = Some(correlation_id);
        self
    }

    pub fn with_header<K: Into<String>, V: Into<String>>(mut self, key: K, value: V) -> Self {
        self.headers.insert(key.into(), value.into());
        self
    }
}

/// Opaque byte payload carried by the transport message.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Payload(pub Vec<u8>);

impl Payload {
    pub fn new(bytes: Vec<u8>) -> Self {
        Self(bytes)
    }

    pub fn as_bytes(&self) -> &[u8] {
        &self.0
    }
}

/// First-class transport message composed of an envelope and payload.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Message {
    pub envelope: Envelope,
    pub payload: Payload,
}

impl Message {
    pub fn new(envelope: Envelope, payload: Payload) -> Self {
        Self { envelope, payload }
    }

    pub fn id(&self) -> &MessageId {
        &self.envelope.message_id
    }
}
