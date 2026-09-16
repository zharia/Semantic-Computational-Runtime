use crate::error::{ApplicationError, ApplicationResult};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum LifecycleState {
    Created,
    Initialized,
    Configured,
    Active,
    Suspended,
    Draining,
    Terminated,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationLifecycle {
    pub state: LifecycleState,
    pub version: u64,
}

impl ApplicationLifecycle {
    pub fn new() -> Self {
        Self {
            state: LifecycleState::Created,
            version: 1,
        }
    }

    pub fn is_legal_transition(from: LifecycleState, to: LifecycleState) -> bool {
        matches!(
            (from, to),
            (LifecycleState::Created, LifecycleState::Initialized)
                | (LifecycleState::Initialized, LifecycleState::Configured)
                | (LifecycleState::Configured, LifecycleState::Active)
                | (LifecycleState::Active, LifecycleState::Suspended)
                | (LifecycleState::Suspended, LifecycleState::Active)
                | (LifecycleState::Active, LifecycleState::Draining)
                | (LifecycleState::Suspended, LifecycleState::Draining)
                | (LifecycleState::Draining, LifecycleState::Terminated)
        )
    }

    pub fn transition_to(&mut self, target: LifecycleState) -> ApplicationResult<()> {
        if self.state == LifecycleState::Terminated {
            return Err(ApplicationError::ApplicationTerminated(format!(
                "Cannot transition out of terminal state {:?}",
                self.state
            )));
        }

        if !Self::is_legal_transition(self.state, target) {
            return Err(ApplicationError::IllegalLifecycleTransition {
                from: format!("{:?}", self.state),
                to: format!("{:?}", target),
            });
        }

        self.state = target;
        self.version += 1;
        Ok(())
    }

    pub fn is_active(&self) -> bool {
        self.state == LifecycleState::Active
    }

    pub fn is_terminated(&self) -> bool {
        self.state == LifecycleState::Terminated
    }
}

impl Default for ApplicationLifecycle {
    fn default() -> Self {
        Self::new()
    }
}
