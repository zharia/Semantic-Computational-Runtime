/// Hyrx WASM — Message: envelope + payload.
///
/// Mirrors src/hyrx/core/message.mojo.

#ifndef HYRX_MESSAGE_H
#define HYRX_MESSAGE_H

#include "buffer.h"

#define HYRX_MAX_HEADERS 16
#define HYRX_MAX_ROUTING_KEY 256

typedef struct {
    char key[128];
    char value[256];
} hyrx_header_t;

typedef struct {
    char routing_key[HYRX_MAX_ROUTING_KEY];
    hyrx_buffer_t *payload;
    hyrx_header_t headers[HYRX_MAX_HEADERS];
    uint32_t header_count;
    uint64_t message_id;
    uint32_t delivery_count;
} hyrx_message_t;

/// Create a message with routing key and payload bytes.
static inline hyrx_message_t *hyrx_message_create(
    const char *routing_key,
    const uint8_t *payload_data,
    uint32_t payload_len
) {
    hyrx_message_t *msg = (hyrx_message_t *)calloc(1, sizeof(hyrx_message_t));
    if (!msg) return NULL;

    strncpy(msg->routing_key, routing_key, HYRX_MAX_ROUTING_KEY - 1);
    msg->payload = hyrx_buffer_create(payload_len);
    if (msg->payload && payload_data && payload_len > 0) {
        hyrx_buffer_fill(msg->payload, payload_data, payload_len);
    }
    msg->header_count = 0;
    msg->delivery_count = 0;
    return msg;
}

/// Destroy a message.
static inline void hyrx_message_destroy(hyrx_message_t *msg) {
    if (!msg) return;
    if (msg->payload) hyrx_buffer_destroy(msg->payload);
    free(msg);
}

/// Get routing key.
static inline const char *hyrx_message_routing_key(const hyrx_message_t *msg) {
    return msg ? msg->routing_key : "";
}

/// Get payload bytes.
static inline const uint8_t *hyrx_message_payload(const hyrx_message_t *msg, uint32_t *out_len) {
    if (!msg || !msg->payload) { *out_len = 0; return NULL; }
    *out_len = msg->payload->size;
    return msg->payload->data;
}

/// Get payload size (no copy).
static inline uint32_t hyrx_message_payload_size(const hyrx_message_t *msg) {
    return (msg && msg->payload) ? msg->payload->size : 0;
}

/// Set a header. Returns 0 on success.
static inline int hyrx_message_set_header(hyrx_message_t *msg, const char *key, const char *value) {
    if (!msg || msg->header_count >= HYRX_MAX_HEADERS) return -1;
    hyrx_header_t *h = &msg->headers[msg->header_count++];
    strncpy(h->key, key, sizeof(h->key) - 1);
    strncpy(h->value, value, sizeof(h->value) - 1);
    return 0;
}

/// Get a header value. Returns NULL if not found.
static inline const char *hyrx_message_get_header(const hyrx_message_t *msg, const char *key) {
    if (!msg) return NULL;
    for (uint32_t i = 0; i < msg->header_count; i++) {
        if (strcmp(msg->headers[i].key, key) == 0) {
            return msg->headers[i].value;
        }
    }
    return NULL;
}

#endif // HYRX_MESSAGE_H
