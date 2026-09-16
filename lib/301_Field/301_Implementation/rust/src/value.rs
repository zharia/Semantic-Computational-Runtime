use crate::error::{FieldError, FieldResult};
use std::fmt;

#[derive(Debug, Clone, PartialEq)]
pub enum FieldValue {
    Scalar(f64),
    Vector2([f64; 2]),
    Vector3([f64; 3]),
    VectorN(Vec<f64>),
    Tensor3x3([[f64; 3]; 3]),
    Probability(f64),
    Boolean(bool),
    Composite(Vec<FieldValue>),
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum ValueSpace {
    ScalarSpace,
    VectorSpace(usize),
    TensorSpace(usize, usize),
    ProbabilitySpace,
    BooleanSpace,
    CompositeSpace(Vec<ValueSpace>),
}

impl FieldValue {
    pub fn space(&self) -> ValueSpace {
        match self {
            Self::Scalar(_) => ValueSpace::ScalarSpace,
            Self::Vector2(_) => ValueSpace::VectorSpace(2),
            Self::Vector3(_) => ValueSpace::VectorSpace(3),
            Self::VectorN(v) => ValueSpace::VectorSpace(v.len()),
            Self::Tensor3x3(_) => ValueSpace::TensorSpace(3, 3),
            Self::Probability(_) => ValueSpace::ProbabilitySpace,
            Self::Boolean(_) => ValueSpace::BooleanSpace,
            Self::Composite(vals) => {
                ValueSpace::CompositeSpace(vals.iter().map(|v| v.space()).collect())
            }
        }
    }

    pub fn as_scalar(&self) -> FieldResult<f64> {
        match self {
            Self::Scalar(v) | Self::Probability(v) => Ok(*v),
            other => Err(FieldError::DimensionMismatch {
                expected: 1,
                found: other.dimension(),
            }),
        }
    }

    pub fn as_vector3(&self) -> FieldResult<[f64; 3]> {
        match self {
            Self::Vector3(v) => Ok(*v),
            other => Err(FieldError::DimensionMismatch {
                expected: 3,
                found: other.dimension(),
            }),
        }
    }

    pub fn dimension(&self) -> usize {
        match self {
            Self::Scalar(_) | Self::Probability(_) | Self::Boolean(_) => 1,
            Self::Vector2(_) => 2,
            Self::Vector3(_) => 3,
            Self::VectorN(v) => v.len(),
            Self::Tensor3x3(_) => 9,
            Self::Composite(v) => v.iter().map(|val| val.dimension()).sum(),
        }
    }

    pub fn add(&self, other: &Self) -> FieldResult<Self> {
        match (self, other) {
            (Self::Scalar(a), Self::Scalar(b)) => Ok(Self::Scalar(a + b)),
            (Self::Vector2([a0, a1]), Self::Vector2([b0, b1])) => {
                Ok(Self::Vector2([a0 + b0, a1 + b1]))
            }
            (Self::Vector3([a0, a1, a2]), Self::Vector3([b0, b1, b2])) => {
                Ok(Self::Vector3([a0 + b0, a1 + b1, a2 + b2]))
            }
            (Self::VectorN(a), Self::VectorN(b)) => {
                if a.len() != b.len() {
                    return Err(FieldError::DimensionMismatch {
                        expected: a.len(),
                        found: b.len(),
                    });
                }
                let sum: Vec<f64> = a.iter().zip(b.iter()).map(|(x, y)| x + y).collect();
                Ok(Self::VectorN(sum))
            }
            (Self::Tensor3x3(a), Self::Tensor3x3(b)) => {
                let mut out = [[0.0; 3]; 3];
                for i in 0..3 {
                    for j in 0..3 {
                        out[i][j] = a[i][j] + b[i][j];
                    }
                }
                Ok(Self::Tensor3x3(out))
            }
            (Self::Probability(a), Self::Probability(b)) => {
                let sum = (a + b).clamp(0.0, 1.0);
                Ok(Self::Probability(sum))
            }
            _ => Err(FieldError::OperatorError(format!(
                "Cannot add incompatible value types: {:?} and {:?}",
                self.space(),
                other.space()
            ))),
        }
    }

    pub fn scale(&self, factor: f64) -> Self {
        match self {
            Self::Scalar(a) => Self::Scalar(a * factor),
            Self::Vector2([a0, a1]) => Self::Vector2([a0 * factor, a1 * factor]),
            Self::Vector3([a0, a1, a2]) => {
                Self::Vector3([a0 * factor, a1 * factor, a2 * factor])
            }
            Self::VectorN(a) => Self::VectorN(a.iter().map(|v| v * factor).collect()),
            Self::Tensor3x3(a) => {
                let mut out = [[0.0; 3]; 3];
                for i in 0..3 {
                    for j in 0..3 {
                        out[i][j] = a[i][j] * factor;
                    }
                }
                Self::Tensor3x3(out)
            }
            Self::Probability(a) => Self::Probability((a * factor).clamp(0.0, 1.0)),
            Self::Boolean(b) => Self::Boolean(*b),
            Self::Composite(v) => Self::Composite(v.iter().map(|val| val.scale(factor)).collect()),
        }
    }

    pub fn dot(&self, other: &Self) -> FieldResult<f64> {
        match (self, other) {
            (Self::Scalar(a), Self::Scalar(b)) => Ok(a * b),
            (Self::Vector2([a0, a1]), Self::Vector2([b0, b1])) => Ok(a0 * b0 + a1 * b1),
            (Self::Vector3([a0, a1, a2]), Self::Vector3([b0, b1, b2])) => {
                Ok(a0 * b0 + a1 * b1 + a2 * b2)
            }
            (Self::VectorN(a), Self::VectorN(b)) => {
                if a.len() != b.len() {
                    return Err(FieldError::DimensionMismatch {
                        expected: a.len(),
                        found: b.len(),
                    });
                }
                Ok(a.iter().zip(b.iter()).map(|(x, y)| x * y).sum())
            }
            _ => Err(FieldError::OperatorError(format!(
                "Dot product unsupported between {:?} and {:?}",
                self.space(),
                other.space()
            ))),
        }
    }

    pub fn cross(&self, other: &Self) -> FieldResult<Self> {
        match (self, other) {
            (Self::Vector3([a0, a1, a2]), Self::Vector3([b0, b1, b2])) => {
                Ok(Self::Vector3([
                    a1 * b2 - a2 * b1,
                    a2 * b0 - a0 * b2,
                    a0 * b1 - a1 * b0,
                ]))
            }
            _ => Err(FieldError::OperatorError(
                "Cross product requires two 3D vectors".to_string(),
            )),
        }
    }

    pub fn norm(&self) -> f64 {
        match self {
            Self::Scalar(v) | Self::Probability(v) => v.abs(),
            Self::Vector2([a0, a1]) => (a0 * a0 + a1 * a1).sqrt(),
            Self::Vector3([a0, a1, a2]) => (a0 * a0 + a1 * a1 + a2 * a2).sqrt(),
            Self::VectorN(v) => v.iter().map(|x| x * x).sum::<f64>().sqrt(),
            Self::Tensor3x3(m) => {
                let sum: f64 = m.iter().flat_map(|row| row.iter()).map(|x| x * x).sum();
                sum.sqrt()
            }
            Self::Boolean(b) => {
                if *b {
                    1.0
                } else {
                    0.0
                }
            }
            Self::Composite(vals) => vals.iter().map(|v| v.norm().powi(2)).sum::<f64>().sqrt(),
        }
    }
}

impl fmt::Display for FieldValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Scalar(v) => write!(f, "{:.4}", v),
            Self::Vector2([x, y]) => write!(f, "({:.3}, {:.3})", x, y),
            Self::Vector3([x, y, z]) => write!(f, "({:.3}, {:.3}, {:.3})", x, y, z),
            Self::VectorN(v) => write!(f, "Vec{:?}", v),
            Self::Tensor3x3(m) => write!(f, "Tensor3x3{:?}", m),
            Self::Probability(p) => write!(f, "P({:.4})", p),
            Self::Boolean(b) => write!(f, "{}", b),
            Self::Composite(vals) => write!(f, "Composite({:?})", vals),
        }
    }
}

impl From<scr_math::Vector> for FieldValue {
    fn from(v: scr_math::Vector) -> Self {
        let slice = v.as_slice();
        match v.dim() {
            2 => FieldValue::Vector2([slice[0], slice[1]]),
            3 => FieldValue::Vector3([slice[0], slice[1], slice[2]]),
            _ => FieldValue::VectorN(slice.to_vec()),
        }
    }
}

impl TryFrom<&FieldValue> for scr_math::Vector {
    type Error = FieldError;

    fn try_from(val: &FieldValue) -> Result<Self, Self::Error> {
        match val {
            FieldValue::Scalar(s) | FieldValue::Probability(s) => Ok(scr_math::Vector::new(vec![*s])),
            FieldValue::Vector2([x, y]) => Ok(scr_math::Vector::new(vec![*x, *y])),
            FieldValue::Vector3([x, y, z]) => Ok(scr_math::Vector::new(vec![*x, *y, *z])),
            FieldValue::VectorN(v) => Ok(scr_math::Vector::new(v.clone())),
            other => Err(FieldError::ConversionError(format!(
                "Cannot convert FieldValue {:?} to scr_math::Vector",
                other.space()
            ))),
        }
    }
}

impl TryFrom<FieldValue> for scr_math::Vector {
    type Error = FieldError;

    fn try_from(val: FieldValue) -> Result<Self, Self::Error> {
        scr_math::Vector::try_from(&val)
    }
}

impl From<[[f64; 3]; 3]> for FieldValue {
    fn from(m: [[f64; 3]; 3]) -> Self {
        FieldValue::Tensor3x3(m)
    }
}

impl TryFrom<&FieldValue> for scr_math::Matrix {
    type Error = FieldError;

    fn try_from(val: &FieldValue) -> Result<Self, Self::Error> {
        match val {
            FieldValue::Tensor3x3(m) => {
                let data = vec![
                    m[0][0], m[0][1], m[0][2],
                    m[1][0], m[1][1], m[1][2],
                    m[2][0], m[2][1], m[2][2],
                ];
                scr_math::Matrix::new(3, 3, data).map_err(|e| FieldError::ConversionError(e.to_string()))
            }
            other => Err(FieldError::ConversionError(format!(
                "Cannot convert FieldValue {:?} to scr_math::Matrix",
                other.space()
            ))),
        }
    }
}

impl TryFrom<FieldValue> for scr_math::Matrix {
    type Error = FieldError;

    fn try_from(val: FieldValue) -> Result<Self, Self::Error> {
        scr_math::Matrix::try_from(&val)
    }
}
