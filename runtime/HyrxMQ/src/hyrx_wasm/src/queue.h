/// Hyrx WASM — Queue: bounded FIFO with delivery tracking.
///
/// Mirrors src/hyrx/core/queue.mojo.
/// Two-stack queue for FIFO ordering (inbox → outbox).

#ifndef HYRX_QUEUE_H
#define HYRX_QUEUE_H

#include "message.h"

#define HYRX_QUEUE_MAX_MESSAGES 65536

typedef struct {
    hyrx_message_t *msg;
    uint64_t delivery_tag;
} hyrx_unacked_entry_t;

typedef struct {
    char name[128];
    uint32_t capacity;

    // Inbox: new messages appended here.
    hyrx_message_t *inbox[HYRX_QUEUE_MAX_MESSAGES];
    uint32_t inbox_count;

    // Outbox: messages dequeued from here (FIFO).
    hyrx_message_t *outbox[HYRX_QUEUE_MAX_MESSAGES];
    uint32_t outbox_count;

    // Unacked: messages awaiting acknowledgement.
    hyrx_unacked_entry_t unacked[HYRX_QUEUE_MAX_MESSAGES];
    uint32_t unacked_count;

    uint64_t next_delivery_tag;
} hyrx_queue_t;

/// Create a queue.
static inline hyrx_queue_t *hyrx_queue_create(const char *name, uint32_t capacity) {
    hyrx_queue_t *q = (hyrx_queue_t *)calloc(1, sizeof(hyrx_queue_t));
    if (!q) return NULL;
    strncpy(q->name, name, sizeof(q->name) - 1);
    q->capacity = capacity > 0 ? capacity : 1024;
    return q;
}

/// Destroy a queue and all its messages.
static inline void hyrx_queue_destroy(hyrx_queue_t *q) {
    if (!q) return;
    for (uint32_t i = 0; i < q->inbox_count; i++) hyrx_message_destroy(q->inbox[i]);
    for (uint32_t i = 0; i < q->outbox_count; i++) hyrx_message_destroy(q->outbox[i]);
    for (uint32_t i = 0; i < q->unacked_count; i++) hyrx_message_destroy(q->unacked[i].msg);
    free(q);
}

static inline uint32_t hyrx_queue_total(const hyrx_queue_t *q) {
    return q->inbox_count + q->outbox_count + q->unacked_count;
}

/// Reverse inbox into outbox (FIFO transfer).
static inline void hyrx_queue_transfer(hyrx_queue_t *q) {
    while (q->inbox_count > 0) {
        q->outbox[q->outbox_count++] = q->inbox[--q->inbox_count];
    }
}

/// Enqueue a message. Returns 1 on success, 0 if full.
static inline int hyrx_queue_enqueue(hyrx_queue_t *q, hyrx_message_t *msg) {
    if (!q || !msg) return 0;
    if (hyrx_queue_total(q) >= q->capacity) return 0;
    q->inbox[q->inbox_count++] = msg;
    return 1;
}

/// Dequeue next message (move to unacked). Returns delivery tag, or 0 if empty.
static inline uint64_t hyrx_queue_dequeue(hyrx_queue_t *q) {
    if (!q) return 0;
    if (q->outbox_count == 0) hyrx_queue_transfer(q);
    if (q->outbox_count == 0) return 0;

    hyrx_message_t *msg = q->outbox[--q->outbox_count];
    msg->delivery_count++;
    uint64_t tag = q->next_delivery_tag++;

    q->unacked[q->unacked_count].msg = msg;
    q->unacked[q->unacked_count].delivery_tag = tag;
    q->unacked_count++;

    return tag;
}

/// Find unacked index by delivery tag. Returns -1 if not found.
static inline int hyrx_queue_find_unacked(const hyrx_queue_t *q, uint64_t tag) {
    for (uint32_t i = 0; i < q->unacked_count; i++) {
        if (q->unacked[i].delivery_tag == tag) return (int)i;
    }
    return -1;
}

/// Read payload of an unacked message.
static inline const uint8_t *hyrx_queue_read_payload(
    const hyrx_queue_t *q, uint64_t delivery_tag, uint32_t *out_len
) {
    int idx = hyrx_queue_find_unacked(q, delivery_tag);
    if (idx < 0) { *out_len = 0; return NULL; }
    return hyrx_message_payload(q->unacked[idx].msg, out_len);
}

/// Acknowledge a delivery. Returns 1 if found.
static inline int hyrx_queue_acknowledge(hyrx_queue_t *q, uint64_t delivery_tag) {
    int idx = hyrx_queue_find_unacked(q, delivery_tag);
    if (idx < 0) return 0;
    hyrx_message_destroy(q->unacked[idx].msg);
    // Shift remaining entries.
    for (uint32_t i = (uint32_t)idx; i < q->unacked_count - 1; i++) {
        q->unacked[i] = q->unacked[i + 1];
    }
    q->unacked_count--;
    return 1;
}

/// Reject a delivery (requeue). Returns 1 if found.
static inline int hyrx_queue_reject(hyrx_queue_t *q, uint64_t delivery_tag) {
    int idx = hyrx_queue_find_unacked(q, delivery_tag);
    if (idx < 0) return 0;
    hyrx_message_t *msg = q->unacked[idx].msg;
    // Shift unacked.
    for (uint32_t i = (uint32_t)idx; i < q->unacked_count - 1; i++) {
        q->unacked[i] = q->unacked[i + 1];
    }
    q->unacked_count--;
    // Requeue to inbox.
    q->inbox[q->inbox_count++] = msg;
    return 1;
}

/// Ready depth (inbox + outbox).
static inline uint32_t hyrx_queue_depth(const hyrx_queue_t *q) {
    return q->inbox_count + q->outbox_count;
}

#endif // HYRX_QUEUE_H
