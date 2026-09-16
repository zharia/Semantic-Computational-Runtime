use crate::position::Coordinates;
use crate::error::{SpatialError, SpatialResult};

/// Geometric nature of spatial transformation (Section 20).
#[derive(Debug, Clone, PartialEq)]
pub enum SpatialTransformKind {
    Translation(Vec<f64>),
    UniformScale(f64),
    Rotation2D(f64), // Angle in radians
    CustomAffine { matrix: Vec<Vec<f64>>, offset: Vec<f64> },
}

/// A spatial transformation with explicit source and target reference contexts (Section 20 & SPATIAL-INV-012).
#[derive(Debug, Clone, PartialEq)]
pub struct SpatialTransform {
    pub id: String,
    pub source_frame_id: String,
    pub target_frame_id: String,
    pub kind: SpatialTransformKind,
}

impl SpatialTransform {
    pub fn translation(
        id: impl Into<String>,
        source_frame_id: impl Into<String>,
        target_frame_id: impl Into<String>,
        delta: Vec<f64>,
    ) -> Self {
        Self {
            id: id.into(),
            source_frame_id: source_frame_id.into(),
            target_frame_id: target_frame_id.into(),
            kind: SpatialTransformKind::Translation(delta),
        }
    }

    pub fn uniform_scale(
        id: impl Into<String>,
        source_frame_id: impl Into<String>,
        target_frame_id: impl Into<String>,
        scale: f64,
    ) -> Self {
        Self {
            id: id.into(),
            source_frame_id: source_frame_id.into(),
            target_frame_id: target_frame_id.into(),
            kind: SpatialTransformKind::UniformScale(scale),
        }
    }

    /// Applies the transformation to coordinates, preserving SPATIAL-INV-012.
    pub fn apply(&self, coords: &Coordinates) -> SpatialResult<Coordinates> {
        if coords.reference_frame_id != self.source_frame_id {
            return Err(SpatialError::IncompatibleReferenceFrame {
                source_frame: coords.reference_frame_id.clone(),
                target_frame: self.source_frame_id.clone(),
            });
        }

        let transformed_values = match &self.kind {
            SpatialTransformKind::Translation(delta) => {
                if coords.dim() != delta.len() {
                    return Err(SpatialError::DimensionMismatch {
                        expected: delta.len(),
                        found: coords.dim(),
                    });
                }
                coords
                    .values
                    .iter()
                    .zip(delta.iter())
                    .map(|(c, d)| c + d)
                    .collect()
            }
            SpatialTransformKind::UniformScale(scale) => {
                coords.values.iter().map(|c| c * scale).collect()
            }
            SpatialTransformKind::Rotation2D(theta) => {
                if coords.dim() != 2 {
                    return Err(SpatialError::DimensionMismatch {
                        expected: 2,
                        found: coords.dim(),
                    });
                }
                let x = coords.values[0];
                let y = coords.values[1];
                let cos_t = theta.cos();
                let sin_t = theta.sin();
                vec![x * cos_t - y * sin_t, x * sin_t + y * cos_t]
            }
            SpatialTransformKind::CustomAffine { matrix, offset } => {
                if coords.dim() != offset.len() {
                    return Err(SpatialError::DimensionMismatch {
                        expected: offset.len(),
                        found: coords.dim(),
                    });
                }
                let mut out = Vec::with_capacity(coords.dim());
                for (row, off) in matrix.iter().zip(offset.iter()) {
                    let dot: f64 = row.iter().zip(coords.values.iter()).map(|(m, c)| m * c).sum();
                    out.push(dot + off);
                }
                out
            }
        };

        Ok(Coordinates::new(self.target_frame_id.clone(), transformed_values))
    }
}
