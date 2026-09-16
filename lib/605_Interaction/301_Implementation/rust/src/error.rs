use core::fmt;

/// Errors arising within the Interaction domain.
#[derive(Debug, Clone, PartialEq)]
pub enum InteractionError {
    /// An input or observation was invalid or malformed.
    InvalidInput(String),
    /// A gesture was unrecognized or failed constraints.
    UnrecognizedGesture(String),
    /// An interaction sequence or chord composition invariant was violated.
    CompositionViolation(String),
    /// The session was in an invalid state for the requested transition.
    InvalidSessionState {
        expected: String,
        found: String,
    },
    /// The interaction was explicitly cancelled.
    SessionCancelled(String),
    /// Mapping resolution failed or was ambiguous without required confirmation.
    MappingResolutionFailed(String),
    /// Actor is not authorized to execute the resulting action.
    UnauthorizedAction(String),
    /// Hypergraph mapping error.
    HypergraphMappingError(String),
}

impl fmt::Display for InteractionError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            InteractionError::InvalidInput(msg) => write!(f, "Invalid input: {}", msg),
            InteractionError::UnrecognizedGesture(msg) => write!(f, "Unrecognized gesture: {}", msg),
            InteractionError::CompositionViolation(msg) => write!(f, "Composition violation: {}", msg),
            InteractionError::InvalidSessionState { expected, found } => {
                write!(f, "Invalid session state: expected {}, found {}", expected, found)
            }
            InteractionError::SessionCancelled(msg) => write!(f, "Session cancelled: {}", msg),
            InteractionError::MappingResolutionFailed(msg) => write!(f, "Mapping resolution failed: {}", msg),
            InteractionError::UnauthorizedAction(msg) => write!(f, "Unauthorized action: {}", msg),
            InteractionError::HypergraphMappingError(msg) => write!(f, "Hypergraph mapping error: {}", msg),
        }
    }
}

pub type InteractionResult<T> = Result<T, InteractionError>;
