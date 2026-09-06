# 111 — Digital Twins

## 1. Use case

Digital twins represent physical or organisational entities across their lifecycle, combining models, telemetry, state, simulation and operational data.

## 2. Problems and friction in conventional systems

- CAD, PLM, ERP, SCADA, IoT, simulation and maintenance systems use incompatible representations.
- Twin identity is often fragmented across systems.
- Real-time state and engineering models are difficult to unify.
- Simulation and operational control often remain separate.
- Lifecycle provenance is distributed across databases and documents.

## 3. Key requirements

- Persistent identity.
- Multi-modal state.
- Temporal history.
- Model interoperability.
- Telemetry ingestion.
- Simulation coupling.
- Provenance and lifecycle management.
- Real-time execution.

## 4. What SCR can offer

SCR can represent the physical asset, its models, measurements, relationships, operational state and simulations as one semantic topology. Different engineering and operational representations become manifestations linked by persistent semantic identity.

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

The non-obvious advantage is **the twin can become computationally alive**. Simulation, telemetry, analytics and control can operate on one semantic entity rather than on separately synchronised copies. A simulated asset and a physical asset can share semantic structure while differing in manifestation.

## 7. Target users and market segments

- Manufacturing.
- Energy.
- Aerospace.
- Smart infrastructure.
- Industrial engineering.
- Defence.

## 8. Adoption path

Start with one asset class and connect telemetry, engineering metadata and simulation. Demonstrate identity, provenance and state continuity before introducing closed-loop control.

## 9. Competitive positioning

Digital-twin platforms and industrial standards are valuable complements. SCR differentiates by making the twin a computational substrate rather than principally a data/integration model.

## 10. Strategic thesis

The opportunity is strongest where a system spends significant effort translating between representations, runtimes, data stores, devices and execution environments. SCR should therefore be evaluated on total system friction, not only on the speed of an isolated operation.
