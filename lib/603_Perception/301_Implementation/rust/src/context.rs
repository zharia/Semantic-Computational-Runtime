/// Declared spatial reference system for localization and geometry (Section 17 & PERCEPTION-INV-012).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SpatialReference {
    Euclidean3D { frame_id: String },
    Euclidean2D { frame_id: String },
    Geospatial { datum: String },
    SemanticSpace { metric: String },
    GraphTopology { graph_uri: String },
    Manifold { dimension: usize, chart: String },
    None,
}

/// The context relative to which a perceptual process is evaluated (Section 3 & 22, PERCEPTION-INV-006).
#[derive(Debug, Clone, PartialEq)]
pub struct PerceptualContext {
    /// Declared perceiving system or observer ID.
    pub observer_id: String,
    /// Spatial reference system.
    pub spatial_reference: SpatialReference,
    /// Perceptual task or purpose.
    pub task: String,
    /// Declared environment parameters (e.g. ambient conditions, background fields).
    pub environment: Vec<(String, String)>,
    /// Active semantic invariant declarations.
    pub declared_invariants: Vec<String>,
}

impl PerceptualContext {
    pub fn new(observer_id: impl Into<String>, task: impl Into<String>) -> Self {
        Self {
            observer_id: observer_id.into(),
            spatial_reference: SpatialReference::None,
            task: task.into(),
            environment: Vec::new(),
            declared_invariants: Vec::new(),
        }
    }

    pub fn with_spatial_reference(mut self, ref_system: SpatialReference) -> Self {
        self.spatial_reference = ref_system;
        self
    }

    pub fn with_invariant(mut self, invariant: impl Into<String>) -> Self {
        self.declared_invariants.push(invariant.into());
        self
    }

    pub fn with_env(mut self, key: impl Into<String>, val: impl Into<String>) -> Self {
        self.environment.push((key.into(), val.into()));
        self
    }
}
