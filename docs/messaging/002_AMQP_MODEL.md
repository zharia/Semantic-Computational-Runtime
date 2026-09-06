# AMQP Messaging Model

## 1. Purpose

SCR standardises its messaging abstraction around the AMQP model while retaining semantic independence from any particular broker implementation.

## 2. Mapping

```text
SCR semantic producer → AMQP publisher
SCR semantic message  → AMQP message
SCR routing relation  → exchange/binding semantics
SCR delivery endpoint → queue/consumer
SCR execution action  → message handling transformation
```

## 3. Exchanges and queues

Exchanges express routing policy; queues express delivery buffering and consumer coordination. Neither is automatically a semantic entity unless exposed by the application contract.

## 4. Acknowledgement

Acknowledgement is part of delivery semantics. The runtime MUST distinguish receipt, acceptance, processing and semantic commitment where these have different meanings.

## 5. Backpressure

Backpressure is a resource/execution condition that may become semantic when producers are required to observe flow-control guarantees.

## 6. Broker independence

RabbitMQ or another AMQP implementation is a provider. SCR semantics MUST be representable independently of a particular broker's topology or configuration API.
