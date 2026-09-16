// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{MathError, Result};

/// Classification of abstract algebraic structures.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AlgebraicStructureType {
    Semigroup,
    Monoid,
    Group,
    AbelianGroup,
    Ring,
    Field,
    VectorSpace,
}

/// Verification of algebraic laws for a binary operation $\oplus$.
pub struct BinaryOperationContract<T> {
    pub name: String,
    pub op: fn(&T, &T) -> T,
    pub identity: Option<T>,
}

impl<T: PartialEq + Clone + std::fmt::Debug> BinaryOperationContract<T> {
    pub fn new(name: impl Into<String>, op: fn(&T, &T) -> T, identity: Option<T>) -> Self {
        Self {
            name: name.into(),
            op,
            identity,
        }
    }

    /// Verifies associativity: (a ⊕ b) ⊕ c == a ⊕ (b ⊕ c).
    pub fn verify_associativity(&self, a: &T, b: &T, c: &T) -> Result<()> {
        let lhs = (self.op)(&(self.op)(a, b), c);
        let rhs = (self.op)(a, &(self.op)(b, c));
        if lhs == rhs {
            Ok(())
        } else {
            Err(MathError::SemanticInvalidity(format!(
                "Associativity violation for {}: ({:?} ⊕ {:?}) ⊕ {:?} = {:?} != {:?}",
                self.name, a, b, c, lhs, rhs
            )))
        }
    }

    /// Verifies identity element: a ⊕ e == a and e ⊕ a == a.
    pub fn verify_identity(&self, a: &T) -> Result<()> {
        if let Some(e) = &self.identity {
            let right = (self.op)(a, e);
            let left = (self.op)(e, a);
            if right == *a && left == *a {
                Ok(())
            } else {
                Err(MathError::SemanticInvalidity(format!(
                    "Identity violation for {}: {:?} ⊕ {:?} = {:?}",
                    self.name, a, e, right
                )))
            }
        } else {
            Ok(())
        }
    }

    /// Verifies commutativity: a ⊕ b == b ⊕ a.
    pub fn verify_commutativity(&self, a: &T, b: &T) -> Result<()> {
        let ab = (self.op)(a, b);
        let ba = (self.op)(b, a);
        if ab == ba {
            Ok(())
        } else {
            Err(MathError::SemanticInvalidity(format!(
                "Commutativity violation for {}: {:?} ⊕ {:?} = {:?} != {:?}",
                self.name, a, b, ab, ba
            )))
        }
    }
}
