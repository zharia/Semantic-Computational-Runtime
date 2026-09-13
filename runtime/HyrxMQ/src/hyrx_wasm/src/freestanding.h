/// Hyrx WASM — Freestanding runtime support.
///
/// Minimal C runtime for WASM: no libc needed.
/// Provides malloc/free via WASM memory, and basic string operations.

#ifndef HYRX_RUNTIME_H
#define HYRX_RUNTIME_H

#ifdef __wasm__

// ---- Freestanding types ----
typedef unsigned long size_t;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long long uint64_t;
typedef signed char int8_t;
typedef short int16_t;
typedef int int32_t;
typedef long long int64_t;
#define NULL ((void*)0)

// ---- WASM memory management ----
// WASM linear memory is managed by the runtime. We use a simple bump allocator
// for the static binary, and the JS host provides malloc/free for dynamic use.

extern uint8_t __heap_base;
static uint8_t *_heap_ptr = &__heap_base;

static inline void *malloc(size_t size) {
    // Align to 8 bytes.
    size = (size + 7) & ~7;
    void *ptr = _heap_ptr;
    _heap_ptr += size;
    return ptr;
}

static inline void *calloc(size_t nmemb, size_t size) {
    size_t total = nmemb * size;
    void *ptr = malloc(total);
    if (ptr) {
        uint8_t *p = (uint8_t *)ptr;
        for (size_t i = 0; i < total; i++) p[i] = 0;
    }
    return ptr;
}

static inline void free(void *ptr) {
    // No-op in bump allocator. WASM memory only grows.
    (void)ptr;
}

// ---- String operations ----
static inline size_t strlen(const char *s) {
    size_t n = 0;
    while (*s++) n++;
    return n;
}

static inline int strcmp(const char *a, const char *b) {
    while (*a && *a == *b) { a++; b++; }
    return (unsigned char)*a - (unsigned char)*b;
}

static inline char *strncpy(char *dst, const char *src, size_t n) {
    size_t i;
    for (i = 0; i < n && src[i]; i++) dst[i] = src[i];
    for (; i < n; i++) dst[i] = 0;
    return dst;
}

static inline void *memcpy(void *dst, const void *src, size_t n) {
    uint8_t *d = (uint8_t *)dst;
    const uint8_t *s = (const uint8_t *)src;
    for (size_t i = 0; i < n; i++) d[i] = s[i];
    return dst;
}

static inline void *memset(void *s, int c, size_t n) {
    uint8_t *p = (uint8_t *)s;
    for (size_t i = 0; i < n; i++) p[i] = (uint8_t)c;
    return s;
}

// strtok: simplified single-threaded version.
static char *_strtok_last = NULL;
static inline char *strtok(char *str, const char *delim) {
    char *start = str ? str : _strtok_last;
    if (!start) return NULL;
    // Skip leading delimiters.
    while (*start) {
        const char *d = delim;
        int is_delim = 0;
        while (*d) { if (*start == *d) { is_delim = 1; break; } d++; }
        if (!is_delim) break;
        start++;
    }
    if (!*start) { _strtok_last = NULL; return NULL; }
    char *token = start;
    while (*start) {
        const char *d = delim;
        while (*d) {
            if (*start == *d) {
                *start = 0;
                _strtok_last = start + 1;
                return token;
            }
            d++;
        }
        start++;
    }
    _strtok_last = NULL;
    return token;
}

#else
// Native build: use system libc.
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#endif

#endif // HYRX_RUNTIME_H
