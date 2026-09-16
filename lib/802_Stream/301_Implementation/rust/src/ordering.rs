// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

use std::collections::HashMap;

/// Declaration of the ordering guarantees provided by a Stream contract.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OrderingSemantics {
    /// Strict total order across all elements (e.g. monotonically increasing sequence number).
    Total,
    /// Partial order defined by keys, partitions, or causal ancestry.
    Partial,
    /// Explicit causal order tracked via vector clocks or explicit dependency tokens.
    Causal,
    /// Elements are treated as an unordered bag/set across the stream.
    Unordered,
}

/// Comparison result between two causal vector clocks.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CausalRelation {
    Equal,
    Precedes,
    Succeeds,
    Concurrent,
}

/// Vector clock tracking causal dependencies across distributed stream nodes.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct VectorClock {
    pub clocks: HashMap<String, u64>,
}

impl VectorClock {
    pub fn new() -> Self {
        Self {
            clocks: HashMap::new(),
        }
    }

    pub fn increment(&mut self, node: &str) {
        let entry = self.clocks.entry(node.to_string()).or_insert(0);
        *entry += 1;
    }

    pub fn set(&mut self, node: &str, count: u64) {
        self.clocks.insert(node.to_string(), count);
    }

    pub fn get(&self, node: &str) -> u64 {
        self.clocks.get(node).copied().unwrap_or(0)
    }

    /// Merges another vector clock into this one by taking component-wise maximums.
    pub fn merge(&mut self, other: &VectorClock) {
        for (node, count) in &other.clocks {
            let current = self.clocks.entry(node.clone()).or_insert(0);
            if *count > *current {
                *current = *count;
            }
        }
    }

    /// Determines the causal relationship between `self` and `other`.
    pub fn compare(&self, other: &VectorClock) -> CausalRelation {
        let mut self_has_greater = false;
        let mut other_has_greater = false;

        let mut all_keys: std::collections::HashSet<&String> = self.clocks.keys().collect();
        all_keys.extend(other.clocks.keys());

        for key in all_keys {
            let s_val = self.get(key);
            let o_val = other.get(key);

            if s_val > o_val {
                self_has_greater = true;
            } else if o_val > s_val {
                other_has_greater = true;
            }
        }

        match (self_has_greater, other_has_greater) {
            (false, false) => CausalRelation::Equal,
            (true, false) => CausalRelation::Succeeds,
            (false, true) => CausalRelation::Precedes,
            (true, true) => CausalRelation::Concurrent,
        }
    }
}
