// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Stream Domain (`SCR-LIB-STREAM`)
//!
//! Authoritative normative semantic foundation for Streams within the Semantic Computational Runtime.
//!
//! A Stream represents the ordered, partially ordered, causal, continuous, or discrete evolution
//! and availability of semantic entities, state, occurrences, observations, operations, or
//! transformations across an ordered or causal domain.
//!
//! In accordance with the SCR Governing Principle:
//! ```text
//! Transport ≠ Queue ≠ Broker ≠ Buffer ≠ Scheduler ≠ Stream
//! ```

pub mod availability;
pub mod boundary;
pub mod element;
pub mod error;
pub mod hypergraph;
pub mod lifecycle;
pub mod loss;
pub mod occurrence;
pub mod operator;
pub mod ordering;
pub mod replay;
pub mod stream;
pub mod stream_types;
pub mod temporal;
pub mod window;

pub use availability::AvailabilityStatus;
pub use boundary::{DeliveryGuarantee, StreamSink, StreamSource};
pub use element::{ElementPayload, ProvenanceRecord, StreamElement, StreamElementId};
pub use error::{Result, StreamError};
pub use hypergraph::project_stream_to_hypergraph;
pub use lifecycle::{StreamLifecycle, StreamState};
pub use loss::{LossClassification, LossRecord};
pub use occurrence::OccurrenceRecord;
pub use operator::{merge_streams, split_stream, FilterOperator, MapOperator, OperatorPurity};
pub use ordering::{CausalRelation, OrderingSemantics, VectorClock};
pub use replay::{ReplayController, ReplayMode};
pub use stream::SemanticStream;
pub use stream_types::{StateReconstructionContract, StreamKind};
pub use temporal::{ClockDomain, TemporalReference, Watermark};
pub use window::{StreamWindow, WindowType};
