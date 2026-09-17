# RabbitMQ Messaging Provider Contract

**Provider:** rabbitmq  
**Domain:** system  
**Subdomain:** messaging  
**Version:** 0.1.0  
**Status:** Normative Contract  
**Governing Documents:** [`docs/architecture/103_provider_contracts.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/architecture/103_provider_contracts.md)

---

## 1. Contract Overview

This document specifies the concrete Provider Contract implemented by the `rabbitmq` provider for the `system/messaging` capability domain. It defines connection management, queue declaration, asynchronous binary message publishing, and FIFO consumption for distributed runtime and stream communication.

---

## 2. Semantic Capabilities

* `[system, messaging, rabbitmq, connection_lifecycle]` — AMQP broker connection lifecycle.
* `[system, messaging, rabbitmq, queue_declare]` — Named queue creation and declaration.
* `[system, messaging, rabbitmq, publish]` — Binary payload message publishing.
* `[system, messaging, rabbitmq, consume]` — FIFO ordered message consumption.

---

## 3. Operations & Signatures

* `rabbitmq_connection_create(host, port, out_conn) -> int`
* `rabbitmq_connection_destroy(conn) -> void`
* `rabbitmq_queue_declare(conn, queue_name) -> int`
* `rabbitmq_publish(conn, queue_name, payload, payload_bytes) -> int`
* `rabbitmq_consume(conn, queue_name, out_buffer, max_bytes, out_bytes_read) -> int`
* `rabbitmq_queue_depth(conn, queue_name, out_depth) -> int`

---

## 4. Preconditions & Postconditions

1. **Precondition (Non-Null Handles):** All queue operations require valid connection handles and non-empty queue names.
2. **Postcondition (FIFO Ordering):** Messages published to a declared queue are consumed in exact first-in, first-out order.
3. **Postcondition (Payload Conservation):** The consumed payload bytes must be bitwise identical to the published payload bytes.

---

## 5. Failure Semantics & Error Codes

* `RABBITMQ_SUCCESS = 0`
* `RABBITMQ_ERR_NULL_POINTER = -1`
* `RABBITMQ_ERR_INVALID_HANDLE = -2`
* `RABBITMQ_ERR_QUEUE_EMPTY = -3`
* `RABBITMQ_ERR_OUT_OF_MEMORY = -4`
* `RABBITMQ_ERR_BUFFER_TOO_SMALL = -5`

---

## 6. Conformance Test Suite

The provider is validated against the conformance suite in `tests/test_rabbitmq_contract.c`.
