// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Interfaces Domain (`SCR-LIB-INTERFACES`)
//!
//! Authoritative normative semantic foundation for cross-cutting capability interfaces
//! and boundary contracts within the Semantic Computational Runtime.
//!
//! Encapsulates:
//! ```text
//! Interface = what may be relied upon
//! Implementation = how it is realized
//! I = (N, O, T, C, B, S, E, R, K, V, P)
//! ```

pub mod capability;
pub mod composition;
pub mod contract;
pub mod effects;
pub mod error;
pub mod hypergraph;
pub mod identity;
pub mod interface;
pub mod operation;
pub mod provider;
pub mod substitutability;

pub use capability::{Capability, CapabilitySet};
pub use composition::compose_interfaces;
pub use contract::{InvariantContract, Postcondition, Precondition};
pub use effects::Effect;
pub use error::{InterfaceError, Result};
pub use hypergraph::project_interface_to_hypergraph;
pub use identity::{InterfaceId, Namespace, SemanticVersion};
pub use interface::{InterfaceLifecycle, SemanticInterface};
pub use operation::{OperationContract, ParameterContract, TypeContract};
pub use provider::{ProviderBinding, ProviderSubstrate};
pub use substitutability::verify_substitutability;
