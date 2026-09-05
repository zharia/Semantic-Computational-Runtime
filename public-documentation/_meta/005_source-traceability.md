# Source Traceability

SCR documentation should make it possible to determine where an architectural claim comes from.

## Evidence chain

```text
Public Documentation
       ↓
Normative Definition / Project Specification
       ↓
Library Domain
       ↓
Implementation
       ↓
Test / Example
```

Not every claim will have evidence at every level.

A research document may legitimately terminate at:

```text
Research Question
```

A proposed architecture may terminate at:

```text
Architectural Specification
```

An implemented feature should ultimately be traceable to executable evidence.

## Review questions

For each substantive claim ask:

1. Is this semantic, architectural, implementation, or research information?
2. What is the authoritative source?
3. Is the source current?
4. Is implementation status explicit?
5. Does the public wording overstate the evidence?
6. Could the statement survive an implementation change?

## Future automation

A later documentation validator can use:

- semantic IDs;
- domain paths;
- status records;
- library graphs;
- test identifiers;
- example identifiers.

The goal is to make documentation coverage itself inspectable as part of the project's engineering graph.
