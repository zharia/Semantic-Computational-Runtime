use crate::metric::{compute_distance, DistanceMetric};
use crate::position::{Coordinates, Position};
use crate::region::BoundingBox;
use crate::error::SpatialResult;

/// A declarative spatial query (Section 15 & SPATIAL-INV-014).
#[derive(Debug, Clone, PartialEq)]
pub enum SpatialQuery {
    WithinRadius {
        center: Coordinates,
        radius: f64,
        metric: DistanceMetric,
    },
    WithinBoundingBox {
        bounds: BoundingBox,
    },
    KNearestNeighbors {
        center: Coordinates,
        k: usize,
        metric: DistanceMetric,
    },
}

impl SpatialQuery {
    /// Evaluates the spatial query over a candidate set of positions.
    /// Invariant SPATIAL-INV-014: Semantics remain independent of indexing structures.
    pub fn evaluate<'a>(&self, candidates: &'a [Position]) -> SpatialResult<Vec<&'a Position>> {
        match self {
            Self::WithinRadius { center, radius, metric } => {
                let mut matches = Vec::new();
                for pos in candidates {
                    if pos.coordinates.reference_frame_id == center.reference_frame_id {
                        let dist = compute_distance(&pos.coordinates, center, *metric)?;
                        if dist.value <= *radius {
                            matches.push(pos);
                        }
                    }
                }
                Ok(matches)
            }
            Self::WithinBoundingBox { bounds } => {
                let mut matches = Vec::new();
                for pos in candidates {
                    if bounds.contains_point(&pos.coordinates.values) {
                        matches.push(pos);
                    }
                }
                Ok(matches)
            }
            Self::KNearestNeighbors { center, k, metric } => {
                let mut scored: Vec<(f64, &'a Position)> = Vec::new();
                for pos in candidates {
                    if pos.coordinates.reference_frame_id == center.reference_frame_id {
                        let dist = compute_distance(&pos.coordinates, center, *metric)?;
                        scored.push((dist.value, pos));
                    }
                }
                scored.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap_or(core::cmp::Ordering::Equal));
                Ok(scored.into_iter().take(*k).map(|(_, pos)| pos).collect())
            }
        }
    }
}
