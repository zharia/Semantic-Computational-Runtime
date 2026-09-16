#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ArtifactKind {
    Mojo,
    Mlir,
    Wasm,
    NativeSharedObject,
    GpuKernel,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExecutableArtifact {
    pub id: String,
    pub kind: ArtifactKind,
    pub uri: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExecutionContract {
    pub calling_convention: String,
    pub memory_model: String,
    pub is_deterministic: bool,
    pub timeout_ms: Option<u64>,
}

impl ExecutionContract {
    pub fn new_deterministic(calling_convention: impl Into<String>) -> Self {
        Self {
            calling_convention: calling_convention.into(),
            memory_model: "borrowed_immutable".to_string(),
            is_deterministic: true,
            timeout_ms: Some(5000),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImplementationBinding {
    pub id: String,
    pub operation_id: String,
    pub artifact: ExecutableArtifact,
    pub contract: ExecutionContract,
    pub entry_point: String,
}

impl ImplementationBinding {
    pub fn new(
        id: impl Into<String>,
        operation_id: impl Into<String>,
        artifact: ExecutableArtifact,
        contract: ExecutionContract,
        entry_point: impl Into<String>,
    ) -> Self {
        Self {
            id: id.into(),
            operation_id: operation_id.into(),
            artifact,
            contract,
            entry_point: entry_point.into(),
        }
    }
}
