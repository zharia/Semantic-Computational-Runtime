// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::identity::InterfaceId;

/// Execution substrate or technology realizing a provider.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ProviderSubstrate {
    MojoNative,
    MlirDialect(String),
    WasmModule,
    GpuKernel(String),
    NativeLibrary(String),
    ExternalRpc(String),
}

/// A decoupled realization binding linking a provider to an interface.
///
/// In accordance with:
/// - INTERFACE-INV-002: Interfaces MUST NOT depend upon a particular implementation.
/// - INTERFACE-INV-015: Providers MUST NOT become semantic authorities; they realize contracts.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProviderBinding {
    pub provider_id: String,
    pub interface_id: InterfaceId,
    pub substrate: ProviderSubstrate,
    pub entry_point: String,
}

impl ProviderBinding {
    pub fn new(
        provider_id: impl Into<String>,
        interface_id: InterfaceId,
        substrate: ProviderSubstrate,
        entry_point: impl Into<String>,
    ) -> Self {
        Self {
            provider_id: provider_id.into(),
            interface_id,
            substrate,
            entry_point: entry_point.into(),
        }
    }
}
