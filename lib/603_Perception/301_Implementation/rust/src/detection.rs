use crate::uncertainty::{Confidence, Uncertainty};
use crate::provenance::PerceptualProvenance;

/// Spatial bounding region for detected candidate.
#[derive(Debug, Clone, PartialEq)]
pub enum RegionExtent {
    Point([f64; 3]),
    BoundingBox {
        min: [f64; 3],
        max: [f64; 3],
    },
    GraphNeighborhood {
        root_node: String,
        radius: usize,
    },
    Unbounded,
}

/// A detection result (Section 12).
/// Invariant PERCEPTION-INV-010: Detection does not establish persistent semantic identity.
#[derive(Debug, Clone, PartialEq)]
pub struct Detection {
    /// Detection ID.
    pub id: String,
    /// Detected pattern or candidate phenomenon label.
    pub candidate_label: String,
    /// Spatial extent or region if localized.
    pub extent: RegionExtent,
    /// Declared confidence.
    pub confidence: Confidence,
    /// Associated uncertainty.
    pub uncertainty: Uncertainty,
    /// Provenance tracking.
    pub provenance: PerceptualProvenance,
}

impl Detection {
    pub fn new(
        id: impl Into<String>,
        candidate_label: impl Into<String>,
        extent: RegionExtent,
        confidence: Confidence,
        uncertainty: Uncertainty,
        provenance: PerceptualProvenance,
    ) -> Self {
        Self {
            id: id.into(),
            candidate_label: candidate_label.into(),
            extent,
            confidence,
            uncertainty,
            provenance,
        }
    }
}
