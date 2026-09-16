use crate::target::InteractionTarget;

/// Desired semantic goal or operation type (Section 27).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum IntentKind {
    Select,
    Deselect,
    Translate,
    Rotate,
    Scale,
    Create,
    Delete,
    Connect,
    Inspect,
    Trigger,
    Custom(String),
}

/// Explicit representation of intention prior to action (Section 27 & INT-005, INT-006).
#[derive(Debug, Clone, PartialEq)]
pub struct Intent {
    pub id: String,
    pub kind: IntentKind,
    pub target: InteractionTarget,
    pub confidence: f64,
    pub parameters: Vec<(String, f64)>,
}

impl Intent {
    pub fn new(id: impl Into<String>, kind: IntentKind, target: InteractionTarget) -> Self {
        Self {
            id: id.into(),
            kind,
            target,
            confidence: 1.0,
            parameters: Vec::new(),
        }
    }

    pub fn with_confidence(mut self, conf: f64) -> Self {
        self.confidence = conf.clamp(0.0, 1.0);
        self
    }

    pub fn with_param(mut self, name: impl Into<String>, val: f64) -> Self {
        self.parameters.push((name.into(), val));
        self
    }
}
