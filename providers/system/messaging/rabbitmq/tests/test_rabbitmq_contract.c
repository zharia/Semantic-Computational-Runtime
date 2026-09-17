// Copyright 2026 Semantic Computational Runtime (SCR) Contributors
// SPDX-License-Identifier: Apache-2.0

#include "../adapter/rabbitmq_c_api.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

static void test_rabbitmq_publish_consume(void) {
    printf("[Test 1] RabbitMQ Publish & FIFO Consume... ");
    RabbitMqConnHandle conn = NULL;
    int rc = rabbitmq_connection_create("localhost", 5672, &conn);
    assert(rc == RABBITMQ_SUCCESS);
    assert(conn != NULL);

    const char* queue = "scr.telemetry.stream";
    rc = rabbitmq_queue_declare(conn, queue);
    assert(rc == RABBITMQ_SUCCESS);

    const char* msg1 = "Payload-Alpha-123";
    const char* msg2 = "Payload-Beta-456";

    rc = rabbitmq_publish(conn, queue, msg1, strlen(msg1) + 1);
    assert(rc == RABBITMQ_SUCCESS);

    rc = rabbitmq_publish(conn, queue, msg2, strlen(msg2) + 1);
    assert(rc == RABBITMQ_SUCCESS);

    size_t depth = 0;
    rc = rabbitmq_queue_depth(conn, queue, &depth);
    assert(rc == RABBITMQ_SUCCESS);
    assert(depth == 2);

    char buf[128];
    size_t bytes_read = 0;
    // Consume msg1
    rc = rabbitmq_consume(conn, queue, buf, sizeof(buf), &bytes_read);
    assert(rc == RABBITMQ_SUCCESS);
    assert(strcmp(buf, msg1) == 0);

    // Consume msg2
    rc = rabbitmq_consume(conn, queue, buf, sizeof(buf), &bytes_read);
    assert(rc == RABBITMQ_SUCCESS);
    assert(strcmp(buf, msg2) == 0);

    // Queue should now be empty
    rc = rabbitmq_consume(conn, queue, buf, sizeof(buf), &bytes_read);
    assert(rc == RABBITMQ_ERR_QUEUE_EMPTY);

    rabbitmq_connection_destroy(conn);
    printf("PASSED\n");
}

static void test_rabbitmq_error_handling(void) {
    printf("[Test 2] RabbitMQ Precondition and Error Handling... ");
    int rc = rabbitmq_connection_create("localhost", 5672, NULL);
    assert(rc == RABBITMQ_ERR_NULL_POINTER);

    RabbitMqConnHandle conn = NULL;
    rabbitmq_connection_create("localhost", 5672, &conn);

    rc = rabbitmq_publish(conn, NULL, "test", 4);
    assert(rc == RABBITMQ_ERR_NULL_POINTER);

    char buf[128];
    size_t read_bytes = 0;
    rc = rabbitmq_consume(conn, "nonexistent", buf, sizeof(buf), &read_bytes);
    assert(rc == RABBITMQ_ERR_QUEUE_EMPTY);

    rabbitmq_connection_destroy(conn);
    printf("PASSED\n");
}

int main(void) {
    printf("=========================================\n");
    printf(" Running RabbitMQ Provider Contract Tests\n");
    printf("=========================================\n");
    test_rabbitmq_publish_consume();
    test_rabbitmq_error_handling();
    printf("\nAll RabbitMQ Contract Tests PASSED successfully.\n\n");
    return 0;
}
