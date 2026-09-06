# Reference Executor Architecture

```text
Program Representation
        |
        v
Parser / Loader
        |
        v
Semantic Field
        |
        +--> Entities
        +--> Relationships
        +--> State
        +--> Constraints
        |
        v
Transformation Resolver
        |
        v
Validation
        |
        v
Atomic State Transition
        |
        v
Observation + Trace
```

The execution engine should be deliberately simple. Semantic complexity belongs in explicit
model, operation, and validation components.

Golden fixtures describe expected semantic outcomes independently of Python object layout.
