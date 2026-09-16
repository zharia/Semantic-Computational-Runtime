use std::fmt;

/// Representation domain errors across Serialization, Transport, and Persistence.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RepresentationError {
    SerializationError(String),
    DeserializationError(String),
    SchemaMismatch { expected: String, found: String },
    IncompatibleVersion { expected: u32, found: u32 },
    CorruptedData(String),
    MalformedInput(String),
    TransportDeliveryFailed { message_id: String, reason: String },
    EndpointNotFound(String),
    BackpressureExceeded { capacity: usize, current: usize },
    DuplicateMessage(String),
    PersistenceFailure(String),
    IntegrityViolation { expected_checksum: u64, computed_checksum: u64 },
    EntityNotFound(String),
}

impl fmt::Display for RepresentationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::SerializationError(msg) => write!(f, "Serialization error: {}", msg),
            Self::DeserializationError(msg) => write!(f, "Deserialization error: {}", msg),
            Self::SchemaMismatch { expected, found } => {
                write!(f, "Schema mismatch: expected '{}', found '{}'", expected, found)
            }
            Self::IncompatibleVersion { expected, found } => {
                write!(f, "Incompatible version: expected {}, found {}", expected, found)
            }
            Self::CorruptedData(msg) => write!(f, "Corrupted data: {}", msg),
            Self::MalformedInput(msg) => write!(f, "Malformed input: {}", msg),
            Self::TransportDeliveryFailed { message_id, reason } => {
                write!(f, "Transport delivery failed for {}: {}", message_id, reason)
            }
            Self::EndpointNotFound(ep) => write!(f, "Transport endpoint not found: {}", ep),
            Self::BackpressureExceeded { capacity, current } => {
                write!(f, "Backpressure exceeded: capacity {}, current {}", capacity, current)
            }
            Self::DuplicateMessage(msg_id) => write!(f, "Duplicate message rejected: {}", msg_id),
            Self::PersistenceFailure(msg) => write!(f, "Persistence failure: {}", msg),
            Self::IntegrityViolation { expected_checksum, computed_checksum } => {
                write!(
                    f,
                    "Persistence integrity violation: expected checksum 0x{:016x}, computed 0x{:016x}",
                    expected_checksum, computed_checksum
                )
            }
            Self::EntityNotFound(id) => write!(f, "Entity not found in representation: {}", id),
        }
    }
}

impl std::error::Error for RepresentationError {}
