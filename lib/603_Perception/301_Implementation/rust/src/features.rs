use crate::provenance::PerceptualProvenance;

/// A semantically relevant extracted feature (Section 11).
#[derive(Debug, Clone, PartialEq)]
pub struct Feature {
    /// Semantic identifier for this feature.
    pub name: String,
    /// Numeric or symbolic values representing the feature.
    pub values: Vec<f64>,
    /// Declared invariances (e.g. "scale-invariant", "rotation-invariant") (Section 31).
    pub declared_invariances: Vec<String>,
    /// Provenance tracking.
    pub provenance: PerceptualProvenance,
}

impl Feature {
    pub fn new(
        name: impl Into<String>,
        values: Vec<f64>,
        provenance: PerceptualProvenance,
    ) -> Self {
        Self {
            name: name.into(),
            values,
            declared_invariances: Vec::new(),
            provenance,
        }
    }

    pub fn with_invariance(mut self, invariance: impl Into<String>) -> Self {
        self.declared_invariances.push(invariance.into());
        self
    }
}
