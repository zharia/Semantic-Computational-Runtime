// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

/// Distinct error conditions across the SCR Stream semantic domain.
///
/// In accordance with STREAM-INV-022, execution failures MUST NOT silently
/// become semantic absence.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StreamError {
    SourceUnavailable(String),
    TransportError(String),
    ConsumerError(String),
    ProviderError(String),
    Timeout(String),
    UnavailableElement(String),
    LostElement(String),
    MalformedElement(String),
    SemanticInvalidity(String),
    TransformationFailure(String),
    ResourceExhaustion(String),
    Cancellation(String),
    StreamTerminated(String),
    InvalidStateTransition { from: String, to: String },
    CausalViolation(String),
    ReplaySideEffectViolation(String),
    WindowClosed(String),
    TypeMismatch { expected: String, actual: String },
}

impl fmt::Display for StreamError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            StreamError::SourceUnavailable(s) => write!(f, "Source unavailable: {}", s),
            StreamError::TransportError(s) => write!(f, "Transport failure: {}", s),
            StreamError::ConsumerError(s) => write!(f, "Consumer failure: {}", s),
            StreamError::ProviderError(s) => write!(f, "Provider failure: {}", s),
            StreamError::Timeout(s) => write!(f, "Stream timeout: {}", s),
            StreamError::UnavailableElement(s) => write!(f, "Element unavailable: {}", s),
            StreamError::LostElement(s) => write!(f, "Element lost in stream: {}", s),
            StreamError::MalformedElement(s) => write!(f, "Malformed stream element: {}", s),
            StreamError::SemanticInvalidity(s) => write!(f, "Semantic contract invalidity: {}", s),
            StreamError::TransformationFailure(s) => write!(f, "Stream transformation failed: {}", s),
            StreamError::ResourceExhaustion(s) => write!(f, "Stream resource exhaustion: {}", s),
            StreamError::Cancellation(s) => write!(f, "Stream cancelled: {}", s),
            StreamError::StreamTerminated(s) => write!(f, "Stream is terminated: {}", s),
            StreamError::InvalidStateTransition { from, to } => {
                write!(f, "Invalid stream lifecycle transition from {} to {}", from, to)
            }
            StreamError::CausalViolation(s) => write!(f, "Causal ordering violation: {}", s),
            StreamError::ReplaySideEffectViolation(s) => {
                write!(f, "Replay side effect violation: {}", s)
            }
            StreamError::WindowClosed(s) => write!(f, "Window is already closed: {}", s),
            StreamError::TypeMismatch { expected, actual } => {
                write!(f, "Type mismatch in stream: expected {}, got {}", expected, actual)
            }
        }
    }
}

impl std::error::Error for StreamError {}

pub type Result<T> = std::result::Result<T, StreamError>;
