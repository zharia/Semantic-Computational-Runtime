// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # SCR Mathematics Domain (`SCR-LIB-MATHEMATICS`)
//!
//! Authoritative normative semantic foundation for mathematical structures,
//! spaces, algebras, quantities, and operations within the Semantic Computational Runtime.
//!
//! Encapsulates:
//! ```text
//! Mathematical Meaning ≠ Numerical Representation ≠ Numerical Algorithm ≠ Hardware Execution
//! ```

pub mod algebra;
pub mod calculus;
pub mod dual;
pub mod error;
pub mod hypergraph;
pub mod matrix;
pub mod polynomial;
pub mod precision;
pub mod quaternion;
pub mod scalar;
pub mod statistics;
pub mod vector;

pub use algebra::{AlgebraicStructureType, BinaryOperationContract};
pub use calculus::{eval_derivative_exact, eval_derivative_finite_diff, verify_derivative_approximation};
pub use dual::DualNumber;
pub use error::{MathError, Result};
pub use hypergraph::project_math_axioms_to_hypergraph;
pub use matrix::Matrix;
pub use polynomial::Polynomial;
pub use precision::{NumericValue, ToleranceContract};
pub use quaternion::Quaternion;
pub use scalar::ComplexNumber;
pub use statistics::{sample_covariance, sample_mean, sample_std_dev, sample_variance};
pub use vector::Vector;
