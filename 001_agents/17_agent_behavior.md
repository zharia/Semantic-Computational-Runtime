# 17 — Common Failure Modes, Mental Model, The Three Questions

---

## Common Agent Failure Modes

Avoid these patterns.

### Coding from filenames

```
directory exists
    ↓
therefore capability exists
```

False.

### Coding from documentation alone

Documentation may be stale.

Check definitions, status, tests and implementation.

### Treating implementation as specification

```
current behavior
    ↓
therefore intended semantics
```

False.

### Treating external libraries as semantic authorities

```
library API
    ↓
SCR semantics
```

Incorrect direction.

### Inventing semantics to make code compile

Compilation is not semantic validation.

### Creating abstractions prematurely

Do not build generalized infrastructure before a real semantic requirement establishes the need.

### Confusing representations with concepts

```
Tensor ≠ Field
Mesh ≠ Morphology
GPU Buffer ≠ Data
Vulkan Resource ≠ Render Object
```

### Treating status as proof

A status label is evidence about reported state, not proof of correctness.

### Treating one passing test as equivalence

One output is not semantic equivalence.

### Expanding task scope

Do not refactor unrelated architecture merely because you discover an opportunity.

### Fixing generated artifacts directly

Change the authoritative source and regenerate.

---

## Preferred Agent Mental Model

An SCR agent should reason in this order:

```
                    ┌─────────────────────┐
                    │  What does it mean? │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ What is the contract?│
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ What relates to it? │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it represented?│
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it transformed?│
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it lowered?  │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Which provider?     │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ Where does it run?  │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │ How is it validated?│
                    └─────────────────────┘
```

Never reverse this process merely because implementation details are easier to see.

---

## The Three Questions

Before changing SCR, an agent should be able to answer:

### 1. What does this mean?

The semantic definition.

### 2. What currently exists?

The implementation and status.

### 3. How do I prove the change is correct?

The contract, tests and validation.

If any of these cannot be answered, investigate before implementing.
