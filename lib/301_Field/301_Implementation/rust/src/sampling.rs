use crate::value::FieldValue;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum SamplingSemantics {
    PointSampled,
    CellIntegrated,
    Stochastic,
    AnalyticContinuum,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SamplePoint {
    pub coords: Vec<f64>,
    pub value: FieldValue,
    pub weight: f64,
}

impl SamplePoint {
    pub fn new(coords: Vec<f64>, value: FieldValue) -> Self {
        Self {
            coords,
            value,
            weight: 1.0,
        }
    }

    pub fn with_weight(coords: Vec<f64>, value: FieldValue, weight: f64) -> Self {
        Self {
            coords,
            value,
            weight,
        }
    }
}
