// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Geometric Transformations
//!
//! Affine, rigid-body, and similarity transformations conforming to
//! GEOMETRY-INV-006 (Transformation Integrity) and GEOMETRY-INV-003 (Coordinate Integrity).

use crate::error::{GeometryError, GeometryResult};
use crate::point::{Point3D, Vector3D};
use crate::primitives::{AABB3D, Ray3D};
use scr_math::Quaternion;

/// A 3D spatial affine transformation composed of scale, rotation, and translation:
/// $T(p) = R \cdot (S \cdot p) + t$.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Transform3D {
    pub translation: Vector3D,
    pub rotation: Quaternion,
    pub scale: Vector3D,
}

impl Transform3D {
    pub fn identity() -> Self {
        Self {
            translation: Vector3D::ZERO,
            rotation: Quaternion::identity(),
            scale: Vector3D::new(1.0, 1.0, 1.0),
        }
    }

    pub fn from_translation(t: Vector3D) -> Self {
        Self {
            translation: t,
            rotation: Quaternion::identity(),
            scale: Vector3D::new(1.0, 1.0, 1.0),
        }
    }

    pub fn from_rotation(q: Quaternion) -> Self {
        Self {
            translation: Vector3D::ZERO,
            rotation: q,
            scale: Vector3D::new(1.0, 1.0, 1.0),
        }
    }

    pub fn from_scale(s: Vector3D) -> Self {
        Self {
            translation: Vector3D::ZERO,
            rotation: Quaternion::identity(),
            scale: s,
        }
    }

    pub fn new(translation: Vector3D, rotation: Quaternion, scale: Vector3D) -> Self {
        Self { translation, rotation, scale }
    }

    /// Checks if this transformation is a rigid-body isometry (scale is (1, 1, 1)).
    pub fn is_rigid(&self) -> bool {
        (self.scale.x - 1.0).abs() < 1e-9
            && (self.scale.y - 1.0).abs() < 1e-9
            && (self.scale.z - 1.0).abs() < 1e-9
    }

    /// Applies transformation to a 3D position point: $p' = R \cdot (S \cdot p) + t$.
    pub fn apply_point(&self, p: &Point3D) -> Point3D {
        // 1. Scale
        let sp = Vector3D::new(p.x * self.scale.x, p.y * self.scale.y, p.z * self.scale.z);
        // 2. Rotate
        let math_vec = scr_math::Vector::from(sp);
        let rot_vec = self.rotation.rotate_vector(&math_vec).unwrap_or(math_vec);
        let rot_sp = Vector3D::try_from(rot_vec).unwrap_or(sp);
        // 3. Translate
        Point3D::ORIGIN + rot_sp + self.translation
    }

    /// Applies transformation to a 3D displacement vector: $v' = R \cdot (S \cdot v)$.
    ///
    /// Notice: Vectors are invariant under translation (pure directional displacements).
    pub fn apply_vector(&self, v: &Vector3D) -> Vector3D {
        let sv = Vector3D::new(v.x * self.scale.x, v.y * self.scale.y, v.z * self.scale.z);
        let math_vec = scr_math::Vector::from(sv);
        let rot_vec = self.rotation.rotate_vector(&math_vec).unwrap_or(math_vec);
        Vector3D::try_from(rot_vec).unwrap_or(sv)
    }

    /// Transforms a ray by transforming origin as a point and direction as a vector.
    pub fn apply_ray(&self, ray: &Ray3D) -> GeometryResult<Ray3D> {
        let new_origin = self.apply_point(&ray.origin);
        let new_dir = self.apply_vector(&ray.direction).normalize()?;
        Ok(Ray3D { origin: new_origin, direction: new_dir })
    }

    /// Transforms an AABB by transforming all 8 corner points and taking the tight bounding box.
    pub fn apply_aabb(&self, aabb: &AABB3D) -> GeometryResult<AABB3D> {
        let corners = [
            Point3D::new(aabb.min.x, aabb.min.y, aabb.min.z),
            Point3D::new(aabb.min.x, aabb.min.y, aabb.max.z),
            Point3D::new(aabb.min.x, aabb.max.y, aabb.min.z),
            Point3D::new(aabb.min.x, aabb.max.y, aabb.max.z),
            Point3D::new(aabb.max.x, aabb.min.y, aabb.min.z),
            Point3D::new(aabb.max.x, aabb.min.y, aabb.max.z),
            Point3D::new(aabb.max.x, aabb.max.y, aabb.min.z),
            Point3D::new(aabb.max.x, aabb.max.y, aabb.max.z),
        ];

        let first = self.apply_point(&corners[0]);
        let mut min = first;
        let mut max = first;

        for pt in &corners[1..] {
            let tpt = self.apply_point(pt);
            if tpt.x < min.x { min.x = tpt.x; }
            if tpt.y < min.y { min.y = tpt.y; }
            if tpt.z < min.z { min.z = tpt.z; }

            if tpt.x > max.x { max.x = tpt.x; }
            if tpt.y > max.y { max.y = tpt.y; }
            if tpt.z > max.z { max.z = tpt.z; }
        }

        AABB3D::new(min, max)
    }

    /// Computes the inverse transform $T^{-1}$.
    pub fn inverse(&self) -> GeometryResult<Self> {
        if self.scale.x == 0.0 || self.scale.y == 0.0 || self.scale.z == 0.0 {
            return Err(GeometryError::InvalidOperation(
                "Cannot invert transformation with zero scale component".to_string(),
            ));
        }

        let inv_scale = Vector3D::new(1.0 / self.scale.x, 1.0 / self.scale.y, 1.0 / self.scale.z);
        let inv_rot = self.rotation.inverse().map_err(|e| GeometryError::InvalidOperation(e.to_string()))?;

        // t' = - S⁻¹ · R⁻¹ · t
        let neg_t = -self.translation;
        let math_neg_t = scr_math::Vector::from(neg_t);
        let rot_neg_t = inv_rot.rotate_vector(&math_neg_t).map_err(|e| GeometryError::InvalidOperation(e.to_string()))?;
        let v_rot = Vector3D::try_from(rot_neg_t)?;
        let inv_t = Vector3D::new(v_rot.x * inv_scale.x, v_rot.y * inv_scale.y, v_rot.z * inv_scale.z);

        Ok(Self {
            translation: inv_t,
            rotation: inv_rot,
            scale: inv_scale,
        })
    }
}
