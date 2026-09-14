/*
 * HyrxMQ POSIX signal shim.
 *
 * Mojo 1.0 has no signal module and no module-level mutable globals, so the
 * async-signal-safe flag the SIGTERM/SIGINT handler flips cannot live in Mojo
 * source. This tiny C translation unit owns that flag
 * (`volatile sig_atomic_t`) and installs the handlers via signal(2).
 *
 * The Mojo listener polls `hyrxmq_shutdown_requested()` from its serving loop
 * and calls `begin_shutdown()` when it becomes true. Built and linked into the
 * `hyrxmq-listen` executable by the pixi `hyrxmq-listen` task
 * (`clang -c ... -o build/shutdown_shim.o` + `mojo build -Xlinker ...`).
 *
 * It is deliberately NOT linked into `mojo run` (JIT) unit tests: `mojo run`
 * cannot link native objects, and tests exercise only the pure-Mojo
 * ShutdownState / listener-flag seam.
 */
#include <signal.h>
#include <unistd.h>

static volatile sig_atomic_t hyrxmq_shutdown_requested_flag = 0;

static void hyrxmq_shutdown_handler(int sig) {
    (void)sig;
    hyrxmq_shutdown_requested_flag = 1;
}

int hyrxmq_install_shutdown_signals(void) {
    if (signal(SIGTERM, hyrxmq_shutdown_handler) == SIG_ERR) {
        return -1;
    }
    if (signal(SIGINT, hyrxmq_shutdown_handler) == SIG_ERR) {
        return -1;
    }
    return 0;
}

/*
 * Exit-on-signal variant for PID 1 containers (the web binary).
 *
 * Linux gives PID 1 special signal semantics: a signal with no installed
 * handler is IGNORED, not defaulted. A container whose entrypoint is the web
 * binary therefore ignores SIGTERM and is SIGKILLed after the full
 * termination grace period (observed exit code 137 in the kind E2E run).
 *
 * Installing a handler fixes it. `_exit(0)` is async-signal-safe (unlike
 * `exit(3)`, which is not, and `printf`, which would deadlock). The web
 * process holds no WAL write state, so an immediate clean exit is correct;
 * the `hyrxmq-listen` binary keeps the polling variant above so it can drain.
 */
static void hyrxmq_shutdown_exit_handler(int sig) {
    (void)sig;
    hyrxmq_shutdown_requested_flag = 1;
    _exit(0);
}

int hyrxmq_install_shutdown_signals_exit(void) {
    if (signal(SIGTERM, hyrxmq_shutdown_exit_handler) == SIG_ERR) {
        return -1;
    }
    if (signal(SIGINT, hyrxmq_shutdown_exit_handler) == SIG_ERR) {
        return -1;
    }
    return 0;
}

int hyrxmq_shutdown_requested(void) {
    return (int)hyrxmq_shutdown_requested_flag;
}

void hyrxmq_reset_shutdown_flag(void) {
    hyrxmq_shutdown_requested_flag = 0;
}
