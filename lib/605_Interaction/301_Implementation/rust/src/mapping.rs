use crate::intent::Intent;
use crate::context::InteractionContext;
use crate::error::{InteractionError, InteractionResult};

/// Declared reversibility properties of an action (Section 66).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Reversibility {
    Reversible,
    Irreversible,
    ConditionallyReversible,
    Transactional,
}

/// A semantic action requested by an intent (Section 31 & INT-006).
#[derive(Debug, Clone, PartialEq)]
pub struct Action {
    pub id: String,
    pub operation_uri: String,
    pub intent_id: String,
    pub reversibility: Reversibility,
    pub payload: Vec<(String, f64)>,
}

impl Action {
    pub fn new(
        id: impl Into<String>,
        operation_uri: impl Into<String>,
        intent_id: impl Into<String>,
        reversibility: Reversibility,
    ) -> Self {
        Self {
            id: id.into(),
            operation_uri: operation_uri.into(),
            intent_id: intent_id.into(),
            reversibility,
            payload: Vec::new(),
        }
    }
}

/// An executable reification of an Action (Section 32).
#[derive(Debug, Clone, PartialEq)]
pub struct Command {
    pub id: String,
    pub action: Action,
    pub target_runtime_uri: String,
}

impl Command {
    pub fn new(id: impl Into<String>, action: Action, target_runtime_uri: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            action,
            target_runtime_uri: target_runtime_uri.into(),
        }
    }
}

/// A rule mapping an Intent to an Action under a given Context (Section 30).
#[derive(Debug, Clone, PartialEq)]
pub struct InteractionMapping {
    pub id: String,
    pub target_operation_uri: String,
    pub reversibility: Reversibility,
    pub requires_confirmation: bool,
}

impl InteractionMapping {
    pub fn new(
        id: impl Into<String>,
        target_operation_uri: impl Into<String>,
        reversibility: Reversibility,
    ) -> Self {
        Self {
            id: id.into(),
            target_operation_uri: target_operation_uri.into(),
            reversibility,
            requires_confirmation: false,
        }
    }

    pub fn with_confirmation(mut self, required: bool) -> Self {
        self.requires_confirmation = required;
        self
    }

    pub fn resolve(&self, intent: &Intent, _context: &InteractionContext) -> InteractionResult<Action> {
        if self.requires_confirmation && intent.confidence < 0.95 {
            return Err(InteractionError::MappingResolutionFailed(format!(
                "Action '{}' requires high-confidence confirmation (confidence: {:.2})",
                self.target_operation_uri, intent.confidence
            )));
        }

        let mut action = Action::new(
            format!("act:{}", intent.id),
            &self.target_operation_uri,
            &intent.id,
            self.reversibility,
        );
        action.payload = intent.parameters.clone();
        Ok(action)
    }
}
