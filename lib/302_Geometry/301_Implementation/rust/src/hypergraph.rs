// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Canonical Hypergraph Projection
//!
//! Projects geometric entities, dimensions, boundaries, and spatial relations
//! into the canonical SCR hypergraph (`SCR-LIB-HYPERGRAPH`).

use crate::dimension::GeometricDimension;
use crate::error::{GeometryError, GeometryResult};
use crate::primitives::AABB3D;
use scr_hypergraph::{
    Direction, ElementId, Hypergraph, IncidenceId, RelationId, Role,
};
use scr_identity::SidCoordinate;
use std::fmt;

/// Semantic identity of a geometric entity.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct GeometricId(pub String);

impl GeometricId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for GeometricId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<&str> for GeometricId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl From<String> for GeometricId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<SidCoordinate> for GeometricId {
    fn from(coord: SidCoordinate) -> Self {
        Self(coord.to_uri("scr"))
    }
}

/// Projects a geometric entity into the canonical hypergraph.
pub fn project_geometry_to_hypergraph(
    id: &GeometricId,
    dim: GeometricDimension,
    bounding_box: Option<&AABB3D>,
    hypergraph: &mut Hypergraph,
) -> GeometryResult<()> {
    // 1. Geometric Entity Element
    let geom_elem_id = ElementId(format!("elem:geom:{}", id));
    if hypergraph.get_element(&geom_elem_id).is_none() {
        hypergraph
            .create_element(
                geom_elem_id.clone(),
                format!("GeometryEntity:{}:dim={}", id, dim),
            )
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;
    }

    // 2. Dimension Element
    let dim_elem_id = ElementId(format!("elem:dim:{}", dim));
    if hypergraph.get_element(&dim_elem_id).is_none() {
        hypergraph
            .create_element(dim_elem_id.clone(), format!("GeometricDimension:{}", dim))
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;
    }

    // 3. Dimensionality Hyperedge
    let dim_rel_id = RelationId(format!("rel:geom_dim:{}", id));
    if hypergraph.get_relation(&dim_rel_id).is_none() {
        hypergraph
            .create_relation(dim_rel_id.clone(), "GeometricDimensionality".to_string())
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;

        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:geom_dim_src:{}", id)),
                &geom_elem_id,
                &dim_rel_id,
                Role::Source,
                Direction::Outgoing,
            )
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;

        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:geom_dim_tgt:{}", id)),
                &dim_elem_id,
                &dim_rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;
    }

    // 4. Bounding Box Element & Spatial Extent Hyperedge
    if let Some(aabb) = bounding_box {
        let aabb_elem_id = ElementId(format!("elem:aabb:{}", id));
        if hypergraph.get_element(&aabb_elem_id).is_none() {
            hypergraph
                .create_element(
                    aabb_elem_id.clone(),
                    format!(
                        "BoundingBox:min=({:.2},{:.2},{:.2}),max=({:.2},{:.2},{:.2})",
                        aabb.min.x, aabb.min.y, aabb.min.z, aabb.max.x, aabb.max.y, aabb.max.z
                    ),
                )
                .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;
        }

        let aabb_rel_id = RelationId(format!("rel:geom_aabb:{}", id));
        if hypergraph.get_relation(&aabb_rel_id).is_none() {
            hypergraph
                .create_relation(aabb_rel_id.clone(), "SpatialBoundingExtent".to_string())
                .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:geom_aabb_src:{}", id)),
                    &geom_elem_id,
                    &aabb_rel_id,
                    Role::Source,
                    Direction::Outgoing,
                )
                .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;

            hypergraph
                .attach_incidence(
                    IncidenceId(format!("inc:geom_aabb_tgt:{}", id)),
                    &aabb_elem_id,
                    &aabb_rel_id,
                    Role::Target,
                    Direction::Ingoing,
                )
                .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;
        }
    }

    Ok(())
}

/// Projects a binary geometric relation (e.g. Containment, Intersection, Adjacency) into the hypergraph.
pub fn project_geometric_relationship_to_hypergraph(
    source_id: &GeometricId,
    target_id: &GeometricId,
    relationship_kind: &str,
    hypergraph: &mut Hypergraph,
) -> GeometryResult<()> {
    let src_elem = ElementId(format!("elem:geom:{}", source_id));
    let tgt_elem = ElementId(format!("elem:geom:{}", target_id));

    let rel_id = RelationId(format!(
        "rel:geom_rel:{}:{}:{}",
        relationship_kind, source_id, target_id
    ));

    if hypergraph.get_relation(&rel_id).is_none() {
        hypergraph
            .create_relation(rel_id.clone(), relationship_kind.to_string())
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;

        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:geom_rel_src:{}", rel_id.0)),
                &src_elem,
                &rel_id,
                Role::Source,
                Direction::Outgoing,
            )
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;

        hypergraph
            .attach_incidence(
                IncidenceId(format!("inc:geom_rel_tgt:{}", rel_id.0)),
                &tgt_elem,
                &rel_id,
                Role::Target,
                Direction::Ingoing,
            )
            .map_err(|e| GeometryError::HypergraphMappingError(e.to_string()))?;
    }

    Ok(())
}
