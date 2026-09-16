use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum IdentityError {
    InvalidRequest(String),
    InvariantViolation(String),
    RootAlreadyExists(String),
    RootNotFound(String),
    SpaceAlreadyExists(String),
    SpaceNotFound(String),
    DomainAlreadyExists(String),
    DomainNotFound(String),
    AuthorityAlreadyExists(String),
    AuthorityNotFound(String),
    AuthoritySuspendedOrRevoked(String),
    GenerationMismatch {
        expected: u32,
        provided: u32,
    },
    AuthorityMismatch {
        domain_authority: String,
        provided_authority: String,
    },
    InvalidRegion(String),
    RegionOutOfBounds {
        index: u64,
        low: u64,
        high: u64,
    },
    RegionOverlap {
        domain_a: String,
        domain_b: String,
    },
    RegionNotContainedInParent {
        child: String,
        parent: String,
    },
    CoordinateAlreadyAllocated(String),
    CoordinateCurrentlyReserved(String),
    TransactionNotFound(String),
    TransactionRebound {
        tx_id: String,
        existing_sid: String,
        attempted_sid: String,
    },
    CoordinateNotFound(String),
    InvalidUri(String),
}

impl fmt::Display for IdentityError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidRequest(msg) => write!(f, "Invalid request: {}", msg),
            Self::InvariantViolation(msg) => write!(f, "Invariant violation: {}", msg),
            Self::RootAlreadyExists(id) => write!(f, "Root authority already exists: {}", id),
            Self::RootNotFound(id) => write!(f, "Root authority not found: {}", id),
            Self::SpaceAlreadyExists(id) => write!(f, "Identity space already exists: {}", id),
            Self::SpaceNotFound(id) => write!(f, "Identity space not found: {}", id),
            Self::DomainAlreadyExists(id) => write!(f, "Allocation domain already exists: {}", id),
            Self::DomainNotFound(id) => write!(f, "Allocation domain not found: {}", id),
            Self::AuthorityAlreadyExists(id) => write!(f, "Authority already exists: {}", id),
            Self::AuthorityNotFound(id) => write!(f, "Authority not found: {}", id),
            Self::AuthoritySuspendedOrRevoked(id) => {
                write!(f, "Authority is suspended or revoked: {}", id)
            }
            Self::GenerationMismatch { expected, provided } => {
                write!(
                    f,
                    "Authority generation mismatch: expected {}, provided {}",
                    expected, provided
                )
            }
            Self::AuthorityMismatch {
                domain_authority,
                provided_authority,
            } => {
                write!(
                    f,
                    "Authority mismatch: domain authority is {}, caller provided {}",
                    domain_authority, provided_authority
                )
            }
            Self::InvalidRegion(msg) => write!(f, "Invalid region: {}", msg),
            Self::RegionOutOfBounds { index, low, high } => {
                write!(
                    f,
                    "Coordinate index {} out of region bounds [{}, {})",
                    index, low, high
                )
            }
            Self::RegionOverlap { domain_a, domain_b } => {
                write!(
                    f,
                    "Sibling domains {} and {} overlap coordinate regions",
                    domain_a, domain_b
                )
            }
            Self::RegionNotContainedInParent { child, parent } => {
                write!(
                    f,
                    "Child domain {} region is not strictly contained within parent {}",
                    child, parent
                )
            }
            Self::CoordinateAlreadyAllocated(sid) => {
                write!(f, "Coordinate {} has already been historically allocated", sid)
            }
            Self::CoordinateCurrentlyReserved(sid) => {
                write!(f, "Coordinate {} is currently reserved by a pending transaction", sid)
            }
            Self::TransactionNotFound(tx_id) => {
                write!(f, "Transaction {} not found", tx_id)
            }
            Self::TransactionRebound {
                tx_id,
                existing_sid,
                attempted_sid,
            } => {
                write!(
                    f,
                    "Transaction non-rebinding violation (IAM-R018): tx {} already bound to {} cannot be rebound to {}",
                    tx_id, existing_sid, attempted_sid
                )
            }
            Self::CoordinateNotFound(sid) => {
                write!(f, "Coordinate {} not found in historical allocation set", sid)
            }
            Self::InvalidUri(uri) => write!(f, "Invalid SID URI: {}", uri),
        }
    }
}

impl std::error::Error for IdentityError {}
