# 03 — Architecture Navigation, Task Scoping, Discovery

---

## Architecture Navigation

Before modifying a semantic domain, determine:

```
Where am I?
What domain does this represent?
What is its parent?
What are its children?
What concepts does it define?
What interfaces does it implement?
What interfaces does it consume?
What semantic relationships does it have?
What implementations exist?
What providers exist?
What tests exist?
What MLIR representation exists?
What lowering exists?
What runtime path exists?
What status is recorded?
```

At minimum inspect:

```
101_definition.md
102_status.yaml
```

and relevant:

```
103_library.graph.json
interfaces
IR definitions
implementations
providers
transforms
lowering
tests
```

Do not begin implementation from a filename alone.

---

## Task Scoping

Before changing anything, establish the scope of the task.

Use:

```
Task
 ↓
Program Increment
 ↓
Domain
 ↓
Module
 ↓
Capability
 ↓
Function / Operation
```

Determine:

1. What has explicitly been requested?
2. What semantic unit is affected?
3. What contracts are upstream?
4. What contracts are downstream?
5. What implementation is currently responsible?
6. What tests establish current behavior?
7. What is explicitly outside scope?

Do not expand a task merely because an adjacent architectural improvement is visible.

Record or report discovered issues separately when they are outside scope.

---

## Discovery Is Not Permission to Change

Do not assume:

```
I discovered a problem
        ↓
I should fix it
```

Instead:

```
DISCOVER
   ↓
CLASSIFY
   ↓
ASSESS
   ↓
DECIDE
   ↓
CHANGE
```

Discovery may reveal:

- ambiguity;
- inconsistency;
- missing specification;
- stale implementation;
- missing tests;
- architectural debt;
- incorrect status;
- dependency problems.

The discovery itself does not authorize changing the architecture.
