/// Hyrx WASM — Export layer: C functions exported to WebAssembly.
///
/// These functions are the ABI boundary between WASM and JavaScript.
/// Each function uses a global engine instance (single-threaded WASM).

#include "engine.h"
#include "freestanding.h"

// ---- Global engine instance ----

static hyrx_engine_t *g_engine = NULL;

// ---- WASM Exported Functions ----

/// Initialize the engine. Returns 1 on success.
int hyrx_init(uint32_t queue_capacity) {
    if (g_engine) hyrx_engine_destroy(g_engine);
    g_engine = hyrx_engine_create_with_capacity(queue_capacity);
    return g_engine != NULL;
}

/// Shutdown and free the engine.
void hyrx_shutdown(void) {
    if (g_engine) { hyrx_engine_destroy(g_engine); g_engine = NULL; }
}

/// Declare an exchange. type: 0=direct,1=fanout,2=topic,3=headers.
int hyrx_declare_exchange(const char *name, int type) {
    if (!g_engine) return 0;
    return hyrx_engine_declare_exchange(g_engine, name, (hyrx_exchange_type_t)type);
}

/// Declare a queue.
int hyrx_declare_queue(const char *name) {
    if (!g_engine) return 0;
    return hyrx_engine_declare_queue(g_engine, name);
}

/// Bind a queue to an exchange.
int hyrx_bind_queue(const char *queue_name, const char *exchange_name, const char *routing_key) {
    if (!g_engine) return 0;
    return hyrx_engine_bind_queue(g_engine, queue_name, exchange_name, routing_key);
}

/// Unbind a queue from an exchange.
int hyrx_unbind_queue(const char *queue_name, const char *exchange_name, const char *routing_key) {
    if (!g_engine) return 0;
    return hyrx_engine_unbind_queue(g_engine, queue_name, exchange_name, routing_key);
}

/// Delete a queue. Returns message count or -1.
int hyrx_delete_queue(const char *name) {
    if (!g_engine) return -1;
    return hyrx_engine_delete_queue(g_engine, name);
}

/// Delete an exchange. Returns 0 or -1.
int hyrx_delete_exchange(const char *name) {
    if (!g_engine) return -1;
    return hyrx_engine_delete_exchange(g_engine, name);
}

/// Check if a queue exists.
int hyrx_has_queue(const char *name) {
    if (!g_engine) return 0;
    return hyrx_engine_has_queue(g_engine, name);
}

/// Check if an exchange exists.
int hyrx_has_exchange(const char *name) {
    if (!g_engine) return 0;
    return hyrx_engine_has_exchange(g_engine, name);
}

/// Publish a message. Returns routed count.
uint32_t hyrx_publish(const char *routing_key, const uint8_t *payload, uint32_t payload_len, const char *exchange_name) {
    if (!g_engine) return 0;
    hyrx_message_t *msg = hyrx_message_create(routing_key, payload, payload_len);
    if (!msg) return 0;
    uint32_t result = hyrx_engine_publish(g_engine, msg, exchange_name);
    // If publish didn't consume the message (no routes), free it.
    if (result == 0) hyrx_message_destroy(msg);
    return result;
}

/// Publish directly to a queue. Returns 1 on success.
uint32_t hyrx_publish_to_queue(const char *routing_key, const uint8_t *payload, uint32_t payload_len, const char *queue_name) {
    if (!g_engine) return 0;
    hyrx_message_t *msg = hyrx_message_create(routing_key, payload, payload_len);
    if (!msg) return 0;
    uint32_t result = hyrx_engine_publish_to_queue(g_engine, msg, queue_name);
    if (result == 0) hyrx_message_destroy(msg);
    return result;
}

/// Register a consumer. Returns consumer id.
uint64_t hyrx_consume(const char *queue_name) {
    if (!g_engine) return 0;
    return hyrx_engine_consume(g_engine, queue_name);
}

/// Deliver next message. Returns delivery tag, or 0 if none.
uint64_t hyrx_next_message(uint64_t consumer_id) {
    if (!g_engine) return 0;
    return hyrx_engine_next_message(g_engine, consumer_id);
}

/// Read payload. Returns byte count written to out_buf, or 0.
uint32_t hyrx_read_payload(uint64_t consumer_id, uint64_t delivery_tag, uint8_t *out_buf, uint32_t buf_len) {
    if (!g_engine) return 0;
    uint32_t payload_len = 0;
    const uint8_t *data = hyrx_engine_read_payload(g_engine, consumer_id, delivery_tag, &payload_len);
    if (!data || payload_len == 0) return 0;
    uint32_t n = payload_len < buf_len ? payload_len : buf_len;
    memcpy(out_buf, data, n);
    return n;
}

/// Acknowledge a delivery.
int hyrx_acknowledge(uint64_t consumer_id, uint64_t delivery_tag) {
    if (!g_engine) return 0;
    return hyrx_engine_acknowledge(g_engine, consumer_id, delivery_tag);
}

/// Reject a delivery (requeue).
int hyrx_reject(uint64_t consumer_id, uint64_t delivery_tag) {
    if (!g_engine) return 0;
    return hyrx_engine_reject(g_engine, consumer_id, delivery_tag);
}

/// Unregister consumer.
int hyrx_unregister_consumer(uint64_t consumer_id) {
    if (!g_engine) return 0;
    return hyrx_engine_unregister_consumer(g_engine, consumer_id);
}

/// Get stats. Returns 6 fields via pointers.
void hyrx_stats(
    uint64_t *published, uint64_t *delivered,
    uint64_t *acknowledged, uint64_t *rejected,
    uint32_t *queues, uint32_t *consumers
) {
    if (!g_engine) {
        *published = *delivered = *acknowledged = *rejected = 0;
        *queues = *consumers = 0;
        return;
    }
    hyrx_engine_stats_t s = hyrx_engine_stats(g_engine);
    *published = s.messages_published;
    *delivered = s.messages_delivered;
    *acknowledged = s.messages_acknowledged;
    *rejected = s.messages_rejected;
    *queues = s.active_queues;
    *consumers = s.active_consumers;
}

/// Get queue depth.
uint32_t hyrx_get_queue_depth(const char *name) {
    if (!g_engine) return 0;
    int idx = hyrx_engine_find_queue(g_engine, name);
    if (idx < 0) return 0;
    return hyrx_queue_depth(g_engine->queues[idx]);
}

/// List queue names. Writes up to max_names null-terminated strings into out_buf.
/// Returns count written. Each name is separated by '\0', double '\0' = end.
uint32_t hyrx_list_queues(char *out_buf, uint32_t buf_len) {
    if (!g_engine || buf_len == 0) return 0;
    uint32_t pos = 0;
    for (uint32_t i = 0; i < g_engine->queue_count && pos < buf_len - 1; i++) {
        uint32_t nlen = strlen(g_engine->queues[i]->name);
        if (pos + nlen + 1 >= buf_len) break;
        memcpy(out_buf + pos, g_engine->queues[i]->name, nlen);
        pos += nlen;
        out_buf[pos++] = '\0';
    }
    if (pos < buf_len) out_buf[pos] = '\0'; // double-null terminator
    return pos;
}

/// List exchange names.
uint32_t hyrx_list_exchanges(char *out_buf, uint32_t buf_len) {
    if (!g_engine || buf_len == 0) return 0;
    uint32_t pos = 0;
    for (uint32_t i = 0; i < g_engine->exchange_count && pos < buf_len - 1; i++) {
        uint32_t nlen = strlen(g_engine->exchanges[i]->name);
        if (pos + nlen + 1 >= buf_len) break;
        memcpy(out_buf + pos, g_engine->exchanges[i]->name, nlen);
        pos += nlen;
        out_buf[pos++] = '\0';
    }
    if (pos < buf_len) out_buf[pos] = '\0';
    return pos;
}
