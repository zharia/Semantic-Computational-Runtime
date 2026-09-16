/// Modality classification for available information (Section 9).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum Modality {
    Visual,
    Auditory,
    Tactile,
    Thermal,
    Chemical,
    Electromagnetic,
    Proprioceptive,
    Textual,
    Symbolic,
    Numerical,
    Spatial,
    Temporal,
    Semantic,
    Custom(String),
}

/// Boundary mechanism through which an observation entered the computational domain (Section 6 & 8).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ObservationBoundary {
    Direct,
    Indirect,
    Partial,
    Sampled,
    Aggregated,
    Transformed,
    Simulated,
    ExternallySupplied,
    InferredFromObservation,
}

/// Clocks and timestamps preserved distinctively to satisfy PERCEPTION-INV-011.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TemporalIntegrity {
    pub observation_time_ns: u64,
    pub event_time_ns: Option<u64>,
    pub semantic_time_ns: Option<u64>,
    pub simulation_time_ns: Option<u64>,
    pub processing_time_ns: Option<u64>,
}

impl TemporalIntegrity {
    pub fn new(observation_time_ns: u64) -> Self {
        Self {
            observation_time_ns,
            event_time_ns: None,
            semantic_time_ns: None,
            simulation_time_ns: None,
            processing_time_ns: None,
        }
    }
}

/// Status of an observation, supporting PERCEPTION-INV-018 (Absence of observation != absence of phenomenon).
#[derive(Debug, Clone, PartialEq)]
pub enum ObservationStatus {
    /// Information was directly or indirectly observed.
    Observed,
    /// Information was not observed due to occlusion.
    Occluded { reason: String },
    /// Information was out of sensor or observation range.
    OutOfRange,
    /// Sensor, transport, or acquisition mechanism failed.
    SensorFailure { error: String },
    /// Information was filtered out by semantic or computational filter.
    Filtered { criteria: String },
    /// Known unobserved state.
    Unknown,
}

/// A discrete observation input boundary for Perception.
#[derive(Debug, Clone, PartialEq)]
pub struct Observation {
    /// Semantic ID of this observation.
    pub id: String,
    /// Source state, entity, or field reference URI.
    pub source_uri: String,
    /// Declared modality.
    pub modality: Modality,
    /// Input boundary type.
    pub boundary: ObservationBoundary,
    /// Distinct temporal milestones.
    pub temporal: TemporalIntegrity,
    /// Status of the observation (Observed, Occluded, Failed, etc.).
    pub status: ObservationStatus,
    /// Raw observation payload values (technology-independent).
    pub data: Vec<f64>,
    /// Metadata tags.
    pub metadata: Vec<(String, String)>,
}

impl Observation {
    pub fn new(
        id: impl Into<String>,
        source_uri: impl Into<String>,
        modality: Modality,
        data: Vec<f64>,
        observation_time_ns: u64,
    ) -> Self {
        Self {
            id: id.into(),
            source_uri: source_uri.into(),
            modality,
            boundary: ObservationBoundary::Direct,
            temporal: TemporalIntegrity::new(observation_time_ns),
            status: ObservationStatus::Observed,
            data,
            metadata: Vec::new(),
        }
    }

    /// Creates an explicit unobserved state record (e.g. occlusion or failure) satisfying INV-018.
    pub fn new_unobserved(
        id: impl Into<String>,
        source_uri: impl Into<String>,
        modality: Modality,
        status: ObservationStatus,
        observation_time_ns: u64,
    ) -> Self {
        Self {
            id: id.into(),
            source_uri: source_uri.into(),
            modality,
            boundary: ObservationBoundary::Indirect,
            temporal: TemporalIntegrity::new(observation_time_ns),
            status,
            data: Vec::new(),
            metadata: Vec::new(),
        }
    }

    pub fn is_observed(&self) -> bool {
        matches!(self.status, ObservationStatus::Observed)
    }
}
