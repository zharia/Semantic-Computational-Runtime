/// Nature of an interacting participant (Section 8 & INT-030).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum ActorKind {
    Human,
    Agent,
    Machine,
    AutonomousProcess,
    ExternalSystem,
}

/// An entity that participates in, initiates, or directs an interaction (Section 8).
#[derive(Debug, Clone, PartialEq)]
pub struct Actor {
    pub id: String,
    pub kind: ActorKind,
    pub authority_tokens: Vec<String>,
}

impl Actor {
    pub fn new(id: impl Into<String>, kind: ActorKind) -> Self {
        Self {
            id: id.into(),
            kind,
            authority_tokens: Vec::new(),
        }
    }

    pub fn with_authority(mut self, token: impl Into<String>) -> Self {
        self.authority_tokens.push(token.into());
        self
    }
}

/// A participant that receives feedback or observes an interaction (Section 9).
#[derive(Debug, Clone, PartialEq)]
pub struct Observer {
    pub id: String,
    pub kind: ActorKind,
}

impl Observer {
    pub fn new(id: impl Into<String>, kind: ActorKind) -> Self {
        Self {
            id: id.into(),
            kind,
        }
    }
}
