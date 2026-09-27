/* scr_sim_loader.h — header-only dlopen loader + startup version gate for the
 * SCR simulation C ABI.
 *
 * Normative source: providers/render/graphics/godot/104_contract.md §3, §7.
 * C ABI declarations: scr_godot_abi.h (same directory) — never redefined here.
 *
 * Shared by BOTH:
 *   - adapter/scr_godot_adapter.cpp  (production GDExtension adapter)
 *   - tests/schema_mismatch_test.c   (negative test: schema mismatch refusal)
 * so the negative test exercises the exact load policy the adapter runs.
 *
 * Load policy (all failures are loud — never silently coerced):
 *   1. path must dlopen               -> SCR_LOAD_ERR_DLOPEN
 *   2. all 7 contract symbols resolve -> SCR_LOAD_ERR_SYMBOL
 *   3. scr_sim_abi_version()   == SCR_SIM_ABI_VERSION  (1)
 *                                           -> SCR_LOAD_ERR_ABI
 *   4. scr_sim_schema_version()== SCR_SIM_SCHEMA_VER  (1)
 *                                           -> SCR_LOAD_ERR_SCHEMA
 * On any failure the API struct is zeroed (handle closed) and `err` carries a
 * human-readable message for ERR_PRINT.
 *
 * This file is C11-compatible (used by the C negative test) and C++-safe.
 *
 * NOTE: path resolution (which file to load) is NOT done here — the adapter
 * resolves `res://` paths (see scr_godot_adapter.cpp header comment); tests
 * pass an explicit path.
 */
#ifndef SCR_SIM_LOADER_H
#define SCR_SIM_LOADER_H

#include <dlfcn.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "scr_godot_abi.h"

#if defined(__GNUC__) || defined(__clang__)
#define SCR_SIM_UNUSED __attribute__((unused))
#else
#define SCR_SIM_UNUSED
#endif

/* Load result codes (loader-local; contract SCR_ERR_* codes are untouched). */
#define SCR_LOAD_OK         0
#define SCR_LOAD_ERR_DLOPEN (-100)
#define SCR_LOAD_ERR_SYMBOL (-101)
#define SCR_LOAD_ERR_ABI    (-102)
#define SCR_LOAD_ERR_SCHEMA (-103)

/* Resolved contract function table. Signatures mirror scr_godot_abi.h. */
typedef struct scr_sim_api {
    void *handle;
    int32_t (*init)(uint32_t seed);
    void (*shutdown)(void);
    uint32_t (*abi_version)(void);
    uint32_t (*schema_version)(void);
    int32_t (*step)(double frame_dt, const scr_input_batch *in);
    uint32_t (*snapshot_size)(void);
    int32_t (*snapshot_write)(uint8_t *buf, uint32_t cap);
} scr_sim_api;

static SCR_SIM_UNUSED void scr_sim_set_err(char *err, size_t err_len,
                                            const char *fmt, ...);

/* Load `path`, bind all 7 contract symbols, enforce abi/schema versions.
 * Returns SCR_LOAD_OK or SCR_LOAD_ERR_*. */
static SCR_SIM_UNUSED int scr_sim_load(scr_sim_api *api, const char *path,
                                char *err, size_t err_len) {
    void *handle;
    uint32_t abi;
    uint32_t schema;

    if (err != NULL && err_len > 0) {
        err[0] = '\0';
    }
    if (api == NULL || path == NULL || path[0] == '\0') {
        scr_sim_set_err(err, err_len, "loader: invalid arguments");
        return SCR_LOAD_ERR_DLOPEN;
    }
    memset(api, 0, sizeof(*api));

    handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) {
        const char *de = dlerror();
        scr_sim_set_err(err, err_len, "dlopen(%s) failed: %s", path,
                        de ? de : "unknown error");
        return SCR_LOAD_ERR_DLOPEN;
    }

    /* POSIX guarantees dlsym results can be converted to function pointers;
     * memcpy avoids strict-aliasing casts. */
#define SCR_SIM_BIND(field, symbol)                                       \
    do {                                                                  \
        void *sym_;                                                       \
        (void)dlerror();                                                  \
        sym_ = dlsym(handle, (symbol));                                   \
        if (sym_ == NULL || dlerror() != NULL) {                          \
            scr_sim_set_err(err, err_len, "missing symbol %s", (symbol)); \
            dlclose(handle);                                              \
            memset(api, 0, sizeof(*api));                                 \
            return SCR_LOAD_ERR_SYMBOL;                                  \
        }                                                                 \
        memcpy(&(api->field), &sym_, sizeof(sym_));                       \
    } while (0)

    SCR_SIM_BIND(init, "scr_sim_init");
    SCR_SIM_BIND(shutdown, "scr_sim_shutdown");
    SCR_SIM_BIND(abi_version, "scr_sim_abi_version");
    SCR_SIM_BIND(schema_version, "scr_sim_schema_version");
    SCR_SIM_BIND(step, "scr_sim_step");
    SCR_SIM_BIND(snapshot_size, "scr_sim_snapshot_size");
    SCR_SIM_BIND(snapshot_write, "scr_sim_snapshot_write");

#undef SCR_SIM_BIND

    api->handle = handle;

    abi = api->abi_version();
    if (abi != SCR_SIM_ABI_VERSION) {
        scr_sim_set_err(err, err_len,
                        "ABI mismatch: library %u, adapter %u (refusing to run)",
                        (unsigned)abi, (unsigned)SCR_SIM_ABI_VERSION);
        dlclose(handle);
        memset(api, 0, sizeof(*api));
        return SCR_LOAD_ERR_ABI;
    }

    schema = api->schema_version();
    if (schema != SCR_SIM_SCHEMA_VER) {
        scr_sim_set_err(err, err_len,
                        "schema mismatch: library %u, adapter %u (refusing to run)",
                        (unsigned)schema, (unsigned)SCR_SIM_SCHEMA_VER);
        dlclose(handle);
        memset(api, 0, sizeof(*api));
        return SCR_LOAD_ERR_SCHEMA;
    }

    if (err != NULL && err_len > 0) {
        err[0] = '\0';
    }
    return SCR_LOAD_OK;
}

/* Close the library (safe on a zeroed or loaded api). */
static SCR_SIM_UNUSED void scr_sim_unload(scr_sim_api *api) {
    if (api == NULL) {
        return;
    }
    if (api->handle != NULL) {
        dlclose(api->handle);
    }
    memset(api, 0, sizeof(*api));
}

static SCR_SIM_UNUSED const char *scr_sim_load_strerror(int code) {
    switch (code) {
        case SCR_LOAD_OK: return "ok";
        case SCR_LOAD_ERR_DLOPEN: return "dlopen failed";
        case SCR_LOAD_ERR_SYMBOL: return "missing contract symbol";
        case SCR_LOAD_ERR_ABI: return "ABI version mismatch";
        case SCR_LOAD_ERR_SCHEMA: return "schema version mismatch";
        default: return "unknown loader error";
    }
}

static SCR_SIM_UNUSED void scr_sim_set_err(char *err, size_t err_len,
                                            const char *fmt, ...) {
    va_list ap;
    if (err == NULL || err_len == 0) {
        return;
    }
    va_start(ap, fmt);
    vsnprintf(err, err_len, fmt, ap);
    va_end(ap);
}

#endif /* SCR_SIM_LOADER_H */
