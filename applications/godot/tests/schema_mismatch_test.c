/* schema_mismatch_test.c — negative test for 104_contract.md §3/§7:
 * "Adapter startup rejection: refuse to run when
 *  scr_sim_abi_version() != 1 || scr_sim_schema_version() != 1".
 *
 * Built TWICE by tests/test_schema_mismatch.sh:
 *   1. -DSCR_STUB_IMPL : a stub libscr_sim that exports the 7 contract symbols
 *      where scr_sim_schema_version() returns 2 (ABI stays 1).
 *   2. -DSCR_TEST_MAIN : the test runner. It dlopens the stub through the
 *      SAME header-only loader the adapter uses
 *      (providers/render/graphics/godot/adapter/scr_sim_loader.h) and asserts
 *      the loader refuses with SCR_LOAD_ERR_SCHEMA. Optionally (2nd argv) it
 *      also loads the real schema-1 library and asserts acceptance, proving
 *      the refusal is specific to the mismatch and not a loader bug.
 *
 * Exit 0 = all checks passed; 1 = failure (loud, never silently coerced).
 */

#include <stdio.h>
#include <string.h>

#include "scr_sim_loader.h"

#ifdef SCR_STUB_IMPL

/* --- Stub library: schema_version() lies (returns 2) --------------------- */

int32_t scr_sim_init(uint32_t seed) {
    (void)seed;
    return 0;
}

void scr_sim_shutdown(void) {}

uint32_t scr_sim_abi_version(void) {
    return SCR_SIM_ABI_VERSION; /* correct — isolates the schema check */
}

uint32_t scr_sim_schema_version(void) {
    return 2u; /* VIOLATION under test */
}

int32_t scr_sim_step(double frame_dt, const scr_input_batch *in) {
    (void)frame_dt;
    (void)in;
    return 0;
}

uint32_t scr_sim_snapshot_size(void) {
    return 0;
}

int32_t scr_sim_snapshot_write(uint8_t *buf, uint32_t cap) {
    (void)buf;
    (void)cap;
    return SCR_ERR_NOT_INIT;
}

#elif defined(SCR_TEST_MAIN)

/* --- Test runner --------------------------------------------------------- */

static int failures = 0;

static void check(int cond, const char *msg) {
    if (cond) {
        printf("  PASS  %s\n", msg);
    } else {
        printf("  FAIL  %s\n", msg);
        failures++;
    }
}

int main(int argc, char **argv) {
    scr_sim_api api;
    char err[512];
    int rc;

    if (argc < 2) {
        fprintf(stderr,
                "usage: %s <schema2-stub.so> [real-schema1-libscr_sim.so]\n",
                argv[0]);
        return 1;
    }

    printf("[1] loader must REFUSE a schema-2 library (104_contract §3, §7)\n");
    memset(&api, 0, sizeof(api));
    rc = scr_sim_load(&api, argv[1], err, sizeof(err));
    check(rc == SCR_LOAD_ERR_SCHEMA,
          "scr_sim_load returns SCR_LOAD_ERR_SCHEMA (-103)");
    check(strstr(err, "schema mismatch") != NULL,
          "error message names the schema mismatch");
    check(api.handle == NULL, "refused library handle is not retained");
    printf("       message: %s\n", err);

    if (argc >= 3) {
        printf("[2] control: loader must ACCEPT the real schema-1 library\n");
        memset(&api, 0, sizeof(api));
        rc = scr_sim_load(&api, argv[2], err, sizeof(err));
        check(rc == SCR_LOAD_OK, "scr_sim_load returns SCR_LOAD_OK for schema 1");
        if (rc == SCR_LOAD_OK) {
            check(api.schema_version() == SCR_SIM_SCHEMA_VER,
                  "accepted library reports schema 1");
            scr_sim_unload(&api);
        } else {
            printf("       message: %s\n", err);
        }
    }

    if (failures == 0) {
        printf("PASS — schema mismatch negative test (%d check(s)).\n",
               argc >= 3 ? 5 : 4);
        return 0;
    }
    printf("FAIL — %d check(s) failed.\n", failures);
    return 1;
}

#else
#error "define SCR_STUB_IMPL (stub library) or SCR_TEST_MAIN (test runner)"
#endif
