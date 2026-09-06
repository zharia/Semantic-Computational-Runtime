---

document: 101_definition
document_type: directory_inventory
schema_version: 1.0.0

id: SCR-LIB-DATA
name: Data

version: 0.1.0
status: draft

created: 2026-09-05
updated: 2026-09-06

parent: SCR-LIB-CORE

authority: SCR
domain: semantic-library
------------------------

# SCR Data

## 1. Definition

Data is the semantic computational domain concerned with meaningful information structures, their organization, representation, storage, access, and manipulation.

Data builds upon Core primitives to describe how information is structured, typed, stored, queried, and transformed as computational information.

---

# 2. Purpose

The purpose of Data is to provide semantic definitions for information structures beyond the foundational primitives defined by Core.

Core defines:

* identity;
* type;
* value;
* entity;
* relationships;
* state;
* transformations.

Data specializes these into information-oriented structures such as:

* scalars;
* vectors;
* matrices;
* tensors;
* collections;
* records;
* sequences;
* tables;
* buffers;
* memory;
* serialization;
* partitioning;
* storage locality.

---

# 3. Semantic Position

Data occupies the information layer above Core:

```text
Core
  ↓
Data
  ↓
Collections / Records / Tensors / Serialization / Storage
```

All other information-bearing domains MAY depend on Data.

Data MUST NOT depend semantically on a higher-level domain.

---

# 4. Scope

The Data domain encompasses:

* scalar types and values;
* vector structures;
* matrix structures;
* tensor structures;
* collections (sets, lists, maps);
* records and tuples;
* sequences;
* tables;
* buffers and memory;
* dense representations;
* sparse representations;
* structured data;
* unstructured data;
* serialization and deserialization;
* compression;
* partitioning and sharding;
* locality;
* data transfer;
* data types and type systems;
* data values;
* data objects.

---

# 5. Semantic Model

Data can be conceptually represented as:

```text
D = (S, V, T, C, R, M, B, P, L, X)
```

where:

* `S` = scalar and primitive types;
* `V` = vector, matrix, and tensor structures;
* `T` = type system and type relationships;
* `C` = collections and containers;
* `R` = records and structured types;
* `M` = memory and storage semantics;
* `B` = buffer and access semantics;
* `P` = partitioning and distribution;
* `L` = locality and access patterns;
* `X` = serialization and transformation.

This equation is a conceptual semantic model and does not prescribe an implementation structure.

---

# 6. Fundamental Distinctions

The following distinctions are essential:

```text
Semantic Data Type
    ≠
Programming Language Type

Semantic Data Value
    ≠
Memory Representation

Semantic Collection
    ≠
In-Memory Data Structure

Semantic Serialization
    ≠
File Format

Semantic Partitioning
    ≠
Physical Sharding
```

Data semantics MUST remain independent of their physical encoding.

---

# 7. Scalars

A scalar represents a single, atomic data value.

Scalars MAY be:

* numerical (integer, floating-point, fixed-point);
* categorical;
* boolean;
* temporal;
* symbolic;
* reference;
* opaque.

Scalar semantics include:

* value space;
* precision;
* range;
* units (where applicable);
* ordering (where applicable);
* arithmetic operations (where applicable);
* comparison operations.

---

# 8. Vectors

A vector represents an ordered collection of elements of uniform type.

Vector semantics MAY describe:

* dimensionality;
* element type;
* storage layout (dense, sparse);
* orientation (row, column);
* operations (addition, scaling, dot product, norm);
* iteration semantics.

A vector MUST NOT be reduced to its memory layout.

---

# 9. Matrices

A matrix represents a two-dimensional array of elements.

Matrix semantics MAY describe:

* dimensions (rows, columns);
* element type;
* storage layout (dense, sparse, compressed);
* operations (multiplication, transpose, inverse, decomposition);
* structure (symmetric, diagonal, triangular, banded);
* rank and factorization.

Matrix semantics are distinct from their storage format.

---

# 10. Tensors

A tensor generalizes scalars, vectors, and matrices to arbitrary dimensionality.

Tensor semantics MAY describe:

* rank (order);
* shape (dimensions per axis);
* element type;
* storage layout;
* operations (contraction, outer product, reduction);
* structure (sparse, dense, structured);
* index semantics.

A tensor is a semantic construct. Its representation in memory, on GPU, or in serialization format is implementation-defined.

---

# 11. Collections

A collection is a container holding multiple elements.

Collections MAY include:

* sets (unordered, unique);
* lists/sequences (ordered, indexed);
* maps/dictionaries (keyed);
* multisets/bags (unordered, non-unique);
* queues (FIFO);
* stacks (LIFO);
* priority queues;
* deques.

Collection semantics include:

* element type;
* ordering guarantees;
* uniqueness guarantees;
* access semantics (by index, by key, by value);
* mutation semantics (insert, remove, update);
* iteration semantics;
* size/cardinality.

---

# 12. Records

A record is a composite type with named or positional fields.

Record semantics MAY describe:

* field names;
* field types;
* field ordering (where positional);
* default values;
* optional fields;
* operations (field access, update, projection).

A record is a semantic construct. Its memory layout is implementation-defined.

---

# 13. Sequences

A sequence is an ordered collection with positional access.

Sequence semantics include:

* ordering;
* indexing;
* slicing;
* concatenation;
* iteration;
* length;
* element type.

Sequences MAY be:

* finite;
* infinite/lazy;
* bounded;
* unbounded;
* mutable;
* immutable.

---

# 14. Tables

A table represents a two-dimensional structure with named columns and typed rows.

Table semantics MAY describe:

* schema (column names and types);
* row semantics;
* key semantics (primary key, foreign key);
* operations (select, join, filter, aggregate);
* ordering;
* null semantics;
* constraint semantics.

Tables are semantic constructs distinct from database implementations.

---

# 15. Buffers

A buffer represents a contiguous or structured region of storage.

Buffer semantics include:

* element type;
* capacity;
* length;
* access patterns (sequential, random, strided);
* mutability;
* lifetime;
* ownership.

A buffer MUST NOT be reduced to a raw memory pointer.

---

# 16. Memory

Memory semantics describe how data is stored and accessed.

Memory MAY describe:

* allocation;
* deallocation;
* ownership;
* borrowing;
* aliasing;
* mutability;
* alignment;
* locality;
* regions;
* arenas;
* reference counting.

Memory semantics are distinct from storage technology.

---

# 17. Dense Representations

Dense representations store all elements explicitly.

Dense semantics include:

* fixed shape;
* contiguous storage;
* predictable access patterns;
* full element enumeration.

---

# 18. Sparse Representations

Sparse representations store only non-default or non-zero elements.

Sparse semantics MAY describe:

* sparsity pattern;
* index format (coordinate, compressed, block);
* compression scheme;
* access semantics;
* mutation semantics;
* fill-in behavior.

---

# 19. Structured Data

Structured data has explicit schema, type, or organizational constraints.

Examples include:

* records with named fields;
* typed arrays;
* relational tables;
* typed graphs;
* annotated trees.

---

# 20. Unstructured Data

Unstructured data lacks explicit internal schema.

Examples include:

* raw text;
* raw bytes;
* point clouds without schema;
* image pixels without metadata;
* audio samples.

Unstructured data MAY acquire structure through interpretation.

---

# 21. Serialization

Serialization transforms data into a representational format.

Serialization semantics include:

* format (JSON, CBOR, Protobuf, Arrow, Parquet, etc.);
* schema preservation;
* type fidelity;
* precision preservation;
* versioning;
* backward/forward compatibility;
* streaming serialization;
* partial serialization.

Serialization MUST NOT redefine the semantics of the data being serialized.

---

# 22. Compression

Compression reduces the representational size of data.

Compression semantics MAY describe:

* lossless vs lossy;
* compression ratio;
* decompression requirements;
* streaming capability;
* incremental compression;
* domain-specific compression.

Compression semantics MUST be explicit about information preservation.

---

# 23. Partitioning

Partitioning distributes data across partitions.

Partitioning semantics MAY describe:

* partition key;
* partition strategy (hash, range, list, round-robin);
* partition count;
* rebalancing semantics;
* cross-partition operations;
* consistency guarantees.

Partitioning is a semantic distribution concern, not merely a physical storage detail.

---

# 24. Sharding

Sharding distributes data across nodes or machines.

Sharding semantics MAY describe:

* shard key;
* shard count;
* replication;
* consistency;
* rebalancing;
* cross-shard operations.

Sharding builds upon partitioning but adds distribution semantics.

---

# 25. Locality

Locality describes data access patterns and proximity.

Locality semantics MAY describe:

* spatial locality;
* temporal locality;
* access frequency;
* co-location;
* affinity;
* migration.

---

# 26. Transfer

Transfer describes moving data between locations, representations, or systems.

Transfer semantics MAY describe:

* source;
* destination;
* protocol;
* format conversion;
* streaming vs batch;
* reliability;
* ordering guarantees.

---

# 27. Data Types

The Data domain defines a semantic type system for information structures.

A data type MAY specify:

* value space;
* operations;
* constraints;
* relationships to other types;
* representation requirements;
* serialization behavior.

Semantic data types MUST NOT be reduced to programming language types.

---

# 28. Data Values

A data value is a specific instance of a data type.

Value semantics include:

* equality;
* ordering (where applicable);
* arithmetic (where applicable);
* comparison;
* hashing;
* serialization;
* representation independence.

---

# 29. Data Objects

A data object is a semantic entity with identity, type, and value.

Data objects MAY possess:

* identity;
* type;
* value;
* attributes;
* metadata;
* provenance;
* constraints;
* relationships.

---

# 30. Relationship to Core

Data specializes Core concepts:

```text
Core.Value → Data.Scalar / Data.Vector / Data.Tensor
Core.Type → Data.DataType
Core.Entity → Data.DataObject
Core.Collection → Data.Collection
Core.Transformation → Data.Serialization / Data.Compression
Core.Region → Data.Buffer / Data.Memory
```

Core provides the semantic substrate. Data provides information-specific semantics.

---

# 31. Relationship to Mathematics

Mathematics and Data have a bidirectional relationship:

```text
Data
  ↓
Numerical Types
  ↓
Mathematics

Mathematics
  ↓
Operations
  ↓
Data
```

Mathematics defines operations on numerical data. Data provides the information structures those operations consume and produce.

---

# 32. Relationship to Fields

Fields may be defined over Data structures:

```text
Data (grid of values)
  ↓
Field semantics
  ↓
Spatial/Temporal distribution
```

Data provides the value storage; Fields provides the semantic distribution.

---

# 33. Relationship to Graphs

Graphs may be stored as Data structures:

```text
Data (adjacency matrix, edge list)
  ↓
Graph semantics
  ↓
Relational structure
```

Data provides storage; Graphs provides relational semantics.

---

# 34. Relationship to Streams

Streams may carry Data items:

```text
Data item
  ↓
Stream
  ↓
Ordered processing
```

Data defines item semantics; Streams defines flow semantics.

---

# 35. Semantic Hypergraph Integration

Data is a first-class semantic object:

```text
DataObject
  ├── HAS_TYPE → DataType
  ├── HAS_VALUE → Value
  ├── STORED_IN → Buffer
  ├── SERIALIZED_AS → Format
  ├── PARTITIONED_BY → Strategy
  ├── LOCATED_AT → Locality
  └── TRANSFERRED_VIA → Protocol
```

---

# 36. Representation Independence

Data semantics MUST remain independent of:

* in-memory layout;
* file format;
* database technology;
* serialization format;
* hardware representation;
* network protocol.

---

# 37. Provider Independence

Data MAY be implemented through:

* Rust standard library collections;
* NumPy;
* Arrow;
* Parquet;
* HDF5;
* Protocol Buffers;
* FlatBuffers;
* custom implementations.

Providers implement data semantics. They do not define them.

---

# 38. Capabilities

Data MAY expose capabilities including:

* `Indexable`
* `Iterable`
* `Sortable`
* `Serializable`
* `Compressible`
* `Partitionable`
* `Distributable`
* `Streamable`
* `Observable`
* `Cacheable`
* `Comparable`
* `Hashable`

---

# 39. Invariants

### DATA-INV-001 — Type Integrity

A data object's type MUST remain consistent unless explicitly transformed.

### DATA-INV-002 — Value Integrity

A data value MUST remain equal to itself under the declared equality relation.

### DATA-INV-003 — Representation Independence

Data semantics MUST NOT depend on a particular representation.

### DATA-INV-004 — Serialization Integrity

Serialization MUST preserve the semantic meaning of the data.

### DATA-INV-005 — Partition Integrity

Partitioning MUST preserve the logical completeness of the dataset.

### DATA-INV-006 — Provider Independence

Data providers MUST NOT redefine data semantics.

---

# 40. MLIR Relationship

Data types and operations MAY be represented through MLIR:

```text
Data Semantics
    ↓
Data IR
    ↓
MLIR Representation
    ↓
Lowering
    ↓
Execution
```

MLIR provides compilation infrastructure. It does not define data semantics.

---

# 41. Testing Requirements

Data implementations MUST support:

* type correctness;
* value correctness;
* collection semantics;
* serialization round-trip fidelity;
* compression/decompression fidelity;
* partitioning correctness;
* locality behavior;
* transfer semantics;
* provider equivalence.

---

# 42. Definition Authority

This document defines the normative semantic meaning of the SCR Data domain.

Implementations, libraries, storage formats, serialization mechanisms, and external libraries MUST conform to this definition where they claim to implement SCR Data semantics.

---

# 43. Definition Principle

> **Data defines semantic information structures, their types, values, organization, storage, access, and transformation as computational objects, independently of their physical representation, encoding, or execution substrate.**
