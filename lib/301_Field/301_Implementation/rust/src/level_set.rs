use crate::domain::FieldDomain;
use crate::error::{FieldError, FieldResult};
use crate::field::Field;
use crate::operators::gradient;
use crate::value::{FieldValue, ValueSpace};

/// Level Set abstraction for implicit surfaces and volumetric Signed Distance Fields (SDF).
/// Interface designed for seamless OpenVDB / NanoVDB bridge.
#[derive(Clone)]
pub struct LevelSet {
    pub sdf_field: Field,
    pub iso_value: f64,
}

impl LevelSet {
    pub fn new(sdf_field: Field, iso_value: f64) -> FieldResult<Self> {
        if sdf_field.value_space != ValueSpace::ScalarSpace {
            return Err(FieldError::OperatorError(
                "LevelSet requires a Scalar Field".to_string(),
            ));
        }
        Ok(Self {
            sdf_field,
            iso_value,
        })
    }

    /// Evaluates distance φ(x) from the implicit surface.
    pub fn evaluate_distance(&self, point: &[f64]) -> FieldResult<f64> {
        let val = self.sdf_field.evaluate(point)?.as_scalar()?;
        Ok(val - self.iso_value)
    }

    pub fn is_inside(&self, point: &[f64]) -> FieldResult<bool> {
        Ok(self.evaluate_distance(point)? < 0.0)
    }

    pub fn is_on_surface(&self, point: &[f64], epsilon: f64) -> FieldResult<bool> {
        Ok(self.evaluate_distance(point)?.abs() <= epsilon)
    }

    /// Computes the outward surface unit normal: n = ∇φ / ||∇φ||
    pub fn compute_surface_normal(&self, point: &[f64]) -> FieldResult<[f64; 3]> {
        if point.len() != 3 {
            return Err(FieldError::DimensionMismatch {
                expected: 3,
                found: point.len(),
            });
        }
        let grad = gradient(&self.sdf_field, None)?;
        let grad_val = grad.evaluate(point)?;
        let norm = grad_val.norm();
        if norm < 1e-12 {
            return Ok([0.0, 0.0, 1.0]); // Default fallback at singular center
        }
        let v = grad_val.as_vector3()?;
        Ok([v[0] / norm, v[1] / norm, v[2] / norm])
    }
}

/// Creates an analytic Sphere Signed Distance Field (SDF).
pub fn create_sphere_sdf(
    id: impl Into<String>,
    center: [f64; 3],
    radius: f64,
    domain: FieldDomain,
) -> Field {
    Field::new_analytic(id, domain, ValueSpace::ScalarSpace, move |p: &[f64]| {
        let dx = p[0] - center[0];
        let dy = p[1] - center[1];
        let dz = p[2] - center[2];
        let dist = (dx * dx + dy * dy + dz * dz).sqrt() - radius;
        Ok(FieldValue::Scalar(dist))
    })
}

/// Constructive Solid Geometry (CSG) Boolean Union for SDFs: min(φA, φB)
pub fn union_sdf(f1: &Field, f2: &Field) -> FieldResult<Field> {
    let field1 = f1.clone();
    let field2 = f2.clone();
    let id = format!("union_{}_{}", f1.id, f2.id);
    let domain = f1.domain.clone();

    Ok(Field::new_analytic(
        id,
        domain,
        ValueSpace::ScalarSpace,
        move |p: &[f64]| {
            let d1 = field1.evaluate(p)?.as_scalar()?;
            let d2 = field2.evaluate(p)?.as_scalar()?;
            Ok(FieldValue::Scalar(d1.min(d2)))
        },
    ))
}

/// Constructive Solid Geometry (CSG) Boolean Intersection for SDFs: max(φA, φB)
pub fn intersect_sdf(f1: &Field, f2: &Field) -> FieldResult<Field> {
    let field1 = f1.clone();
    let field2 = f2.clone();
    let id = format!("inter_{}_{}", f1.id, f2.id);
    let domain = f1.domain.clone();

    Ok(Field::new_analytic(
        id,
        domain,
        ValueSpace::ScalarSpace,
        move |p: &[f64]| {
            let d1 = field1.evaluate(p)?.as_scalar()?;
            let d2 = field2.evaluate(p)?.as_scalar()?;
            Ok(FieldValue::Scalar(d1.max(d2)))
        },
    ))
}
