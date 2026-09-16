use crate::error::{InteractionError, InteractionResult};
use crate::mapping::Action;

/// State of an ongoing interaction session (Section 34 & INT-014).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SessionState {
    Idle,
    Active,
    Committed,
    Cancelled,
}

/// A continuous or discrete interaction session (Section 34 & INT-014, INT-015, INT-016).
#[derive(Debug, Clone, PartialEq)]
pub struct InteractionSession {
    pub id: String,
    pub actor_id: String,
    pub context_id: String,
    pub state: SessionState,
    pub pending_action: Option<Action>,
    pub committed_actions: Vec<Action>,
}

impl InteractionSession {
    pub fn new(
        id: impl Into<String>,
        actor_id: impl Into<String>,
        context_id: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            actor_id: actor_id.into(),
            context_id: context_id.into(),
            state: SessionState::Idle,
            pending_action: None,
            committed_actions: Vec::new(),
        }
    }

    /// Activates the session (e.g. pointer contact, gesture start).
    pub fn begin(&mut self) -> InteractionResult<()> {
        match self.state {
            SessionState::Idle => {
                self.state = SessionState::Active;
                Ok(())
            }
            _ => Err(InteractionError::InvalidSessionState {
                expected: "Idle".into(),
                found: format!("{:?}", self.state),
            }),
        }
    }

    /// Proposes or updates a continuous pending action during the active session.
    pub fn stage_action(&mut self, action: Action) -> InteractionResult<()> {
        if self.state != SessionState::Active {
            return Err(InteractionError::InvalidSessionState {
                expected: "Active".into(),
                found: format!("{:?}", self.state),
            });
        }
        self.pending_action = Some(action);
        Ok(())
    }

    /// Explicitly commits the interaction session (Section 36 & INT-016).
    pub fn commit(&mut self) -> InteractionResult<Option<Action>> {
        if self.state != SessionState::Active {
            return Err(InteractionError::InvalidSessionState {
                expected: "Active".into(),
                found: format!("{:?}", self.state),
            });
        }

        self.state = SessionState::Committed;
        if let Some(action) = self.pending_action.take() {
            self.committed_actions.push(action.clone());
            Ok(Some(action))
        } else {
            Ok(None)
        }
    }

    /// Explicitly cancels the interaction session (Section 37 & INT-015).
    /// Invariant INT-015: Guaranteed no state mutation; pending action is discarded.
    pub fn cancel(&mut self, reason: &str) -> InteractionResult<()> {
        if self.state != SessionState::Active && self.state != SessionState::Idle {
            return Err(InteractionError::InvalidSessionState {
                expected: "Active or Idle".into(),
                found: format!("{:?}", self.state),
            });
        }

        self.state = SessionState::Cancelled;
        self.pending_action = None; // Discard pending action completely
        Err(InteractionError::SessionCancelled(reason.to_string()))
    }
}
