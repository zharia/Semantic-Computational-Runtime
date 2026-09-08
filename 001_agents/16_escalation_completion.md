# 16 — Escalation, Definition of Done, Change Classification, Review

---

## When to Escalate

An agent must stop and request clarification or architectural direction when:

- two normative specifications conflict;
- a required semantic distinction is undefined;
- an implementation requires inventing domain semantics;
- a proposed change alters a foundational invariant;
- a provider limitation would require weakening the semantic contract;
- two architectural interpretations are materially incompatible;
- a change affects multiple foundational domains without an established relationship;
- a task requires changing the source of truth outside the assigned scope;
- security, persistence, identity, or execution semantics are unclear;
- the correct behavior cannot be established from authoritative project material.

Do not guess foundational architecture.

---

## Definition of Done

A substantive change is complete only when the applicable requirements have evidence.

Consider:

```
Semantic Contract    ✓
Implementation       ✓
Tests                ✓
Validation           ✓
Documentation        ✓
Status               ✓
Derived Artifacts    ✓
```

Additional requirements may apply:

```
MLIR Integration
Lowering
Provider
Runtime
Serialization
Cross-Substrate Validation
Performance
Security
```

These are conditional.

Do not mark a requirement complete merely because an artifact exists.

Completion means the requirement has been demonstrated.

---

## Change Classification

Before finalizing a change, classify it.

### Semantic Change

Changes what a concept means.

Requires:

- specification review;
- invariant review;
- contract review;
- affected relationship review;
- tests;
- status update.

### Representational Change

Changes how meaning is represented.

Requires:

- representation correctness;
- preservation of semantics;
- transformation tests.

### Implementation Change

Changes how a contract is realized.

Requires:

- implementation tests;
- conformance validation;
- equivalence analysis where applicable.

### Provider Change

Changes an external implementation path.

Requires:

- provider capability review;
- contract coverage;
- provider-specific validation.

### Optimization

Changes execution characteristics while preserving the applicable semantic contract.

Requires:

- measurement;
- equivalence validation;
- regression testing.

### Documentation Change

Changes explanation without changing normative meaning.

Must not accidentally introduce semantic changes.

---

## Review Questions

Before completing substantive work, ask:

### Semantics

```
What does this mean?
What contract does it implement?
What invariants must hold?
```

### Architecture

```
Where does this belong?
What relationships does it have?
What layer owns it?
```

### Representation

```
What is semantic?
What is representational?
What is implementation-specific?
```

### Execution

```
How does this reach MLIR?
How does it lower?
Which provider executes it?
What substrate runs it?
```

### Correctness

```
What proves it works?
What proves invariants are preserved?
What proves equivalence?
```

### Scope

```
Was this actually required?
Did the change expand beyond the assigned task?
```
