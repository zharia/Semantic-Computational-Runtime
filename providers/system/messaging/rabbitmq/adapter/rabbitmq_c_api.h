// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#ifndef SCR_RABBITMQ_C_API_H
#define SCR_RABBITMQ_C_API_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define RABBITMQ_SUCCESS 0
#define RABBITMQ_ERR_NULL_POINTER -1
#define RABBITMQ_ERR_INVALID_HANDLE -2
#define RABBITMQ_ERR_QUEUE_EMPTY -3
#define RABBITMQ_ERR_OUT_OF_MEMORY -4
#define RABBITMQ_ERR_BUFFER_TOO_SMALL -5

typedef void* RabbitMqConnHandle;

/**
 * Creates a message queue broker connection handle.
 */
int rabbitmq_connection_create(const char* host, int port, RabbitMqConnHandle* out_conn);

/**
 * Destroys a connection and purges associated queues.
 */
void rabbitmq_connection_destroy(RabbitMqConnHandle conn);

/**
 * Declares a named message queue.
 */
int rabbitmq_queue_declare(RabbitMqConnHandle conn, const char* queue_name);

/**
 * Publishes a binary payload message to the specified queue.
 */
int rabbitmq_publish(
    RabbitMqConnHandle conn,
    const char* queue_name,
    const void* payload,
    size_t payload_bytes
);

/**
 * Consumes the next FIFO message from the specified queue.
 * @param conn Connection handle
 * @param queue_name Name of queue
 * @param out_buffer Preallocated buffer for payload
 * @param max_bytes Capacity of out_buffer
 * @param out_bytes_read Pointer receiving actual size of consumed message
 */
int rabbitmq_consume(
    RabbitMqConnHandle conn,
    const char* queue_name,
    void* out_buffer,
    size_t max_bytes,
    size_t* out_bytes_read
);

/**
 * Returns the current message count in a queue.
 */
int rabbitmq_queue_depth(RabbitMqConnHandle conn, const char* queue_name, size_t* out_depth);

#ifdef __cplusplus
}
#endif

#endif // SCR_RABBITMQ_C_API_H
