use crate::uncertainty::{Confidence, Uncertainty};
use crate::provenance::PerceptualProvenance;

/// A classified label with associated confidence score.
#[derive(Debug, Clone, PartialEq)]
pub struct ScoredLabel {
    pub label: String,
    pub confidence: Confidence,
}

/// A classification result (Section 14).
#[derive(Debug, Clone, PartialEq)]
pub struct Classification {
    pub id: String,
    pub target_id: String,
    pub taxonomy_uri: String,
    pub labels: Vec<ScoredLabel>,
    pub uncertainty: Uncertainty,
    pub provenance: PerceptualProvenance,
}

impl Classification {
    pub fn new(
        id: impl Into<String>,
        target_id: impl Into<String>,
        taxonomy_uri: impl Into<String>,
        labels: Vec<ScoredLabel>,
        uncertainty: Uncertainty,
        provenance: PerceptualProvenance,
    ) -> Self {
        Self {
            id: id.into(),
            target_id: target_id.into(),
            taxonomy_uri: taxonomy_uri.into(),
            labels,
            uncertainty,
            provenance,
        }
    }

    pub fn top_label(&self) -> Option<&ScoredLabel> {
        self.labels.iter().max_by(|a, b| {
            a.confidence
                .value
                .partial_cmp(&b.confidence.value)
                .unwrap_or(core::cmp::Ordering::Equal)
        })
    }
}
