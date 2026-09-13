/// Hyrx WASM — Buffer: contiguous byte region.
///
/// Mirrors src/hyrx/core/buffer.mojo.
/// Ownership: caller allocates/frees via hyrx_buffer_create/destroy.

#ifndef HYRX_BUFFER_H
#define HYRX_BUFFER_H

#include "freestanding.h"

typedef struct {
    uint8_t *data;
    uint32_t size;
    uint32_t capacity;
    int pool_class;  // -1 = not pooled
} hyrx_buffer_t;

/// Create a buffer with given capacity.
static inline hyrx_buffer_t *hyrx_buffer_create(uint32_t capacity) {
    hyrx_buffer_t *buf = (hyrx_buffer_t *)malloc(sizeof(hyrx_buffer_t));
    if (!buf) return NULL;
    buf->data = (uint8_t *)calloc(capacity, 1);
    if (!buf->data) { free(buf); return NULL; }
    buf->size = 0;
    buf->capacity = capacity;
    buf->pool_class = -1;
    return buf;
}

/// Destroy a buffer and free its memory.
static inline void hyrx_buffer_destroy(hyrx_buffer_t *buf) {
    if (!buf) return;
    free(buf->data);
    free(buf);
}

/// Current logical size.
static inline uint32_t hyrx_buffer_size(const hyrx_buffer_t *buf) {
    return buf ? buf->size : 0;
}

/// Total allocated capacity.
static inline uint32_t hyrx_buffer_capacity(const hyrx_buffer_t *buf) {
    return buf ? buf->capacity : 0;
}

/// Read a byte by index.
static inline uint8_t hyrx_buffer_get(const hyrx_buffer_t *buf, uint32_t index) {
    if (!buf || index >= buf->size) return 0;
    return buf->data[index];
}

/// Write a byte by index.
static inline void hyrx_buffer_set(hyrx_buffer_t *buf, uint32_t index, uint8_t value) {
    if (!buf || index >= buf->size) return;
    buf->data[index] = value;
}

/// Append one byte. Grows size by 1 (must be within capacity).
static inline int hyrx_buffer_append(hyrx_buffer_t *buf, uint8_t value) {
    if (!buf || buf->size >= buf->capacity) return 0;
    buf->data[buf->size++] = value;
    return 1;
}

/// Reset logical length to 0.
static inline void hyrx_buffer_clear(hyrx_buffer_t *buf) {
    if (buf) buf->size = 0;
}

/// Copy contents into a newly allocated byte array. Caller frees.
/// *out_len receives the byte count.
static inline uint8_t *hyrx_buffer_to_bytes(const hyrx_buffer_t *buf, uint32_t *out_len) {
    if (!buf || buf->size == 0) { *out_len = 0; return NULL; }
    uint8_t *copy = (uint8_t *)malloc(buf->size);
    if (!copy) { *out_len = 0; return NULL; }
    memcpy(copy, buf->data, buf->size);
    *out_len = buf->size;
    return copy;
}

/// Fill buffer from a byte array. Returns bytes written.
static inline uint32_t hyrx_buffer_fill(hyrx_buffer_t *buf, const uint8_t *src, uint32_t len) {
    if (!buf || !src) return 0;
    uint32_t n = len;
    if (n > buf->capacity - buf->size) n = buf->capacity - buf->size;
    memcpy(buf->data + buf->size, src, n);
    buf->size += n;
    return n;
}

#endif // HYRX_BUFFER_H
