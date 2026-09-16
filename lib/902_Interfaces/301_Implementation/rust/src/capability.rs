// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::collections::HashSet;

/// The 25 first-class capability interfaces established by the SCR Interfaces domain.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Capability {
    Composable,
    Controllable,
    Deterministic,
    Differentiable,
    Distributable,
    Dynamical,
    Integrable,
    Learnable,
    Morphological,
    Observable,
    Optimizable,
    Parallelizable,
    Persistable,
    Reducible,
    Renderable,
    Serializable,
    Spatial,
    Stateful,
    Stateless,
    Stochastic,
    Streamable,
    Temporal,
    Tileable,
    Transformable,
    Vectorizable,
}

impl Capability {
    pub fn name(&self) -> &'static str {
        match self {
            Capability::Composable => "Composable",
            Capability::Controllable => "Controllable",
            Capability::Deterministic => "Deterministic",
            Capability::Differentiable => "Differentiable",
            Capability::Distributable => "Distributable",
            Capability::Dynamical => "Dynamical",
            Capability::Integrable => "Integrable",
            Capability::Learnable => "Learnable",
            Capability::Morphological => "Morphological",
            Capability::Observable => "Observable",
            Capability::Optimizable => "Optimizable",
            Capability::Parallelizable => "Parallelizable",
            Capability::Persistable => "Persistable",
            Capability::Reducible => "Reducible",
            Capability::Renderable => "Renderable",
            Capability::Serializable => "Serializable",
            Capability::Spatial => "Spatial",
            Capability::Stateful => "Stateful",
            Capability::Stateless => "Stateless",
            Capability::Stochastic => "Stochastic",
            Capability::Streamable => "Streamable",
            Capability::Temporal => "Temporal",
            Capability::Tileable => "Tileable",
            Capability::Transformable => "Transformable",
            Capability::Vectorizable => "Vectorizable",
        }
    }
}

/// A set of capabilities declared or required by an interface.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct CapabilitySet {
    capabilities: HashSet<Capability>,
}

impl CapabilitySet {
    pub fn new() -> Self {
        Self {
            capabilities: HashSet::new(),
        }
    }

    pub fn insert(&mut self, cap: Capability) {
        self.capabilities.insert(cap);
    }

    pub fn contains(&self, cap: Capability) -> bool {
        self.capabilities.contains(&cap)
    }

    pub fn is_superset(&self, other: &CapabilitySet) -> bool {
        other.capabilities.is_subset(&self.capabilities)
    }

    pub fn len(&self) -> usize {
        self.capabilities.len()
    }

    pub fn is_empty(&self) -> bool {
        self.capabilities.is_empty()
    }

    pub fn iter(&self) -> impl Iterator<Item = &Capability> {
        self.capabilities.iter()
    }
}
