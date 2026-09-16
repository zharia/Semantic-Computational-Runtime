/// Interaction operational mode (Section 64).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum InteractionMode {
    Navigation,
    Selection,
    Manipulation,
    Creation,
    Inspection,
    Annotation,
    Connection,
    SimulationControl,
    Custom(String),
}

/// The context within which an interaction expression is evaluated (Section 28 & INT-007).
#[derive(Debug, Clone, PartialEq)]
pub struct InteractionContext {
    pub id: String,
    pub mode: InteractionMode,
    pub active_actor_id: String,
    pub spatial_frame: String,
    pub parameters: Vec<(String, String)>,
}

impl InteractionContext {
    pub fn new(
        id: impl Into<String>,
        mode: InteractionMode,
        active_actor_id: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            mode,
            active_actor_id: active_actor_id.into(),
            spatial_frame: "world".into(),
            parameters: Vec::new(),
        }
    }

    pub fn with_frame(mut self, frame: impl Into<String>) -> Self {
        self.spatial_frame = frame.into();
        self
    }

    pub fn with_param(mut self, key: impl Into<String>, val: impl Into<String>) -> Self {
        self.parameters.push((key.into(), val.into()));
        self
    }
}
