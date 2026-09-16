use crate::boundary::BoundaryCondition;
use crate::domain::FieldDomain;
use crate::error::{FieldError, FieldResult};
use crate::interpolation::InterpolationScheme;
use crate::sampling::{SamplePoint, SamplingSemantics};
use crate::value::{FieldValue, ValueSpace};
use std::sync::Arc;

pub type AnalyticEvaluator = Arc<dyn Fn(&[f64]) -> FieldResult<FieldValue> + Send + Sync>;

#[derive(Clone)]
pub enum FieldAssignment {
    Analytic(AnalyticEvaluator),
    Grid2D {
        resolution: [usize; 2],
        values: Vec<f64>,
    },
    Grid3D {
        resolution: [usize; 3],
        values: Vec<f64>,
    },
    Sparse(Vec<SamplePoint>),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FieldProvenance {
    pub authority_sid: Option<String>,
    pub lineage: Vec<String>,
    pub creation_step: u64,
}

impl FieldProvenance {
    pub fn new(authority_sid: Option<String>) -> Self {
        Self {
            authority_sid,
            lineage: Vec::new(),
            creation_step: 0,
        }
    }
}

/// Conceptual Model: F = (D, V, A, R, T, S, I, B, P)
#[derive(Clone)]
pub struct Field {
    pub id: String,
    pub domain: FieldDomain,
    pub value_space: ValueSpace,
    pub assignment: FieldAssignment,
    pub reference_frame_id: String,
    pub sampling: SamplingSemantics,
    pub interpolation: InterpolationScheme,
    pub boundary: BoundaryCondition,
    pub provenance: FieldProvenance,
}

impl Field {
    pub fn new_analytic<F>(
        id: impl Into<String>,
        domain: FieldDomain,
        value_space: ValueSpace,
        evaluator: F,
    ) -> Self
    where
        F: Fn(&[f64]) -> FieldResult<FieldValue> + Send + Sync + 'static,
    {
        Self {
            id: id.into(),
            domain,
            value_space,
            assignment: FieldAssignment::Analytic(Arc::new(evaluator)),
            reference_frame_id: "frame:canonical".to_string(),
            sampling: SamplingSemantics::AnalyticContinuum,
            interpolation: InterpolationScheme::Linear,
            boundary: BoundaryCondition::Zero,
            provenance: FieldProvenance::new(None),
        }
    }

    pub fn new_grid_2d(
        id: impl Into<String>,
        domain: FieldDomain,
        resolution: [usize; 2],
        values: Vec<f64>,
    ) -> FieldResult<Self> {
        if domain.dimension != 2 {
            return Err(FieldError::DimensionMismatch {
                expected: 2,
                found: domain.dimension,
            });
        }
        if values.len() != resolution[0] * resolution[1] {
            return Err(FieldError::BoundaryError(format!(
                "Grid2D values count ({}) does not match resolution product ({}x{} = {})",
                values.len(),
                resolution[0],
                resolution[1],
                resolution[0] * resolution[1]
            )));
        }
        Ok(Self {
            id: id.into(),
            domain,
            value_space: ValueSpace::ScalarSpace,
            assignment: FieldAssignment::Grid2D { resolution, values },
            reference_frame_id: "frame:canonical".to_string(),
            sampling: SamplingSemantics::PointSampled,
            interpolation: InterpolationScheme::Bilinear,
            boundary: BoundaryCondition::Clamped,
            provenance: FieldProvenance::new(None),
        })
    }

    pub fn new_grid_3d(
        id: impl Into<String>,
        domain: FieldDomain,
        resolution: [usize; 3],
        values: Vec<f64>,
    ) -> FieldResult<Self> {
        if domain.dimension != 3 {
            return Err(FieldError::DimensionMismatch {
                expected: 3,
                found: domain.dimension,
            });
        }
        let total = resolution[0] * resolution[1] * resolution[2];
        if values.len() != total {
            return Err(FieldError::BoundaryError(format!(
                "Grid3D values count ({}) does not match resolution product ({})",
                values.len(),
                total
            )));
        }
        Ok(Self {
            id: id.into(),
            domain,
            value_space: ValueSpace::ScalarSpace,
            assignment: FieldAssignment::Grid3D { resolution, values },
            reference_frame_id: "frame:canonical".to_string(),
            sampling: SamplingSemantics::PointSampled,
            interpolation: InterpolationScheme::Trilinear,
            boundary: BoundaryCondition::Clamped,
            provenance: FieldProvenance::new(None),
        })
    }

    /// Evaluates the field at a given continuous coordinate point in its domain.
    pub fn evaluate(&self, point: &[f64]) -> FieldResult<FieldValue> {
        if point.len() != self.domain.dimension {
            return Err(FieldError::DimensionMismatch {
                expected: self.domain.dimension,
                found: point.len(),
            });
        }

        // Apply boundary condition mapping if point is outside domain
        let mapped_point = match self.boundary.handle_coordinate(point, &self.domain) {
            Some(p) => p,
            None => {
                return match &self.boundary {
                    BoundaryCondition::Dirichlet(val) => Ok(val.clone()),
                    BoundaryCondition::Zero => Ok(FieldValue::Scalar(0.0)),
                    _ => Err(FieldError::OutOfBounds {
                        coords: point.iter().map(|&x| x as i64).collect(),
                        domain_id: self.domain.id.clone(),
                    }),
                }
            }
        };

        match &self.assignment {
            FieldAssignment::Analytic(f) => f(&mapped_point),
            FieldAssignment::Grid2D { resolution, values } => {
                self.evaluate_grid_2d(&mapped_point, *resolution, values)
            }
            FieldAssignment::Grid3D { resolution, values } => {
                self.evaluate_grid_3d(&mapped_point, *resolution, values)
            }
            FieldAssignment::Sparse(samples) => self.evaluate_sparse(&mapped_point, samples),
        }
    }

    fn evaluate_grid_2d(
        &self,
        point: &[f64],
        resolution: [usize; 2],
        values: &[f64],
    ) -> FieldResult<FieldValue> {
        let x_norm = (point[0] - self.domain.bounds_min[0])
            / (self.domain.bounds_max[0] - self.domain.bounds_min[0]);
        let y_norm = (point[1] - self.domain.bounds_min[1])
            / (self.domain.bounds_max[1] - self.domain.bounds_min[1]);

        let fx = x_norm.clamp(0.0, 1.0) * (resolution[0] - 1) as f64;
        let fy = y_norm.clamp(0.0, 1.0) * (resolution[1] - 1) as f64;

        let x0 = (fx.floor() as usize).min(resolution[0] - 1);
        let y0 = (fy.floor() as usize).min(resolution[1] - 1);
        let x1 = (x0 + 1).min(resolution[0] - 1);
        let y1 = (y0 + 1).min(resolution[1] - 1);

        let tx = fx - x0 as f64;
        let ty = fy - y0 as f64;

        let idx = |x: usize, y: usize| -> usize { y * resolution[0] + x };

        let v00 = values[idx(x0, y0)];
        let v10 = values[idx(x1, y0)];
        let v01 = values[idx(x0, y1)];
        let v11 = values[idx(x1, y1)];

        let interpolated = match self.interpolation {
            InterpolationScheme::NearestNeighbor => {
                if tx < 0.5 {
                    if ty < 0.5 {
                        v00
                    } else {
                        v01
                    }
                } else {
                    if ty < 0.5 {
                        v10
                    } else {
                        v11
                    }
                }
            }
            _ => InterpolationScheme::bilerp(v00, v10, v01, v11, tx, ty),
        };

        Ok(FieldValue::Scalar(interpolated))
    }

    fn evaluate_grid_3d(
        &self,
        point: &[f64],
        resolution: [usize; 3],
        values: &[f64],
    ) -> FieldResult<FieldValue> {
        let x_norm = (point[0] - self.domain.bounds_min[0])
            / (self.domain.bounds_max[0] - self.domain.bounds_min[0]);
        let y_norm = (point[1] - self.domain.bounds_min[1])
            / (self.domain.bounds_max[1] - self.domain.bounds_min[1]);
        let z_norm = (point[2] - self.domain.bounds_min[2])
            / (self.domain.bounds_max[2] - self.domain.bounds_min[2]);

        let fx = x_norm.clamp(0.0, 1.0) * (resolution[0] - 1) as f64;
        let fy = y_norm.clamp(0.0, 1.0) * (resolution[1] - 1) as f64;
        let fz = z_norm.clamp(0.0, 1.0) * (resolution[2] - 1) as f64;

        let x0 = (fx.floor() as usize).min(resolution[0] - 1);
        let y0 = (fy.floor() as usize).min(resolution[1] - 1);
        let z0 = (fz.floor() as usize).min(resolution[2] - 1);

        let x1 = (x0 + 1).min(resolution[0] - 1);
        let y1 = (y0 + 1).min(resolution[1] - 1);
        let z1 = (z0 + 1).min(resolution[2] - 1);

        let tx = fx - x0 as f64;
        let ty = fy - y0 as f64;
        let tz = fz - z0 as f64;

        let idx = |x: usize, y: usize, z: usize| -> usize {
            (z * resolution[1] + y) * resolution[0] + x
        };

        let c000 = values[idx(x0, y0, z0)];
        let c100 = values[idx(x1, y0, z0)];
        let c010 = values[idx(x0, y1, z0)];
        let c110 = values[idx(x1, y1, z0)];
        let c001 = values[idx(x0, y0, z1)];
        let c101 = values[idx(x1, y0, z1)];
        let c011 = values[idx(x0, y1, z1)];
        let c111 = values[idx(x1, y1, z1)];

        let interpolated = match self.interpolation {
            InterpolationScheme::NearestNeighbor => {
                let rx = if tx < 0.5 { x0 } else { x1 };
                let ry = if ty < 0.5 { y0 } else { y1 };
                let rz = if tz < 0.5 { z0 } else { z1 };
                values[idx(rx, ry, rz)]
            }
            _ => InterpolationScheme::trilerp(c000, c100, c010, c110, c001, c101, c011, c111, tx, ty, tz),
        };

        Ok(FieldValue::Scalar(interpolated))
    }

    fn evaluate_sparse(&self, point: &[f64], samples: &[SamplePoint]) -> FieldResult<FieldValue> {
        if samples.is_empty() {
            return Err(FieldError::UndefinedEvaluation(
                "No samples available in sparse field".to_string(),
            ));
        }

        // Inverse distance weighted (IDW) interpolation
        let mut weights_sum = 0.0;
        let mut total_scalar = 0.0;

        for s in samples {
            let dist_sq: f64 = point
                .iter()
                .zip(s.coords.iter())
                .map(|(a, b)| (a - b).powi(2))
                .sum();

            if dist_sq < 1e-12 {
                return Ok(s.value.clone());
            }

            let w = s.weight / dist_sq;
            weights_sum += w;
            if let Ok(sc) = s.value.as_scalar() {
                total_scalar += sc * w;
            }
        }

        if weights_sum > 0.0 {
            Ok(FieldValue::Scalar(total_scalar / weights_sum))
        } else {
            Ok(samples[0].value.clone())
        }
    }
}
