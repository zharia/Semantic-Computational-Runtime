pub mod authority;
pub mod coordinate;
pub mod domain;
pub mod error;
pub mod hypergraph;
pub mod invariants;
pub mod machine;
pub mod models;

pub use authority::{Authority, AuthorityState};
pub use coordinate::{CoordinateRegion, GlobalIdentity, SidCoordinate};
pub use domain::{Domain, DomainState};
pub use error::IdentityError;
pub use invariants::InvariantChecker;
pub use machine::IAMMachine;
pub use models::{
    IdentitySpace, ManifestationRecord, ProvenanceRecord, SemanticBinding, State,
    TransactionRecord, TransactionStatus,
};

pub mod prelude {
    pub use crate::authority::{Authority, AuthorityState};
    pub use crate::coordinate::{CoordinateRegion, GlobalIdentity, SidCoordinate};
    pub use crate::domain::{Domain, DomainState};
    pub use crate::error::IdentityError;
    pub use crate::invariants::InvariantChecker;
    pub use crate::machine::IAMMachine;
    pub use crate::models::{
        IdentitySpace, ManifestationRecord, ProvenanceRecord, SemanticBinding, State,
        TransactionRecord, TransactionStatus,
    };
}
