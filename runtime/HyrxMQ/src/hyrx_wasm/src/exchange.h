/// Hyrx WASM — Exchange: message router with binding matching.
///
/// Mirrors src/hyrx/core/exchange.mojo.
/// Supports direct, fanout, topic (*, #), and headers exchange types.

#ifndef HYRX_EXCHANGE_H
#define HYRX_EXCHANGE_H

#include "freestanding.h"

#define HYRX_EXCHANGE_MAX_BINDINGS 1024
#define HYRX_EXCHANGE_MAX_NAME 128
#define HYRX_EXCHANGE_MAX_RESULTS 64

typedef enum {
    HYRX_EXCHANGE_DIRECT = 0,
    HYRX_EXCHANGE_FANOUT = 1,
    HYRX_EXCHANGE_TOPIC  = 2,
    HYRX_EXCHANGE_HEADERS = 3,
} hyrx_exchange_type_t;

typedef struct {
    char queue_name[128];
    char routing_key[128];
} hyrx_binding_t;

typedef struct {
    char name[HYRX_EXCHANGE_MAX_NAME];
    hyrx_exchange_type_t type;
    hyrx_binding_t bindings[HYRX_EXCHANGE_MAX_BINDINGS];
    uint32_t binding_count;
} hyrx_exchange_t;

/// Create an exchange.
static inline hyrx_exchange_t *hyrx_exchange_create(const char *name, hyrx_exchange_type_t type) {
    hyrx_exchange_t *ex = (hyrx_exchange_t *)calloc(1, sizeof(hyrx_exchange_t));
    if (!ex) return NULL;
    strncpy(ex->name, name, HYRX_EXCHANGE_MAX_NAME - 1);
    ex->type = type;
    return ex;
}

/// Destroy an exchange.
static inline void hyrx_exchange_destroy(hyrx_exchange_t *ex) {
    free(ex);
}

/// Add a binding. Returns 1 if added, 0 if duplicate.
static inline int hyrx_exchange_add_binding(hyrx_exchange_t *ex, const char *queue_name, const char *routing_key) {
    if (!ex || ex->binding_count >= HYRX_EXCHANGE_MAX_BINDINGS) return 0;
    // Check for duplicate.
    for (uint32_t i = 0; i < ex->binding_count; i++) {
        if (strcmp(ex->bindings[i].queue_name, queue_name) == 0 &&
            strcmp(ex->bindings[i].routing_key, routing_key) == 0) {
            return 0;
        }
    }
    hyrx_binding_t *b = &ex->bindings[ex->binding_count++];
    strncpy(b->queue_name, queue_name, sizeof(b->queue_name) - 1);
    strncpy(b->routing_key, routing_key, sizeof(b->routing_key) - 1);
    return 1;
}

/// Remove a binding. Returns 1 if found and removed.
static inline int hyrx_exchange_remove_binding(hyrx_exchange_t *ex, const char *queue_name, const char *routing_key) {
    if (!ex) return 0;
    for (uint32_t i = 0; i < ex->binding_count; i++) {
        if (strcmp(ex->bindings[i].queue_name, queue_name) == 0 &&
            strcmp(ex->bindings[i].routing_key, routing_key) == 0) {
            for (uint32_t j = i; j < ex->binding_count - 1; j++) {
                ex->bindings[j] = ex->bindings[j + 1];
            }
            ex->binding_count--;
            return 1;
        }
    }
    return 0;
}

/// Check if a name is already in the result set.
static inline int hyrx_already_present(char results[][128], uint32_t count, const char *name) {
    for (uint32_t i = 0; i < count; i++) {
        if (strcmp(results[i], name) == 0) return 1;
    }
    return 0;
}

/// Match words for topic pattern (* = one word, # = zero or more).
static inline int hyrx_topic_match_words(
    const char *key_parts[], uint32_t key_len, uint32_t ki,
    const char *pat_parts[], uint32_t pat_len, uint32_t pi
) {
    if (pi == pat_len) return ki == key_len;
    const char *word = pat_parts[pi];
    if (strcmp(word, "#") == 0) {
        for (uint32_t n = ki; n <= key_len; n++) {
            if (hyrx_topic_match_words(key_parts, key_len, n, pat_parts, pat_len, pi + 1))
                return 1;
        }
        return 0;
    }
    if (ki == key_len) return 0;
    if (strcmp(word, "*") == 0) {
        return hyrx_topic_match_words(key_parts, key_len, ki + 1, pat_parts, pat_len, pi + 1);
    }
    if (strcmp(word, key_parts[ki]) != 0) return 0;
    return hyrx_topic_match_words(key_parts, key_len, ki + 1, pat_parts, pat_len, pi + 1);
}

/// Split routing key by "." and match against pattern.
static inline int hyrx_topic_match(const char *routing_key, const char *pattern) {
    // Simple split: max 32 parts.
    const char *key_parts[32];
    uint32_t key_len = 0;
    char key_buf[512];
    strncpy(key_buf, routing_key, sizeof(key_buf) - 1);
    char *tok = strtok(key_buf, ".");
    while (tok && key_len < 32) { key_parts[key_len++] = tok; tok = strtok(NULL, "."); }

    const char *pat_parts[32];
    uint32_t pat_len = 0;
    char pat_buf[512];
    strncpy(pat_buf, pattern, sizeof(pat_buf) - 1);
    tok = strtok(pat_buf, ".");
    while (tok && pat_len < 32) { pat_parts[pat_len++] = tok; tok = strtok(NULL, "."); }

    return hyrx_topic_match_words(key_parts, key_len, 0, pat_parts, pat_len, 0);
}

/// Match routing key to bound queues. Returns count of matched queues.
/// results[] receives pointers into exchange's binding names (valid until exchange modified).
static inline uint32_t hyrx_exchange_match(
    const hyrx_exchange_t *ex,
    const char *routing_key,
    char results[][128],
    uint32_t max_results
) {
    uint32_t count = 0;
    if (!ex || count >= max_results) return 0;

    switch (ex->type) {
        case HYRX_EXCHANGE_DIRECT:
            for (uint32_t i = 0; i < ex->binding_count && count < max_results; i++) {
                if (strcmp(ex->bindings[i].routing_key, routing_key) == 0) {
                    if (!hyrx_already_present(results, count, ex->bindings[i].queue_name)) {
                        strncpy(results[count++], ex->bindings[i].queue_name, 127);
                    }
                }
            }
            break;

        case HYRX_EXCHANGE_FANOUT:
            for (uint32_t i = 0; i < ex->binding_count && count < max_results; i++) {
                if (!hyrx_already_present(results, count, ex->bindings[i].queue_name)) {
                    strncpy(results[count++], ex->bindings[i].queue_name, 127);
                }
            }
            break;

        case HYRX_EXCHANGE_TOPIC:
            for (uint32_t i = 0; i < ex->binding_count && count < max_results; i++) {
                if (hyrx_topic_match(routing_key, ex->bindings[i].routing_key)) {
                    if (!hyrx_already_present(results, count, ex->bindings[i].queue_name)) {
                        strncpy(results[count++], ex->bindings[i].queue_name, 127);
                    }
                }
            }
            break;

        case HYRX_EXCHANGE_HEADERS:
            // Headers matching needs message headers — simplified: return all bindings.
            for (uint32_t i = 0; i < ex->binding_count && count < max_results; i++) {
                if (!hyrx_already_present(results, count, ex->bindings[i].queue_name)) {
                    strncpy(results[count++], ex->bindings[i].queue_name, 127);
                }
            }
            break;
    }
    return count;
}

#endif // HYRX_EXCHANGE_H
