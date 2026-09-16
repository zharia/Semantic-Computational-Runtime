#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ApplicationAdapter {
    pub id: String,
    pub name: String,
    pub port_id: String,
    pub technology: String,
    pub provider_id: Option<String>,
}

impl ApplicationAdapter {
    pub fn new(
        id: impl Into<String>,
        name: impl Into<String>,
        port_id: impl Into<String>,
        technology: impl Into<String>,
        provider_id: Option<String>,
    ) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            port_id: port_id.into(),
            technology: technology.into(),
            provider_id,
        }
    }
}
