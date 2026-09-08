# 02 — Repository Graph and Controlled Relationship Vocabulary

---

## The Repository Is a Graph

The filesystem is an organization mechanism.

The semantic architecture is a graph.

Do not infer semantic relationships from directory placement.

Distinguish:

```
Filesystem Relationship
        ≠
Semantic Relationship
        ≠
Implementation Dependency
```

For example:

```
Morphology REFINES Geometry
```

is a semantic relationship.

Whereas:

```
morphology.rs DEPENDS_ON geometry.rs
```

is an implementation dependency.

Likewise:

```
Physics IMPLEMENTED_BY Provider
```

does not mean:

```
Physics IS Provider
```

---

## Controlled Relationship Vocabulary

Prefer explicit relationship types.

Use existing vocabulary where possible:

```
CONTAINS
REFINES
SPECIALIZES
COMPOSES
DEPENDS_ON
REPRESENTS
LOWERS_TO
IMPLEMENTED_BY
EXECUTES_ON
ADAPTS
PRODUCES
CONSUMES
INTERACTS_WITH
CONSTRAINS
OBSERVES
TRANSFORMS
DERIVES_FROM
REFERENCES
EQUIVALENT_TO
```

Do not invent a new relationship when an existing relationship expresses the intended meaning.

If the distinction between two relationships is semantically important, document the distinction before encoding it.
