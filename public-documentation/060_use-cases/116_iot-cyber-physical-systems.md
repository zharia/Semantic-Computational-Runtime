# 116 — IoT and Cyber-Physical Systems

## 1. Use case

IoT and cyber-physical systems connect sensors, machines, controllers, gateways, networks and software into operational environments.

## 2. Problems and friction in conventional systems

- Device fleets are heterogeneous.
- Protocols and data models differ.
- Device identity and asset identity are frequently separate.
- Telemetry, control and historical state live in different systems.
- Failure propagation is difficult to model.
- Operational topology changes over time.

## 3. Key requirements

- Device identity.
- Real-time signals.
- State and lifecycle.
- Relationship modelling.
- Control constraints.
- Fault tolerance.
- Local and distributed execution.
- Security.

## 4. What SCR can offer

SCR can represent devices, measurements, controllers, physical assets, networks and transformations as one semantic field. Protocols become manifestations of semantic relationships rather than separate semantic universes.

## 5. How the Semantic Field changes the architecture

SCR models the domain as semantic structure first and physical manifestation second. Entities, relationships, transformations, context, state, constraints, topology and resources remain first-class. Physical mechanisms such as databases, queues, devices, accelerators, VMs and networks become manifestations of those structures.

```text
Semantic state
     ↓
relationships + transformations + context + constraints
     ↓
evolving computational topology
     ↓
representation / placement / execution
     ↓
physical resources
```

## 6. Non-obvious advantage

The non-obvious advantage is **the topology of the physical system can become executable**. A factory topology can simultaneously describe routing, computation, dependency, monitoring and control relationships.

## 7. Target users and market segments

- Industrial automation.
- Energy.
- Smart buildings.
- Telecom.
- Manufacturing.
- Utilities.

## 8. Adoption path

Begin with telemetry and device-state integration. Add semantic control paths only after identity, constraints and failure semantics are robust.

## 9. Competitive positioning

Industrial IoT platforms and OPC UA-style ecosystems remain important. SCR should complement standards by providing a computational substrate across their semantic and physical boundaries.

## 10. Strategic thesis

The opportunity is strongest where a system spends significant effort translating between representations, runtimes, data stores, devices and execution environments. SCR should therefore be evaluated on total system friction, not only on the speed of an isolated operation.
