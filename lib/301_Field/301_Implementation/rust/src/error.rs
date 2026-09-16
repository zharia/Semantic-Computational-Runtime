use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FieldError {
    DomainMismatch {
        expected: String,
        found: String,
    },
    DimensionMismatch {
        expected: usize,
        found: usize,
    },
    OutOfBounds {
        coords: Vec<i64>,
        domain_id: String,
    },
    UndefinedEvaluation(String),
    InterpolationError(String),
    BoundaryError(String),
    OperatorError(String),
    HypergraphMappingError(String),
    InvariantViolation(String),
}

impl fmt::Display for FieldError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::DomainMismatch { expected, found } => {
                write!(f, "Domain mismatch: expected {}, found {}", expected, found)
            }
            Self::DimensionMismatch { expected, found } => {
                write!(
                    f,
                    "Dimension mismatch: expected {}, found {}",
                    expected, found
                )
            }
            Self::OutOfBounds { coords, domain_id } => {
                write!(
                    f,
                    "Coordinates {:?} are out of bounds for domain {}",
                    coords, domain_id
                )
            }
            Self::UndefinedEvaluation(msg) => write!(f, "Undefined evaluation: {}", msg),
            Self::InterpolationError(msg) => write!(f, "Interpolation error: {}", msg),
            Self::BoundaryError(msg) => write!(f, "Boundary error: {}", msg),
            Self::OperatorError(msg) => write!(f, "Operator error: {}", msg),
            Self::HypergraphMappingError(msg) => write!(f, "Hypergraph mapping error: {}", msg),
            Self::InvariantViolation(msg) => write!(f, "Invariant violation: {}", msg),
        }
    }
}

impl std::error::Error for FieldError {}

pub type FieldResult<T> = Result<T, FieldError>;
