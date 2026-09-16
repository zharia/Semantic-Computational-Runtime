// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use crate::error::{MathError, Result};

/// Computes the sample mean of a slice of values.
pub fn sample_mean(data: &[f64]) -> Result<f64> {
    if data.is_empty() {
        return Err(MathError::SemanticInvalidity(
            "Cannot compute sample mean of empty slice".into(),
        ));
    }
    let sum: f64 = data.iter().sum();
    Ok(sum / data.len() as f64)
}

/// Computes the unbiased sample variance (denominator N - 1).
pub fn sample_variance(data: &[f64]) -> Result<f64> {
    if data.len() < 2 {
        return Err(MathError::SemanticInvalidity(
            "Sample variance requires at least 2 data points".into(),
        ));
    }
    let mean = sample_mean(data)?;
    let sq_diff_sum: f64 = data.iter().map(|x| (x - mean).powi(2)).sum();
    Ok(sq_diff_sum / (data.len() - 1) as f64)
}

/// Computes the sample standard deviation.
pub fn sample_std_dev(data: &[f64]) -> Result<f64> {
    let var = sample_variance(data)?;
    Ok(var.sqrt())
}

/// Computes the sample covariance between two variables x and y.
pub fn sample_covariance(x: &[f64], y: &[f64]) -> Result<f64> {
    if x.len() != y.len() {
        return Err(MathError::DimensionMismatch {
            expected: format!("len {}", x.len()),
            actual: format!("len {}", y.len()),
        });
    }
    if x.len() < 2 {
        return Err(MathError::SemanticInvalidity(
            "Sample covariance requires at least 2 points".into(),
        ));
    }
    let mean_x = sample_mean(x)?;
    let mean_y = sample_mean(y)?;

    let cov_sum: f64 = x
        .iter()
        .zip(y.iter())
        .map(|(a, b)| (a - mean_x) * (b - mean_y))
        .sum();

    Ok(cov_sum / (x.len() - 1) as f64)
}
