// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::fmt;

/// Stable semantic identifier for an Interface.
///
/// In accordance with INTERFACE-INV-003, Interfaces MUST possess stable semantic identity
/// independent of realization programming language, ABI, or transport protocol.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct InterfaceId(pub String);

impl InterfaceId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Hierarchical namespace organizing interfaces.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct Namespace(pub String);

impl Namespace {
    pub fn new(ns: impl Into<String>) -> Self {
        Self(ns.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Explicit semantic version for an interface contract.
///
/// In accordance with INTERFACE-INV-016:
/// Material semantic changes MUST be reflected in interface versioning.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct SemanticVersion {
    pub major: u32,
    pub minor: u32,
    pub patch: u32,
}

impl SemanticVersion {
    pub fn new(major: u32, minor: u32, patch: u32) -> Self {
        Self { major, minor, patch }
    }

    /// Checks backward compatibility (same major version, self >= other).
    pub fn is_compatible_with(&self, other: &SemanticVersion) -> bool {
        self.major == other.major && (self.minor > other.minor || (self.minor == other.minor && self.patch >= other.patch))
    }
}

impl fmt::Display for SemanticVersion {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}.{}.{}", self.major, self.minor, self.patch)
    }
}
