// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Physical Quantities & Dimensional Analysis
//!
//! Enforces PHYSICS-INV-002 (Quantity Integrity) and PHYSICS-INV-014 (Dimensional Integrity).
//!
//! Physical quantities retain dimensional consistency: $[M]^m [L]^l [T]^t [I]^i [\Theta]^\theta [N]^n [J]^j$.

use crate::error::{PhysicsError, PhysicsResult};
use std::ops::{Add, Div, Mul, Sub};

/// 7 fundamental base dimensions of SI physics:
/// Mass (M), Length (L), Time (T), Current (I), Temperature (Theta), Amount (N), Luminous Intensity (J).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Dimension {
    pub mass: i8,
    pub length: i8,
    pub time: i8,
    pub current: i8,
    pub temperature: i8,
    pub amount: i8,
    pub luminous: i8,
}

impl Dimension {
    pub const DIMENSIONLESS: Self = Self { mass: 0, length: 0, time: 0, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const MASS: Self = Self { mass: 1, length: 0, time: 0, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const LENGTH: Self = Self { mass: 0, length: 1, time: 0, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const TIME: Self = Self { mass: 0, length: 0, time: 1, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const CURRENT: Self = Self { mass: 0, length: 0, time: 0, current: 1, temperature: 0, amount: 0, luminous: 0 };
    pub const TEMPERATURE: Self = Self { mass: 0, length: 0, time: 0, current: 0, temperature: 1, amount: 0, luminous: 0 };

    pub const VELOCITY: Self = Self { mass: 0, length: 1, time: -1, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const ACCELERATION: Self = Self { mass: 0, length: 1, time: -2, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const FORCE: Self = Self { mass: 1, length: 1, time: -2, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const ENERGY: Self = Self { mass: 1, length: 2, time: -2, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const MOMENTUM: Self = Self { mass: 1, length: 1, time: -1, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const PRESSURE: Self = Self { mass: 1, length: -1, time: -2, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const POWER: Self = Self { mass: 1, length: 2, time: -3, current: 0, temperature: 0, amount: 0, luminous: 0 };
    pub const CHARGE: Self = Self { mass: 0, length: 0, time: 1, current: 1, temperature: 0, amount: 0, luminous: 0 };

    pub fn is_dimensionless(&self) -> bool {
        *self == Self::DIMENSIONLESS
    }

    pub fn mul_dim(&self, other: &Self) -> Self {
        Self {
            mass: self.mass + other.mass,
            length: self.length + other.length,
            time: self.time + other.time,
            current: self.current + other.current,
            temperature: self.temperature + other.temperature,
            amount: self.amount + other.amount,
            luminous: self.luminous + other.luminous,
        }
    }

    pub fn div_dim(&self, other: &Self) -> Self {
        Self {
            mass: self.mass - other.mass,
            length: self.length - other.length,
            time: self.time - other.time,
            current: self.current - other.current,
            temperature: self.temperature - other.temperature,
            amount: self.amount - other.amount,
            luminous: self.luminous - other.luminous,
        }
    }
}

/// A physical quantity combining a numerical value, physical dimension, unit name, and optional uncertainty.
#[derive(Debug, Clone, PartialEq)]
pub struct Quantity {
    pub value: f64,
    pub dimension: Dimension,
    pub unit_name: String,
    pub uncertainty: Option<f64>,
}

impl Quantity {
    pub fn new(value: f64, dimension: Dimension, unit_name: impl Into<String>) -> Self {
        Self {
            value,
            dimension,
            unit_name: unit_name.into(),
            uncertainty: None,
        }
    }

    pub fn with_uncertainty(mut self, uncertainty: f64) -> Self {
        self.uncertainty = Some(uncertainty);
        self
    }

    pub fn dimensionless(value: f64) -> Self {
        Self::new(value, Dimension::DIMENSIONLESS, "1")
    }

    pub fn mass(kg: f64) -> Self {
        Self::new(kg, Dimension::MASS, "kg")
    }

    pub fn length(meters: f64) -> Self {
        Self::new(meters, Dimension::LENGTH, "m")
    }

    pub fn time(seconds: f64) -> Self {
        Self::new(seconds, Dimension::TIME, "s")
    }

    pub fn velocity(m_per_s: f64) -> Self {
        Self::new(m_per_s, Dimension::VELOCITY, "m/s")
    }

    pub fn force(newtons: f64) -> Self {
        Self::new(newtons, Dimension::FORCE, "N")
    }

    pub fn energy(joules: f64) -> Self {
        Self::new(joules, Dimension::ENERGY, "J")
    }

    pub fn momentum(kg_m_per_s: f64) -> Self {
        Self::new(kg_m_per_s, Dimension::MOMENTUM, "kg*m/s")
    }

    /// Asserts dimensional compatibility before addition/subtraction.
    pub fn assert_compatible_dimension(&self, other: &Self) -> PhysicsResult<()> {
        if self.dimension != other.dimension {
            return Err(PhysicsError::DimensionMismatch(format!(
                "Cannot combine quantities with different dimensions: {:?} vs {:?}",
                self.dimension, other.dimension
            )));
        }
        Ok(())
    }
}

impl Add for Quantity {
    type Output = PhysicsResult<Self>;

    fn add(self, rhs: Self) -> Self::Output {
        self.assert_compatible_dimension(&rhs)?;
        let combined_uncertainty = match (self.uncertainty, rhs.uncertainty) {
            (Some(u1), Some(u2)) => Some((u1 * u1 + u2 * u2).sqrt()),
            (Some(u1), None) => Some(u1),
            (None, Some(u2)) => Some(u2),
            (None, None) => None,
        };

        Ok(Self {
            value: self.value + rhs.value,
            dimension: self.dimension,
            unit_name: self.unit_name,
            uncertainty: combined_uncertainty,
        })
    }
}

impl Sub for Quantity {
    type Output = PhysicsResult<Self>;

    fn sub(self, rhs: Self) -> Self::Output {
        self.assert_compatible_dimension(&rhs)?;
        let combined_uncertainty = match (self.uncertainty, rhs.uncertainty) {
            (Some(u1), Some(u2)) => Some((u1 * u1 + u2 * u2).sqrt()),
            (Some(u1), None) => Some(u1),
            (None, Some(u2)) => Some(u2),
            (None, None) => None,
        };

        Ok(Self {
            value: self.value - rhs.value,
            dimension: self.dimension,
            unit_name: self.unit_name,
            uncertainty: combined_uncertainty,
        })
    }
}

impl Mul for Quantity {
    type Output = Self;

    fn mul(self, rhs: Self) -> Self::Output {
        let new_dim = self.dimension.mul_dim(&rhs.dimension);
        let new_unit = format!("{}*{}", self.unit_name, rhs.unit_name);
        Self {
            value: self.value * rhs.value,
            dimension: new_dim,
            unit_name: new_unit,
            uncertainty: None,
        }
    }
}

impl Div for Quantity {
    type Output = Self;

    fn div(self, rhs: Self) -> Self::Output {
        let new_dim = self.dimension.div_dim(&rhs.dimension);
        let new_unit = format!("{}/{}", self.unit_name, rhs.unit_name);
        Self {
            value: self.value / rhs.value,
            dimension: new_dim,
            unit_name: new_unit,
            uncertainty: None,
        }
    }
}
