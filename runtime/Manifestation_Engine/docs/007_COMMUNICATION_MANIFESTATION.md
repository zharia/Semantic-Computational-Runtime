# Manifestation Engine — Communication Manifestation

## 1. Semantic communication

Communication is modeled as semantic interaction, not transport API invocation.

Examples include:

- publish message;
- send message;
- subscribe;
- receive;
- acknowledge;
- reject;
- stream;
- route;
- correlate.

## 2. Transport independence

A semantic communication operation MUST NOT require knowledge of TCP, HTTP, WebSocket, AMQP, Kafka, Unix sockets or other physical protocols.

## 3. Messaging providers

The Engine may use AMQP-oriented infrastructure internally. Such infrastructure is a provider/manifestation layer.

## 4. Delivery semantics

The semantic contract SHOULD specify, where relevant:

- at-most-once;
- at-least-once;
- exactly-once as a qualified contract;
- ordering;
- durability;
- acknowledgement;
- retry;
- expiry;
- backpressure;
- correlation.

Claims of exactly-once MUST account for actual failure and storage boundaries.

## 5. Routing

Semantic targets are identities or relationships. Broker routing keys, queue names and exchange names are manifestations.

## 6. Message identity

Message identity MUST be distinct from transport packet identity. Retries MUST preserve or intentionally change semantic message identity according to contract.

## 7. External communication

External systems are accessed through semantic communication capabilities and protocol adapters. The graph does not acquire direct network authority.

## 8. Backpressure

Backpressure is an execution property unless the semantic stream contract requires specific behavior. Providers MUST expose enough information for the Engine to prevent uncontrolled resource growth.
