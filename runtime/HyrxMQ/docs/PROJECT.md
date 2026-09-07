# Project Definition

## Name

- Product: **HyrxMQ**
- Technology/substrate: **Hyrx**
- Executable/service: `hyrxmq`

Capitalization is normative.

## Definition

Hyrx is a self-contained native Mojo messaging engine designed for extremely low-cost message routing and delivery. HyrxMQ is the independently deployable broker product built on that engine.

## Independence invariant

Hyrx SHALL NOT require:

- a simulation
- a creature/agent ontology
- a game engine
- a semantic-world model
- a particular application
- RabbitMQ
- Erlang/OTP
- AMQP framing internally
- network availability for direct in-process use

Any application may use Hyrx.

## Relationship to simulation

A simulation is an external consumer of Hyrx. It may use one Hyrx instance per process, multiple logical domains, local IPC, or networked Hyrx instances. The choice belongs to the simulation/application.

The Hyrx codebase must not contain simulation-specific concepts merely because the simulation is an important motivating workload.

## Product relationship

HyrxMQ is not a simulation component. It is a standalone broker product that can be installed on an unrelated GNU/Linux host and used by unrelated applications.

## Initial platform

- GNU/Linux only
- systemd as the normative service manager
- native Mojo
- single-node execution

Container/VM operation may be supported as a deployment convenience, but neither Docker nor Kubernetes is an architectural dependency.

## Success criteria

The project succeeds when:

1. Hyrx provides a useful low-cost native messaging substrate.
2. Hyrx can be embedded without networking.
3. HyrxMQ can run independently as an AMQP 0-9-1 broker.
4. existing AMQP/RabbitMQ clients can be demonstrated to interoperate according to a published compatibility matrix.
5. performance is measured across local and network transports.
6. persistence and recovery are reliable.
7. operations are practical through API, CLI, UI, metrics, and systemd.
8. the implementation remains maintainable and semantically correct.
