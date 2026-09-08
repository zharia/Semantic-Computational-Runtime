# 04 — Development Lifecycle, Inspection, Missing Semantics

---

## Development Lifecycle

Substantive work should follow:

```
DISCOVER
    ↓
CLASSIFY
    ↓
DEFINE
    ↓
RELATE
    ↓
SPECIFY
    ↓
DESIGN TESTS
    ↓
IMPLEMENT
    ↓
TEST
    ↓
VALIDATE
    ↓
INTEGRATE
    ↓
OPTIMIZE
```

Not every task requires every stage.

However, semantic ambiguity must be resolved before implementation is allowed to define the missing behavior.

---

## Inspect Before Editing

Before modifying code:

1. Inspect the target.
2. Inspect its semantic definition.
3. Inspect its status.
4. Search for related concepts.
5. Search for existing implementations.
6. Search for interfaces.
7. Search for tests.
8. Inspect callers and consumers.
9. Inspect providers and adapters.
10. Inspect relevant MLIR representation.

Useful commands include:

```bash
find . -maxdepth 2 -type f | sort
find lib -type d | sort
find lib -type f | sort
rg "ConceptName" .
rg "operation_name|type_name|interface_name" .
find . -type f \( -name '*test*' -o -name '*lit*' \) | sort
```

Use the repository's actual build and test configuration.

Do not invent commands or workflows when the repository already defines them.

---

## Do Not Implement Around Missing Semantics

If the semantic contract is incomplete, do not silently fill the gap with implementation assumptions.

Classify the problem:

```
Specified
Partially specified
Ambiguous
Contradictory
Missing
```

For:

```
Ambiguous
Contradictory
Missing
```

either:

1. resolve it from an authoritative source; or
2. stop and escalate if the decision is architectural.

Do not encode an architectural assumption merely because it makes the code compile.
