pub mod boundary;
pub mod domain;
pub mod error;
pub mod field;
pub mod hypergraph;
pub mod interpolation;
pub mod level_set;
pub mod math_bridge;
pub mod operators;
pub mod sampling;
pub mod value;

pub use boundary::BoundaryCondition;
pub use domain::{FieldDomain, FieldDomainKind};
pub use error::{FieldError, FieldResult};
pub use field::{Field, FieldAssignment, FieldProvenance};
pub use interpolation::InterpolationScheme;
pub use level_set::{create_sphere_sdf, intersect_sdf, union_sdf, LevelSet};
pub use math_bridge::{
    directional_derivative_exact, evaluate_as_vector, transform_vector_field,
    verify_differential_tolerance,
};
pub use operators::{advection, curl, divergence, gradient, laplacian, linear_combination};
pub use sampling::{SamplePoint, SamplingSemantics};
pub use value::{FieldValue, ValueSpace};

pub mod prelude {
    pub use crate::boundary::BoundaryCondition;
    pub use crate::domain::{FieldDomain, FieldDomainKind};
    pub use crate::error::{FieldError, FieldResult};
    pub use crate::field::{Field, FieldAssignment, FieldProvenance};
    pub use crate::interpolation::InterpolationScheme;
    pub use crate::level_set::{create_sphere_sdf, intersect_sdf, union_sdf, LevelSet};
    pub use crate::math_bridge::{
        directional_derivative_exact, evaluate_as_vector, transform_vector_field,
        verify_differential_tolerance,
    };
    pub use crate::operators::{advection, curl, divergence, gradient, laplacian, linear_combination};
    pub use crate::sampling::{SamplePoint, SamplingSemantics};
    pub use crate::value::{FieldValue, ValueSpace};
}
