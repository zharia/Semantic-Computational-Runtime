# Relationships and Topology

## 1. Relationships are first-class

A relationship is a semantic object connecting entities, values, regions, transformations or contexts. It may possess identity, direction, weight, validity interval, geometry, constraints and metadata.

## 2. Topology

The topology of a semantic field is the set of meaningful connectivity and adjacency relationships among its elements. Topology is therefore richer than a memory layout or pointer graph.

```text
semantic identity
      ↓
relationships
      ↓
connectivity
      ↓
topology
      ↓
representation
```

## 3. Dynamic topology

Topology MAY evolve. Creation, deletion, merging, splitting, rewiring and migration are semantic transformations when they alter field relationships.

## 4. Spatiality

Spatial relationships may be explicit, implicit, continuous, discrete or abstract. A graph edge, geometric adjacency, physical contact and logical dependency may all be spatially meaningful in different semantic domains.

## 5. References

A semantic reference identifies another semantic object or region. It MUST NOT be equated with a physical pointer. A provider may realise a reference as an address, handle, index, key, capability, route or distributed locator.

## 6. Graph manifestation

Hypergraphs are valid structural manifestations of the field when they preserve required relationships. They are not the definition of the Semantic Field itself.
