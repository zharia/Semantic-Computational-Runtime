/* scr_transport.h — ITransport abstraction for the SCR GDExtension adapter
 * (milestone_0008, 0008 §1.1 / §3.1, APP-ADP-002 substitutability).
 *
 * Normative source: providers/render/graphics/godot/104_contract.md.
 * The Port semantics (snapshot down, input/edit up) are IDENTICAL across
 * implementations — swapping transports must not change meaning:
 *
 *   InprocTransport  dlopen(libscr_sim.so) + C ABI calls (milestone 0002
 *                    behavior, extracted verbatim; default, safety path)
 *   SocketTransport  UDS connect + SCRT framing + worker thread (0008)
 *                    with a seqlock latest-snapshot slot and SPSC uplink
 *
 * Selection (0008 §1.1): environment SCR_SIM_TRANSPORT overrides project
 * setting `scr/transport`; anything other than "socket" => in-process.
 * That decision is taken by the adapter (the only layer allowed to know
 * Godot); transports themselves are engine-free.
 *
 * Threading contract (AP-15 / AP-9): every implementation must be safe to
 * call as:
 *   init/shutdown .......... single-threaded setup/teardown (main thread),
 *                            may block (handshake, join),
 *   step, snapshot_write, snapshot_size, edit_submit, poll_notices
 *                            ... render thread, NON-BLOCKING,
 *                            zero socket I/O, zero mutex shared with a
 *                            worker (SocketTransport hands off lock-free).
 *
 * Errors are loud (AP-17): last_error() carries a human-readable message
 * for any failed init; poll_notices() surfaces asynchronous runtime errors
 * (connection loss, server ERROR frames) for ERR_PRINT on the render
 * thread. Nothing is coerced into an empty frame.
 *
 * AP-4: socket path / library path are runtime strings — no filesystem
 * literal lives in this layer.
 */
#ifndef SCR_TRANSPORT_H
#define SCR_TRANSPORT_H

#include <stddef.h>
#include <stdint.h>

#include <string>

#include "scr_godot_abi.h"

/* Transport-local failure codes (same class as SCR_LOAD_ERR_* in
 * scr_sim_loader.h; contract SCR_ERR_* codes are untouched). */
#define SCR_TPORT_ERR_CONNECT   (-200) /* socket() / connect() failed */
#define SCR_TPORT_ERR_HANDSHAKE (-201) /* HELLO refused / version mismatch /
                                        * timeout / protocol violation */
#define SCR_TPORT_ERR_CONFIG    (-202) /* missing SCR_SIM_SOCKET etc. */

struct ITransport {
    virtual ~ITransport() = default;

    /* "InprocTransport" / "SocketTransport" — log lines the gates grep. */
    virtual const char *name() const = 0;

    /* Bring the transport up. Returns 0, a SCR_TPORT_ERR_*, a SCR_LOAD_ERR_*
     * (in-process load policy) or a SCR_ERR_*; last_error() explains any
     * non-zero return. Blocking (handshake) — main thread only. */
    virtual int32_t init(uint32_t seed) = 0;

    /* Tear down (sends BYE on the socket path). Safe to call twice. */
    virtual void shutdown() = 0;

    virtual bool ready() const = 0;

    /* Hand off one frame's input batch. Returns ticks executed (>= 0,
     * in-process) or 0 (socket: pacing lives elsewhere — the server's wall
     * 60 Hz clock, or the CMD_TICK 1 this call queues in manual pace
     * SCR_SIM_IPC_PACE=manual), or a negative SCR_ERR_*. NON-BLOCKING on
     * the render thread. */
    virtual int32_t step(double frame_dt, const scr_input_batch *in) = 0;

    /* Copy the latest snapshot into buf. Returns bytes written (>= 0) or a
     * negative SCR_ERR_*. NON-BLOCKING (seqlock retry, worst case a few
     * reads — no mutex, no I/O). */
    virtual int32_t snapshot_write(uint8_t *buf, uint32_t cap) = 0;

    /* Byte size of the latest snapshot (0 before the first one). */
    virtual uint32_t snapshot_size() = 0;

    /* Uplink one edit batch (ABI semantics preserved verbatim). */
    virtual int32_t edit_submit(const scr_edit_batch *batch) = 0;

    /* Message for the last failed init(); "" when init succeeded. */
    virtual const char *last_error() const = 0;

    /* Async runtime notices for the render thread to print (AP-17: loud).
     * Fills at most one pending info line and one pending error line per
     * call; empty strings mean "nothing new". NON-BLOCKING, lock-free. */
    virtual void poll_notices(std::string &info, std::string &error) = 0;

    /* Handshake/init version facts (set before init() returns; safe to read
     * afterwards without synchronization). */
    virtual void get_versions(uint32_t &proto, uint32_t &abi,
                              uint32_t &schema) const = 0;
};

/* Factories — implementation lives in transport_inproc.cpp /
 * transport_socket.cpp. `path` is the sim library path (in-process) or the
 * filesystem UDS path (socket); ownership stays with the caller's string.
 *
 * Socket supervision (0008 §1.1 / AP-18): when `server_bin` is non-null the
 * transport OWNS the server process — it posix_spawns it with
 *   argv = [server_bin, --socket, path, --seed, N]
 * waits for it to accept, and restarts it on crash/EOF with backoff
 * 100→200→400→800→1600 ms (cap 2 s). More than 5 restarts inside 30 s is
 * fatal: a loud notice, ready() goes false, stepping stops. Every session is
 * a FRESH one (same seed, tick reset) and is logged. `repo_root` (optional)
 * is exported to the child as SCR_REPO_ROOT so the server's catalog lookup
 * never depends on the caller's cwd.
 *
 * `server_bin == nullptr` = external owner: the transport only connects
 * (tests and tooling that start the server themselves use this mode). */
ITransport *scr_create_inproc_transport(const char *path);
ITransport *scr_create_socket_transport(const char *path,
                                        const char *server_bin = nullptr,
                                        const char *repo_root = nullptr);

#endif /* SCR_TRANSPORT_H */
