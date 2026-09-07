# Development-Agent Self-Assessment

The development agent must perform an explicit self-assessment at the end of every implementation phase and before every release candidate.

## Required questions

### Architecture

1. Did I preserve Hyrx independence from simulation?
2. Did I accidentally make AMQP or TCP an internal dependency?
3. Did I introduce a product-layer dependency into Hyrx Core?
4. Did I add abstractions for hypothetical distributed operation prematurely?

### Correctness

5. What invariants are proven by tests?
6. What behavior remains assumption rather than evidence?
7. What failure paths remain untested?

### Performance

8. What operation is actually the current bottleneck?
9. What evidence supports the optimization I made?
10. Did the optimization increase complexity or reduce semantic clarity?
11. Did I measure allocations, copies, contention, scheduler cost, and transport cost separately?
12. Did I benchmark tail latency rather than only throughput?

### Compatibility

13. Which AMQP features are genuinely tested?
14. Which RabbitMQ behaviors are only inferred?
15. Did I update the compatibility matrix?

### Reliability

16. What happens under resource exhaustion?
17. What happens after abrupt termination?
18. Can state be recovered without silent corruption?

### Security

19. What hostile inputs were tested?
20. What privilege does the process require?
21. Which systemd hardening controls have been validated?

### Documentation

22. Does the documentation describe actual behavior rather than intended behavior?
23. Are unsupported features explicitly identified?
24. Are configuration and operational procedures reproducible?

## Required evidence

A phase report should include:

- implementation summary
- changed architectural decisions
- tests executed
- benchmark results
- compatibility results
- known limitations
- unresolved risks
- next-phase prerequisites

## Honesty clause

The agent SHALL NOT mark a requirement complete merely because:

- code exists
- compilation succeeds
- a happy-path test passes
- a benchmark number looks impressive
- the behavior appears plausible

Completion requires the evidence specified by the relevant quality gate.

## Stop-and-escalate conditions

Stop implementation and request architectural review when:

- a requirement conflicts with another requirement
- a transport optimization changes semantics
- an unsafe memory technique appears necessary
- a compatibility claim cannot be validated
- persistence semantics are ambiguous
- a proposed dependency violates project boundaries
- a simulation-specific concept is being proposed for Hyrx Core
