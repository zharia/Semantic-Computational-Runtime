use crate::error::{FieldError, FieldResult};
use crate::field::Field;
use crate::value::{FieldValue, ValueSpace};

/// Differential step for numerical differentiation
pub const DEFAULT_FINITE_DIFF_H: f64 = 1e-5;

/// Gradient operator: ∇φ
/// Converts a Scalar Field into a Vector Field.
pub fn gradient(field: &Field, h: Option<f64>) -> FieldResult<Field> {
    if field.value_space != ValueSpace::ScalarSpace {
        return Err(FieldError::OperatorError(
            "Gradient operator requires a Scalar field".to_string(),
        ));
    }

    let f = field.clone();
    let step = h.unwrap_or(DEFAULT_FINITE_DIFF_H);
    let dim = field.domain.dimension;

    let id = format!("gradient_{}", field.id);
    let domain = field.domain.clone();
    let value_space = ValueSpace::VectorSpace(dim);

    let grad_field = Field::new_analytic(id, domain, value_space, move |point: &[f64]| {
        let mut grad = Vec::with_capacity(dim);
        for i in 0..dim {
            let mut p_plus = point.to_vec();
            let mut p_minus = point.to_vec();
            p_plus[i] += step;
            p_minus[i] -= step;

            let v_plus = f.evaluate(&p_plus)?.as_scalar()?;
            let v_minus = f.evaluate(&p_minus)?.as_scalar()?;
            grad.push((v_plus - v_minus) / (2.0 * step));
        }

        match dim {
            2 => Ok(FieldValue::Vector2([grad[0], grad[1]])),
            3 => Ok(FieldValue::Vector3([grad[0], grad[1], grad[2]])),
            _ => Ok(FieldValue::VectorN(grad)),
        }
    });

    Ok(grad_field)
}

/// Divergence operator: ∇ · v
/// Converts a Vector Field into a Scalar Field.
pub fn divergence(field: &Field, h: Option<f64>) -> FieldResult<Field> {
    let dim = field.domain.dimension;
    match field.value_space {
        ValueSpace::VectorSpace(d) if d == dim => (),
        _ => {
            return Err(FieldError::OperatorError(format!(
                "Divergence requires a Vector field with dimension matching domain ({})",
                dim
            )))
        }
    }

    let f = field.clone();
    let step = h.unwrap_or(DEFAULT_FINITE_DIFF_H);

    let id = format!("divergence_{}", field.id);
    let domain = field.domain.clone();
    let value_space = ValueSpace::ScalarSpace;

    let div_field = Field::new_analytic(id, domain, value_space, move |point: &[f64]| {
        let mut div = 0.0;
        for i in 0..dim {
            let mut p_plus = point.to_vec();
            let mut p_minus = point.to_vec();
            p_plus[i] += step;
            p_minus[i] -= step;

            let v_plus = f.evaluate(&p_plus)?;
            let v_minus = f.evaluate(&p_minus)?;

            let val_plus = match v_plus {
                FieldValue::Vector2([x, y]) => [x, y, 0.0][i],
                FieldValue::Vector3(arr) => arr[i],
                FieldValue::VectorN(vec) => vec[i],
                _ => return Err(FieldError::OperatorError("Expected vector value".into())),
            };

            let val_minus = match v_minus {
                FieldValue::Vector2([x, y]) => [x, y, 0.0][i],
                FieldValue::Vector3(arr) => arr[i],
                FieldValue::VectorN(vec) => vec[i],
                _ => return Err(FieldError::OperatorError("Expected vector value".into())),
            };

            div += (val_plus - val_minus) / (2.0 * step);
        }

        Ok(FieldValue::Scalar(div))
    });

    Ok(div_field)
}

/// Curl operator: ∇ × v
/// Computes the curl of a 3D Vector Field, producing another 3D Vector Field.
pub fn curl(field: &Field, h: Option<f64>) -> FieldResult<Field> {
    if field.domain.dimension != 3 || field.value_space != ValueSpace::VectorSpace(3) {
        return Err(FieldError::OperatorError(
            "Curl operator requires a 3D Vector field over a 3D domain".to_string(),
        ));
    }

    let f = field.clone();
    let step = h.unwrap_or(DEFAULT_FINITE_DIFF_H);

    let id = format!("curl_{}", field.id);
    let domain = field.domain.clone();
    let value_space = ValueSpace::VectorSpace(3);

    let curl_field = Field::new_analytic(id, domain, value_space, move |point: &[f64]| {
        let eval_comp = |p: &[f64], comp: usize| -> FieldResult<f64> {
            let val = f.evaluate(p)?;
            val.as_vector3().map(|v| v[comp])
        };

        // ∂vz/∂y - ∂vy/∂z
        let mut py_plus = point.to_vec();
        py_plus[1] += step;
        let mut py_minus = point.to_vec();
        py_minus[1] -= step;
        let dvz_dy = (eval_comp(&py_plus, 2)? - eval_comp(&py_minus, 2)?) / (2.0 * step);

        let mut pz_plus = point.to_vec();
        pz_plus[2] += step;
        let mut pz_minus = point.to_vec();
        pz_minus[2] -= step;
        let dvy_dz = (eval_comp(&pz_plus, 1)? - eval_comp(&pz_minus, 1)?) / (2.0 * step);

        let curl_x = dvz_dy - dvy_dz;

        // ∂vx/∂z - ∂vz/∂x
        let mut px_plus = point.to_vec();
        px_plus[0] += step;
        let mut px_minus = point.to_vec();
        px_minus[0] -= step;
        let dvz_dx = (eval_comp(&px_plus, 2)? - eval_comp(&px_minus, 2)?) / (2.0 * step);
        let dvx_dz = (eval_comp(&pz_plus, 0)? - eval_comp(&pz_minus, 0)?) / (2.0 * step);

        let curl_y = dvx_dz - dvz_dx;

        // ∂vy/∂x - ∂vx/∂y
        let dvy_dx = (eval_comp(&px_plus, 1)? - eval_comp(&px_minus, 1)?) / (2.0 * step);
        let dvx_dy = (eval_comp(&py_plus, 0)? - eval_comp(&py_minus, 0)?) / (2.0 * step);

        let curl_z = dvy_dx - dvx_dy;

        Ok(FieldValue::Vector3([curl_x, curl_y, curl_z]))
    });

    Ok(curl_field)
}

/// Laplacian operator: ∇²φ = ∇ · ∇φ
/// Converts a Scalar Field into another Scalar Field.
pub fn laplacian(field: &Field, h: Option<f64>) -> FieldResult<Field> {
    if field.value_space != ValueSpace::ScalarSpace {
        return Err(FieldError::OperatorError(
            "Laplacian requires a Scalar field".to_string(),
        ));
    }

    let f = field.clone();
    let step = h.unwrap_or(DEFAULT_FINITE_DIFF_H);
    let dim = field.domain.dimension;

    let id = format!("laplacian_{}", field.id);
    let domain = field.domain.clone();
    let value_space = ValueSpace::ScalarSpace;

    let lap_field = Field::new_analytic(id, domain, value_space, move |point: &[f64]| {
        let center = f.evaluate(point)?.as_scalar()?;
        let mut lap = 0.0;

        for i in 0..dim {
            let mut p_plus = point.to_vec();
            let mut p_minus = point.to_vec();
            p_plus[i] += step;
            p_minus[i] -= step;

            let v_plus = f.evaluate(&p_plus)?.as_scalar()?;
            let v_minus = f.evaluate(&p_minus)?.as_scalar()?;

            // Central second difference: (f(x+h) - 2f(x) + f(x-h)) / h²
            lap += (v_plus - 2.0 * center + v_minus) / (step * step);
        }

        Ok(FieldValue::Scalar(lap))
    });

    Ok(lap_field)
}

/// Semi-Lagrangian Advection step: φ_next(x) = φ(x - u(x) * dt)
pub fn advection(scalar_field: &Field, velocity_field: &Field, dt: f64) -> FieldResult<Field> {
    let sf = scalar_field.clone();
    let vf = velocity_field.clone();
    let dim = scalar_field.domain.dimension;

    let id = format!("advected_{}", scalar_field.id);
    let domain = scalar_field.domain.clone();
    let value_space = scalar_field.value_space.clone();

    let adv_field = Field::new_analytic(id, domain, value_space, move |point: &[f64]| {
        let vel = vf.evaluate(point)?;
        let backtracked: Vec<f64> = match vel {
            FieldValue::Vector2([vx, vy]) => vec![point[0] - vx * dt, point[1] - vy * dt],
            FieldValue::Vector3([vx, vy, vz]) => vec![
                point[0] - vx * dt,
                point[1] - vy * dt,
                point[2] - vz * dt,
            ],
            FieldValue::VectorN(v) => point
                .iter()
                .zip(v.iter())
                .map(|(p, u)| p - u * dt)
                .collect(),
            _ => return Err(FieldError::OperatorError("Velocity field must yield vectors".into())),
        };

        if backtracked.len() != dim {
            return Err(FieldError::DimensionMismatch {
                expected: dim,
                found: backtracked.len(),
            });
        }

        sf.evaluate(&backtracked)
    });

    Ok(adv_field)
}

/// Linear combination / Composition of two fields: a * f1 + b * f2
pub fn linear_combination(
    f1: &Field,
    a: f64,
    f2: &Field,
    b: f64,
) -> FieldResult<Field> {
    if f1.domain.dimension != f2.domain.dimension {
        return Err(FieldError::DimensionMismatch {
            expected: f1.domain.dimension,
            found: f2.domain.dimension,
        });
    }

    let field1 = f1.clone();
    let field2 = f2.clone();
    let id = format!("comb_{}_{}", f1.id, f2.id);
    let domain = f1.domain.clone();
    let value_space = f1.value_space.clone();

    let comb = Field::new_analytic(id, domain, value_space, move |point: &[f64]| {
        let v1 = field1.evaluate(point)?.scale(a);
        let v2 = field2.evaluate(point)?.scale(b);
        v1.add(&v2)
    });

    Ok(comb)
}
