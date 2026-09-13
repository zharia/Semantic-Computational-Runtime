/// Hyrx WASM — Native test suite for the C implementation.
///
/// Compile: gcc -Isrc -o hyrx_test src/test_hyrx.c && ./hyrx_test

#include "engine.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

static int tests_passed = 0;
static int tests_failed = 0;

#define TEST(name) printf("  %-40s ", name);
#define PASS() do { printf("OK\n"); tests_passed++; } while(0)
#define FAIL(msg) do { printf("FAIL: %s\n", msg); tests_failed++; } while(0)

#define ASSERT(expr) do { \
    if (!(expr)) { FAIL(#expr); return; } \
} while(0)

static void test_buffer(void) {
    TEST("buffer: create/read/append/clear");
    hyrx_buffer_t *buf = hyrx_buffer_create(64);
    ASSERT(buf != NULL);
    ASSERT(hyrx_buffer_size(buf) == 0);
    ASSERT(hyrx_buffer_capacity(buf) == 64);

    hyrx_buffer_append(buf, 0x41);
    hyrx_buffer_append(buf, 0x42);
    hyrx_buffer_append(buf, 0x43);
    ASSERT(hyrx_buffer_size(buf) == 3);
    ASSERT(hyrx_buffer_get(buf, 0) == 0x41);
    ASSERT(hyrx_buffer_get(buf, 1) == 0x42);
    ASSERT(hyrx_buffer_get(buf, 2) == 0x43);

    hyrx_buffer_clear(buf);
    ASSERT(hyrx_buffer_size(buf) == 0);

    uint32_t len;
    uint8_t *bytes = hyrx_buffer_to_bytes(buf, &len);
    ASSERT(len == 0);
    free(bytes);

    hyrx_buffer_destroy(buf);
    PASS();
}

static void test_pool(void) {
    TEST("pool: acquire/release/reuse");
    hyrx_pool_t *pool = hyrx_pool_create(1024, 8);
    ASSERT(pool != NULL);

    hyrx_buffer_t *b1 = hyrx_pool_acquire(pool, 128);
    ASSERT(b1 != NULL);
    ASSERT(hyrx_buffer_capacity(b1) >= 128);

    hyrx_pool_stats_t s = hyrx_pool_stats(pool);
    ASSERT(s.allocations == 1);
    ASSERT(s.in_use == 1);

    hyrx_pool_release(pool, b1);
    s = hyrx_pool_stats(pool);
    ASSERT(s.in_use == 0);
    ASSERT(s.reuses == 0); // first acquire was alloc, not reuse

    hyrx_buffer_t *b2 = hyrx_pool_acquire(pool, 128);
    ASSERT(b2 != NULL);
    s = hyrx_pool_stats(pool);
    ASSERT(s.reuses == 1); // b2 came from free list

    hyrx_pool_release(pool, b2);
    hyrx_pool_destroy(pool);
    PASS();
}

static void test_message(void) {
    TEST("message: create/payload/headers");
    uint8_t data[] = {0xDE, 0xAD, 0xBE, 0xEF};
    hyrx_message_t *msg = hyrx_message_create("test.key", data, 4);
    ASSERT(msg != NULL);
    ASSERT(strcmp(hyrx_message_routing_key(msg), "test.key") == 0);

    uint32_t len;
    const uint8_t *payload = hyrx_message_payload(msg, &len);
    ASSERT(len == 4);
    ASSERT(payload[0] == 0xDE);
    ASSERT(payload[3] == 0xEF);

    hyrx_message_set_header(msg, "content-type", "application/json");
    ASSERT(strcmp(hyrx_message_get_header(msg, "content-type"), "application/json") == 0);
    ASSERT(hyrx_message_get_header(msg, "missing") == NULL);

    hyrx_message_destroy(msg);
    PASS();
}

static void test_queue(void) {
    TEST("queue: enqueue/dequeue/ack/reject");
    hyrx_queue_t *q = hyrx_queue_create("test-q", 10);
    ASSERT(q != NULL);
    ASSERT(hyrx_queue_depth(q) == 0);

    hyrx_message_t *m1 = hyrx_message_create("key1", (uint8_t*)"aaa", 3);
    hyrx_message_t *m2 = hyrx_message_create("key2", (uint8_t*)"bbb", 3);
    ASSERT(hyrx_queue_enqueue(q, m1));
    ASSERT(hyrx_queue_enqueue(q, m2));
    ASSERT(hyrx_queue_depth(q) == 2);

    uint64_t tag1 = hyrx_queue_dequeue(q);
    ASSERT(tag1 == 0); // first delivery
    ASSERT(hyrx_queue_depth(q) == 1);

    uint32_t len;
    const uint8_t *payload = hyrx_queue_read_payload(q, tag1, &len);
    ASSERT(len == 3);
    ASSERT(payload[0] == 'a');

    ASSERT(hyrx_queue_acknowledge(q, tag1));
    ASSERT(hyrx_queue_depth(q) == 1);

    uint64_t tag2 = hyrx_queue_dequeue(q);
    ASSERT(tag2 == 1);
    ASSERT(hyrx_queue_reject(q, tag2));
    ASSERT(hyrx_queue_depth(q) == 1); // requeued to inbox, outbox empty

    hyrx_queue_destroy(q);
    PASS();
}

static void test_exchange(void) {
    TEST("exchange: direct/topic routing");
    hyrx_exchange_t *ex = hyrx_exchange_create("test-ex", HYRX_EXCHANGE_DIRECT);
    ASSERT(ex != NULL);

    hyrx_exchange_add_binding(ex, "q1", "orders");
    hyrx_exchange_add_binding(ex, "q2", "events");
    hyrx_exchange_add_binding(ex, "q3", "orders.*");

    // Direct match.
    char results[64][128];
    uint32_t n = hyrx_exchange_match(ex, "orders", results, 64);
    ASSERT(n == 1);
    ASSERT(strcmp(results[0], "q1") == 0);

    // No match.
    n = hyrx_exchange_match(ex, "other", results, 64);
    ASSERT(n == 0);

    // Test topic exchange.
    hyrx_exchange_t *topic = hyrx_exchange_create("topic-ex", HYRX_EXCHANGE_TOPIC);
    hyrx_exchange_add_binding(topic, "q-orders", "orders.*");
    hyrx_exchange_add_binding(topic, "q-all", "#");

    n = hyrx_exchange_match(topic, "orders.created", results, 64);
    ASSERT(n == 2); // matches "orders.*" and "#"

    n = hyrx_exchange_match(topic, "logs.error", results, 64);
    ASSERT(n == 1); // matches only "#"
    ASSERT(strcmp(results[0], "q-all") == 0);

    hyrx_exchange_destroy(ex);
    hyrx_exchange_destroy(topic);
    PASS();
}

static void test_engine(void) {
    TEST("engine: full publish/consume cycle");
    hyrx_engine_t *e = hyrx_engine_create();
    ASSERT(e != NULL);

    // Default exchanges should exist.
    ASSERT(hyrx_engine_has_exchange(e, ""));
    ASSERT(hyrx_engine_has_exchange(e, "amq.direct"));

    // Declare topology.
    ASSERT(hyrx_engine_declare_queue(e, "tasks"));
    ASSERT(hyrx_engine_declare_exchange(e, "my-ex", HYRX_EXCHANGE_TOPIC));
    ASSERT(hyrx_engine_bind_queue(e, "tasks", "my-ex", "task.#"));

    // Publish.
    hyrx_message_t *msg = hyrx_message_create("task.build", (uint8_t*)"payload1", 8);
    uint32_t routed = hyrx_engine_publish(e, msg, "my-ex");
    ASSERT(routed == 1);

    // Consume.
    uint64_t cid = hyrx_engine_consume(e, "tasks");
    ASSERT(cid > 0);

    uint64_t tag = hyrx_engine_next_message(e, cid);
    ASSERT(tag == 0); // first delivery tag

    uint32_t len;
    const uint8_t *payload = hyrx_engine_read_payload(e, cid, tag, &len);
    ASSERT(len == 8);
    ASSERT(memcmp(payload, "payload1", 8) == 0);

    ASSERT(hyrx_engine_acknowledge(e, cid, tag));

    // Stats.
    hyrx_engine_stats_t s = hyrx_engine_stats(e);
    ASSERT(s.messages_published == 1);
    ASSERT(s.messages_delivered == 1);
    ASSERT(s.messages_acknowledged == 1);
    ASSERT(s.active_queues == 1);
    ASSERT(s.active_consumers == 1);

    // Fan-out test.
    hyrx_engine_declare_queue(e, "tasks-copy");
    hyrx_engine_declare_exchange(e, "my-ex2", HYRX_EXCHANGE_TOPIC);
    hyrx_engine_bind_queue(e, "tasks", "my-ex2", "task.#");
    hyrx_engine_bind_queue(e, "tasks-copy", "my-ex2", "task.#");

    hyrx_message_t *msg2 = hyrx_message_create("task.deploy", (uint8_t*)"payload2", 8);
    routed = hyrx_engine_publish(e, msg2, "my-ex2");
    ASSERT(routed == 2);

    hyrx_engine_destroy(e);
    PASS();
}

int main(void) {
    printf("Hyrx WASM — Native Tests\n");
    printf("========================\n\n");

    test_buffer();
    test_pool();
    test_message();
    test_queue();
    test_exchange();
    test_engine();

    printf("\n========================\n");
    printf("Results: %d passed, %d failed\n", tests_passed, tests_failed);
    return tests_failed > 0 ? 1 : 0;
}
