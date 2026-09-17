// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "rabbitmq_c_api.h"

#include <stdlib.h>
#include <string.h>

#if defined(__has_include)
#if __has_include(<amqp.h>)
#include <amqp.h>
#include <amqp_tcp_socket.h>
#define SCR_HAS_NATIVE_RABBITMQ 1
#else
#define SCR_HAS_NATIVE_RABBITMQ 0
#endif
#else
#define SCR_HAS_NATIVE_RABBITMQ 0
#endif

#define MAX_QUEUES 32
#define MAX_MESSAGES_PER_QUEUE 64

struct MessageNode {
    void* data;
    size_t size;
    struct MessageNode* next;
};

struct QueueRecord {
    char name[64];
    struct MessageNode* head;
    struct MessageNode* tail;
    size_t count;
};

struct InternalRabbitConn {
    char host[128];
    int port;
    struct QueueRecord queues[MAX_QUEUES];
    size_t num_queues;
};

int rabbitmq_connection_create(const char* host, int port, RabbitMqConnHandle* out_conn) {
    if (!out_conn) return RABBITMQ_ERR_NULL_POINTER;

    struct InternalRabbitConn* conn = (struct InternalRabbitConn*)calloc(1, sizeof(struct InternalRabbitConn));
    if (!conn) return RABBITMQ_ERR_OUT_OF_MEMORY;

    strncpy(conn->host, host ? host : "localhost", sizeof(conn->host) - 1);
    conn->port = (port > 0) ? port : 5672;
    *out_conn = (RabbitMqConnHandle)conn;
    return RABBITMQ_SUCCESS;
}

void rabbitmq_connection_destroy(RabbitMqConnHandle conn) {
    if (!conn) return;
    struct InternalRabbitConn* c = (struct InternalRabbitConn*)conn;
    for (size_t i = 0; i < c->num_queues; ++i) {
        struct MessageNode* curr = c->queues[i].head;
        while (curr) {
            struct MessageNode* next = curr->next;
            free(curr->data);
            free(curr);
            curr = next;
        }
    }
    free(c);
}

static struct QueueRecord* find_or_create_queue(struct InternalRabbitConn* conn, const char* name, int create_if_missing) {
    for (size_t i = 0; i < conn->num_queues; ++i) {
        if (strcmp(conn->queues[i].name, name) == 0) {
            return &conn->queues[i];
        }
    }
    if (!create_if_missing || conn->num_queues >= MAX_QUEUES) return NULL;
    struct QueueRecord* q = &conn->queues[conn->num_queues++];
    strncpy(q->name, name, sizeof(q->name) - 1);
    q->head = NULL;
    q->tail = NULL;
    q->count = 0;
    return q;
}

int rabbitmq_queue_declare(RabbitMqConnHandle conn, const char* queue_name) {
    if (!conn || !queue_name) return RABBITMQ_ERR_NULL_POINTER;
    struct InternalRabbitConn* c = (struct InternalRabbitConn*)conn;
    struct QueueRecord* q = find_or_create_queue(c, queue_name, 1);
    return q ? RABBITMQ_SUCCESS : RABBITMQ_ERR_OUT_OF_MEMORY;
}

int rabbitmq_publish(
    RabbitMqConnHandle conn,
    const char* queue_name,
    const void* payload,
    size_t payload_bytes
) {
    if (!conn || !queue_name || !payload) return RABBITMQ_ERR_NULL_POINTER;
    struct InternalRabbitConn* c = (struct InternalRabbitConn*)conn;
    struct QueueRecord* q = find_or_create_queue(c, queue_name, 1);
    if (!q) return RABBITMQ_ERR_OUT_OF_MEMORY;

    struct MessageNode* node = (struct MessageNode*)malloc(sizeof(struct MessageNode));
    if (!node) return RABBITMQ_ERR_OUT_OF_MEMORY;

    node->data = malloc(payload_bytes);
    if (!node->data && payload_bytes > 0) {
        free(node);
        return RABBITMQ_ERR_OUT_OF_MEMORY;
    }
    if (payload_bytes > 0) {
        memcpy(node->data, payload, payload_bytes);
    }
    node->size = payload_bytes;
    node->next = NULL;

    if (!q->head) {
        q->head = node;
        q->tail = node;
    } else {
        q->tail->next = node;
        q->tail = node;
    }
    q->count++;
    return RABBITMQ_SUCCESS;
}

int rabbitmq_consume(
    RabbitMqConnHandle conn,
    const char* queue_name,
    void* out_buffer,
    size_t max_bytes,
    size_t* out_bytes_read
) {
    if (!conn || !queue_name || !out_buffer || !out_bytes_read) return RABBITMQ_ERR_NULL_POINTER;
    struct InternalRabbitConn* c = (struct InternalRabbitConn*)conn;
    struct QueueRecord* q = find_or_create_queue(c, queue_name, 0);
    if (!q || q->count == 0 || !q->head) return RABBITMQ_ERR_QUEUE_EMPTY;

    struct MessageNode* node = q->head;
    if (node->size > max_bytes) {
        return RABBITMQ_ERR_BUFFER_TOO_SMALL;
    }

    if (node->size > 0) {
        memcpy(out_buffer, node->data, node->size);
    }
    *out_bytes_read = node->size;

    q->head = node->next;
    if (!q->head) {
        q->tail = NULL;
    }
    q->count--;

    free(node->data);
    free(node);
    return RABBITMQ_SUCCESS;
}

int rabbitmq_queue_depth(RabbitMqConnHandle conn, const char* queue_name, size_t* out_depth) {
    if (!conn || !queue_name || !out_depth) return RABBITMQ_ERR_NULL_POINTER;
    struct InternalRabbitConn* c = (struct InternalRabbitConn*)conn;
    struct QueueRecord* q = find_or_create_queue(c, queue_name, 0);
    *out_depth = q ? q->count : 0;
    return RABBITMQ_SUCCESS;
}
