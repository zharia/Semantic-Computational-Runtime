use crate::uncertainty::{Confidence, Uncertainty};
use crate::provenance::PerceptualProvenance;

/// An identification assertion (Section 15 & PERCEPTION-INV-010).
/// Strictly distinguishes identity from similarity.
#[derive(Debug, Clone, PartialEq)]
pub struct Identification {
    /// Identification assertion ID.
    pub id: String,
    /// The persistent SCR semantic entity identity being asserted.
    pub persistent_entity_id: String,
    /// Similarity measure [0.0, 1.0] if derived from matching.
    pub appearance_similarity: Option<f64>,
    /// Confidence in the identity assertion.
    pub confidence: Confidence,
    /// Associated uncertainty.
    pub uncertainty: Uncertainty,
    /// Full provenance.
    pub provenance: PerceptualProvenance,
}

impl Identification {
    pub fn new(
        id: impl Into<String>,
        persistent_entity_id: impl Into<String>,
        confidence: Confidence,
        uncertainty: Uncertainty,
        provenance: PerceptualProvenance,
    ) -> Self {
        Self {
            id: id.into(),
            persistent_entity_id: persistent_entity_id.into(),
            appearance_similarity: None,
            confidence,
            uncertainty,
            provenance,
        }
    }

    pub fn with_similarity(mut self, sim: f64) -> Self {
        self.appearance_similarity = Some(sim);
        self
    }
}
