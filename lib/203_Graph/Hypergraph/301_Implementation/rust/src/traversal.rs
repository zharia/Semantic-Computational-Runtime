use crate::identity::ElementId;
use crate::hypergraph::Hypergraph;
use crate::error::HypergraphError;
use std::collections::{BTreeSet, VecDeque};

impl Hypergraph {
    /// Retrieve all elements connected to `start_elem` through any relation (1-hop hypergraph neighborhood).
    pub fn neighbors(&self, start_elem: &ElementId) -> Result<BTreeSet<ElementId>, HypergraphError> {
        let elem = self.get_element(start_elem)
            .ok_or_else(|| HypergraphError::ElementNotFound(start_elem.0.clone()))?;

        let mut neighbors = BTreeSet::new();
        for inc_id in elem.incidences() {
            if let Some(inc) = self.get_incidence(inc_id) {
                if let Ok(participants) = self.relation_participants(inc.relation()) {
                    for (other_elem, _, _) in participants {
                        if &other_elem != start_elem {
                            neighbors.insert(other_elem);
                        }
                    }
                }
            }
        }

        Ok(neighbors)
    }

    /// Perform a deterministic Breadth-First Search traversal over elements.
    pub fn bfs(&self, start_elem: &ElementId) -> Result<Vec<ElementId>, HypergraphError> {
        if !self.get_element(start_elem).is_some() {
            return Err(HypergraphError::ElementNotFound(start_elem.0.clone()));
        }

        let mut visited = BTreeSet::new();
        let mut queue = VecDeque::new();
        let mut order = Vec::new();

        visited.insert(start_elem.clone());
        queue.push_back(start_elem.clone());

        while let Some(current) = queue.pop_front() {
            order.push(current.clone());
            for neighbor in self.neighbors(&current)? {
                if !visited.contains(&neighbor) {
                    visited.insert(neighbor.clone());
                    queue.push_back(neighbor);
                }
            }
        }

        Ok(order)
    }
}
