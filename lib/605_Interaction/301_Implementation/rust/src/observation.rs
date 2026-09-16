use crate::input::Input;

/// An interaction observation available to the system (Section 12 & INT-003).
#[derive(Debug, Clone, PartialEq)]
pub struct InteractionObservation {
    pub id: String,
    pub actor_id: String,
    pub input: Input,
    pub channel_uri: String,
    pub observed_time_ns: u64,
}

impl InteractionObservation {
    pub fn new(
        id: impl Into<String>,
        actor_id: impl Into<String>,
        input: Input,
        channel_uri: impl Into<String>,
        observed_time_ns: u64,
    ) -> Self {
        Self {
            id: id.into(),
            actor_id: actor_id.into(),
            input,
            channel_uri: channel_uri.into(),
            observed_time_ns,
        }
    }
}
