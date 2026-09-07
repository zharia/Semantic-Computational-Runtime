# Manifestation Engine — Data Manifestation

## 1. Principle

Data is semantically identified before it is physically located.

`semantic data identity ≠ physical storage address`

## 2. Data classes

The Engine may manifest semantic data as:

- in-memory values;
- buffers;
- files;
- database records;
- object storage;
- device memory;
- remote state;
- generated values;
- streams;
- other semantic fields.

## 3. Read

A semantic read requests a value or state associated with semantic identity. The provider resolves the physical representation.

## 4. Write

A semantic write must specify the semantic state transition. The physical storage mechanism is selected by the Engine.

## 5. Address mapping

The mapping:

`semantic ID → manifestation ID → physical locator`

MUST be mediated by the Engine. Physical locators MUST NOT be required by graph-level execution.

## 6. Coherence

If multiple manifestations of the same semantic state exist, coherence requirements MUST be explicit.

## 7. Versioning

Data manifestations SHOULD expose semantic version, schema/version information and freshness where relevant.

## 8. Streaming data

A stream is a semantic sequence or flow. Its transport, buffering and partitioning are realization details unless explicitly part of semantics.

## 9. External data

External data is not semantically special. Once admitted as a semantic data entity, it participates through normal identity, capability, authorization and provenance mechanisms.

## 10. Data deletion

Physical deletion MUST be distinguished from semantic destruction. Retention, tombstoning and archival semantics must be explicit.

## 11. Data provenance

Reads and writes SHOULD record source manifestation, provider, version/freshness and execution lineage where required for reproducibility or audit.
