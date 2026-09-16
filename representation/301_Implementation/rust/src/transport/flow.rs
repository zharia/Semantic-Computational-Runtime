use crate::error::RepresentationError;

/// Manages channel flow control and backpressure limits.
#[derive(Debug, Clone)]
pub struct FlowController {
    capacity: usize,
    in_flight: usize,
}

impl FlowController {
    pub fn new(capacity: usize) -> Self {
        Self {
            capacity,
            in_flight: 0,
        }
    }

    pub fn capacity(&self) -> usize {
        self.capacity
    }

    pub fn in_flight(&self) -> usize {
        self.in_flight
    }

    pub fn available_capacity(&self) -> usize {
        self.capacity.saturating_sub(self.in_flight)
    }

    /// Try to acquire transmission credit. Fails with BackpressureExceeded if capacity is full.
    pub fn acquire_credit(&mut self) -> Result<(), RepresentationError> {
        if self.in_flight >= self.capacity {
            Err(RepresentationError::BackpressureExceeded {
                capacity: self.capacity,
                current: self.in_flight,
            })
        } else {
            self.in_flight += 1;
            Ok(())
        }
    }

    /// Release credit once a message is acknowledged or dropped.
    pub fn release_credit(&mut self) {
        self.in_flight = self.in_flight.saturating_sub(1);
    }
}
