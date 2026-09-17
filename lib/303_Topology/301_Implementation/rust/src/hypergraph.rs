// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Canonical Hypergraph Projection — Topology Domain
//!
//! Projects topological entities, relationships, and invariants into the
//! canonical SCR Semantic Hypergraph (`SCR-LIB-HYPERGRAPH`).
//!
//! Per `SCR-LIB-TOPOLOGY` section 51: topology is represented as first-class
//! semantic structure within the SCR Semantic Hypergraph.
//!
//! Hyperedge vocabulary for topology:
//! ```text
//! Topology
//!  ├── HAS_ELEMENT        → Element
//!  ├── HAS_BOUNDARY       → Boundary
//!  ├── ADJACENT_TO        → TopologicalElement
//!  ├── INCIDENT_TO        → HigherOrderElement
//!  ├── CONTAINS           → Region
//!  ├── DERIVED_FROM       → Field
//!  ├── REPRESENTS         → Morphology
//!  ├── CONSTRAINS         → Geometry
//!  ├── EVOLVES_BY         → Transformation
//!  └── OBSERVED_BY        → Observation
//! ```

use crate::cell::CellDimension;
use crate::adjacency::AdjacencyRelation;
use crate::error::{TopologyError, TopologyResult};
use scr_hypergraph::{Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role};
use scr_identity::SidCoordinate;
use std::fmt;

/// Semantic identity of a topological entity within the hypergraph.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct TopologicalId(pub String);

impl TopologicalId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for TopologicalId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<&str> for TopologicalId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl From<String> for TopologicalId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<SidCoordinate> for TopologicalId {
    fn from(coord: SidCoordinate) -> Self {
        Self(coord.to_uri("scr"))
    }
}

/// Projects a topological entity and its dimension into the canonical hypergraph.
///
/// Per section 51 of `101_definition.md`:
/// `HAS_ELEMENT` and `HAS_BOUNDARY` are the primary projection hyperedges.
pub fn project_topology_to_hypergraph(
    id: &TopologicalId,
    dimension: CellDimension,
    euler_chi: Option<i64>,
    component_count: Option<usize>,
    hypergraph: &mut Hypergraph,
) -> TopologyResult<()> {
    // 1. Topological Entity Element
    let topo_elem_id = ElementId(format!("elem:topo:{}", id));
    if hypergraph.get_element(&topo_elem_id).is_none() {
        hypergraph
            .create_element(
                topo_elem_id.clone(),
                format!("TopologicalEntity:{}:dim={}", id, dimension),
            )
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
    }

    // 2. Dimension Element
    let dim_elem_id = ElementId(format!("elem:topo_dim:{}", dimension));
    if hypergraph.get_element(&dim_elem_id).is_none() {
        hypergraph
            .create_element(dim_elem_id.clone(), format!("TopologicalDimension:{}", dimension))
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
    }

    // 3. Dimensionality Hyperedge
    let dim_rel_id = RelationId(format!("rel:topo_dim:{}", id));
    if hypergraph.get_relation(&dim_rel_id).is_none() {
        hypergraph
            .create_relation(dim_rel_id.clone(), "TopologicalDimensionality".to_string())
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:topo_dim_src:{}", id)),
                &topo_elem_id,
                &dim_rel_id,
                Role::Source,
                Direction::Outgoing,
            )
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:topo_dim_tgt:{}", id)),
                &dim_elem_id,
                &dim_rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
    }

    // 4. Euler Characteristic Element & Invariant Hyperedge (if known)
    if let Some(chi) = euler_chi {
        let chi_elem_id = ElementId(format!("elem:topo_chi:{}", id));
        if hypergraph.get_element(&chi_elem_id).is_none() {
            hypergraph
                .create_element(chi_elem_id.clone(), format!("EulerCharacteristic:{}", chi))
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
        }

        let chi_rel_id = RelationId(format!("rel:topo_chi:{}", id));
        if hypergraph.get_relation(&chi_rel_id).is_none() {
            hypergraph
                .create_relation(chi_rel_id.clone(), "HasEulerCharacteristic".to_string())
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:topo_chi_src:{}", id)),
                    &topo_elem_id,
                    &chi_rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:topo_chi_tgt:{}", id)),
                    &chi_elem_id,
                    &chi_rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
        }
    }

    // 5. Connected Component Count Element (β₀) if known
    if let Some(comp_count) = component_count {
        let comp_elem_id = ElementId(format!("elem:topo_comp:{}", id));
        if hypergraph.get_element(&comp_elem_id).is_none() {
            hypergraph
                .create_element(
                    comp_elem_id.clone(),
                    format!("ComponentCount:β₀={}", comp_count),
                )
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
        }

        let comp_rel_id = RelationId(format!("rel:topo_comp:{}", id));
        if hypergraph.get_relation(&comp_rel_id).is_none() {
            hypergraph
                .create_relation(comp_rel_id.clone(), "HasConnectedComponents".to_string())
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:topo_comp_src:{}", id)),
                    &topo_elem_id,
                    &comp_rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:topo_comp_tgt:{}", id)),
                    &comp_elem_id,
                    &comp_rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
        }
    }

    Ok(())
}

/// Projects an adjacency relationship into the hypergraph.
///
/// Per section 51: `ADJACENT_TO` is a primary topological hyperedge.
pub fn project_adjacency_to_hypergraph(
    rel: &AdjacencyRelation,
    hypergraph: &mut Hypergraph,
) -> TopologyResult<()> {
    let src_id = ElementId(format!("elem:topo:{}", rel.element_a));
    let tgt_id = ElementId(format!("elem:topo:{}", rel.element_b));

    let rel_id = RelationId(format!(
        "rel:adjacent:{}:{}", rel.element_a, rel.element_b
    ));

    if hypergraph.get_relation(&rel_id).is_none() {
        hypergraph
            .create_relation(
                rel_id.clone(),
                format!("AdjacentTo:{}", rel.kind),
            )
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;

        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:adj_src:{}", rel_id.0)),
                &src_id,
                &rel_id,
                Role::Source,
                Direction::Outgoing,
            )
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;

        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:adj_tgt:{}", rel_id.0)),
                &tgt_id,
                &rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| TopologyError::HypergraphMappingError(e.to_string()))?;
    }

    Ok(())
}
