// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Topological Delta Module
//!
//! Topological deltas — semantic descriptions of state transitions in topology.
//!
//! Conforming to `SCR-LIB-TOPOLOGY-TRANSFORMATION` (sections 41-42).
//!
//! Per `TOPOLOGY-INV-012`: topological deltas MUST represent valid semantic
//! state transitions.
//! Per `TOPOLOGY-RULE-008`: topology-changing state transitions MUST be explicit.

use crate::cell::CellId;
use crate::error::{TopologyError, TopologyResult};

/// The kind of semantic change a topological delta describes.
///
/// These represent semantic operations, NOT prescribed APIs.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum TopologicalDeltaKind {
    /// An element (vertex, edge, face) was added.
    AddElement,
    /// An element was removed.
    RemoveElement,
    /// An adjacency was added between two elements.
    AddAdjacency,
    /// An adjacency was removed.
    RemoveAdjacency,
    /// Two formerly disconnected components merged (β₀ decreases).
    MergeComponent,
    /// A component was split (β₀ increases).
    SplitComponent,
    /// A hole was created (β₁ increases for surfaces).
    CreateHole,
    /// A hole was removed (β₁ decreases).
    RemoveHole,
    /// A boundary changed.
    ChangeBoundary,
    /// A topology-preserving operation was applied.
    PreservingOperation { description: String },
}

impl TopologicalDeltaKind {
    /// Returns whether this delta changes topology.
    pub fn changes_topology(&self) -> bool {
        matches!(
            self,
            Self::MergeComponent
                | Self::SplitComponent
                | Self::CreateHole
                | Self::RemoveHole
                | Self::ChangeBoundary
        )
    }

    /// Returns whether this delta preserves topology.
    pub fn preserves_topology(&self) -> bool {
        matches!(self, Self::PreservingOperation { .. })
    }
}

impl std::fmt::Display for TopologicalDeltaKind {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::AddElement => write!(f, "ADD_ELEMENT"),
            Self::RemoveElement => write!(f, "REMOVE_ELEMENT"),
            Self::AddAdjacency => write!(f, "ADD_ADJACENCY"),
            Self::RemoveAdjacency => write!(f, "REMOVE_ADJACENCY"),
            Self::MergeComponent => write!(f, "MERGE_COMPONENT"),
            Self::SplitComponent => write!(f, "SPLIT_COMPONENT"),
            Self::CreateHole => write!(f, "CREATE_HOLE"),
            Self::RemoveHole => write!(f, "REMOVE_HOLE"),
            Self::ChangeBoundary => write!(f, "CHANGE_BOUNDARY"),
            Self::PreservingOperation { description } => {
                write!(f, "PRESERVING_OP({})", description)
            }
        }
    }
}

/// A topological delta — a semantic description of a topological state change.
///
/// Per `TOPOLOGY-INV-012`: deltas MUST represent valid semantic state transitions.
/// Per `TOPOLOGY-RULE-008`: topology-changing deltas MUST be explicit.
#[derive(Debug, Clone, PartialEq)]
pub struct TopologicalDelta {
    /// Semantic identifier of this delta.
    pub id: String,
    /// The kind of topological change.
    pub kind: TopologicalDeltaKind,
    /// Elements involved in this delta.
    pub elements: Vec<CellId>,
    /// Optional provenance (source transformation or operation).
    pub provenance: Option<String>,
}

impl TopologicalDelta {
    /// Creates a new topological delta.
    pub fn new(
        id: impl Into<String>,
        kind: TopologicalDeltaKind,
        elements: Vec<CellId>,
        provenance: Option<String>,
    ) -> TopologyResult<Self> {
        let id = id.into();
        if id.trim().is_empty() {
            return Err(TopologyError::InvariantViolation(
                "TOPOLOGY-INV-001: Delta identity cannot be empty".to_string(),
            ));
        }
        Ok(Self {
            id,
            kind,
            elements,
            provenance,
        })
    }

    /// Returns whether this delta is a topology-changing operation.
    pub fn changes_topology(&self) -> bool {
        self.kind.changes_topology()
    }

    /// Returns whether this delta is topology-preserving.
    pub fn preserves_topology(&self) -> bool {
        self.kind.preserves_topology()
    }

    /// Validates that a topology-changing delta is not used where preservation is required.
    pub fn assert_preserving(&self) -> TopologyResult<()> {
        if self.changes_topology() {
            Err(TopologyError::UnexpectedTopologyChange(format!(
                "TOPOLOGY-INV-012: Delta '{}' is topology-changing ({}), \
                 but topology preservation was required",
                self.id, self.kind
            )))
        } else {
            Ok(())
        }
    }
}
