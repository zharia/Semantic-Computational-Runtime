# Storage Semantics

## 1. Storage as persistence manifestation

Storage is a physical manifestation of semantic state. A database, file, object store, graph store or memory image is not itself the semantic object.

## 2. Persistence contract

A persistent semantic value requires identity, durability scope, consistency expectations, serialization mapping and recovery semantics.

## 3. Identity

Persistent identity MUST survive representation changes, migration and compaction unless the semantic contract explicitly permits identity replacement.

## 4. Serialization

Serialization is a representation transformation. Schema evolution MUST preserve semantic meaning or declare an explicit migration transformation.

## 5. Indexes

Indexes are derived structures. They MAY be rebuilt, replaced or discarded without changing semantic identity, provided observable query semantics are preserved.

## 6. Transactions

Transaction semantics apply to field transformations that cross persistence boundaries. Atomicity is meaningful only relative to the declared semantic unit of change.
