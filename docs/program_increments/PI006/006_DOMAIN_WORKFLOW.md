# Domain Development Workflow

For every domain/subdomain:
1. Describe
2. Specify
3. Formalize laws
4. Define transformations
5. Define observations
6. Define negative cases
7. Implement reference semantics
8. Implement Mojo
9. Validate
10. Integrate
11. Update graph/status

Before adding a type ask:
- What does it mean?
- How is it represented in semantic state?
- What transformations affect it?
- What observations distinguish it?
- What constraints apply?
- What laws hold?

Provider implementations never define semantic meaning. EGS realizes executable semantic
graphs; MLIR represents/lowers; Mojo implements.
