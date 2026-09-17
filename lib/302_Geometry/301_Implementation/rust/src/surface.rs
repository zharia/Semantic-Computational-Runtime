// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Surfaces & Meshes
//!
//! Discrete surface meshes and continuous implicit surfaces conforming to
//! GEOMETRY-INV-007 (Topological Integrity) and GEOMETRY-INV-013 (Representation Independence).

use crate::error::{GeometryError, GeometryResult};
use crate::point::{Point3D, Vector3D};
use crate::primitives::{AABB3D, Triangle3D};
use std::collections::HashSet;

/// A discrete 2-manifold surface represented as an indexed triangle mesh.
#[derive(Debug, Clone, PartialEq)]
pub struct TriangleMesh {
    pub vertices: Vec<Point3D>,
    pub indices: Vec<[usize; 3]>,
}

impl TriangleMesh {
    pub fn new(vertices: Vec<Point3D>, indices: Vec<[usize; 3]>) -> GeometryResult<Self> {
        let v_len = vertices.len();
        for (f_idx, tri) in indices.iter().enumerate() {
            for &idx in tri {
                if idx >= v_len {
                    return Err(GeometryError::InvalidOperation(format!(
                        "Face {} references out-of-bounds vertex index {} (mesh has {} vertices)",
                        f_idx, idx, v_len
                    )));
                }
            }
        }
        Ok(Self { vertices, indices })
    }

    pub fn vertex_count(&self) -> usize {
        self.vertices.len()
    }

    pub fn face_count(&self) -> usize {
        self.indices.len()
    }

    /// Computes unique undirected edges $\{u, v\}$ in the mesh.
    pub fn unique_edges(&self) -> Vec<(usize, usize)> {
        let mut edges = HashSet::new();
        for tri in &self.indices {
            for i in 0..3 {
                let u = tri[i];
                let v = tri[(i + 1) % 3];
                let edge = if u < v { (u, v) } else { (v, u) };
                edges.insert(edge);
            }
        }
        edges.into_iter().collect()
    }

    pub fn edge_count(&self) -> usize {
        self.unique_edges().len()
    }

    /// Computes the topological Euler characteristic: $\chi = V - E + F$.
    ///
    /// For any closed orientable surface of genus $g$: $\chi = 2 - 2g$.
    /// For a sphere: $\chi = 2$. For a torus: $\chi = 0$.
    pub fn euler_characteristic(&self) -> i64 {
        let v = self.vertex_count() as i64;
        let e = self.edge_count() as i64;
        let f = self.face_count() as i64;
        v - e + f
    }

    /// Computes total surface area by summing individual triangle areas.
    pub fn total_surface_area(&self) -> f64 {
        let mut total = 0.0;
        for tri in &self.indices {
            let t = Triangle3D::new(
                self.vertices[tri[0]],
                self.vertices[tri[1]],
                self.vertices[tri[2]],
            );
            total += t.area();
        }
        total
    }

    /// Computes unit face normals for each triangle.
    pub fn compute_face_normals(&self) -> GeometryResult<Vec<Vector3D>> {
        let mut normals = Vec::with_capacity(self.indices.len());
        for tri in &self.indices {
            let t = Triangle3D::new(
                self.vertices[tri[0]],
                self.vertices[tri[1]],
                self.vertices[tri[2]],
            );
            normals.push(t.normal()?);
        }
        Ok(normals)
    }

    /// Computes the tight axis-aligned bounding box enclosing all vertices.
    pub fn compute_bounding_box(&self) -> GeometryResult<AABB3D> {
        if self.vertices.is_empty() {
            return Err(GeometryError::DegenerateEntity(
                "Cannot compute bounding box for empty mesh".to_string(),
            ));
        }

        let mut min = self.vertices[0];
        let mut max = self.vertices[0];

        for v in &self.vertices[1..] {
            if v.x < min.x { min.x = v.x; }
            if v.y < min.y { min.y = v.y; }
            if v.z < min.z { min.z = v.z; }

            if v.x > max.x { max.x = v.x; }
            if v.y > max.y { max.y = v.y; }
            if v.z > max.z { max.z = v.z; }
        }

        AABB3D::new(min, max)
    }
}

/// An analytical or procedural implicit surface defined by zero level-set $f(p) = 0$.
pub struct ImplicitSurface {
    pub sdf: Box<dyn Fn(&Point3D) -> f64 + Send + Sync>,
}

impl ImplicitSurface {
    pub fn new<F>(f: F) -> Self
    where
        F: Fn(&Point3D) -> f64 + Send + Sync + 'static,
    {
        Self { sdf: Box::new(f) }
    }

    pub fn evaluate(&self, p: &Point3D) -> f64 {
        (self.sdf)(p)
    }

    /// Evaluates the unit surface normal at point `p` via central finite difference gradient.
    pub fn normal_at(&self, p: &Point3D, eps: f64) -> GeometryResult<Vector3D> {
        let h = if eps <= 0.0 { 1e-5 } else { eps };
        let dx = (self.sdf)(&Point3D::new(p.x + h, p.y, p.z)) - (self.sdf)(&Point3D::new(p.x - h, p.y, p.z));
        let dy = (self.sdf)(&Point3D::new(p.x, p.y + h, p.z)) - (self.sdf)(&Point3D::new(p.x, p.y - h, p.z));
        let dz = (self.sdf)(&Point3D::new(p.x, p.y, p.z + h)) - (self.sdf)(&Point3D::new(p.x, p.y, p.z - h));

        Vector3D::new(dx, dy, dz).normalize()
    }
}
