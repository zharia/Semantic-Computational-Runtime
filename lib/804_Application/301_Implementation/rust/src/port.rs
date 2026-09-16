#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PortDirection {
    Inbound,
    Outbound,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum PortKind {
    Command,
    Event,
    Query,
    Persistence,
    Network,
    Display,
    Compute,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationPort {
    pub id: String,
    pub name: String,
    pub direction: PortDirection,
    pub kind: PortKind,
    pub protocol_contract: String,
}

impl ApplicationPort {
    pub fn new_inbound(
        id: impl Into<String>,
        name: impl Into<String>,
        kind: PortKind,
        protocol_contract: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            direction: PortDirection::Inbound,
            kind,
            protocol_contract: protocol_contract.into(),
        }
    }

    pub fn new_outbound(
        id: impl Into<String>,
        name: impl Into<String>,
        kind: PortKind,
        protocol_contract: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            direction: PortDirection::Outbound,
            kind,
            protocol_contract: protocol_contract.into(),
        }
    }
}
