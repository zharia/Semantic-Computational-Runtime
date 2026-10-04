/* schema_mismatch_test.c — negative test for 104_contract.md §3/§7:
 * "Adapter startup rejection: refuse to run when
 *  scr_sim_abi_version() != SCR_SIM_ABI_VERSION ||
 *  scr_sim_schema_version() != SCR_SIM_SCHEMA_VER".
 *
 * Built FOUR times by tests/test_schema_mismatch.sh:
 *   1. -DSCR_STUB_IMPL : a stub libscr_sim that exports the 8 contract
 *      symbols where scr_sim_schema_version() returns SCR_SIM_SCHEMA_VER + 1
 *      (derived from the real header, so a future bump keeps the negative
 *      test honest; ABI stays SCR_SIM_ABI_VERSION).
 *   2. -DSCR_STUB_IMPL -DSCR_STUB_SCHEMA_OLD : a stub whose
 *      scr_sim_schema_version() returns SCR_SIM_SCHEMA_VER - 1 — the
 *      schema-6 refusal (104_contract §3/§7: a stale schema-6 library
 *      must be refused, not only a future schema).
 *   3. -DSCR_STUB_IMPL -DSCR_STUB_ABI : a stub whose scr_sim_abi_version()
 *      returns SCR_SIM_ABI_VERSION + 1 while the schema is correct
 *      (milestone_0007 invariant 9: ABI 1->2 refusal must be
 *      test-asserted, isolating the ABI check from the schema check).
 *   4. -DSCR_TEST_MAIN : the test runner. It dlopens the stubs through the
 *      SAME header-only loader the adapter uses
 *      (providers/render/graphics/godot/adapter/scr_sim_loader.h) and asserts
 *      the loader refuses with SCR_LOAD_ERR_SCHEMA / SCR_LOAD_ERR_ABI.
 *      Optionally (3rd argv) it also loads the real library and asserts
 *      acceptance, proving the refusal is specific to the mismatch and not
 *      a loader bug.
 *
 * Exit 0 = all checks passed; 1 = failure (loud, never silently coerced).
 */

#include <stdio.h>
#include <string.h>

#include "scr_sim_loader.h"

#ifdef SCR_STUB_IMPL

/* --- Stub library: one of the two startup gates lies -------------------- */

int32_t scr_sim_init(uint32_t seed) {
    (void)seed;
    return 0;
}

void scr_sim_shutdown(void) {}

uint32_t scr_sim_abi_version(void) {
#ifdef SCR_STUB_ABI
    /* VIOLATION under test: derived from the real header
     * (SCR_SIM_ABI_VERSION + 1), so any future ABI bump keeps this
     * negative test one ahead (milestone_0007 invariant 9). */
    return SCR_SIM_ABI_VERSION + 1u;
#else
    return SCR_SIM_ABI_VERSION; /* correct — isolates the schema check */
#endif
}

uint32_t scr_sim_schema_version(void) {
#ifdef SCR_STUB_ABI
    return SCR_SIM_SCHEMA_VER; /* correct — isolates the ABI check */
#elif defined(SCR_STUB_SCHEMA_OLD)
    /* VIOLATION under test: one BEHIND the real header — the stale
     * schema-6 library must be refused after the 6 -> 7 bump
     * (104_contract §3/§7). ABI stays correct (isolates the schema check). */
    return SCR_SIM_SCHEMA_VER - 1u;
#else
    /* VIOLATION under test: derived from the real header (SCR_SIM_SCHEMA_VER
     * + 1), so any future schema bump keeps this negative test one ahead
     * instead of silently degrading into a match (0003 AP-13). */
    return SCR_SIM_SCHEMA_VER + 1u;
#endif
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
    int expected = 3;

    if (argc < 4) {
        fprintf(stderr,
                "usage: %s <schema+1-stub.so> <schema-1-stub.so> "
                "<abi-mismatch-stub.so> [real-libscr_sim.so]\n",
                argv[0]);
        return 1;
    }

    printf("[1] loader must REFUSE a schema-mismatched library "
           "(104_contract §3, §7)\n");
    printf("       (stub reports SCR_SIM_SCHEMA_VER + 1 = %u)\n",
           (unsigned)(SCR_SIM_SCHEMA_VER + 1u));
    memset(&api, 0, sizeof(api));
    rc = scr_sim_load(&api, argv[1], err, sizeof(err));
    check(rc == SCR_LOAD_ERR_SCHEMA,
          "scr_sim_load returns SCR_LOAD_ERR_SCHEMA (-103)");
    check(strstr(err, "schema mismatch") != NULL,
          "error message names the schema mismatch");
    check(api.handle == NULL, "refused library handle is not retained");
    printf("       message: %s\n", err);

    expected += 3;
    printf("[2] loader must REFUSE a schema-1 library "
           "(104_contract §3/§7: the stale schema-%u must be refused)\n",
           (unsigned)(SCR_SIM_SCHEMA_VER - 1u));
    printf("       (stub reports SCR_SIM_SCHEMA_VER - 1 = %u)\n",
           (unsigned)(SCR_SIM_SCHEMA_VER - 1u));
    memset(&api, 0, sizeof(api));
    rc = scr_sim_load(&api, argv[2], err, sizeof(err));
    check(rc == SCR_LOAD_ERR_SCHEMA,
          "scr_sim_load returns SCR_LOAD_ERR_SCHEMA (-103)");
    check(strstr(err, "schema mismatch") != NULL,
          "error message names the schema mismatch");
    check(api.handle == NULL, "refused library handle is not retained");
    printf("       message: %s\n", err);

    /* milestone_0007 invariant 9: ABI 1->2 refusal test-asserted
     * (stub reports SCR_SIM_ABI_VERSION + 1, schema correct). */
    expected += 3;
    printf("[3] loader must REFUSE an ABI-mismatched library "
           "(104_contract §3/§7, milestone_0007 invariant 9)\n");
    printf("       (stub reports SCR_SIM_ABI_VERSION + 1 = %u)\n",
           (unsigned)(SCR_SIM_ABI_VERSION + 1u));
    memset(&api, 0, sizeof(api));
    rc = scr_sim_load(&api, argv[3], err, sizeof(err));
    check(rc == SCR_LOAD_ERR_ABI,
          "scr_sim_load returns SCR_LOAD_ERR_ABI (-102)");
    check(strstr(err, "ABI mismatch") != NULL,
          "error message names the ABI mismatch");
    check(api.handle == NULL, "refused library handle is not retained");
    printf("       message: %s\n", err);

    if (argc >= 5) {
        expected += 2;
        printf("[4] control: loader must ACCEPT the real library "
               "(schema %u)\n", (unsigned)SCR_SIM_SCHEMA_VER);
        memset(&api, 0, sizeof(api));
        rc = scr_sim_load(&api, argv[4], err, sizeof(err));
        check(rc == SCR_LOAD_OK,
              "scr_sim_load returns SCR_LOAD_OK for the current schema");
        if (rc == SCR_LOAD_OK) {
            check(api.schema_version() == SCR_SIM_SCHEMA_VER,
                  "accepted library reports SCR_SIM_SCHEMA_VER");
            scr_sim_unload(&api);
        } else {
            printf("       message: %s\n", err);
        }
    }

    if (failures == 0) {
        printf("PASS — schema/ABI mismatch negative test (%d check(s)).\n",
               expected);
        return 0;
    }
    printf("FAIL — %d check(s) failed.\n", failures);
    return 1;
}

#else
#error "define SCR_STUB_IMPL (stub library) or SCR_TEST_MAIN (test runner)"
#endif
