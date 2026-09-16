/// Provenance record for a perceptual result (Section 45 & PERCEPTION-INV-009).
#[derive(Debug, Clone, PartialEq)]
pub struct PerceptualProvenance {
    /// Source observation IDs that contributed to this result.
    pub source_observation_ids: Vec<String>,
    /// Source entity or field URIs.
    pub source_entity_uris: Vec<String>,
    /// Applied transformations (pipeline steps).
    pub transformations: Vec<String>,
    /// Underlying model or algorithm identifier.
    pub algorithm_id: String,
    /// Provider adapter identifier if executed via a provider.
    pub provider_id: Option<String>,
    /// Context ID under which perception occurred.
    pub context_id: String,
}

impl PerceptualProvenance {
    pub fn new(
        algorithm_id: impl Into<String>,
        context_id: impl Into<String>,
    ) -> Self {
        Self {
            source_observation_ids: Vec::new(),
            source_entity_uris: Vec::new(),
            transformations: Vec::new(),
            algorithm_id: algorithm_id.into(),
            provider_id: None,
            context_id: context_id.into(),
        }
    }

    pub fn with_source_observation(mut self, obs_id: impl Into<String>) -> Self {
        self.source_observation_ids.push(obs_id.into());
        self
    }

    pub fn with_transformation(mut self, transform: impl Into<String>) -> Self {
        self.transformations.push(transform.into());
        self
    }

    pub fn with_provider(mut self, provider: impl Into<String>) -> Self {
        self.provider_id = Some(provider.into());
        self
    }
}
