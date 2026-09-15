# HGT-001 Semantic Corrections

The following requirements are **normative additions** to the HGT-001 development instruction.

They must be incorporated into the hypergraph semantic specification, invariants, conformance tests, provider qualification, and implementation plan.

---

# 1. Nullary Relation Policy

SCR shall explicitly define the semantic status of a relation with **zero incidences**.

A nullary relation is **valid SCR semantic state**.

It represents a relation whose existence does not depend on participation by an Element.

Therefore:

$$
|I(R)| = 0
$$

is a valid relation state.

This is not an error, degenerate implementation state, or provider-specific corner case.

## 1.1 Meaning

A nullary relation may represent, for example:

* an asserted proposition with no explicit participants;
* an instantiated semantic fact;
* a zero-argument operation;
* a constant or nullary function;
* a state/event whose semantic identity exists independently of participating elements;
* a relation awaiting attachment of participants;
* a relation whose participants are intentionally absent.

The specific ontology attached to a nullary relation comes from the semantic domain using it. The core hypergraph layer must not impose an artificial meaning.

The hypergraph layer therefore defines only:

> A Relation MAY exist with zero Incidences.

---

## 1.2 Nullary Relation ≠ Invalid Relation

The implementation MUST NOT reject a nullary relation merely because a selected provider cannot represent it.

If a provider lacks native nullary-relation support, the provider adapter must either:

1. represent the relation through an appropriate provider-neutral encoding; or
2. report that the provider lacks the required capability.

The provider's limitation must not redefine SCR semantics.

---

## 1.3 Nullary Relation Identity

A nullary relation has its own semantic identity.

Therefore:

```text
R1 != R2
```

even when:

```text
incidences(R1) = ∅
incidences(R2) = ∅
```

Two nullary relations are not equivalent merely because both contain zero participants.

This follows directly from first-class Relation identity.

---

## 1.4 Nullary Relation Mutation

A nullary relation MAY transition to a non-nullary relation through addition of an Incidence.

For example:

```text
R
│
├── zero incidences
│
└── attach(A)
     │
     └── one incidence
```

The Relation's semantic identity remains unchanged unless the operation explicitly specifies creation of a new Relation.

Likewise, removing all incidences from a relation does **not** automatically delete the Relation.

This distinction is mandatory.

---

# 2. Deletion Semantics

Deletion must be treated as a semantic lifecycle operation, not as memory reclamation.

The semantic model MUST distinguish:

```text
detach
delete
invalidate
destroy
reclaim
```

These are not automatically synonymous.

---

# 2.1 Incidence Deletion

Removing an Incidence means:

> The semantic relationship between the specified Element and Relation no longer exists.

For example:

```text
A --input--> R
```

may become:

```text
A       R
 \     /
  no incidence
```

without deleting either `A` or `R`.

Deleting an Incidence MUST NOT implicitly delete its Element or Relation.

---

# 2.2 Relation Deletion

Deleting a Relation removes the Relation as an active semantic object.

Its associated Incidences MUST cease to be active semantic relationships.

However, this does **not** mean that the semantic history of the Relation disappears.

Where provenance/history is enabled, deletion must remain observable through the appropriate provenance mechanism.

A provider may physically reclaim the relation's storage later, but physical reclamation is not itself the semantic deletion operation.

---

# 2.3 Element Deletion

Deleting an Element requires explicit semantics for all Incidences involving that Element.

The core rule shall be:

> Deleting an Element removes its active participation in the hypergraph but MUST NOT silently delete unrelated Relations merely because the Element participated in them.

For example:

```text
A --input--> R
B --output--> R
```

Deleting `A` results in:

```text
B --output--> R
```

unless the semantic domain has explicitly declared the Relation dependent on `A`.

The Relation does not automatically disappear merely because one participant was removed.

---

# 2.4 Relation Cardinality After Deletion

Deletion of Incidences may change relation cardinality.

Therefore a Relation may legitimately transition:

```text
3 incidences
      ↓
2
      ↓
1
      ↓
0
```

The final state is a valid nullary Relation.

This means:

> **Incidence deletion and Relation deletion are fundamentally different operations.**

An implementation MUST NOT implement "remove the final participant" as automatic Relation deletion.

---

# 2.5 Referential Integrity

A semantic reference to an object that has been deleted MUST NOT silently resolve to a different object.

Identity reuse is therefore prohibited while active references or retained provenance could cause ambiguity.

Provider-local storage reuse is permitted only when it cannot violate SCR identity semantics.

For example:

```text
semantic ID R1
provider slot 42
```

After deleting `R1`, the provider may eventually reuse slot `42`.

It MUST NOT cause a reference that previously designated `R1` to silently designate `R2`.

---

# 3. Reference Semantics

References are semantic objects distinct from the objects they designate.

The SCR model MUST distinguish:

```text
Object identity
Reference identity
Reference target
Provider handle
Memory address
Storage location
```

A reference is not equivalent to a pointer.

---

# 3.1 Stable Semantic References

A semantic reference identifies a semantic object independently of its physical representation.

Therefore a reference MUST survive:

* provider storage relocation;
* memory movement;
* serialization/deserialization;
* provider representation changes;
* internal indexing changes.

provided that the referenced semantic object remains alive.

---

# 3.2 Reference Validity

A reference has a validity state.

At minimum:

```text
Valid
Invalid / dangling
```

A reference to a deleted semantic object MUST NOT silently resolve to another object.

The implementation may choose a richer lifecycle model, but it must preserve this invariant.

---

# 3.3 References Across Mutation

If:

```text
ref → R
```

and `R` gains or loses Incidences, `ref` continues to designate `R`.

Topology mutation does not change object identity.

For example:

```text
R = relation #123

ref → R

attach(A)
attach(B)
detach(A)

ref → R
```

The reference remains valid throughout these topology mutations.

---

# 3.4 References Across Detachment

Removing an Incidence does not invalidate references to:

* the Element;
* the Relation;
* other Incidences.

Only the deleted Incidence itself becomes invalid.

For example:

```text
A --I1--> R
B --I2--> R
```

Deleting `I1` produces:

```text
A       R
        │
        I2
        │
        B
```

References to `A`, `R`, and `I2` remain valid.

A reference to `I1` becomes invalid.

---

# 3.5 References Across Relation Deletion

If:

```text
ref → R
```

and `R` is deleted, then:

```text
ref → deleted(R)
```

The reference MUST NOT silently retarget.

The API must define the observable result of dereferencing such a reference.

Possible mechanisms include:

* explicit invalid-reference state;
* typed error;
* tombstone;
* provenance object;
* generation/version check.

The selected mechanism is an implementation decision provided that the semantic invariant is preserved.

---

# 3.6 Tombstones and Historical Identity

SCR should permit implementations to retain a tombstone or historical identity for deleted objects where required by:

* provenance;
* audit;
* transactional semantics;
* distributed synchronization;
* historical graph state;
* event sourcing.

A tombstone is not an active semantic object.

It represents the continued recognizability of an identity after deletion.

Therefore:

```text
active(R) = false
identity(R) remains historically resolvable
```

may be valid.

This must not be confused with allowing a deleted object to remain semantically active.

---

# 4. Delete vs Detach

The specification MUST explicitly define this distinction.

## Detach

Removes a specific Incidence.

```text
Element ↔ Relation
        ↓
     detached
```

Neither endpoint is deleted.

## Delete Relation

Removes the Relation and its active Incidences.

## Delete Element

Removes the Element and its active Incidences while preserving unrelated Relations unless their own semantic lifecycle explicitly requires deletion.

## Delete Incidence

Removes only the specific Incidence.

---

# 5. Mutation and Identity Invariant

The following must be normative:

> **Topology mutation does not imply identity mutation.**

Adding or removing Incidences does not create a new Relation.

Changing the participant set does not change Relation identity.

Likewise, changing an Element's participation does not change Element identity.

Therefore:

```text
R(t0) == R(t1)
```

may remain true even where:

```text
participants(R,t0) != participants(R,t1)
```

This is essential for SCR because a semantic object may evolve through time without becoming a different object.

---

# 6. Reference and Provider Independence

Provider handles are implementation artifacts.

For example:

```text
SCR Reference
      ↓
Semantic Relation R
      ↓
Provider handle
      ↓
memory/storage location
```

The inverse relationship is not normative.

A provider may move:

```text
R : provider slot 42
```

to:

```text
R : provider slot 981
```

without changing:

```text
SCR identity(R)
```

or invalidating a valid semantic reference to `R`.

---

# 7. Required Conformance Tests

Add the following tests to HGT-001.

### HYPERGRAPH-C009 — Nullary Relation Validity

A Relation with zero Incidences is valid semantic state.

### HYPERGRAPH-C010 — Nullary Relation Identity

Two nullary Relations are distinct unless explicitly identified as the same object.

### HYPERGRAPH-C011 — Nullary Transition

A nullary Relation can acquire an Incidence without changing Relation identity.

### HYPERGRAPH-C012 — Emptying Relation

Removing the final Incidence leaves a valid nullary Relation.

### HYPERGRAPH-C013 — Incidence Deletion

Deleting an Incidence does not delete either endpoint.

### HYPERGRAPH-C014 — Relation Deletion

Deleting a Relation invalidates its active Incidences but does not silently delete unrelated Elements.

### HYPERGRAPH-C015 — Element Deletion

Deleting an Element removes its active Incidences but does not automatically delete unrelated Relations.

### HYPERGRAPH-C016 — Reference Stability

A valid reference remains valid across topology mutation.

### HYPERGRAPH-C017 — Deleted Reference

A reference to a deleted object cannot silently resolve to another object.

### HYPERGRAPH-C018 — Identity Stability

Topology mutation does not change Element or Relation identity.

### HYPERGRAPH-C019 — Provider Handle Independence

Changing provider-local storage does not change semantic identity or valid semantic references.

### HYPERGRAPH-C020 — Historical Identity

Where tombstones/provenance are supported, deletion preserves historical identity without retaining active semantic existence.

Renumber subsequent conformance tests accordingly.

---

# 8. Required Pathological Tests

Add explicit tests for:

```text
create nullary relation
delete final incidence
re-add incidence
delete relation with zero incidences
delete relation with many incidences
delete element participating in multiple relations
delete element leaving relations nullary
hold reference while topology mutates
hold reference while provider storage moves
hold reference while object is deleted
reuse provider storage slot after deletion
serialize reference
deserialize reference
attempt dereference after deletion
```

The last three are especially important because they expose accidental coupling between semantic identity and storage identity.

---

# 9. Required Invariants

Add or refine the following invariants.

### HYPERGRAPH-I011 — Nullary Validity

A Relation with zero Incidences is valid semantic state.

### HYPERGRAPH-I012 — Incidence Independence

Deleting an Incidence does not delete its Element or Relation.

### HYPERGRAPH-I013 — Relation Lifecycle Independence

A Relation remains semantically existent when its final Incidence is removed unless the Relation itself is explicitly deleted.

### HYPERGRAPH-I014 — Element Lifecycle Independence

Deleting an Element does not implicitly delete unrelated Relations.

### HYPERGRAPH-I015 — Reference Stability

A valid reference continues to designate the same semantic object across topology mutation.

### HYPERGRAPH-I016 — No Silent Retargeting

A reference to a deleted object cannot resolve to a different semantic object.

### HYPERGRAPH-I017 — Identity Mutation Separation

Topology mutation does not implicitly mutate semantic identity.

### HYPERGRAPH-I018 — Provider Handle Independence

Provider storage movement/reuse does not alter SCR semantic identity.

### HYPERGRAPH-I019 — Historical Identity Separation

Historical recognition of a deleted object does not imply that the object remains active.

---

# 10. Required Semantic Lifecycle Model

The specification should ultimately make the lifecycle explicit.

A simplified model is:

```text
                  ┌──────────────┐
                  │    Created   │
                  └──────┬───────┘
                         │
                         ▼
                  ┌──────────────┐
             ┌────│    Active    │────┐
             │    └──────────────┘    │
             │                         │
       topology mutation          explicit deletion
             │                         │
             └──────────┐      ┌───────┘
                        │      ▼
                        │  ┌──────────────┐
                        │  │   Deleted    │
                        │  └──────┬───────┘
                        │         │
                        │         ▼
                        │  historical identity
                        │  / tombstone where
                        │  supported
                        │
                        └── object remains active
```

This lifecycle applies conceptually to Elements, Relations, and Incidences, with their respective deletion semantics.

Do not require all providers to implement the lifecycle identically.

Require them to preserve the semantic contract.

---

# 11. Critical Design Consequence

The hypergraph model is therefore **not merely**:

$$
H=(E,R,I)
$$

as a static topology.

It is better understood as a semantic stateful structure:

$$
H_t=(E_t,R_t,I_t,\rho_t,\Lambda_t)
$$

where `Λ` represents lifecycle/reference/provenance state to whatever degree the final SCR formalization requires.

Do not prematurely force lifecycle into the topology tuple if doing so makes the mathematical model less clear.

The important requirement is that topology, identity, lifecycle, reference, and provenance are explicitly related but not conflated.

---

# 12. Agent Decision Rule

When implementing any deletion, mutation, or reference operation, ask:

1. **What semantic object is changing?**
2. **Is identity changing?**
3. **Is topology changing?**
4. **Is lifecycle changing?**
5. **Are references affected?**
6. **Is provenance affected?**
7. **What happens to provider-local state?**
8. **Can the provider perform this operation without changing SCR meaning?**

If these questions cannot be answered, the operation is not yet sufficiently specified for implementation.

The agent must resolve the semantic contract first rather than allowing provider behavior to define it accidentally.
