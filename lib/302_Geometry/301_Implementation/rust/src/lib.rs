// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Geometry Domain (`SCR-LIB-GEOMETRY`)
//!
//! Authoritative normative semantic foundation for spatial form, position,
//! extent, measurement, geometric relationships, and transformations of spatial structures.
//!
//! Conforming to:
//! - `lib/302_Geometry/101_definition.md` (`SCR-LIB-GEOMETRY`, v0.1.0)
//! - `GEOMETRY-INV-001` through `GEOMETRY-INV-018`
//!
//! Foundational governing principle:
//! ```text
//! Spatial Meaning → Geometric Semantics → Representation → Implementation → Execution
//! ```

pub mod csg;
pub mod dimension;
pub mod distance;
pub mod error;
pub mod hypergraph;
pub mod invariants;
pub mod point;
pub mod predicates;
pub mod primitives;
pub mod surface;
pub mod transform;

pub use csg::{
    aabb_intersection, aabb_union, csg_difference_sdf, csg_intersection_sdf,
    csg_smooth_difference_sdf, csg_smooth_intersection_sdf, csg_smooth_union_sdf, csg_union_sdf,
};
pub use dimension::GeometricDimension;
pub use distance::{
    distance_point_aabb_sdf, distance_point_plane_signed, distance_point_point,
    distance_point_point_chebyshev, distance_point_point_manhattan, distance_point_segment,
    distance_point_sphere_sdf,
};
pub use error::{GeometryError, GeometryResult};
pub use hypergraph::{
    project_geometric_relationship_to_hypergraph, project_geometry_to_hypergraph, GeometricId,
};
pub use invariants::*;
pub use point::{Point3D, Vector3D};
pub use predicates::{
    intersect_ray_aabb, intersect_ray_plane, intersect_ray_sphere, intersect_ray_triangle,
    point_in_aabb, point_in_sphere, point_in_triangle,
};
pub use primitives::{AABB3D, LineSegment3D, Plane3D, Ray3D, Sphere3D, Triangle3D};
pub use surface::{ImplicitSurface, TriangleMesh};
pub use transform::Transform3D;

pub mod prelude {
    pub use crate::csg::*;
    pub use crate::dimension::GeometricDimension;
    pub use crate::distance::*;
    pub use crate::error::{GeometryError, GeometryResult};
    pub use crate::hypergraph::{
        project_geometric_relationship_to_hypergraph, project_geometry_to_hypergraph, GeometricId,
    };
    pub use crate::invariants::*;
    pub use crate::point::{Point3D, Vector3D};
    pub use crate::predicates::*;
    pub use crate::primitives::*;
    pub use crate::surface::{ImplicitSurface, TriangleMesh};
    pub use crate::transform::Transform3D;
}
