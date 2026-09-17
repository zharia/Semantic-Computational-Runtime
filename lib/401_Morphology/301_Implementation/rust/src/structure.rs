// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

//! # Structural Organisation & Part-Whole Hierarchy
//!
//! Enforces MORPHOLOGY-INV-002 (Structural Integrity) and MORPHOLOGY-INV-003 (Part-Whole Integrity).
//!
//! Form emerges through hierarchical composition and arrangement of parts.
//! Part-whole structures form a directed acyclic graph (DAG) or tree.

use crate::error::{MorphologyError, MorphologyResult};
use crate::id::ComponentId;
use std::collections::{HashMap, HashSet};

/// A morphological component part.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Component {
    pub id: ComponentId,
    pub name: String,
    pub parent: Option<ComponentId>,
    pub children: Vec<ComponentId>,
    pub level_of_detail: usize,
}

impl Component {
    pub fn new(id: ComponentId, name: impl Into<String>, level_of_detail: usize) -> Self {
        Self {
            id,
            name: name.into(),
            parent: None,
            children: Vec::new(),
            level_of_detail,
        }
    }
}

/// A hierarchical part-whole structural container.
#[derive(Debug, Clone, Default)]
pub struct PartWholeHierarchy {
    components: HashMap<ComponentId, Component>,
    root_ids: Vec<ComponentId>,
}

impl PartWholeHierarchy {
    pub fn new() -> Self {
        Self::default()
    }

    /// Adds a root component to the hierarchy.
    pub fn add_root(&mut self, id: ComponentId, name: impl Into<String>) -> MorphologyResult<()> {
        if self.components.contains_key(&id) {
            return Err(MorphologyError::InvalidStructure(format!(
                "Component {} already exists in hierarchy",
                id
            )));
        }

        let comp = Component::new(id.clone(), name, 0);
        self.components.insert(id.clone(), comp);
        self.root_ids.push(id);
        Ok(())
    }

    /// Adds a child component subordinate to an existing parent component.
    pub fn add_child(
        &mut self,
        parent_id: &ComponentId,
        child_id: ComponentId,
        name: impl Into<String>,
    ) -> MorphologyResult<()> {
        if !self.components.contains_key(parent_id) {
            return Err(MorphologyError::PartNotFound(format!(
                "Parent component {} not found",
                parent_id
            )));
        }

        if self.components.contains_key(&child_id) {
            return Err(MorphologyError::InvalidStructure(format!(
                "Component {} already exists in hierarchy",
                child_id
            )));
        }

        // Check for cycle before adding: child cannot be an ancestor of parent
        let ancestors = self.get_ancestors(parent_id);
        if ancestors.contains(&child_id) {
            return Err(MorphologyError::CycleDetected(format!(
                "Cannot add {} as child of {}: would create cycle in part-whole hierarchy",
                child_id, parent_id
            )));
        }

        let parent_lod = self.components[parent_id].level_of_detail;
        let mut child = Component::new(child_id.clone(), name, parent_lod + 1);
        child.parent = Some(parent_id.clone());

        self.components.insert(child_id.clone(), child);

        if let Some(parent) = self.components.get_mut(parent_id) {
            parent.children.push(child_id);
        }

        Ok(())
    }

    /// Returns the component with the specified ID.
    pub fn get_component(&self, id: &ComponentId) -> Option<&Component> {
        self.components.get(id)
    }

    /// Returns total component count.
    pub fn component_count(&self) -> usize {
        self.components.len()
    }

    /// Returns root component IDs.
    pub fn root_ids(&self) -> &[ComponentId] {
        &self.root_ids
    }

    /// Returns all components.
    pub fn components(&self) -> impl Iterator<Item = &Component> {
        self.components.values()
    }

    /// Returns the list of all ancestors for a given component.
    pub fn get_ancestors(&self, id: &ComponentId) -> HashSet<ComponentId> {
        let mut ancestors = HashSet::new();
        let mut current = id.clone();

        while let Some(comp) = self.components.get(&current) {
            if let Some(ref p) = comp.parent {
                if !ancestors.insert(p.clone()) {
                    // Loop detected in hierarchy graph
                    break;
                }
                current = p.clone();
            } else {
                break;
            }
        }

        ancestors
    }

    /// Verifies that the hierarchy is acyclic and well-formed (MORPHOLOGY-INV-003).
    pub fn verify_integrity(&self) -> MorphologyResult<()> {
        let mut visited = HashSet::new();

        for root in &self.root_ids {
            let mut stack = vec![root.clone()];
            let mut path = HashSet::new();

            while let Some(curr_id) = stack.pop() {
                if !path.insert(curr_id.clone()) {
                    return Err(MorphologyError::CycleDetected(format!(
                        "Cycle detected involving component {}",
                        curr_id
                    )));
                }

                visited.insert(curr_id.clone());

                if let Some(comp) = self.components.get(&curr_id) {
                    for child in &comp.children {
                        stack.push(child.clone());
                    }
                }
            }
        }

        if visited.len() != self.components.len() {
            return Err(MorphologyError::InvalidStructure(format!(
                "Disconnected or unreferenced components present (reachable: {}, total: {})",
                visited.len(),
                self.components.len()
            )));
        }

        Ok(())
    }
}
