use crate::error::{FieldError, FieldResult};

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum FieldDomainKind {
    ContinuousEuclidean,
    DiscreteGrid,
    ManifoldSurface,
    GraphTopology,
    ProductSpace,
}

#[derive(Debug, Clone, PartialEq)]
pub struct FieldDomain {
    pub id: String,
    pub kind: FieldDomainKind,
    pub dimension: usize,
    pub bounds_min: Vec<f64>,
    pub bounds_max: Vec<f64>,
}

impl FieldDomain {
    pub fn new(
        id: impl Into<String>,
        kind: FieldDomainKind,
        bounds_min: Vec<f64>,
        bounds_max: Vec<f64>,
    ) -> FieldResult<Self> {
        let dimension = bounds_min.len();
        if dimension != bounds_max.len() {
            return Err(FieldError::DimensionMismatch {
                expected: dimension,
                found: bounds_max.len(),
            });
        }
        for (min, max) in bounds_min.iter().zip(bounds_max.iter()) {
            if min >= max {
                return Err(FieldError::BoundaryError(format!(
                    "Domain min ({}) must be strictly less than max ({})",
                    min, max
                )));
            }
        }
        Ok(Self {
            id: id.into(),
            kind,
            dimension,
            bounds_min,
            bounds_max,
        })
    }

    pub fn new_2d(
        id: impl Into<String>,
        x_min: f64,
        x_max: f64,
        y_min: f64,
        y_max: f64,
    ) -> FieldResult<Self> {
        Self::new(
            id,
            FieldDomainKind::ContinuousEuclidean,
            vec![x_min, y_min],
            vec![x_max, y_max],
        )
    }

    pub fn new_3d(
        id: impl Into<String>,
        x_min: f64,
        x_max: f64,
        y_min: f64,
        y_max: f64,
        z_min: f64,
        z_max: f64,
    ) -> FieldResult<Self> {
        Self::new(
            id,
            FieldDomainKind::ContinuousEuclidean,
            vec![x_min, y_min, z_min],
            vec![x_max, y_max, z_max],
        )
    }

    pub fn contains(&self, point: &[f64]) -> bool {
        if point.len() != self.dimension {
            return false;
        }
        for i in 0..self.dimension {
            if point[i] < self.bounds_min[i] || point[i] > self.bounds_max[i] {
                return false;
            }
        }
        true
    }

    pub fn measure(&self) -> f64 {
        let mut m = 1.0;
        for i in 0..self.dimension {
            m *= self.bounds_max[i] - self.bounds_min[i];
        }
        m
    }
}
