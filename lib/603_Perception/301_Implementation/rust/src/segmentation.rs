use crate::provenance::PerceptualProvenance;

/// Domain of a segmentation (Section 16).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SegmentationDomain {
    Spatial3D,
    Spatial2D,
    TemporalInterval,
    GraphPartition,
    FieldSubregion,
    SemanticHierarchy,
}

/// A partition region resulting from segmentation.
#[derive(Debug, Clone, PartialEq)]
pub struct SegmentRegion {
    pub segment_id: String,
    pub semantic_label: String,
    pub member_elements: Vec<String>,
}

/// A segmentation result (Section 16).
#[derive(Debug, Clone, PartialEq)]
pub struct Segmentation {
    pub id: String,
    pub domain: SegmentationDomain,
    pub regions: Vec<SegmentRegion>,
    pub provenance: PerceptualProvenance,
}

impl Segmentation {
    pub fn new(
        id: impl Into<String>,
        domain: SegmentationDomain,
        regions: Vec<SegmentRegion>,
        provenance: PerceptualProvenance,
    ) -> Self {
        Self {
            id: id.into(),
            domain,
            regions,
            provenance,
        }
    }
}
