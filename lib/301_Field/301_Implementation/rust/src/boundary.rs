use crate::domain::FieldDomain;
use crate::value::FieldValue;

#[derive(Debug, Clone, PartialEq)]
pub enum BoundaryCondition {
    Zero,
    Clamped,
    Periodic,
    Dirichlet(FieldValue),
    Neumann(f64),
}

impl BoundaryCondition {
    /// Adjust query coordinate or handle boundary behavior according to condition.
    pub fn handle_coordinate(&self, point: &[f64], domain: &FieldDomain) -> Option<Vec<f64>> {
        let mut mapped = Vec::with_capacity(point.len());
        for i in 0..point.len() {
            let min = domain.bounds_min[i];
            let max = domain.bounds_max[i];
            let len = max - min;
            let p = point[i];

            match self {
                Self::Clamped => {
                    mapped.push(p.clamp(min, max));
                }
                Self::Periodic => {
                    let mut wrapped = (p - min) % len;
                    if wrapped < 0.0 {
                        wrapped += len;
                    }
                    mapped.push(min + wrapped);
                }
                Self::Zero | Self::Dirichlet(_) | Self::Neumann(_) => {
                    if p < min || p > max {
                        return None;
                    }
                    mapped.push(p);
                }
            }
        }
        Some(mapped)
    }
}
