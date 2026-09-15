# HYRX

## Messaging for the Age of Heterogeneous Compute

**High-performance AMQP messaging, from the browser to the GPU.**

Hyrx is a new generation of open, high-performance messaging infrastructure built around a simple idea:

**Messaging should move data at the speed and location at which computation actually happens.**

From lightweight application messaging to Kubernetes-native infrastructure and GPU-accelerated data fabrics, Hyrx provides a coherent family of messaging technologies built for modern distributed systems.

**Open. Fast. AMQP-native. Accelerator-ready.**

[Explore Hyrx] [View the Architecture] [Get Started]

---

# The Hyrx Family

Hyrx is not a single product.

It is a family of messaging technologies sharing a common philosophy: **high-performance communication without surrendering interoperability.**

| Product       | Where it runs                                   | What it is for                                         |
| ------------- | ----------------------------------------------- | ------------------------------------------------------ |
| **Hyrx**      | Native applications, services, embedded systems | The optimised open-source AMQP messaging core          |
| **Hyrx WASM** | Web browsers and WebAssembly environments       | High-performance messaging directly inside the browser |
| **HyrxMQ**    | Kubernetes and cloud infrastructure             | Production-grade, Kubernetes-native AMQP messaging     |
| **HyrxMQ++**  | GPU and accelerator clusters                    | Accelerator-aware messaging and data routing           |

Together they form a progression:

**Application → Browser → Cluster → Accelerator**

One messaging philosophy. Increasingly powerful execution environments.

---

# Hyrx

## The Messaging Core

**Hyrx is the foundation.**

Hyrx is an optimised, open-source AMQP messaging core designed for applications that need efficient communication without dragging an entire heavyweight infrastructure stack behind them.

It is intended for developers building:

* distributed applications
* microservices
* high-frequency service communication
* embedded and edge systems
* trading and financial infrastructure
* real-time systems
* AI and data-processing pipelines
* custom messaging infrastructure

Hyrx is deliberately focused on the messaging engine itself.

Rather than beginning with a giant platform and extracting a messaging core from it, Hyrx starts with the communication primitive and optimises outward.

### Why that matters

Modern applications increasingly consist of many independently executing components.

The bottleneck is often no longer computation.

It is **moving information between computations.**

Hyrx exists to make that movement as efficient as possible.

**Hyrx is the engine.**

HyrxMQ is what happens when that engine becomes infrastructure.

---

# Hyrx WASM

## Messaging Inside the Browser

The browser has become a serious application runtime.

Web applications increasingly perform sophisticated computation locally, interact with real-time services and participate in distributed systems.

Yet conventional messaging architectures often assume that the browser is merely a presentation layer.

Hyrx WASM challenges that assumption.

**Hyrx WASM brings the Hyrx messaging model into WebAssembly.**

It is designed to provide high-performance messaging capabilities directly within browser-based and WASM applications.

That opens the door to applications where the browser is an active participant in a distributed computational system rather than simply a graphical terminal.

### Potential applications

* real-time dashboards
* collaborative applications
* browser-based AI
* distributed simulations
* interactive data processing
* trading interfaces
* edge applications
* WebGPU workloads
* real-time control interfaces

The architectural goal is simple:

**Don't send every computation back to the server merely because the browser is involved.**

Let the browser participate.

---

# HyrxMQ

## Messaging for Kubernetes

**HyrxMQ is the production infrastructure layer of the Hyrx family.**

It takes the Hyrx messaging engine and turns it into a Kubernetes-native messaging platform designed for modern cloud infrastructure.

Where Hyrx is the engine, HyrxMQ is the **messaging service**.

It is intended for organisations operating:

* Kubernetes clusters
* cloud-native applications
* microservice architectures
* distributed AI workloads
* real-time data platforms
* financial systems
* industrial systems
* edge/cloud infrastructure

### Built for the way infrastructure actually runs

Modern infrastructure is dynamic.

Services appear and disappear.

Workloads move.

Clusters scale.

Applications are deployed continuously.

Infrastructure becomes increasingly distributed across nodes, availability zones, regions and edge locations.

HyrxMQ is designed around that reality.

Rather than treating Kubernetes as something surrounding a traditional broker, HyrxMQ treats the orchestration environment as part of the operating model.

### The result

**Messaging becomes infrastructure-native rather than infrastructure-adjacent.**

Deploy it.

Scale it.

Observe it.

Automate it.

Integrate it with your cluster.

And keep AMQP at the heart of the communication model.

---

# HyrxMQ++

## The Messaging Fabric for Accelerated Compute

This is where the Hyrx architecture becomes genuinely different.

Modern AI and high-performance computing systems increasingly depend upon accelerators.

GPUs and other specialised processors are no longer peripheral devices sitting beside the CPU.

They are becoming computational infrastructure in their own right.

Yet much of today's messaging architecture still assumes a CPU-centric world.

Data is frequently moved:

**GPU → CPU → network → CPU → GPU**

That movement can become an absurd tax on an otherwise extremely fast system.

HyrxMQ++ is designed around a different proposition:

# What if the messaging fabric understood the accelerator?

HyrxMQ++ extends the HyrxMQ architecture toward **GPU-resident messaging and accelerator-aware data routing**.

The objective is not merely to send messages *to* GPUs.

It is to make the movement of data between computational workloads increasingly aware of where that data already lives.

### HyrxMQ++ is intended for

* AI inference infrastructure
* neural-network pipelines
* GPU clusters
* high-performance computing
* real-time simulation
* scientific computing
* quantitative finance
* computer vision
* distributed tensor processing
* accelerator-to-accelerator communication

The long-term vision is a messaging fabric where the message can become more than a packet of bytes.

It can become:

**a reference to computational data already resident in the fabric.**

That is a very different proposition from conventional message brokering.

---

# One Family. Four Execution Models.

The Hyrx family is deliberately layered.

### Hyrx

**The engine.**

Optimised open-source AMQP messaging for developers who want the messaging core without unnecessary infrastructure.

### Hyrx WASM

**The browser-native messenger.**

Bring high-performance messaging into WebAssembly and make the browser an active computational participant.

### HyrxMQ

**The cloud-native broker.**

Deploy Hyrx as production messaging infrastructure inside Kubernetes.

### HyrxMQ++

**The accelerator-native fabric.**

Extend messaging into GPU-aware, accelerator-aware data movement.

The progression is intentional.

**Hyrx moves messages.
HyrxMQ operates messaging infrastructure.
HyrxMQ++ moves computation's data.**

---

# The Problem

## Data Movement Is Becoming the Bottleneck

For decades, software architecture largely assumed that computation was expensive and communication was comparatively cheap.

That assumption is breaking.

Modern systems contain:

* CPUs
* GPUs
* NPUs
* TPUs
* specialised accelerators
* high-speed storage
* distributed memory
* edge devices
* cloud regions
* browser runtimes

The computational capability of these systems continues to increase.

But computation is useful only when the right data reaches the right computation at the right time.

That creates a new infrastructure problem:

# The data movement problem.

Every unnecessary copy consumes:

* memory bandwidth
* CPU cycles
* PCIe bandwidth
* network bandwidth
* latency budget
* power
* infrastructure capacity

And ultimately:

**money.**

The next generation of infrastructure therefore needs to optimise not merely computation, but the movement of information between computations.

---

# The Old Model

A conventional architecture often looks like this:

**Application → Broker → CPU → Network → CPU → Broker → Application**

Accelerated workloads can become even more elaborate:

**GPU → CPU → Broker → Network → CPU → GPU**

The messaging layer knows about messages.

The application knows about computation.

The accelerator knows about tensors.

But the infrastructure between them may know very little about the relationship.

---

# The Hyrx Model

Hyrx is designed to move toward a different architecture:

**Application → Hyrx → Computational Fabric**

And, for accelerated workloads:

**GPU ↔ HyrxMQ++ ↔ GPU**

The messaging layer becomes increasingly aware of the computational environment in which it operates.

That is the central architectural thesis behind HyrxMQ++.

---

# Why AMQP?

## Open Messaging Semantics Matter

Performance without interoperability is a trap.

A proprietary messaging protocol can be extremely fast while simultaneously creating a new island of infrastructure.

Hyrx takes a different approach.

**Keep the messaging semantics open.**

AMQP provides an established foundation for reliable application messaging and interoperability.

RabbitMQ, for example, supports both AMQP 0-9-1 and AMQP 1.0, while Apache Qpid provides a high-performance AMQP toolkit spanning brokers, clients, routers and other messaging applications.

Hyrx does not need to reinvent messaging semantics merely to optimise the machinery underneath them.

The objective is:

**Open protocol.
Modern implementation.
Aggressive optimisation.**

---

# Hyrx vs the Market

Hyrx is not attempting to replace every messaging technology.

Different systems solve different problems.

## RabbitMQ

RabbitMQ is a mature, general-purpose messaging platform with extensive protocol support, clustering, queues, streams and a substantial ecosystem.

Its strength is breadth, maturity and proven enterprise messaging.

Hyrx approaches the problem from a different direction:

**performance-focused AMQP infrastructure designed from the outset for modern heterogeneous compute.**

RabbitMQ remains an excellent choice where its broad ecosystem and mature feature set are the priority.

Hyrx is intended for workloads where execution efficiency, Kubernetes-native operation and accelerator-aware evolution become increasingly important.

---

## Apache Kafka

Kafka is fundamentally an event-streaming platform.

Its architecture is particularly powerful when organisations need durable event streams, replay, partitioning, large-scale data pipelines and stream processing.

Kafka is therefore exceptionally well suited to:

**“What happened, and how can we retain and process the history?”**

Hyrx is aimed more directly at:

**“Which computational component needs this information, and how efficiently can we get it there?”**

Kafka excels as an event log and streaming platform.

Hyrx is designed around the messaging fabric.

They can therefore be complementary rather than mutually exclusive.

---

## NATS

NATS has established a strong position around lightweight, high-performance distributed messaging, with pub/sub, request/reply and persistent streaming capabilities.

Its architecture is intentionally lightweight and cloud/edge oriented.

Hyrx shares the desire for efficient distributed messaging but retains an AMQP-oriented design centre.

The distinction is therefore less:

**fast vs slow**

and more:

**which messaging semantics and ecosystem do you want your infrastructure built around?**

NATS is an excellent answer for systems designed around NATS semantics.

Hyrx is intended to provide an AMQP-native alternative with an explicit path toward Kubernetes and accelerator-aware messaging.

---

# The Hyrx Difference

The interesting proposition is not that Hyrx merely makes messaging faster.

It is that Hyrx is designed to evolve the **location of the messaging boundary**.

Traditional messaging largely thinks in terms of:

**producer → broker → consumer**

Hyrx increasingly thinks in terms of:

**producer → computational fabric → consumer**

That distinction becomes increasingly important as compute becomes heterogeneous.

---

# The Five Principles

## 1. Open

Hyrx is built around open technology and open standards.

The messaging ecosystem should not become another proprietary island.

---

## 2. Performance

Messaging infrastructure should consume as little computational budget as possible.

Every byte copied unnecessarily is work.

Every unnecessary context switch is work.

Every avoidable serialization is work.

Every unnecessary CPU↔GPU transfer is work.

Hyrx treats that work as an engineering problem.

---

## 3. Native to the Environment

A browser is not a Kubernetes cluster.

A Kubernetes cluster is not a GPU fabric.

The same messaging philosophy should therefore manifest differently according to its computational environment.

**Hyrx WASM.
HyrxMQ.
HyrxMQ++.**

Same family.

Different execution models.

---

## 4. Data Locality

The fastest data transfer is often the one that never needed to happen.

HyrxMQ++ therefore treats data locality as a first-class architectural concern.

Where is the data?

Where is the computation?

Where should the data go?

Can we move a reference instead of moving the data?

Can we route computation to data rather than data to computation?

Those questions define the next generation of messaging infrastructure.

---

## 5. Programmable Performance

Hardware is changing too quickly for infrastructure to be permanently married to one execution model.

Hyrx is therefore built with a modern systems-language strategy.

That language is **Mojo.**

---

# Built with Mojo

## The Language for the Heterogeneous Compute Era

Hyrx is built with **Mojo**, the programming language developed by Modular.

And this is not a superficial implementation detail.

It is part of the architecture.

Modern messaging infrastructure increasingly sits at the intersection of:

* networking
* concurrency
* memory management
* SIMD
* CPU architecture
* GPU computation
* accelerators
* data movement
* low-level systems programming

Historically, solving that problem often meant combining several languages:

**Python + C + C++ + CUDA + compiler tooling + specialised DSLs**

That fragmentation creates friction.

Mojo is designed to collapse much of that complexity into a single systems-oriented language while retaining a familiar, productive programming model.

Mojo 1.0 was released in August 2026, and Modular subsequently open-sourced the language and compiler under Apache 2.0 with LLVM exceptions. Mojo explicitly targets heterogeneous hardware including CPUs and GPUs, while retaining Python interoperability.

That makes Mojo unusually well aligned with the Hyrx vision.

---

# Why Mojo Matters to Hyrx

## One Language Across the Performance Boundary

Hyrx needs to operate close to the hardware.

But it also needs to remain programmable.

Mojo is designed precisely around that tension.

It provides:

**systems-level control + high-level productivity + heterogeneous hardware support.**

Mojo supports CPU and GPU programming within the same language and uses MLIR-based compiler infrastructure to target different hardware backends.

For Hyrx, that creates a compelling development trajectory:

**Network → CPU → SIMD → Memory → GPU → Accelerator**

without requiring the architecture to fracture into unrelated implementation languages at every layer.

---

# Mojo + HyrxMQ++

This becomes particularly important for HyrxMQ++.

GPU-aware messaging is not simply a networking problem.

It is simultaneously a:

* memory problem
* scheduling problem
* concurrency problem
* topology problem
* device-management problem
* data-layout problem
* compilation problem

A language capable of expressing both systems-level infrastructure and accelerator computation is therefore strategically valuable.

Mojo gives Hyrx a path toward a messaging implementation where the distinction between:

**networking infrastructure**

and

**accelerated computation**

can become progressively thinner.

That is the territory HyrxMQ++ is designed to explore.

---

# Why Business Leaders Should Care

Technology leaders should care because infrastructure efficiency eventually becomes financial efficiency.

If a business operates thousands of services, millions of messages, large data pipelines or expensive GPU infrastructure, the cost of moving data can become material.

The questions become economic:

### How much CPU capacity is spent moving data?

### How much GPU capacity sits idle waiting for data?

### How much memory bandwidth is consumed by unnecessary copies?

### How much network traffic is generated by inefficient architectures?

### How much infrastructure exists merely to compensate for inefficient data movement?

### How much developer complexity is created by stitching together multiple messaging technologies?

Hyrx attacks that problem from the infrastructure layer.

---

# The Business Proposition

## More Compute Per Rand

If less infrastructure work is spent moving and transforming messages, more of the infrastructure budget can be spent performing useful computation.

---

## Better GPU Economics

GPUs are expensive because they are extraordinarily capable.

Keeping a GPU waiting for data is therefore expensive.

Accelerator-aware messaging aims to reduce the distance between data and computation.

---

## Lower Architectural Complexity

A coherent messaging family can reduce the need to maintain completely different messaging stacks for:

* native applications
* browsers
* Kubernetes
* GPU infrastructure

---

## Cloud-Native Operation

HyrxMQ is designed around Kubernetes rather than treating Kubernetes as an afterthought.

That aligns messaging infrastructure with the deployment environment in which modern distributed applications increasingly operate.

---

## Open Technology

Businesses should be able to inspect their infrastructure, extend it, integrate it and avoid unnecessary proprietary lock-in.

Open source provides the foundation.

Commercial infrastructure can then be built around it.

---

# Designed for the Systems That Are Coming

The architecture of computing is changing.

The future is unlikely to be:

**CPU + memory + network**

It is increasingly:

**CPU + GPU + NPU + memory + storage + network + edge + cloud + browser**

The messaging layer sits between all of them.

That makes messaging infrastructure increasingly important.

Hyrx is being built for that world.

---

# From Messages to Data Movement

The evolution is straightforward:

### Hyrx

Move messages efficiently.

↓

### Hyrx WASM

Move messages into the browser.

↓

### HyrxMQ

Move messages through cloud-native infrastructure.

↓

### HyrxMQ++

Move computational data intelligently across heterogeneous accelerators.

The destination is not simply a faster message broker.

It is a **computational messaging fabric.**

---

# HyrxMQ++

## Where Messaging Meets Compute

The ultimate HyrxMQ++ vision is a messaging system in which the infrastructure understands that a message may represent something much larger than its serialized payload.

A message might identify:

* a tensor
* a memory region
* a GPU buffer
* a dataset
* a computation
* a model
* a stream
* a computational dependency

The network should not necessarily move all of that data.

Sometimes it should move **the information required to access it.**

That is the conceptual leap from:

**message broker**

to

**data-routing fabric.**

---

# Built for the Next Generation

Hyrx is intended for organisations building systems where performance, scale and heterogeneous computation matter.

### AI & Machine Learning

Move data between inference, preprocessing, postprocessing and model-serving workloads.

### Financial Technology

Low-latency communication between pricing, risk, execution and market-data systems.

### Scientific Computing

Connect distributed computational workloads without treating the network as a dumb pipe.

### Simulation

Move state between distributed simulation components while preserving high-performance execution.

### Robotics & Autonomous Systems

Connect perception, planning, control and sensor-processing workloads.

### Real-Time Analytics

Move information between data producers and computational consumers with minimal unnecessary overhead.

### Edge Computing

Deploy lightweight messaging where bandwidth, power and compute resources are constrained.

### Web Applications

Bring real-time messaging directly into browser-based computation through Hyrx WASM.

---

# One Architecture. Many Machines.

From a laptop to a Kubernetes cluster.

From a browser to a GPU farm.

From a microservice to an accelerator.

**Hyrx is designed to make them participants in the same messaging universe.**

---

# Open Source at the Core

Hyrx begins with open technology.

The core engine is intended to remain open, inspectable and extensible.

The objective is not to build another black box between applications and their data.

It is to provide a foundation upon which developers, infrastructure teams and technology companies can build.

**The protocol is open.
The engine is open.
The architecture is extensible.**

Build on it.

Embed it.

Deploy it.

Extend it.

---

# The Hyrx Philosophy

### Don't move data unnecessarily.

### Don't make the CPU do work an accelerator can do better.

### Don't make the application understand infrastructure it shouldn't need to understand.

### Don't sacrifice interoperability for performance.

### Don't sacrifice performance for abstraction.

### Don't build tomorrow's infrastructure around yesterday's hardware assumptions.

---

# Messaging, Reconsidered.

The first generation of distributed systems asked:

**How do we send a message from A to B?**

The next generation asks:

**Where is the data?**

**Where is the computation?**

**Where should the data exist?**

**What is the cheapest path between them?**

**And does the data need to move at all?**

Hyrx is being built around those questions.

---

# Welcome to Hyrx

## The Messaging Fabric for Heterogeneous Compute

**Hyrx**
Optimised open-source AMQP messaging.

**Hyrx WASM**
High-performance messaging for the browser.

**HyrxMQ**
Kubernetes-native messaging infrastructure.

**HyrxMQ++**
GPU-accelerated messaging and data routing.

One family.

One architectural direction.

A new generation of messaging infrastructure.

### Move less. Compute more.

[Explore Hyrx] [Explore HyrxMQ] [Explore HyrxMQ++] [GitHub]
