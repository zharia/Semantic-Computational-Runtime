/// Fidelity level of a serialization or deserialization operation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum FidelityLevel {
    /// Bit-for-bit or fully isomorphic semantic and structural reconstruction.
    ExactReconstruction,
    /// Preserves structural topology and relationships; layout or internal tokens may differ.
    StructuralEquivalence,
    /// Preserves an identifiable subset of fields; unknown fields omitted or ignored.
    SubsetPreservation,
    /// Known semantic loss occurred during transformation.
    Lossy,
}

/// Detailed fidelity report disclosing whether information was lost and what specifically was dropped.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FidelityReport {
    pub level: FidelityLevel,
    pub disclosures: Vec<String>,
}

impl FidelityReport {
    pub fn exact() -> Self {
        Self {
            level: FidelityLevel::ExactReconstruction,
            disclosures: Vec::new(),
        }
    }

    pub fn with_loss(level: FidelityLevel, disclosures: Vec<String>) -> Self {
        Self { level, disclosures }
    }

    pub fn is_exact(&self) -> bool {
        self.level == FidelityLevel::ExactReconstruction && self.disclosures.is_empty()
    }
}
