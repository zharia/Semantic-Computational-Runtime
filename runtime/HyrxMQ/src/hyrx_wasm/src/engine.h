/// Hyrx WASM — Engine: top-level broker combining queues + exchanges + consumers.
///
/// Mirrors src/hyrx/embedded/api.mojo (HyrxEngine).

#ifndef HYRX_ENGINE_H
#define HYRX_ENGINE_H

#include "queue.h"
#include "exchange.h"
#include "pool.h"
#include "freestanding.h"

#define HYRX_ENGINE_MAX_QUEUES 256
#define HYRX_ENGINE_MAX_EXCHANGES 256
#define HYRX_ENGINE_MAX_CONSUMERS 1024
#define HYRX_ENGINE_MAX_NAME 128

typedef struct {
    uint64_t id;
    char queue_name[128];
    uint32_t prefetch;
    uint32_t outstanding;
} hyrx_consumer_t;

typedef struct {
    uint64_t messages_published;
    uint64_t messages_delivered;
    uint64_t messages_acknowledged;
    uint64_t messages_rejected;
    uint32_t active_queues;
    uint32_t active_consumers;
} hyrx_engine_stats_t;

typedef struct {
    hyrx_queue_t *queues[HYRX_ENGINE_MAX_QUEUES];
    uint32_t queue_count;

    hyrx_exchange_t *exchanges[HYRX_ENGINE_MAX_EXCHANGES];
    uint32_t exchange_count;

    hyrx_consumer_t consumers[HYRX_ENGINE_MAX_CONSUMERS];
    uint32_t consumer_count;
    uint64_t next_consumer_id;

    hyrx_pool_t *pool;

    uint64_t messages_published;
    uint64_t messages_delivered;
    uint64_t messages_acknowledged;
    uint64_t messages_rejected;

    uint32_t default_queue_capacity;
} hyrx_engine_t;

// ---- Lookup helpers (declared first, defined after struct) ----

static inline int hyrx_engine_find_exchange(const hyrx_engine_t *e, const char *name) {
    for (uint32_t i = 0; i < e->exchange_count; i++) {
        if (strcmp(e->exchanges[i]->name, name) == 0) return (int)i;
    }
    return -1;
}

static inline int hyrx_engine_find_queue(const hyrx_engine_t *e, const char *name) {
    for (uint32_t i = 0; i < e->queue_count; i++) {
        if (strcmp(e->queues[i]->name, name) == 0) return (int)i;
    }
    return -1;
}

static inline int hyrx_engine_find_consumer(const hyrx_engine_t *e, uint64_t consumer_id) {
    for (uint32_t i = 0; i < e->consumer_count; i++) {
        if (e->consumers[i].id == consumer_id) return (int)i;
    }
    return -1;
}

// ---- Topology ----

static inline int hyrx_engine_declare_exchange(hyrx_engine_t *e, const char *name, hyrx_exchange_type_t type) {
    if (!e || e->exchange_count >= HYRX_ENGINE_MAX_EXCHANGES) return 0;
    if (hyrx_engine_find_exchange(e, name) >= 0) return 0;
    e->exchanges[e->exchange_count++] = hyrx_exchange_create(name, type);
    return 1;
}

static inline int hyrx_engine_declare_queue(hyrx_engine_t *e, const char *name) {
    if (!e || e->queue_count >= HYRX_ENGINE_MAX_QUEUES) return 0;
    if (hyrx_engine_find_queue(e, name) >= 0) return 0;
    e->queues[e->queue_count++] = hyrx_queue_create(name, e->default_queue_capacity);
    return 1;
}

static inline int hyrx_engine_bind_queue(hyrx_engine_t *e, const char *queue_name, const char *exchange_name, const char *routing_key) {
    int ex_idx = hyrx_engine_find_exchange(e, exchange_name);
    if (ex_idx < 0) return 0;
    return hyrx_exchange_add_binding(e->exchanges[ex_idx], queue_name, routing_key);
}

static inline int hyrx_engine_unbind_queue(hyrx_engine_t *e, const char *queue_name, const char *exchange_name, const char *routing_key) {
    int ex_idx = hyrx_engine_find_exchange(e, exchange_name);
    if (ex_idx < 0) return 0;
    return hyrx_exchange_remove_binding(e->exchanges[ex_idx], queue_name, routing_key);
}

static inline int hyrx_engine_delete_queue(hyrx_engine_t *e, const char *name) {
    int idx = hyrx_engine_find_queue(e, name);
    if (idx < 0) return -1;
    uint32_t total = hyrx_queue_total(e->queues[idx]);
    hyrx_queue_destroy(e->queues[idx]);
    for (uint32_t i = (uint32_t)idx; i < e->queue_count - 1; i++) {
        e->queues[i] = e->queues[i + 1];
    }
    e->queue_count--;
    return (int)total;
}

static inline int hyrx_engine_delete_exchange(hyrx_engine_t *e, const char *name) {
    int idx = hyrx_engine_find_exchange(e, name);
    if (idx < 0) return -1;
    hyrx_exchange_destroy(e->exchanges[idx]);
    for (uint32_t i = (uint32_t)idx; i < e->exchange_count - 1; i++) {
        e->exchanges[i] = e->exchanges[i + 1];
    }
    e->exchange_count--;
    return 0;
}

static inline int hyrx_engine_has_queue(const hyrx_engine_t *e, const char *name) {
    return hyrx_engine_find_queue(e, name) >= 0;
}

static inline int hyrx_engine_has_exchange(const hyrx_engine_t *e, const char *name) {
    return hyrx_engine_find_exchange(e, name) >= 0;
}

// ---- Lifecycle ----

static inline hyrx_engine_t *hyrx_engine_create_with_capacity(uint32_t queue_capacity) {
    hyrx_engine_t *e = (hyrx_engine_t *)calloc(1, sizeof(hyrx_engine_t));
    if (!e) return NULL;
    e->default_queue_capacity = queue_capacity;
    e->next_consumer_id = 1;
    e->pool = hyrx_pool_create(4096, 64);

    hyrx_engine_declare_exchange(e, "", HYRX_EXCHANGE_DIRECT);
    hyrx_engine_declare_exchange(e, "amq.direct", HYRX_EXCHANGE_DIRECT);
    hyrx_engine_declare_exchange(e, "amq.fanout", HYRX_EXCHANGE_FANOUT);
    hyrx_engine_declare_exchange(e, "amq.topic", HYRX_EXCHANGE_TOPIC);
    hyrx_engine_declare_exchange(e, "amq.headers", HYRX_EXCHANGE_HEADERS);

    return e;
}

static inline hyrx_engine_t *hyrx_engine_create(void) {
    return hyrx_engine_create_with_capacity(1024);
}

static inline void hyrx_engine_destroy(hyrx_engine_t *e) {
    if (!e) return;
    for (uint32_t i = 0; i < e->queue_count; i++) hyrx_queue_destroy(e->queues[i]);
    for (uint32_t i = 0; i < e->exchange_count; i++) hyrx_exchange_destroy(e->exchanges[i]);
    if (e->pool) hyrx_pool_destroy(e->pool);
    free(e);
}

// ---- Messaging ----

static inline uint32_t hyrx_engine_publish(hyrx_engine_t *e, hyrx_message_t *msg, const char *exchange_name) {
    if (!e || !msg) return 0;
    int ex_idx = hyrx_engine_find_exchange(e, exchange_name);
    if (ex_idx < 0) return 0;

    char matched[HYRX_EXCHANGE_MAX_RESULTS][128];
    uint32_t matched_count = hyrx_exchange_match(e->exchanges[ex_idx], msg->routing_key, matched, HYRX_EXCHANGE_MAX_RESULTS);

    uint32_t routed = 0;
    for (uint32_t i = 0; i < matched_count; i++) {
        int q_idx = hyrx_engine_find_queue(e, matched[i]);
        if (q_idx >= 0) {
            hyrx_message_t *to_send = msg;
            if (i < matched_count - 1) {
                uint32_t plen = msg->payload ? msg->payload->size : 0;
                to_send = hyrx_message_create(msg->routing_key, msg->payload ? msg->payload->data : NULL, plen);
            }
            if (hyrx_queue_enqueue(e->queues[q_idx], to_send)) {
                routed++;
            } else if (to_send != msg) {
                hyrx_message_destroy(to_send);
            }
        }
    }
    if (routed > 0) e->messages_published++;
    return routed;
}

static inline uint32_t hyrx_engine_publish_to_queue(hyrx_engine_t *e, hyrx_message_t *msg, const char *queue_name) {
    if (!e || !msg) return 0;
    int q_idx = hyrx_engine_find_queue(e, queue_name);
    if (q_idx < 0) return 0;
    if (hyrx_queue_enqueue(e->queues[q_idx], msg)) {
        e->messages_published++;
        return 1;
    }
    return 0;
}

static inline uint64_t hyrx_engine_consume(hyrx_engine_t *e, const char *queue_name) {
    if (!e || e->consumer_count >= HYRX_ENGINE_MAX_CONSUMERS) return 0;
    if (hyrx_engine_find_queue(e, queue_name) < 0) return 0;

    hyrx_consumer_t *c = &e->consumers[e->consumer_count++];
    c->id = e->next_consumer_id++;
    strncpy(c->queue_name, queue_name, sizeof(c->queue_name) - 1);
    c->prefetch = 256;
    c->outstanding = 0;
    return c->id;
}

static inline uint64_t hyrx_engine_next_message(hyrx_engine_t *e, uint64_t consumer_id) {
    int c_idx = hyrx_engine_find_consumer(e, consumer_id);
    if (c_idx < 0) return 0;
    int q_idx = hyrx_engine_find_queue(e, e->consumers[c_idx].queue_name);
    if (q_idx < 0) return 0;

    uint64_t tag = hyrx_queue_dequeue(e->queues[q_idx]);
    // Tag 0 is valid (first delivery). Check unacked count to confirm success.
    if (e->queues[q_idx]->unacked_count > 0 && e->queues[q_idx]->unacked[e->queues[q_idx]->unacked_count - 1].delivery_tag == tag) {
        e->messages_delivered++;
        e->consumers[c_idx].outstanding++;
    }
    return tag;
}

static inline const uint8_t *hyrx_engine_read_payload(
    const hyrx_engine_t *e, uint64_t consumer_id, uint64_t delivery_tag, uint32_t *out_len
) {
    int c_idx = hyrx_engine_find_consumer(e, consumer_id);
    if (c_idx < 0) { *out_len = 0; return NULL; }
    int q_idx = hyrx_engine_find_queue(e, e->consumers[c_idx].queue_name);
    if (q_idx < 0) { *out_len = 0; return NULL; }
    return hyrx_queue_read_payload(e->queues[q_idx], delivery_tag, out_len);
}

static inline int hyrx_engine_acknowledge(hyrx_engine_t *e, uint64_t consumer_id, uint64_t delivery_tag) {
    int c_idx = hyrx_engine_find_consumer(e, consumer_id);
    if (c_idx < 0) return 0;
    int q_idx = hyrx_engine_find_queue(e, e->consumers[c_idx].queue_name);
    if (q_idx < 0) return 0;
    int result = hyrx_queue_acknowledge(e->queues[q_idx], delivery_tag);
    if (result) {
        e->messages_acknowledged++;
        if (e->consumers[c_idx].outstanding > 0) e->consumers[c_idx].outstanding--;
    }
    return result;
}

static inline int hyrx_engine_reject(hyrx_engine_t *e, uint64_t consumer_id, uint64_t delivery_tag) {
    int c_idx = hyrx_engine_find_consumer(e, consumer_id);
    if (c_idx < 0) return 0;
    int q_idx = hyrx_engine_find_queue(e, e->consumers[c_idx].queue_name);
    if (q_idx < 0) return 0;
    int result = hyrx_queue_reject(e->queues[q_idx], delivery_tag);
    if (result) {
        e->messages_rejected++;
        if (e->consumers[c_idx].outstanding > 0) e->consumers[c_idx].outstanding--;
    }
    return result;
}

static inline int hyrx_engine_unregister_consumer(hyrx_engine_t *e, uint64_t consumer_id) {
    int c_idx = hyrx_engine_find_consumer(e, consumer_id);
    if (c_idx < 0) return 0;
    for (uint32_t i = (uint32_t)c_idx; i < e->consumer_count - 1; i++) {
        e->consumers[i] = e->consumers[i + 1];
    }
    e->consumer_count--;
    return 1;
}

static inline hyrx_engine_stats_t hyrx_engine_stats(const hyrx_engine_t *e) {
    hyrx_engine_stats_t s = {0};
    if (!e) return s;
    s.messages_published = e->messages_published;
    s.messages_delivered = e->messages_delivered;
    s.messages_acknowledged = e->messages_acknowledged;
    s.messages_rejected = e->messages_rejected;
    s.active_queues = e->queue_count;
    s.active_consumers = e->consumer_count;
    return s;
}

#endif // HYRX_ENGINE_H
