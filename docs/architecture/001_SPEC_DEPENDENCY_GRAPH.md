# SCR Specification Dependency Graph

**Status:** Normative documentation architecture

## 1. Purpose

This document defines the dependency direction between SCR specifications. Dependencies express semantic authority, not build order.

## 2. Graph

```text
101_BACKGROUND
      ↓
102_ARCHITECTURE
      ↓
103_SEMANTIC_MODEL
      ↓
104_SEMANTIC_INVARIANTS
      ↓
 ┌────┴───────────────┐
 ↓                    ↓
005 NUMERIC       006 SEQUENCE/TEXT
 ↓                    ↓
 └────────┬───────────┘
          ↓
   SEMANTIC DOMAIN SPECS
          ↓
      RUNTIME MODEL
       ↓       ↓
   MEMORY   RESOURCES
       ↓       ↓
       EXECUTION
          ↓
 ┌────────┼─────────┬──────────┐
 ↓        ↓         ↓          ↓
MESSAGING RENDERING STORAGE NETWORKING
      \      |       /          /
       \     |      /          /
        INTEROPERABILITY
               ↓
          IMPLEMENTATION
```

## 3. Rules

- A child specification MAY refine but MUST NOT contradict its ancestors.
- Runtime documents describe manifestation and execution of semantics; they do not redefine semantics.
- Domain specifications MUST state their semantic dependencies explicitly.
- Technical references are informative unless explicitly promoted by a normative specification.
- External standards are incorporated by semantic mapping, not by importing their assumptions wholesale.

## 4. Versioning

A semantic-breaking change requires an update to the dependent specification set. Implementation-only changes SHOULD NOT require semantic document version changes.
