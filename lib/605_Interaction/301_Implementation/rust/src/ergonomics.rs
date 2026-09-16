use crate::input::InputModality;

/// Semantic interaction cost (Section 43 & INT-028).
#[derive(Debug, Clone, PartialEq)]
pub struct InteractionCost {
    pub motor_effort: f64,
    pub cognitive_load: f64,
    pub latency_ms: u64,
}

impl InteractionCost {
    pub fn new(motor_effort: f64, cognitive_load: f64, latency_ms: u64) -> Self {
        Self {
            motor_effort: motor_effort.clamp(0.0, 1.0),
            cognitive_load: cognitive_load.clamp(0.0, 1.0),
            latency_ms,
        }
    }

    pub fn total_cost_score(&self) -> f64 {
        self.motor_effort * 0.5 + self.cognitive_load * 0.5
    }
}

/// Declared accessibility preferences for accessible substitution (Section 44 & INT-018).
#[derive(Debug, Clone, PartialEq)]
pub struct AccessibilityPreference {
    pub preferred_modalities: Vec<InputModality>,
    pub switch_access_enabled: bool,
    pub high_contrast_feedback: bool,
}
