use crate::error::{PerceptionError, PerceptionResult};

/// Declared semantics of a confidence value (Section 33).
/// Confidence != Probability unless explicitly CalibratedProbability.
#[derive(Debug, Clone, PartialEq)]
pub enum ConfidenceMetric {
    /// Arbitrary heuristic score in [0.0, 1.0].
    HeuristicScore,
    /// Statistically calibrated probability measure P(correct) in [0.0, 1.0].
    CalibratedProbability,
    /// Distance-based similarity metric.
    SimilarityMetric,
    /// Ordinal qualitative ranking (Low, Medium, High).
    QualitativeRanking(String),
}

/// A declared confidence measure.
#[derive(Debug, Clone, PartialEq)]
pub struct Confidence {
    pub value: f64,
    pub metric: ConfidenceMetric,
}

impl Confidence {
    pub fn heuristic(value: f64) -> Self {
        Self {
            value: value.clamp(0.0, 1.0),
            metric: ConfidenceMetric::HeuristicScore,
        }
    }

    pub fn probability(value: f64) -> Self {
        Self {
            value: value.clamp(0.0, 1.0),
            metric: ConfidenceMetric::CalibratedProbability,
        }
    }

    pub fn is_calibrated_probability(&self) -> bool {
        matches!(self.metric, ConfidenceMetric::CalibratedProbability)
    }
}

/// Representation of perceptual uncertainty (Section 32 & PERCEPTION-INV-007).
#[derive(Debug, Clone, PartialEq)]
pub enum Uncertainty {
    /// Zero declared uncertainty (strictly asserted).
    Certain,
    /// Variance / Standard deviation over parameter estimate.
    Variance(f64),
    /// Bounded interval [lower, upper].
    Interval { lower: f64, upper: f64 },
    /// Entropy score over distribution.
    Entropy(f64),
    /// Qualitative or categorical uncertainty description.
    Descriptive(String),
}

/// A single hypothesis in an ambiguous perceptual state (Section 34 & PERCEPTION-INV-008).
#[derive(Debug, Clone, PartialEq)]
pub struct Hypothesis<T> {
    pub id: String,
    pub candidate: T,
    pub confidence: Confidence,
    pub uncertainty: Uncertainty,
    pub rationale: String,
}

/// Multi-hypothesis set representing ambiguity without premature collapse (PERCEPTION-INV-008).
#[derive(Debug, Clone, PartialEq)]
pub struct HypothesisSet<T> {
    pub hypotheses: Vec<Hypothesis<T>>,
}

impl<T> HypothesisSet<T> {
    pub fn new() -> Self {
        Self {
            hypotheses: Vec::new(),
        }
    }

    pub fn with_hypothesis(
        mut self,
        id: impl Into<String>,
        candidate: T,
        confidence: Confidence,
        uncertainty: Uncertainty,
        rationale: impl Into<String>,
    ) -> Self {
        self.hypotheses.push(Hypothesis {
            id: id.into(),
            candidate,
            confidence,
            uncertainty,
            rationale: rationale.into(),
        });
        self
    }

    pub fn len(&self) -> usize {
        self.hypotheses.len()
    }

    pub fn is_empty(&self) -> bool {
        self.hypotheses.is_empty()
    }

    pub fn is_ambiguous(&self) -> bool {
        self.hypotheses.len() > 1
    }

    /// Selects the highest confidence hypothesis only if explicitly permitted,
    /// while returning the remaining hypotheses so alternatives are not destroyed.
    pub fn select_dominant_preserving_alternatives(
        &self,
    ) -> PerceptionResult<(&Hypothesis<T>, Vec<&Hypothesis<T>>)> {
        if self.hypotheses.is_empty() {
            return Err(PerceptionError::AmbiguityIntegrityViolation(
                "Cannot select from empty hypothesis set".into(),
            ));
        }

        let mut dominant_idx = 0;
        let mut max_conf = self.hypotheses[0].confidence.value;
        for (i, h) in self.hypotheses.iter().enumerate().skip(1) {
            if h.confidence.value > max_conf {
                max_conf = h.confidence.value;
                dominant_idx = i;
            }
        }

        let dominant = &self.hypotheses[dominant_idx];
        let alternatives = self
            .hypotheses
            .iter()
            .enumerate()
            .filter(|(i, _)| *i != dominant_idx)
            .map(|(_, h)| h)
            .collect();

        Ok((dominant, alternatives))
    }
}
