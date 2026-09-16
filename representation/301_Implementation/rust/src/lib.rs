//! # Semantic Computational Runtime (SCR) — Representation Domain
//!
//! Authoritative normative representation implementations conforming to:
//! - `representation.serialization` (`representation/serialization/101_definition.md`)
//! - `representation.transport` (`representation/transport/101_definition.md`)
//! - `representation.persistence` (`representation/persistence/101_definition.md`)

pub mod error;
pub mod serialization;
pub mod transport;
pub mod persistence;

pub use error::RepresentationError;
pub use serialization::*;
pub use transport::*;
pub use persistence::*;
