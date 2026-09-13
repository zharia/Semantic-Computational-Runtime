/// Hyrx WASM — BufferPool: size-classed allocator for buffer reuse.
///
/// Mirrors src/hyrx/core/buffer_pool.mojo.

#ifndef HYRX_POOL_H
#define HYRX_POOL_H

#include "buffer.h"
#include "freestanding.h"

#define HYRX_POOL_MAX_CLASSES 16

typedef struct {
    uint32_t allocations;
    uint32_t reuses;
    uint32_t capacity;
    uint32_t in_use;
} hyrx_pool_stats_t;

typedef struct {
    uint32_t class_bytes[HYRX_POOL_MAX_CLASSES];
    uint32_t num_classes;
    hyrx_buffer_t *free_list[HYRX_POOL_MAX_CLASSES][256]; // simple freelist
    uint32_t free_count[HYRX_POOL_MAX_CLASSES];
    uint32_t max_pooled;
    uint32_t created;
    uint32_t in_use;
    uint32_t alloc_count;
    uint32_t reuse_count;
    uint32_t pooled_bytes;
} hyrx_pool_t;

/// Create a pool.
static inline hyrx_pool_t *hyrx_pool_create(uint32_t max_class_bytes, uint32_t max_pooled) {
    hyrx_pool_t *pool = (hyrx_pool_t *)calloc(1, sizeof(hyrx_pool_t));
    if (!pool) return NULL;

    pool->max_pooled = max_pooled;
    uint32_t cap = 128; // min class
    uint32_t idx = 0;
    while (cap < max_class_bytes && idx < HYRX_POOL_MAX_CLASSES) {
        pool->class_bytes[idx] = cap;
        pool->free_count[idx] = 0;
        cap *= 2;
        idx++;
    }
    pool->class_bytes[idx] = cap;
    pool->free_count[idx] = 0;
    pool->num_classes = idx + 1;
    return pool;
}

/// Destroy a pool and all its cached buffers.
static inline void hyrx_pool_destroy(hyrx_pool_t *pool) {
    if (!pool) return;
    for (uint32_t c = 0; c < pool->num_classes; c++) {
        for (uint32_t i = 0; i < pool->free_count[c]; i++) {
            hyrx_buffer_destroy(pool->free_list[c][i]);
        }
    }
    free(pool);
}

/// Find the smallest class index with capacity >= min_bytes, or -1.
static inline int hyrx_pool_class_index(const hyrx_pool_t *pool, uint32_t min_bytes) {
    if (min_bytes == 0) return 0;
    for (uint32_t i = 0; i < pool->num_classes; i++) {
        if (pool->class_bytes[i] >= min_bytes) return (int)i;
    }
    return -1;
}

/// Acquire a buffer of at least min_bytes.
static inline hyrx_buffer_t *hyrx_pool_acquire(hyrx_pool_t *pool, uint32_t min_bytes) {
    int idx = hyrx_pool_class_index(pool, min_bytes);
    if (idx >= 0 && pool->free_count[idx] > 0) {
        hyrx_buffer_t *buf = pool->free_list[idx][--pool->free_count[idx]];
        hyrx_buffer_clear(buf);
        buf->pool_class = idx;
        pool->in_use++;
        pool->reuse_count++;
        return buf;
    }
    if (idx >= 0 && pool->created < pool->max_pooled) {
        hyrx_buffer_t *buf = hyrx_buffer_create(pool->class_bytes[idx]);
        if (buf) {
            buf->pool_class = idx;
            pool->created++;
            pool->pooled_bytes += pool->class_bytes[idx];
            pool->in_use++;
            pool->alloc_count++;
            return buf;
        }
    }
    // Oversize or exhausted: direct allocation.
    return hyrx_buffer_create(min_bytes);
}

/// Return a buffer to the pool (only if pooled).
static inline void hyrx_pool_release(hyrx_pool_t *pool, hyrx_buffer_t *buf) {
    if (!pool || !buf) return;
    if (buf->pool_class < 0 || (uint32_t)buf->pool_class >= pool->num_classes) {
        hyrx_buffer_destroy(buf);
        return;
    }
    uint32_t c = (uint32_t)buf->pool_class;
    hyrx_buffer_clear(buf);
    pool->in_use--;
    if (pool->free_count[c] < 256) {
        pool->free_list[c][pool->free_count[c]++] = buf;
    } else {
        hyrx_buffer_destroy(buf);
    }
}

/// Get pool statistics.
static inline hyrx_pool_stats_t hyrx_pool_stats(const hyrx_pool_t *pool) {
    hyrx_pool_stats_t s = {0, 0, 0, 0};
    if (!pool) return s;
    s.allocations = pool->alloc_count;
    s.reuses = pool->reuse_count;
    s.capacity = pool->pooled_bytes;
    s.in_use = pool->in_use;
    return s;
}

#endif // HYRX_POOL_H
