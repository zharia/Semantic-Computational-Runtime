use crate::error::{ApplicationError, ApplicationResult};
use std::collections::BTreeSet;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationController {
    pub id: String,
    pub name: String,
    pub handled_commands: BTreeSet<String>,
    pub handled_events: BTreeSet<String>,
    pub target_service_id: String,
}

impl ApplicationController {
    pub fn new(
        id: impl Into<String>,
        name: impl Into<String>,
        target_service_id: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            handled_commands: BTreeSet::new(),
            handled_events: BTreeSet::new(),
            target_service_id: target_service_id.into(),
        }
    }

    pub fn can_handle_command(&self, cmd: &str) -> bool {
        self.handled_commands.contains(cmd)
    }

    pub fn can_handle_event(&self, evt: &str) -> bool {
        self.handled_events.contains(evt)
    }

    pub fn dispatch_command(&self, cmd: &str) -> ApplicationResult<&str> {
        if !self.can_handle_command(cmd) {
            return Err(ApplicationError::PreconditionFailed(format!(
                "Controller '{}' cannot handle command '{}'",
                self.name, cmd
            )));
        }
        Ok(&self.target_service_id)
    }
}
