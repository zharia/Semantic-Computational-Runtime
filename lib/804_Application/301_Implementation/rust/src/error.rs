use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ApplicationError {
    IllegalLifecycleTransition {
        from: String,
        to: String,
    },
    ApplicationTerminated(String),
    ModuleNotFound(String),
    ServiceNotFound(String),
    OperationNotFound(String),
    PortNotFound(String),
    AdapterError(String),
    ProviderError(String),
    PreconditionFailed(String),
    PostconditionFailed(String),
    PolicyViolation(String),
    ResourceExhausted(String),
    HypergraphMappingError(String),
    InvariantViolation(String),
}

impl fmt::Display for ApplicationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::IllegalLifecycleTransition { from, to } => {
                write!(
                    f,
                    "Illegal lifecycle transition from {} to {}",
                    from, to
                )
            }
            Self::ApplicationTerminated(id) => {
                write!(f, "Application {} is in terminal Terminated state", id)
            }
            Self::ModuleNotFound(id) => write!(f, "Module {} not found", id),
            Self::ServiceNotFound(id) => write!(f, "Service {} not found", id),
            Self::OperationNotFound(id) => write!(f, "Operation {} not found", id),
            Self::PortNotFound(id) => write!(f, "Port {} not found", id),
            Self::AdapterError(msg) => write!(f, "Adapter error: {}", msg),
            Self::ProviderError(msg) => write!(f, "Provider error: {}", msg),
            Self::PreconditionFailed(msg) => write!(f, "Precondition failed: {}", msg),
            Self::PostconditionFailed(msg) => write!(f, "Postcondition failed: {}", msg),
            Self::PolicyViolation(msg) => write!(f, "Policy violation: {}", msg),
            Self::ResourceExhausted(msg) => write!(f, "Resource exhausted: {}", msg),
            Self::HypergraphMappingError(msg) => write!(f, "Hypergraph mapping error: {}", msg),
            Self::InvariantViolation(msg) => write!(f, "Invariant violation: {}", msg),
        }
    }
}

impl std::error::Error for ApplicationError {}

pub type ApplicationResult<T> = Result<T, ApplicationError>;
