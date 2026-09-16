use core::fmt;

/// Errors arising within the Perception domain.
#[derive(Debug, Clone, PartialEq)]
pub enum PerceptionError {
    /// An observation is invalid, malformed, or corrupted.
    InvalidObservation(String),
    /// An observation modality is incompatible with the requested perceptual transformation.
    IncompatibleModality {
        expected: String,
        found: String,
    },
    /// The requested transformation is unsupported.
    UnsupportedTransformation(String),
    /// Perceptual uncertainty or ambiguity was lost or collapsed unlawfully.
    UncertaintyIntegrityViolation(String),
    /// Inferred information was unlawfully conflated with directly observed information.
    InferenceConflationViolation(String),
    /// A persistent identity was asserted without meeting identification contract requirements.
    IdentityContractViolation(String),
    /// A required perceptual context was missing or invalid.
    InvalidContext(String),
    /// Ambiguity resolution failed without retaining alternative hypotheses.
    AmbiguityIntegrityViolation(String),
    /// A perceptual failure occurred and must not silently masquerade as a valid observation.
    PerceptualFailure(String),
    /// Provider execution failed.
    ProviderFailure(String),
    /// Hypergraph mapping failure.
    HypergraphMappingError(String),
}

impl fmt::Display for PerceptionError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PerceptionError::InvalidObservation(msg) => write!(f, "Invalid observation: {}", msg),
            PerceptionError::IncompatibleModality { expected, found } => {
                write!(f, "Incompatible modality: expected {}, found {}", expected, found)
            }
            PerceptionError::UnsupportedTransformation(msg) => write!(f, "Unsupported transformation: {}", msg),
            PerceptionError::UncertaintyIntegrityViolation(msg) => write!(f, "Uncertainty integrity violation: {}", msg),
            PerceptionError::InferenceConflationViolation(msg) => write!(f, "Inference conflation violation: {}", msg),
            PerceptionError::IdentityContractViolation(msg) => write!(f, "Identity contract violation: {}", msg),
            PerceptionError::InvalidContext(msg) => write!(f, "Invalid context: {}", msg),
            PerceptionError::AmbiguityIntegrityViolation(msg) => write!(f, "Ambiguity integrity violation: {}", msg),
            PerceptionError::PerceptualFailure(msg) => write!(f, "Perceptual failure: {}", msg),
            PerceptionError::ProviderFailure(msg) => write!(f, "Provider failure: {}", msg),
            PerceptionError::HypergraphMappingError(msg) => write!(f, "Hypergraph mapping error: {}", msg),
        }
    }
}

pub type PerceptionResult<T> = Result<T, PerceptionError>;
