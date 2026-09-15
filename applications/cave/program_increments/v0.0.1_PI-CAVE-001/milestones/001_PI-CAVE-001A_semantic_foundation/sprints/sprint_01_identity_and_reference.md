# Sprint 01: Semantic Identity & Reference Model

**Parent Milestone:** [Milestone 001: PI-CAVE-001A Semantic Foundation](../spec.md)  
**Derived from:** `spec.md` (Sections 9, 40, 41, 42)  
**Governing Documents:** [`docs/104_SEMANTIC_INVARIANTS.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/104_SEMANTIC_INVARIANTS.md), [`docs/106_SEMANTIC_MACHINE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/106_SEMANTIC_MACHINE_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Implement the core identity and reference primitives for the Cave spatial desktop, establishing a strict algebraic separation between semantic identity coordinates, content identity hashes, typed semantic references, and cryptographic provenance.

---

## 2. Technical Specifications & Data Models

### 2.1 Semantic Identifier (SID) Coordinate
Conforms to SCR IAM-001 v0.2:
```mojo
@value
struct SemanticId(KeyElement):
    var space_id: String
    var coordinate: Int
    
    fn __eq__(self, other: Self) -> Bool:
        return self.space_id == other.space_id and self.coordinate == other.coordinate
```
* **Coordinate Invariance:** SID coordinates are assigned upon allocation and are permanently immutable.
* **Non-Reuse:** An SID coordinate that has been retired can never be reissued.

### 2.2 Content Identity (CID)
Represents immutable structural snapshots of entity state:
```mojo
@value
struct ContentId:
    var hash_bytes: StaticTuple[UInt8, 32]  # SHA-256 digest
    
    fn hex(self) -> String:
        ...
```
* **Rule:** If entity $E$ mutates state from $S_1$ to $S_2$, its $\text{SID}$ remains constant, but its $\text{CID}$ changes from $\text{SHA-256}(S_1)$ to $\text{SHA-256}(S_2)$.

### 2.3 Typed Semantic References
References decouple the holder from internal storage representation:
```mojo
@value
struct Ref[T: AnyType]:
    var target_id: SemanticId
    
    fn resolve(self, field: SemanticField) -> Optional[T]:
        ...
```
* **Dangling Reference Prevention:** Reference resolution must safely return `None` or an explicit error type if the target object is detached or retired.

### 2.4 Provenance Tracking
Every semantic entity records its issuing lineage:
```mojo
struct ProvenanceRecord:
    var entity_id: SemanticId
    var authority_id: String
    var root_id: String
    var creation_step: Int
    var parent_entity: Optional[SemanticId]
```

---

## 3. Invariants & Verification Tasks

1. **Uniqueness Check:** Prove that duplicate allocations of the same `SemanticId` within a space raise an immediate invariant error.
2. **CID Sensitivity:** Prove that any attribute alteration within an entity generates a strictly distinct `ContentId`.
3. **Reference Dereferencing:** Verify bidirectional resolution and cycle tolerance under typed `Ref[T]`.
4. **Provenance Integrity:** Verify that every allocated entity retains an unbroken provenance chain tracing back to root authority.
