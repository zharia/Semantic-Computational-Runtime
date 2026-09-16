use crate::position::Coordinates;
use crate::error::{SpatialError, SpatialResult};

/// Declared metric used to measure distance and proximity (Section 9 & SPATIAL-INV-006).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum DistanceMetric {
    Euclidean,
    Manhattan,
    Chebyshev,
    GeodesicHaversine,
    GraphHop,
}

/// A computed or declared spatial distance retaining its metric origin (Section 9 & SPATIAL-INV-006).
#[derive(Debug, Clone, PartialEq)]
pub struct Distance {
    pub value: f64,
    pub metric: DistanceMetric,
}

impl Distance {
    pub fn new(value: f64, metric: DistanceMetric) -> Self {
        Self { value, metric }
    }
}

/// Qualitative spatial proximity (Section 10).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Proximity {
    Coincident,
    Adjacent,
    Near,
    Medium,
    Far,
    OutOfRange,
}

/// Computes distance between two coordinates under an explicit metric.
pub fn compute_distance(
    a: &Coordinates,
    b: &Coordinates,
    metric: DistanceMetric,
) -> SpatialResult<Distance> {
    if a.reference_frame_id != b.reference_frame_id {
        return Err(SpatialError::IncompatibleReferenceFrame {
            source_frame: a.reference_frame_id.clone(),
            target_frame: b.reference_frame_id.clone(),
        });
    }

    if a.dim() != b.dim() {
        return Err(SpatialError::DimensionMismatch {
            expected: a.dim(),
            found: b.dim(),
        });
    }

    let val = match metric {
        DistanceMetric::Euclidean => {
            let sum_sq: f64 = a
                .values
                .iter()
                .zip(b.values.iter())
                .map(|(x, y)| (x - y).powi(2))
                .sum();
            sum_sq.sqrt()
        }
        DistanceMetric::Manhattan => a
            .values
            .iter()
            .zip(b.values.iter())
            .map(|(x, y)| (x - y).abs())
            .sum(),
        DistanceMetric::Chebyshev => a
            .values
            .iter()
            .zip(b.values.iter())
            .map(|(x, y)| (x - y).abs())
            .fold(0.0, f64::max),
        DistanceMetric::GeodesicHaversine => {
            if a.dim() != 2 {
                return Err(SpatialError::DimensionMismatch {
                    expected: 2,
                    found: a.dim(),
                });
            }
            // Latitude / Longitude in degrees
            let lat1 = a.values[0].to_radians();
            let lon1 = a.values[1].to_radians();
            let lat2 = b.values[0].to_radians();
            let lon2 = b.values[1].to_radians();

            let dlat = lat2 - lat1;
            let dlon = lon2 - lon1;

            let sin_dlat_2 = (dlat / 2.0).sin();
            let sin_dlon_2 = (dlon / 2.0).sin();

            let h = sin_dlat_2 * sin_dlat_2 + lat1.cos() * lat2.cos() * sin_dlon_2 * sin_dlon_2;
            let c = 2.0 * h.sqrt().atan2((1.0 - h).sqrt());
            const EARTH_RADIUS_M: f64 = 6_371_000.0;
            EARTH_RADIUS_M * c
        }
        DistanceMetric::GraphHop => {
            if a.dim() != 1 {
                return Err(SpatialError::DimensionMismatch {
                    expected: 1,
                    found: a.dim(),
                });
            }
            (a.values[0] - b.values[0]).abs()
        }
    };

    Ok(Distance::new(val, metric))
}
