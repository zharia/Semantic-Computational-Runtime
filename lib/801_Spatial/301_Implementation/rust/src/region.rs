use crate::position::Coordinates;

/// Axis-aligned bounding box region in N dimensions (Section 6).
#[derive(Debug, Clone, PartialEq)]
pub struct BoundingBox {
    pub min: Vec<f64>,
    pub max: Vec<f64>,
}

impl BoundingBox {
    pub fn new(min: Vec<f64>, max: Vec<f64>) -> Self {
        Self { min, max }
    }

    pub fn contains_point(&self, pt: &[f64]) -> bool {
        if pt.len() != self.min.len() || pt.len() != self.max.len() {
            return false;
        }
        pt.iter()
            .zip(self.min.iter())
            .zip(self.max.iter())
            .all(|((val, min_v), max_v)| val >= min_v && val <= max_v)
    }

    pub fn intersects(&self, other: &BoundingBox) -> bool {
        if self.min.len() != other.min.len() {
            return false;
        }
        self.min
            .iter()
            .zip(self.max.iter())
            .zip(other.min.iter().zip(other.max.iter()))
            .all(|((self_min, self_max), (other_min, other_max))| {
                self_min <= other_max && self_max >= other_min
            })
    }
}

/// Hyperspherical spatial region (Section 6).
#[derive(Debug, Clone, PartialEq)]
pub struct SphereRegion {
    pub center: Coordinates,
    pub radius: f64,
}

impl SphereRegion {
    pub fn new(center: Coordinates, radius: f64) -> Self {
        Self { center, radius }
    }
}

/// Discrete 3D voxel extent (Section 6 & 18).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VoxelExtent {
    pub min_index: [i64; 3],
    pub max_index: [i64; 3],
    pub voxel_size_m: u64, // Micro-meters or explicit units
}

/// A declared spatial region or extent (Section 6).
#[derive(Debug, Clone, PartialEq)]
pub enum SpatialRegion {
    Box(BoundingBox),
    Sphere(SphereRegion),
    Discrete(VoxelExtent),
    GlobalSpace,
}
