/// Modality of raw interaction input (Section 10).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum InputModality {
    Pointer,
    Touch,
    Spatial,
    Voice,
    Gaze,
    SemanticCommand,
    Custom(String),
}

/// State of a pointing device or contact (Section 11).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PointerState {
    Hover,
    PrimaryDown,
    SecondaryDown,
    Dragging,
    Released,
}

/// Device-independent pointer abstraction (Section 11 & INT-002).
#[derive(Debug, Clone, PartialEq)]
pub struct Pointer {
    pub id: String,
    pub coordinates: [f64; 3],
    pub direction: Option<[f64; 3]>,
    pub state: PointerState,
    pub pressure: f64,
}

impl Pointer {
    pub fn new(id: impl Into<String>, coordinates: [f64; 3], state: PointerState) -> Self {
        Self {
            id: id.into(),
            coordinates,
            direction: None,
            state,
            pressure: 1.0,
        }
    }
}

/// A discrete raw input event (Section 10).
#[derive(Debug, Clone, PartialEq)]
pub struct Input {
    pub id: String,
    pub modality: InputModality,
    pub timestamp_ns: u64,
    pub pointer: Option<Pointer>,
    pub payload: Vec<f64>,
}

impl Input {
    pub fn pointer_event(
        id: impl Into<String>,
        timestamp_ns: u64,
        pointer: Pointer,
    ) -> Self {
        Self {
            id: id.into(),
            modality: InputModality::Pointer,
            timestamp_ns,
            pointer: Some(pointer),
            payload: Vec::new(),
        }
    }

    pub fn semantic_event(
        id: impl Into<String>,
        timestamp_ns: u64,
        command_tokens: Vec<f64>,
    ) -> Self {
        Self {
            id: id.into(),
            modality: InputModality::SemanticCommand,
            timestamp_ns,
            pointer: None,
            payload: command_tokens,
        }
    }
}
