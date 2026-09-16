use crate::context::PerceptualContext;
use crate::detection::Detection;
use crate::features::Feature;
use crate::classification::Classification;
use crate::identification::Identification;
use crate::observation::Observation;
use crate::provenance::PerceptualProvenance;
use crate::segmentation::Segmentation;
use crate::tracking::Track;
use crate::uncertainty::{HypothesisSet, Uncertainty};
use crate::error::{PerceptionError, PerceptionResult};

/// The resulting semantic representation produced by a perceptual process (Section 28).
#[derive(Debug, Clone, PartialEq)]
pub struct PerceptualRepresentation {
    pub id: String,
    pub features: Vec<Feature>,
    pub detections: Vec<Detection>,
    pub classifications: Vec<Classification>,
    pub identifications: Vec<Identification>,
    pub segmentations: Vec<Segmentation>,
    pub tracks: Vec<Track>,
    pub ambiguity: Option<HypothesisSet<String>>,
    /// Meaningful nullary perceptual assertions (Section 43 & PERCEPTION-INV-023).
    pub nullary_assertions: Vec<String>,
}

impl PerceptualRepresentation {
    pub fn empty(id: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            features: Vec::new(),
            detections: Vec::new(),
            classifications: Vec::new(),
            identifications: Vec::new(),
            segmentations: Vec::new(),
            tracks: Vec::new(),
            ambiguity: None,
            nullary_assertions: Vec::new(),
        }
    }
}

/// The formal conceptual tuple P = (O, C, K, T, R, U, X) defined in Section 3 of 101_definition.md.
pub struct PerceptualProcess {
    /// O = available observations
    pub observations: Vec<Observation>,
    /// C = context
    pub context: PerceptualContext,
    /// K = prior knowledge / available semantic state
    pub prior_knowledge: Vec<(String, String)>,
    /// U = declared uncertainty
    pub uncertainty: Uncertainty,
    /// X = provenance
    pub provenance: PerceptualProvenance,
}

impl PerceptualProcess {
    pub fn new(
        context: PerceptualContext,
        algorithm_id: impl Into<String>,
    ) -> Self {
        let algo = algorithm_id.into();
        let prov = PerceptualProvenance::new(&algo, &context.observer_id);
        Self {
            observations: Vec::new(),
            context,
            prior_knowledge: Vec::new(),
            uncertainty: Uncertainty::Certain,
            provenance: prov,
        }
    }

    pub fn add_observation(&mut self, obs: Observation) {
        self.provenance.source_observation_ids.push(obs.id.clone());
        self.provenance.source_entity_uris.push(obs.source_uri.clone());
        self.observations.push(obs);
    }

    pub fn add_prior_knowledge(&mut self, key: impl Into<String>, val: impl Into<String>) {
        self.prior_knowledge.push((key.into(), val.into()));
    }

    pub fn set_uncertainty(&mut self, u: Uncertainty) {
        self.uncertainty = u;
    }

    /// Executes a declared perceptual transformation T, producing representation R.
    /// Invariant PERCEPTION-INV-025: A failure must not silently become a valid assertion.
    pub fn execute_transformation<F>(
        &mut self,
        transform_name: &str,
        transform: F,
    ) -> PerceptionResult<PerceptualRepresentation>
    where
        F: FnOnce(&[Observation], &PerceptualContext, &[(String, String)]) -> PerceptionResult<PerceptualRepresentation>,
    {
        self.provenance.transformations.push(transform_name.to_string());
        let result = transform(&self.observations, &self.context, &self.prior_knowledge);

        match result {
            Ok(rep) => Ok(rep),
            Err(e) => Err(PerceptionError::PerceptualFailure(format!(
                "Transformation '{}' failed: {}",
                transform_name, e
            ))),
        }
    }
}
