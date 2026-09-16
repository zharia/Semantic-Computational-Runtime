// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::collections::HashSet;

use crate::contract::{Postcondition, Precondition};
use crate::effects::Effect;

/// Type contract defining a semantic type and its constraints.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct TypeContract {
    pub name: String,
    pub schema_uri: String,
}

impl TypeContract {
    pub fn new(name: impl Into<String>, schema_uri: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            schema_uri: schema_uri.into(),
        }
    }
}

/// Parameter descriptor.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParameterContract {
    pub name: String,
    pub type_contract: TypeContract,
    pub is_required: bool,
}

/// Formal semantic contract of an operation exposed by an interface.
///
/// In accordance with INTERFACE-INV-005:
/// Matching input/output types alone MUST NOT establish semantic compatibility;
/// preconditions, postconditions, and effects must also align.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OperationContract {
    pub name: String,
    pub inputs: Vec<ParameterContract>,
    pub output: TypeContract,
    pub preconditions: Vec<Precondition>,
    pub postconditions: Vec<Postcondition>,
    pub effects: HashSet<Effect>,
}

impl OperationContract {
    pub fn new(name: impl Into<String>, output: TypeContract) -> Self {
        Self {
            name: name.into(),
            inputs: Vec::new(),
            output,
            preconditions: Vec::new(),
            postconditions: Vec::new(),
            effects: HashSet::new(),
        }
    }

    pub fn with_input(mut self, input: ParameterContract) -> Self {
        self.inputs.push(input);
        self
    }

    pub fn with_precondition(mut self, pre: Precondition) -> Self {
        self.preconditions.push(pre);
        self
    }

    pub fn with_postcondition(mut self, post: Postcondition) -> Self {
        self.postconditions.push(post);
        self
    }

    pub fn with_effect(mut self, effect: Effect) -> Self {
        self.effects.insert(effect);
        self
    }
}
