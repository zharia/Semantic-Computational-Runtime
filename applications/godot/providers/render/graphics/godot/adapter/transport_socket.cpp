/* transport_socket.cpp — SocketTransport (milestone_0008, 0008 §1.1/§3.2/§3.3).
 *
 * Connects to the standalone sim server over a filesystem Unix-domain
 * socket, handshakes SCRT frames (HELLO -> HELLO_OK iff proto/abi/schema all
 * match this adapter's scr_godot_abi.h constants — the same startup gate the
 * in-process loader runs, AP-17), then:
 *
 *   worker thread (owns EVERY socket syscall — AP-15/AP-9):
 *     poll/read/parse frames; publish SNAPSHOT payloads into a seqlock
 *     double-buffer; drain the SPSC uplink ring and send INPUT/EDIT frames.
 *
 *   Supervision (0008 §1.1, Sprint 03, AP-15..18 — 0008 AP-15..18):
 *     when constructed with a server binary the worker OWNS the server
 *     process: posix_spawn it, wait for it to accept, handshake, and on
 *     BYE/EOF/crash reap it and start a FRESH session (same seed, tick
 *     reset) with backoff 100→200→400→800→1600 ms (cap 2 s). More than 5
 *     restarts inside 30 s is fatal: a loud notice, ready() goes false and
 *     the adapter stops stepping. A handshake refused AFTER a restart
 *     (version skew) is fatal too — no version-skew flapping. The last
 *     snapshot is kept across a restart; nothing is faked. shutdown() sends
 *     BYE and reaps the child, so exit never orphans a server (AP-18).
 *     With no server binary the transport only connects (external owner:
 *     tests and tooling that start the server themselves) and never respawns.
 *
 *   render thread (never touches a fd or a mutex):
 *     step()            -> push one input batch into the ring (merge-on-full
 *                          so look deltas are never dropped, 0008 §1.1),
 *     snapshot_write()  -> seqlock read with bounded retry,
 *     edit_submit()     -> push an edit (SCR_ERR_QUEUE_FULL when the ring
 *                          is full — atomic rejection, never a silent drop),
 *     poll_notices()    -> lock-free atomics the adapter ERR_PRINTs.
 *
 * Pacing (0008 §1.1, both modes transport-neutral — same CMD_TICK
 * semantics the determinism harness uses): HELLO flags always carry
 * SCR_IPC_FLAG_EDIT_CAP, plus SCR_IPC_FLAG_MANUAL_PACE when
 * $SCR_SIM_IPC_PACE=manual (anything else, including unset, = wall).
 *
 *   wall   (default)  — the server owns the fixed 60 Hz timestep; snapshots
 *                       stream as ticks execute; the render thread always
 *                       reads the newest one.
 *   manual (opt-in)   — client-paced: every step() (one Godot physics
 *                       frame) queues CMD_TICK 1 behind that frame's
 *                       INPUT/EDIT frames, so the sim advances exactly one
 *                       fixed tick per physics frame. Socket tick timing
 *                       then equals the in-process leg's (ticks are born
 *                       on physics frames in both legs), which is what the
 *                       rendered gates assert against: content at a fixed
 *                       sim tick is only wall-clock-neutral when sim ticks
 *                       track physics frames (shader/TIME displays —
 *                       clouds, plume lifetime — advance on wall time).
 *
 * Determinism (0008 §3.4): this file adds framing AROUND payload bytes it
 * never alters (AP-16); the byte-identity gate is tests/ipc/
 * test_ipc_determinism.sh (harness-driven, both legs on the same core).
 *
 * AP-4: the socket path arrives as a runtime string (argv/env) — no
 * filesystem literal in this source.
 */

#include "scr_transport.h"

#include <array>
#include <atomic>
#include <cerrno>
#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <spawn.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <sys/un.h>
#include <unistd.h>

extern char **environ;

namespace {

/* --- SCRT framing constants (mirror src/mojo/transport/framing.mojo) ---- */

constexpr uint32_t kMagic = 0x54524353u; /* 'S','C','R','T' little-endian */
constexpr uint32_t kProtoVer = 1u;

constexpr uint32_t kFtHello = 1;
constexpr uint32_t kFtHelloOk = 2;
constexpr uint32_t kFtError = 3;
constexpr uint32_t kFtSnapshot = 4;
constexpr uint32_t kFtInput = 5;
constexpr uint32_t kFtEdit = 6;
constexpr uint32_t kFtAck = 7;
constexpr uint32_t kFtBye = 8;
constexpr uint32_t kFtCmdTick = 9;

constexpr uint32_t kFlagManualPace = 0x1u;
constexpr uint32_t kFlagEditCap = 0x2u;

constexpr size_t kHeaderBytes = 16;
/* Server-side cap on client payloads is 64 KiB (session.mojo); snapshots at
 * schema 6 are ~250 KB (fixture 249680 B) — 4 MiB matches the server's own
 * staging buffers. */
constexpr uint32_t kMaxPayload = 16u * 1024u * 1024u;
constexpr uint32_t kHandshakeTimeoutMs = 5000;
/* spawn mode: the child needs fork+exec+bind on top of the handshake */
constexpr uint32_t kSpawnHandshakeTimeoutMs = 10000;
/* bounded connect window while (re)starting our own server */
constexpr int kSpawnConnectTimeoutMs = 5000;
/* backoff + restart cap (0008 §1.1): 100,200,400,800,1600 (cap 2 s);
 * > 5 restarts within 30 s => fatal, stop stepping */
constexpr int kBackoffBaseMs = 100;
constexpr int kBackoffCapMs = 2000;
constexpr int kRestartWindow = 5;
constexpr int kRestartWindowMs = 30000;

constexpr size_t kRingDepth = 16; /* 0008 §1.1: SPSC ring depth 16 */
constexpr int kPollTimeoutMs = 2; /* worker cadence when idle */

enum MsgKind : uint8_t {
    kMsgInput = 1,
    kMsgEdit = 2,
    kMsgTick = 3 /* manual pace: one CMD_TICK, payload u32 n ticks */
};

struct UplinkMsg {
    uint8_t kind;
    uint8_t len;
    uint8_t data[20]; /* scr_input_batch (20 B) > scr_edit_batch (4 B) */
};

inline void put_u32_le(uint8_t *p, uint32_t v) {
    p[0] = static_cast<uint8_t>(v & 0xFFu);
    p[1] = static_cast<uint8_t>((v >> 8) & 0xFFu);
    p[2] = static_cast<uint8_t>((v >> 16) & 0xFFu);
    p[3] = static_cast<uint8_t>((v >> 24) & 0xFFu);
}

inline uint32_t get_u32_le(const uint8_t *p) {
    return static_cast<uint32_t>(p[0]) | (static_cast<uint32_t>(p[1]) << 8) |
           (static_cast<uint32_t>(p[2]) << 16) |
           (static_cast<uint32_t>(p[3]) << 24);
}

/* Pack the 20-byte scr_input_batch layout by hand — the struct is packed on
 * the wire (scr_godot_abi.h), no padding assumptions across languages. */
inline void pack_input(const scr_input_batch &in, uint8_t out[20]) {
    std::memcpy(out + 0, &in.move_x, 4);
    std::memcpy(out + 4, &in.move_y, 4);
    std::memcpy(out + 8, &in.look_dx, 4);
    std::memcpy(out + 12, &in.look_dy, 4);
    out[16] = in.jump;
    out[17] = in.sprint;
    out[18] = in.action_primary;
    out[19] = in.action_secondary;
}

class SocketTransport final : public ITransport {
public:
    SocketTransport(const char *path, const char *server_bin,
                    const char *repo_root)
        : path_(path != nullptr ? path : ""),
          server_bin_(server_bin != nullptr ? server_bin : ""),
          repo_root_(repo_root != nullptr ? repo_root : "") {
        /* Pacing selection (0008 §1.1, AP-4: runtime string from env):
         * $SCR_SIM_IPC_PACE=manual ⇒ client-paced CMD_TICK mode; default /
         * any other value ⇒ wall (server free-run, pre-existing behavior —
         * safety default invariant: no opt-in, no change). Read once on the
         * main thread before the worker starts; immutable afterwards. */
        const char *pace = std::getenv("SCR_SIM_IPC_PACE");
        manual_pace_ = (pace != nullptr && std::strcmp(pace, "manual") == 0);
    }

    ~SocketTransport() override { shutdown(); }

    const char *name() const override { return "SocketTransport"; }

    int32_t init(uint32_t seed) override {
        err_.clear();
        if (path_.empty()) {
            err_ =
                "socket transport: SCR_SIM_SOCKET is not set — set it to the "
                "server's filesystem socket path";
            return SCR_TPORT_ERR_CONFIG;
        }
        if (ready_.load(std::memory_order_acquire)) {
            return 0;
        }
        seed_ = seed; /* the child is spawned with `--seed N` (0008 §1.1) */
        stop_.store(false, std::memory_order_release);
        fatal_.store(false, std::memory_order_release);
        pace_debt_.store(0, std::memory_order_release);
        hs_done_ = false;
        hs_rc_ = SCR_TPORT_ERR_HANDSHAKE;
        hs_err_.clear();
        worker_ = std::thread(&SocketTransport::worker_main, this);

        const uint32_t hs_ms = server_bin_.empty() ? kHandshakeTimeoutMs
                                                   : kSpawnHandshakeTimeoutMs;
        std::unique_lock<std::mutex> lock(hs_mu_);
        const bool done = hs_cv_.wait_for(
            lock, std::chrono::milliseconds(hs_ms), [this] { return hs_done_; });
        if (!done) {
            stop_.store(true, std::memory_order_release);
            lock.unlock();
            worker_.join();
            err_ =
                "socket transport: handshake timed out after " +
                std::to_string(hs_ms) + " ms";
            return SCR_TPORT_ERR_HANDSHAKE;
        }
        if (hs_rc_ != 0) {
            err_ = hs_err_;
            lock.unlock();
            worker_.join();
            return hs_rc_;
        }
        proto_ = hs_proto_;
        abi_ = hs_abi_;
        schema_ = hs_schema_;
        ready_.store(true, std::memory_order_release);
        return 0;
    }

    void shutdown() override {
        if (worker_.joinable()) {
            ready_.store(false, std::memory_order_release);
            stop_.store(true, std::memory_order_release);
            worker_.join(); /* worker sends BYE before returning (frame_loop) */
        }
        /* AP-18: BYE/exit_tree must leave no orphan server behind. The child
         * exits on BYE; if it does not, it is asked (SIGTERM) and then forced
         * (SIGKILL) and always reaped. No-op without a supervised child. */
        reap_child();
    }

    bool ready() const override { return ready_.load(std::memory_order_acquire); }

    int32_t step(double /*frame_dt*/, const scr_input_batch *in) override {
        if (!ready_.load(std::memory_order_acquire)) {
            return SCR_ERR_NOT_INIT;
        }
        if (in != nullptr) {
            (void)push_input(*in);
        }
        if (manual_pace_) {
            /* Client-paced (SCR_SIM_IPC_PACE=manual): exactly one fixed
             * tick per Godot physics frame, queued AFTER this frame's
             * INPUT/EDIT so the server consumes them first. Still zero
             * socket I/O here (AP-15) — the worker sends from the ring. */
            (void)push_tick();
        }
        /* Ticks executed are not reported here: wall pace has none pending
         * (server owns the 60 Hz clock), manual pace counts CMD_TICKs the
         * server has not run yet. */
        return 0;
    }

    int32_t snapshot_write(uint8_t *buf, uint32_t cap) override {
        if (!ready_.load(std::memory_order_acquire)) {
            return SCR_ERR_NOT_INIT;
        }
        /* Consume the session-first latch before touching the latest slot
         * (see publish()): the render thread's first read must observe the
         * session's first frame, otherwise the optional TERRAIN/FLORA
         * sections of that frame are lost (TERRAIN until the next
         * regeneration, FLORA until its next change-driven emission). */
        if (first_pending_.load(std::memory_order_acquire)) {
            for (int attempt = 0; attempt < 64; ++attempt) {
                const uint64_t f1 = first_epoch_.load(std::memory_order_acquire);
                if ((f1 & 1u) != 0) {
                    continue; /* worker writing the latch — retry */
                }
                const uint32_t n = first_len_;
                if (n == 0) {
                    break; /* nothing latched — fall through to latest */
                }
                if (n > cap) {
                    return SCR_ERR_BUF_SMALL; /* latch kept: caller retries */
                }
                std::memcpy(buf, first_slot_.data(), n);
                const uint64_t f2 = first_epoch_.load(std::memory_order_acquire);
                if (f1 == f2) {
                    first_pending_.store(false, std::memory_order_release);
                    return static_cast<int32_t>(n);
                }
                /* torn by a session restart re-latching — retry */
            }
        }
        for (int attempt = 0; attempt < 64; ++attempt) {
            uint64_t e1 = epoch_.load(std::memory_order_acquire);
            if ((e1 & 1u) != 0) {
                continue; /* writer mid-publish — retry, never block */
            }
            const uint32_t r = static_cast<uint32_t>((e1 / 2) % 2);
            const uint32_t n = slot_len_[r];
            if (n == 0) {
                return SCR_ERR_NOT_INIT; /* no snapshot published yet */
            }
            if (n > cap) {
                return SCR_ERR_BUF_SMALL;
            }
            std::memcpy(buf, slot_[r].data(), n);
            const uint64_t e2 = epoch_.load(std::memory_order_acquire);
            if (e1 == e2) {
                return static_cast<int32_t>(n);
            }
            /* torn by a newer publish — bounded retry (spec §3.3) */
        }
        /* Saturated by publishes: report as transient bad state; the adapter
         * re-reads size and retries (render thread never blocks on I/O). */
        return SCR_ERR_BAD_STATE;
    }

    uint32_t snapshot_size() override {
        if (!ready_.load(std::memory_order_acquire)) {
            return 0;
        }
        /* Report the latched session-first frame while it is unconsumed so
         * the caller's buffer is sized for it (pairs with snapshot_write). */
        if (first_pending_.load(std::memory_order_acquire)) {
            for (int attempt = 0; attempt < 64; ++attempt) {
                const uint64_t f1 = first_epoch_.load(std::memory_order_acquire);
                if ((f1 & 1u) != 0) {
                    continue;
                }
                const uint32_t n = first_len_;
                const uint64_t f2 = first_epoch_.load(std::memory_order_acquire);
                if (f1 == f2) {
                    return n;
                }
            }
        }
        for (int attempt = 0; attempt < 64; ++attempt) {
            const uint64_t e1 = epoch_.load(std::memory_order_acquire);
            if ((e1 & 1u) != 0) {
                continue;
            }
            const uint32_t r = static_cast<uint32_t>((e1 / 2) % 2);
            const uint32_t n = slot_len_[r];
            const uint64_t e2 = epoch_.load(std::memory_order_acquire);
            if (e1 == e2) {
                return n;
            }
        }
        return 0;
    }

    int32_t edit_submit(const scr_edit_batch *batch) override {
        if (!ready_.load(std::memory_order_acquire)) {
            return SCR_ERR_NOT_INIT;
        }
        if (batch == nullptr || batch->reserved != 0) {
            return SCR_ERR_BAD_STATE;
        }
        UplinkMsg m;
        m.kind = kMsgEdit;
        m.len = 4;
        m.data[0] = batch->op;
        m.data[1] = batch->select_slot;
        m.data[2] = static_cast<uint8_t>(batch->reserved & 0xFFu);
        m.data[3] = static_cast<uint8_t>((batch->reserved >> 8) & 0xFFu);
        if (!try_push_msg(m)) {
            queue_full_notices_.fetch_add(1, std::memory_order_relaxed);
            return SCR_ERR_QUEUE_FULL; /* loud, atomic — never a silent drop */
        }
        return 0;
    }

    const char *last_error() const override { return err_.c_str(); }

    void poll_notices(std::string &info, std::string &error) override {
        info.clear();
        error.clear();

        /* Server ERROR frame (first one keeps its message; later ones only
         * bump the count — the worker writes each field once, so the render
         * thread reads stable memory). */
        const uint32_t serr = server_err_code_.load(std::memory_order_acquire);
        if (serr != 0 && serr != reported_server_err_) {
            reported_server_err_ = serr;
            const uint32_t total =
                server_err_count_.load(std::memory_order_acquire);
            error = "ERROR: socket transport: server ERROR frame code=" +
                    std::to_string(serr) + " (" + server_err_msg_ + ")" +
                    (total > 1 ? " [+ " + std::to_string(total - 1) +
                                     " further server error(s)]"
                               : "");
        }

        /* Connection loss: loud, last snapshot kept. Supervised mode then
         * restarts (see below); external mode never respawns. */
        const uint32_t losses =
            conn_loss_count_.load(std::memory_order_acquire);
        if (losses != reported_conn_loss_) {
            reported_conn_loss_ = losses;
            const int e = conn_errno_.load(std::memory_order_acquire);
            error += std::string(error.empty() ? "" : "; ") +
                     "ERROR: socket transport: connection to the sim server "
                     "closed (" +
                     (e != 0 ? std::string(std::strerror(e))
                             : std::string("EOF/BYE")) +
                     ") — last snapshot kept" +
                     (supervised() ? ", supervised restart in progress"
                                   : ", external server, no respawn");
        }

        /* Session restart (0008 §1.1): fresh session, same seed, tick reset. */
        const uint32_t restarts =
            restart_count_.load(std::memory_order_acquire);
        if (restarts != reported_restart_count_) {
            reported_restart_count_ = restarts;
            info = "SCR: socket transport: session restart #" +
                   std::to_string(restarts) +
                   " (fresh session, same seed, tick reset) — snapshots "
                   "resume";
            awaiting_resumed_ = true;
        }

        /* …and the first snapshot of the new session proves they did. */
        if (awaiting_resumed_ &&
            snaps_since_restart_.load(std::memory_order_acquire) > 0) {
            awaiting_resumed_ = false;
            const std::string line =
                "SCR: socket transport: snapshots resumed after restart #" +
                std::to_string(restarts);
            info = info.empty() ? line : info + "; " + line;
        }

        /* Supervised spawn: which process we own (loud, once per session). */
        const uint32_t spawns = spawn_count_.load(std::memory_order_acquire);
        if (spawns != reported_spawn_count_) {
            reported_spawn_count_ = spawns;
            const std::string line =
                "SCR: socket transport: spawned sim server pid " +
                std::to_string(child_pid_.load(std::memory_order_acquire)) +
                " (socket " + path_ + ", seed " + std::to_string(seed_) +
                ")";
            info = info.empty() ? line : info + "; " + line;
        }

        /* Restart cap (0008 §1.1): fatal — loud, once, ready() goes false. */
        if (fatal_.load(std::memory_order_acquire) && !reported_fatal_) {
            reported_fatal_ = true;
            error += std::string(error.empty() ? "" : "; ") +
                     "ERROR: socket transport: FATAL — " + fatal_msg_ +
                     " — stepping stopped";
        }

        if (protocol_err_.load(std::memory_order_acquire) &&
            !reported_protocol_err_) {
            reported_protocol_err_ = true;
            error += std::string(error.empty() ? "" : "; ") +
                     "ERROR: socket transport: protocol violation from server "
                     "(bad magic, frame type or length) — session aborted";
        }

        const uint32_t drops =
            input_drops_.load(std::memory_order_acquire);        if (drops != 0 && drops > reported_input_drops_) {
            reported_input_drops_ = drops;
            error += std::string(error.empty() ? "" : "; ") +
                     "ERROR: socket transport: " + std::to_string(drops) +
                     " input batch(es) dropped (uplink ring saturated with "
                     "edits)";
        }

        const uint32_t qfull = queue_full_notices_.load(
            std::memory_order_acquire);
        if (qfull != 0 && qfull > reported_queue_full_) {
            const uint32_t added = qfull - reported_queue_full_;
            reported_queue_full_ = qfull;
            info = "SCR: socket transport: edit uplink returned QUEUE_FULL x" +
                   std::to_string(added) + " (ring depth 16, caller saw the "
                   "SCR_ERR_QUEUE_FULL code)";
        }

        /* Pacing mode, loud once (AP-17): the socket leg runs client-paced
         * only when $SCR_SIM_IPC_PACE=manual asked for it. */
        if (manual_pace_ && !reported_pace_) {
            reported_pace_ = true;
            const std::string line =
                "SCR: socket transport: manual pace (SCR_SIM_IPC_PACE=manual) "
                "— CMD_TICK 1 per physics frame, server does not free-run";
            info = info.empty() ? line : info + "; " + line;
        }
    }

    void get_versions(uint32_t &proto, uint32_t &abi,
                      uint32_t &schema) const override {
        proto = proto_;
        abi = abi_;
        schema = schema_;
    }

private:
    /* --------------------------------------------------------------------
     * SPSC uplink ring (producer: render thread, consumer: worker).
     * Index slots are published with release stores; each side owns its
     * counter. Merge-on-full for INPUT (look deltas never drop); EDIT is
     * rejected atomically with SCR_ERR_QUEUE_FULL (0008 §1.1).
     * ------------------------------------------------------------------ */

    /* Pack one frame of input into the uplink ring (render thread). */
    void push_input(const scr_input_batch &in) {
        UplinkMsg m;
        m.kind = kMsgInput;
        m.len = 20;
        pack_input(in, m.data);
        (void)try_push_msg(m);
    }

    /* Manual pace: queue CMD_TICK{1} behind the frame's INPUT/EDIT (render
     * thread). The SPSC FIFO orders them exactly like in-process
     * `step(dt, input)` — input first, then the tick it feeds. Only a FULL
     * ring (>= 16 unflushed frames, worker stalled) defers the tick into
     * pace_debt_; the worker flushes that debt right after draining the
     * ring (see frame_loop), so a tick is delayed, never lost — a lost tick
     * would silently stall the sim at a fixed gate. */
    void push_tick() {
        UplinkMsg m;
        m.kind = kMsgTick;
        m.len = 4;
        put_u32_le(m.data, 1u);
        if (!try_push_msg(m)) {
            pace_debt_.fetch_add(1, std::memory_order_relaxed);
        }
    }

    bool try_push_msg(const UplinkMsg &m) {
        const uint32_t wp = wp_.load(std::memory_order_relaxed);
        const uint32_t rp = rp_.load(std::memory_order_acquire);
        const uint32_t count = wp - rp;
        if (count < kRingDepth) {
            ring_[wp % kRingDepth] = m;
            wp_.store(wp + 1, std::memory_order_release);
            return true;
        }
        if (m.kind != kMsgInput) {
            return false;
        }
        /* Ring full: merge into the NEWEST queued input batch. */
        for (uint32_t back = 1; back <= count; ++back) {
            UplinkMsg &slot = ring_[(wp - back) % kRingDepth];
            if (slot.kind != kMsgInput) {
                continue;
            }
            float mvx, mvy, ldx, ldy;
            std::memcpy(&mvx, m.data + 0, 4);
            std::memcpy(&mvy, m.data + 4, 4);
            std::memcpy(&ldx, m.data + 8, 4);
            std::memcpy(&ldy, m.data + 12, 4);
            float smv_x, smv_y, sld_x, sld_y;
            std::memcpy(&smv_x, slot.data + 0, 4);
            std::memcpy(&smv_y, slot.data + 4, 4);
            std::memcpy(&sld_x, slot.data + 8, 4);
            std::memcpy(&sld_y, slot.data + 12, 4);
            /* newest movement wins; look deltas accumulate; booleans OR so a
             * pending edge is never lost across the merge. */
            std::memcpy(slot.data + 0, &mvx, 4);
            std::memcpy(slot.data + 4, &mvy, 4);
            sld_x += ldx;
            sld_y += ldy;
            std::memcpy(slot.data + 8, &sld_x, 4);
            std::memcpy(slot.data + 12, &sld_y, 4);
            slot.data[16] |= m.data[16];
            slot.data[17] |= m.data[17];
            slot.data[18] |= m.data[18];
            slot.data[19] |= m.data[19];
            return true;
        }
        /* Full of edits only — pathological (>= 16 unflushed edits inside
         * one render interval). Count it; the adapter prints it loudly. */
        input_drops_.fetch_add(1, std::memory_order_relaxed);
        return true;
    }

    bool pop_msg(UplinkMsg &out) {
        const uint32_t rp = rp_.load(std::memory_order_relaxed);
        const uint32_t wp = wp_.load(std::memory_order_acquire);
        if (rp == wp) {
            return false;
        }
        out = ring_[rp % kRingDepth];
        rp_.store(rp + 1, std::memory_order_release);
        return true;
    }

    /* --------------------------------------------------------------------
     * Seqlock latest-snapshot slot (spec §3.3): worker publishes (odd ->
     * fill other buffer -> even), render copies with an epoch re-check.
     * ------------------------------------------------------------------ */
    void publish(const uint8_t *payload, uint32_t n) {
        const uint32_t prior =
            snaps_since_restart_.fetch_add(1, std::memory_order_relaxed);
        if (prior == 0) {
            /* Session-first snapshot is LATCHED in its own seqlock slot in
             * addition to the latest slot. The latest slot is latest-wins
             * (0008 §3.2 coalescing), and at session start the render thread
             * may not run its first read for several server ticks (scene /
             * shader startup) — consuming only the newest frame would drop
             * the session's first frame for good, and that frame carries the
             * optional sections at their initial values (TERRAIN: first
             * snapshot after init, then on world regeneration; FLORA: the
             * first change-driven emission after init — 0006 invariant 5,
             * 0009 §3.2; 104_contract §2.3/§4.3 §10). The latch is released by the
             * first snapshot_write()/snapshot_size() after it is published;
             * every other publish uses the ordinary latest slot. A restart
             * resets snaps_since_restart_ (start_session), so each fresh
             * session latches its own first frame (0008 §1.1 supervision:
             * world regenerates ⇒ the new session's first frame carries
             * TERRAIN again, and FLORA re-emits under the same init rule). */
            const uint64_t f = first_epoch_.load(std::memory_order_relaxed);
            first_epoch_.store(f + 1, std::memory_order_relaxed);
            first_slot_.assign(payload, payload + n);
            first_len_ = n;
            first_epoch_.store(f + 2, std::memory_order_release);
            first_pending_.store(true, std::memory_order_release);
        }
        const uint64_t old = epoch_.load(std::memory_order_relaxed);
        epoch_.store(old + 1, std::memory_order_relaxed); /* odd = writing */
        const uint32_t w = static_cast<uint32_t>(((old / 2) + 1) % 2);
        slot_[w].assign(payload, payload + n);
        slot_len_[w] = n;
        epoch_.store(old + 2, std::memory_order_release); /* even = published */
    }

    /* --------------------------------------------------------------------
     * Worker thread — the ONLY place with socket syscalls (AP-15).
     * Bring up a session (spawn if we own the server, connect, handshake),
     * serve it, and on loss either stop (external owner) or supervise a
     * fresh session with backoff + restart cap (0008 §1.1).
     * ------------------------------------------------------------------ */
    void worker_main() {
        int fd = -1;
        std::string err;

        switch (start_session(fd, err)) {
            case kStartOk:
                break;
            case kStartStop:
                return; /* shutdown() raced the bring-up */
            case kStartRefused:
            case kStartIo:
                /* do_handshake() already published its verdict when it ran;
                 * finish_handshake() is idempotent, so a spawn/connect failure
                 * still reaches init() with SCR_TPORT_ERR_CONNECT. */
                finish_handshake(SCR_TPORT_ERR_CONNECT, err);
                reap_child(); /* never leak a server we cannot talk to */
                return;
        }

        /* Handshake OK — enter the frame loop. */
        {
            std::lock_guard<std::mutex> lock(hs_mu_);
            hs_done_ = true;
            hs_rc_ = 0;
            hs_err_.clear();
            hs_proto_ = rx_proto_;
            hs_abi_ = rx_abi_;
            hs_schema_ = rx_schema_;
        }
        hs_cv_.notify_all();

        for (;;) {
            frame_loop(fd);
            ::close(fd);
            fd = -1;
            fd_ = -1;
            if (stop_.load(std::memory_order_acquire)) {
                break; /* graceful BYE path — not a connection loss */
            }
            register_connection_loss(); /* loud, every time */
            if (!supervised()) {
                break; /* external owner: keep last snapshot, never respawn */
            }
            if (fatal_.load(std::memory_order_acquire)) {
                break;
            }
            if (!supervised_restart(fd)) {
                break; /* stop_ or fatal_ — the notice carries the reason */
            }
        }
    }

    /* --------------------------------------------------------------------
     * Supervision (0008 §1.1, Sprint 03, 0008 AP-15..18): spawn, backoff,
     * fresh session, restart cap. Worker-thread only.
     * ------------------------------------------------------------------ */

    enum SessionStart { kStartOk, kStartIo, kStartRefused, kStartStop };
    enum HsResult { kHsOk, kHsIo, kHsRefused };

    bool supervised() const { return !server_bin_.empty(); }

    /* One bring-up attempt. The child is spawned only when its slot is
     * empty, so a surviving server is reused and no twin is ever forked. */
    SessionStart start_session(int &fd, std::string &err) {
        if (supervised() && child_pid_.load(std::memory_order_acquire) <= 0) {
            if (!spawn_server(err)) {
                return kStartIo;
            }
            spawn_count_.fetch_add(1, std::memory_order_release);
        }
        if (!connect_wait(fd, err)) {
            return kStartIo;
        }
        fd_ = fd;
        const HsResult hr = do_handshake(fd);
        if (hr == kHsOk) {
            return kStartOk;
        }
        ::close(fd);
        fd_ = -1;
        fd = -1;
        return hr == kHsRefused ? kStartRefused : kStartIo;
    }

    /* Reap -> reserve a slot in the 30 s window -> backoff -> fresh session.
     * A refusal after a restart is fatal (version skew must not flap); the
     * window makes > 5 restarts / 30 s fatal. */
    bool supervised_restart(int &fd) {
        std::string err;
        for (;;) {
            if (stop_.load(std::memory_order_acquire)) {
                return false;
            }
            if (fatal_.load(std::memory_order_acquire)) {
                return false;
            }
            reap_child(); /* dead child of the previous session -> reaped */
            if (!reserve_restart(err)) {
                set_fatal(err);
                return false;
            }
            if (!sleep_ms(restart_backoff_ms())) {
                return false;
            }
            switch (start_session(fd, err)) {
                case kStartOk:
                    last_seq_ = 0; /* new session, seq restarts at 1 */
                    snaps_since_restart_.store(0, std::memory_order_release);
                    restart_count_.fetch_add(1, std::memory_order_release);
                    return true;
                case kStartStop:
                    return false;
                case kStartRefused:
                    set_fatal("handshake refused after restart: " + err);
                    return false;
                case kStartIo:
                    break; /* transient — the next iteration spends a slot */
            }
        }
    }

    /* Push a restart timestamp into the 30 s window; more than kRestartWindow
     * entries is fatal (0008 §1.1: > 5 restarts / 30 s => stop stepping). */
    bool reserve_restart(std::string &why) {
        const auto now = std::chrono::steady_clock::now();
        while (!restart_times_.empty() &&
               now - restart_times_.front() >
                   std::chrono::milliseconds(kRestartWindowMs)) {
            restart_times_.pop_front();
        }
        if (restart_times_.size() >= static_cast<size_t>(kRestartWindow)) {
            why = "restart cap reached: " + std::to_string(kRestartWindow) +
                  " restarts within " + std::to_string(kRestartWindowMs / 1000) +
                  " s (backoff exceeded) — the sim server is not staying up";
            return false;
        }
        restart_times_.push_back(now);
        return true;
    }

    /* 100,200,400,800,1600 ms by window depth, capped at 2 s. */
    int restart_backoff_ms() const {
        const size_t n = restart_times_.size();
        if (n == 0) {
            return kBackoffBaseMs;
        }
        int shift = static_cast<int>(n) - 1;
        if (shift > 4) {
            shift = 4;
        }
        const int ms = kBackoffBaseMs << shift;
        return ms > kBackoffCapMs ? kBackoffCapMs : ms;
    }

    /* Sleep that watches stop_ (shutdown never waits out a whole backoff). */
    bool sleep_ms(int ms) {
        const auto deadline =
            std::chrono::steady_clock::now() + std::chrono::milliseconds(ms);
        while (!stop_.load(std::memory_order_acquire)) {
            if (std::chrono::steady_clock::now() >= deadline) {
                return true;
            }
            ::usleep(20000);
        }
        return false;
    }

    void register_connection_loss() {
        conn_loss_count_.fetch_add(1, std::memory_order_release);
    }

    /* Publish the fatal stop: the message lands before the flag (release),
     * and ready_ goes false before it, so nothing steps after a fatal. */
    void set_fatal(const std::string &msg) {
        size_t n = msg.size();
        if (n >= sizeof(fatal_msg_)) {
            n = sizeof(fatal_msg_) - 1;
        }
        std::memcpy(fatal_msg_, msg.data(), n);
        fatal_msg_[n] = '\0';
        ready_.store(false, std::memory_order_release);
        fatal_.store(true, std::memory_order_release);
    }

    /* posix_spawn(argv = [bin, --socket, path, --seed, N]); SCR_REPO_ROOT is
     * exported so the server's catalog lookup never depends on our cwd. */
    bool spawn_server(std::string &err) {
        if (server_bin_.empty()) {
            err = "spawn requested but no sim server binary was configured";
            return false;
        }
        if (path_.empty()) {
            err = "spawn requested but the socket path is empty";
            return false;
        }
        const std::vector<std::string> args = {
            server_bin_, "--socket", path_, "--seed", std::to_string(seed_)};
        std::vector<char *> argv;
        argv.reserve(args.size() + 1);
        for (const std::string &a : args) {
            argv.push_back(const_cast<char *>(a.c_str()));
        }
        argv.push_back(nullptr);

        std::vector<std::string> env_store;
        if (!repo_root_.empty()) {
            env_store.emplace_back("SCR_REPO_ROOT=" + repo_root_);
        }
        for (char **e = environ; e != nullptr && *e != nullptr; ++e) {
            const std::string s(*e);
            if (!repo_root_.empty() && s.rfind("SCR_REPO_ROOT=", 0) == 0) {
                continue; /* replaced by the adapter-derived root */
            }
            env_store.push_back(s);
        }
        std::vector<char *> envp;
        envp.reserve(env_store.size() + 1);
        for (std::string &s : env_store) {
            envp.push_back(const_cast<char *>(s.c_str()));
        }
        envp.push_back(nullptr);

        posix_spawn_file_actions_t actions;
        posix_spawn_file_actions_init(&actions);
        pid_t pid = 0;
        const int rc = ::posix_spawn(&pid, server_bin_.c_str(), &actions,
                                     nullptr, argv.data(), envp.data());
        posix_spawn_file_actions_destroy(&actions);
        if (rc != 0) {
            err = "spawn(" + server_bin_ + ") failed: " + std::strerror(rc);
            return false;
        }
        child_pid_.store(pid, std::memory_order_release);
        return true;
    }

    /* Connect. External owner: a single attempt (0008 Sprint 02 behavior).
     * Supervised: a bounded window, because the child may still be in
     * fork/exec/bind; a child that dies during it fails fast. */
    bool connect_wait(int &fd, std::string &err) {
        fd = -1;
        const int budget_ms = supervised() ? kSpawnConnectTimeoutMs : 0;
        const auto deadline = std::chrono::steady_clock::now() +
                              std::chrono::milliseconds(budget_ms);
        std::string last;
        for (;;) {
            if (stop_.load(std::memory_order_acquire)) {
                err = "socket transport: shutdown during connect";
                return false;
            }
            if (try_connect(fd, last)) {
                return true;
            }
            const pid_t pid = child_pid_.load(std::memory_order_acquire);
            if (pid > 0) {
                int st = 0;
                const pid_t r = ::waitpid(pid, &st, WNOHANG);
                if (r == pid) {
                    child_pid_.store(-1, std::memory_order_release);
                    err = "sim server exited before accepting a connection (" +
                          describe_status(st) + ")";
                    return false;
                }
                if (r < 0 && errno == ECHILD) {
                    child_pid_.store(-1, std::memory_order_release);
                }
            }
            if (budget_ms <= 0 ||
                std::chrono::steady_clock::now() >= deadline) {
                err = last;
                return false;
            }
            if (!sleep_ms(20)) {
                err = "socket transport: shutdown while waiting for the sim "
                      "server to accept";
                return false;
            }
        }
    }

    bool try_connect(int &fd, std::string &err) {
        fd = ::socket(AF_UNIX, SOCK_STREAM, 0);
        if (fd < 0) {
            err =
                "socket(AF_UNIX) failed: " + std::string(std::strerror(errno));
            return false;
        }
        if (path_.size() + 3 > sizeof(sockaddr_un::sun_path)) {
            ::close(fd);
            fd = -1;
            err = "socket path too long for sockaddr_un";
            return false;
        }
        sockaddr_un addr;
        std::memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        std::memcpy(addr.sun_path, path_.c_str(), path_.size() + 1);
        if (::connect(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) !=
            0) {
            err = "connect(" + path_ + ") failed: " + std::strerror(errno);
            ::close(fd);
            fd = -1;
            return false;
        }
        return true;
    }

    static std::string describe_status(int st) {
        if (WIFEXITED(st)) {
            return "exit code " + std::to_string(WEXITSTATUS(st));
        }
        if (WIFSIGNALED(st)) {
            return "killed by signal " + std::to_string(WTERMSIG(st));
        }
        return "unknown status";
    }

    /* Reap the supervised child — never a zombie, never an orphan (AP-18).
     * A child that exited by itself (crash, or our own BYE) is reaped at
     * once; a survivor gets SIGTERM, then SIGKILL. Safe with no child. */
    void reap_child() {
        const pid_t pid = child_pid_.load(std::memory_order_acquire);
        if (pid <= 0) {
            return;
        }
        int st = 0;
        for (int i = 0; i < 15; ++i) {
            const pid_t r = ::waitpid(pid, &st, WNOHANG);
            if (r == pid || (r < 0 && errno == ECHILD)) {
                child_pid_.store(-1, std::memory_order_release);
                return;
            }
            ::usleep(20000); /* grace: a BYE-triggered exit lands in here */
        }
        (void)::kill(pid, SIGTERM);
        for (int i = 0; i < 15; ++i) {
            const pid_t r = ::waitpid(pid, &st, WNOHANG);
            if (r == pid || (r < 0 && errno == ECHILD)) {
                child_pid_.store(-1, std::memory_order_release);
                return;
            }
            if (stop_.load(std::memory_order_acquire)) {
                break; /* shutdown asked for no orphans — escalate now */
            }
            ::usleep(20000);
        }
        (void)::kill(pid, SIGKILL);
        while (::waitpid(pid, nullptr, 0) < 0 && errno == EINTR) {
        }
        child_pid_.store(-1, std::memory_order_release);
    }

    void finish_handshake(int32_t rc, const std::string &msg) {
        {
            std::lock_guard<std::mutex> lock(hs_mu_);
            if (hs_done_) {
                return; /* first verdict wins (init() may already have it) */
            }
            hs_done_ = true;
            hs_rc_ = rc;
            hs_err_ = msg;
        }
        hs_cv_.notify_all();
    }

    /* Blocking-with-deadline recv helpers (worker only). */
    bool wait_readable(int fd, int timeout_ms) {
        if (stop_.load(std::memory_order_acquire)) {
            return false;
        }
        struct pollfd pfd;
        pfd.fd = fd;
        pfd.events = POLLIN;
        pfd.revents = 0;
        const int rc = ::poll(&pfd, 1, timeout_ms);
        if (rc < 0) {
            if (errno == EINTR) {
                return true;
            }
            conn_errno_.store(errno, std::memory_order_relaxed);
            return false;
        }
        if (rc == 0) {
            return false; /* timeout */
        }
        if ((pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0 &&
            (pfd.revents & POLLIN) == 0) {
            return false;
        }
        return (pfd.revents & POLLIN) != 0;
    }

    /* Receive exactly n bytes with a deadline (handshake phase). */
    bool recv_exact(int fd, uint8_t *buf, size_t n, int timeout_ms) {
        size_t got = 0;
        const auto deadline =
            std::chrono::steady_clock::now() +
            std::chrono::milliseconds(timeout_ms);
        while (got < n) {
            if (std::chrono::steady_clock::now() >= deadline ||
                stop_.load(std::memory_order_acquire)) {
                return false;
            }
            const auto remain = std::chrono::duration_cast<
                std::chrono::milliseconds>(deadline -
                                           std::chrono::steady_clock::now())
                                    .count();
            if (!wait_readable(fd, static_cast<int>(remain) + 1)) {
                if (errno == 0 && !stop_.load(std::memory_order_acquire)) {
                    continue; /* timeout slice — loop checks the deadline */
                }
                return false;
            }
            const ssize_t r =
                ::recv(fd, buf + got, n - got, 0);
            if (r < 0) {
                if (errno == EINTR || errno == EAGAIN ||
                    errno == EWOULDBLOCK) {
                    continue;
                }
                return false;
            }
            if (r == 0) {
                return false; /* EOF */
            }
            got += static_cast<size_t>(r);
        }
        return true;
    }

    bool send_all(int fd, const uint8_t *buf, size_t n) {
        size_t sent = 0;
        int stalls = 0;
        while (sent < n) {
            if (stop_.load(std::memory_order_acquire)) {
                return false;
            }
            const ssize_t r = ::send(fd, buf + sent, n - sent, MSG_NOSIGNAL);
            if (r < 0) {
                if (errno == EINTR || errno == EAGAIN ||
                    errno == EWOULDBLOCK) {
                    struct pollfd pfd;
                    pfd.fd = fd;
                    pfd.events = POLLOUT;
                    pfd.revents = 0;
                    if (::poll(&pfd, 1, 200) <= 0 && ++stalls > 20) {
                        return false;
                    }
                    continue;
                }
                conn_errno_.store(errno, std::memory_order_relaxed);
                return false;
            }
            sent += static_cast<size_t>(r);
        }
        return true;
    }

    bool send_frame(int fd, uint32_t type, uint32_t seq,
                    const uint8_t *payload, uint32_t len) {
        uint8_t hdr[kHeaderBytes];
        put_u32_le(hdr + 0, kMagic);
        put_u32_le(hdr + 4, type);
        put_u32_le(hdr + 8, seq);
        put_u32_le(hdr + 12, len);
        if (!send_all(fd, hdr, kHeaderBytes)) {
            return false;
        }
        if (len > 0 && !send_all(fd, payload, len)) {
            return false;
        }
        return true;
    }

    /* kHsRefused = a verdict the server itself delivered (ERROR frame, version
     * skew, unusable peer): persistent, fatal after a restart. kHsIo = a
     * transport-level failure (spawn/connect/EOF/timeout): transient. */
    HsResult do_handshake(int fd) {
        uint8_t hello[16];
        put_u32_le(hello + 0, kProtoVer);
        put_u32_le(hello + 4, SCR_SIM_ABI_VERSION);
        put_u32_le(hello + 8, SCR_SIM_SCHEMA_VER);
        uint32_t flags = kFlagEditCap; /* edit uplink capability */
        if (manual_pace_) {
            /* Client-paced mode (SCR_SIM_IPC_PACE=manual): advertise
             * MANUAL_PACE — the server then executes exactly the CMD_TICK
             * counts this transport issues (0008 §1.1) instead of its wall
             * 60 Hz clock. Re-issued on every (re)session, so a supervised
             * restart keeps the same pacing. */
            flags |= kFlagManualPace;
        }
        put_u32_le(hello + 12, flags);
        if (!send_frame(fd, kFtHello, 1, hello, 16)) {
            finish_handshake(SCR_TPORT_ERR_CONNECT,
                             "failed to send HELLO: " +
                                 std::string(std::strerror(errno)));
            return kHsIo;
        }

        uint8_t hdr[kHeaderBytes];
        if (!recv_exact(fd, hdr, kHeaderBytes,
                        static_cast<int>(kHandshakeTimeoutMs))) {
            finish_handshake(SCR_TPORT_ERR_HANDSHAKE,
                             "no frame header from server (timeout/EOF) — "
                             "is scr_sim_server running on " +
                                 path_ + "?");
            return kHsIo;
        }
        if (get_u32_le(hdr + 0) != kMagic) {
            finish_handshake(SCR_TPORT_ERR_HANDSHAKE,
                             "bad frame magic from server (not an SCRT "
                             "peer)");
            return kHsRefused;
        }
        const uint32_t type = get_u32_le(hdr + 4);
        const uint32_t len = get_u32_le(hdr + 12);
        if (len > kMaxPayload) {
            finish_handshake(SCR_TPORT_ERR_HANDSHAKE,
                             "absurd frame length from server: " +
                                 std::to_string(len));
            return kHsRefused;
        }
        std::vector<uint8_t> payload(len);
        if (len > 0 &&
            !recv_exact(fd, payload.data(), len,
                        static_cast<int>(kHandshakeTimeoutMs))) {
            finish_handshake(SCR_TPORT_ERR_HANDSHAKE,
                             "truncated handshake frame from server");
            return kHsIo;
        }

        if (type == kFtError) {
            const uint32_t code = len >= 4 ? get_u32_le(payload.data()) : 0;
            const uint32_t mlen =
                (len >= 8) ? get_u32_le(payload.data() + 4) : 0;
            std::string msg;
            if (mlen > 0 && 8 + mlen <= payload.size()) {
                msg.assign(reinterpret_cast<const char *>(payload.data() + 8),
                           mlen);
            }
            finish_handshake(
                SCR_TPORT_ERR_HANDSHAKE,
                "server refused the handshake: ERROR code=" +
                    std::to_string(code) + " (" + msg + ")");
            return kHsRefused;
        }
        if (type != kFtHelloOk || len < 12) {
            finish_handshake(SCR_TPORT_ERR_HANDSHAKE,
                             "expected HELLO_OK from server, got frame type " +
                                 std::to_string(type));
            return kHsRefused;
        }
        rx_proto_ = get_u32_le(payload.data() + 0);
        rx_abi_ = get_u32_le(payload.data() + 4);
        rx_schema_ = get_u32_le(payload.data() + 8);

        /* Same startup gate as scr_sim_loader.h, over the wire (AP-17). */
        if (rx_proto_ != kProtoVer) {
            finish_handshake(
                SCR_TPORT_ERR_HANDSHAKE,
                "proto mismatch: server " + std::to_string(rx_proto_) +
                    ", adapter " + std::to_string(kProtoVer) +
                    " (refusing to run)");
            return kHsRefused;
        }
        if (rx_abi_ != SCR_SIM_ABI_VERSION) {
            finish_handshake(
                SCR_TPORT_ERR_HANDSHAKE,
                "ABI mismatch: server " + std::to_string(rx_abi_) +
                    ", adapter " + std::to_string(SCR_SIM_ABI_VERSION) +
                    " (refusing to run)");
            return kHsRefused;
        }
        if (rx_schema_ != SCR_SIM_SCHEMA_VER) {
            finish_handshake(
                SCR_TPORT_ERR_HANDSHAKE,
                "schema mismatch: server " + std::to_string(rx_schema_) +
                    ", adapter " + std::to_string(SCR_SIM_SCHEMA_VER) +
                    " (refusing to run)");
            return kHsRefused;
        }
        return kHsOk;
    }

    void frame_loop(int fd) {
        std::vector<uint8_t> rx;
        rx.reserve(64 * 1024);
        uint8_t scratch[64 * 1024];
        uint32_t uplink_seq = 2; /* HELLO used seq 1 */

        while (!stop_.load(std::memory_order_acquire)) {
            /* 1) drain the uplink ring (render thread is the producer) */
            UplinkMsg msg;
            int burst = 0;
            while (burst < 64 && pop_msg(msg)) {
                const uint32_t type = msg.kind == kMsgInput  ? kFtInput
                                      : msg.kind == kMsgEdit ? kFtEdit
                                                             : kFtCmdTick;
                if (!send_frame(fd, type, uplink_seq, msg.data, msg.len)) {
                    return; /* loss counted by the caller after frame_loop */
                }
                ++uplink_seq;
                ++burst;
            }

            /* 1b) manual pace: ticks that found the ring full (pace_debt_).
             * Flushed only AFTER a ring drain, and drained once more first:
             * any INPUT queued in the meantime must reach the server before
             * the deferred CMD_TICK that consumes it (ordering matches the
             * in-process step: input batch, then the fixed tick it feeds). */
            if (manual_pace_) {
                const uint32_t owed =
                    pace_debt_.exchange(0, std::memory_order_acq_rel);
                if (owed > 0) {
                    while (burst < 64 && pop_msg(msg)) {
                        const uint32_t type = msg.kind == kMsgInput  ? kFtInput
                                              : msg.kind == kMsgEdit ? kFtEdit
                                                                     : kFtCmdTick;
                        if (!send_frame(fd, type, uplink_seq, msg.data,
                                        msg.len)) {
                            return;
                        }
                        ++uplink_seq;
                        ++burst;
                    }
                    uint8_t n[4];
                    put_u32_le(n, owed);
                    if (!send_frame(fd, kFtCmdTick, uplink_seq, n, 4)) {
                        return;
                    }
                    ++uplink_seq;
                }
            }

            /* 2) wait for downlink traffic */
            if (!wait_readable(fd, kPollTimeoutMs)) {
                if (conn_errno_.load(std::memory_order_relaxed) != 0) {
                    return;
                }
                if (stop_.load(std::memory_order_acquire)) {
                    break;
                }
                continue; /* idle timeout slice */
            }
            const ssize_t r = ::recv(fd, scratch, sizeof(scratch), 0);
            if (r == 0) {
                /* Server exited (BYE/EOF) — loud, last snapshot kept. The
                 * caller counts the loss and (supervised) restarts. */
                return;
            }
            if (r < 0) {
                if (errno == EINTR || errno == EAGAIN ||
                    errno == EWOULDBLOCK) {
                    continue;
                }
                conn_errno_.store(errno, std::memory_order_relaxed);
                return;
            }
            rx.insert(rx.end(), scratch, scratch + r);
            if (!drain_rx(rx)) {
                return;
            }
        }

        /* Graceful stop: BYE then close (server exits after flushing). */
        (void)send_frame(fd, kFtBye, uplink_seq, nullptr, 0);
    }

    /* Parse every complete frame in rx; drops consumed bytes. Returns false
     * on a protocol violation (bad magic/type/length) — loud, never coerced. */
    bool drain_rx(std::vector<uint8_t> &rx) {
        size_t off = 0;
        while (rx.size() - off >= kHeaderBytes) {
            const uint8_t *h = rx.data() + off;
            if (get_u32_le(h) != kMagic) {
                conn_errno_.store(0, std::memory_order_relaxed);
                protocol_err_.store(true, std::memory_order_release);
                return false;
            }
            const uint32_t type = get_u32_le(h + 4);
            const uint32_t seq = get_u32_le(h + 8);
            const uint32_t len = get_u32_le(h + 12);
            if (len > kMaxPayload) {
                protocol_err_.store(true, std::memory_order_release);
                return false;
            }
            const size_t total = kHeaderBytes + len;
            if (rx.size() - off < total) {
                break; /* incomplete frame — wait for more bytes */
            }
            const uint8_t *payload = rx.data() + off + kHeaderBytes;
            switch (type) {
                case kFtSnapshot: {
                    /* stale-drop (0008 §3.2: client discards seq <= applied) */
                    if (static_cast<int64_t>(seq) > last_seq_) {
                        last_seq_ = static_cast<int64_t>(seq);
                        publish(payload, len);
                    }
                    break;
                }
                case kFtAck:
                    break; /* no window accounting needed (UDS is ordered) */
                case kFtError: {
                    const uint32_t code = len >= 4 ? get_u32_le(payload) : 0;
                    const uint32_t mlen =
                        (len >= 8) ? get_u32_le(payload + 4) : 0;
                    const uint32_t first =
                        server_err_code_.load(std::memory_order_relaxed);
                    if (first == 0) {
                        size_t n = 0;
                        if (mlen > 0 && 8 + mlen <= len) {
                            n = mlen < sizeof(server_err_msg_) - 1
                                    ? mlen
                                    : sizeof(server_err_msg_) - 1;
                            std::memcpy(server_err_msg_, payload + 8, n);
                        }
                        server_err_msg_[n] = '\0';
                        server_err_code_.store(
                            code == 0 ? 0xFFFFFFFFu : code,
                            std::memory_order_release);
                    }
                    server_err_count_.fetch_add(1, std::memory_order_relaxed);
                    break;
                }
                case kFtHello:
                case kFtHelloOk:
                case kFtEdit:
                case kFtInput:
                    /* server-to-client direction only carries 2/3/4/7 —
                     * anything else mid-session is a protocol violation */
                    protocol_err_.store(true, std::memory_order_release);
                    return false;
                default:
                    protocol_err_.store(true, std::memory_order_release);
                    return false;
            }
            off += total;
        }
        if (off > 0) {
            rx.erase(rx.begin(), rx.begin() + static_cast<long>(off));
        }
        return true;
    }

    /* --- configuration ------------------------------------------------- */
    std::string path_;
    std::string server_bin_; /* empty => external owner, never spawn */
    std::string repo_root_;  /* exported to the child as SCR_REPO_ROOT */
    uint32_t seed_ = 0;      /* the child is spawned with `--seed N` */
    /* Pacing mode from $SCR_SIM_IPC_PACE (ctor, main thread; immutable
     * before the worker starts): false = wall (server free-run, default),
     * true = manual (CMD_TICK 1 per physics frame — see file header). */
    bool manual_pace_ = false;

    /* --- worker lifecycle ---------------------------------------------- */
    std::thread worker_;
    std::atomic<bool> stop_{false};
    std::atomic<bool> ready_{false};
    int fd_ = -1; /* worker-owned; only read/written by the worker */

    /* handshake results (init() waits on this cv — startup path only) */
    std::mutex hs_mu_;
    std::condition_variable hs_cv_;
    bool hs_done_ = false;
    int32_t hs_rc_ = SCR_TPORT_ERR_HANDSHAKE;
    std::string hs_err_;
    uint32_t hs_proto_ = 0;
    uint32_t hs_abi_ = 0;
    uint32_t hs_schema_ = 0;
    uint32_t rx_proto_ = 0;
    uint32_t rx_abi_ = 0;
    uint32_t rx_schema_ = 0;

    /* --- seqlock snapshot slot ----------------------------------------- */
    std::atomic<uint64_t> epoch_{0}; /* even = published, odd = writing */
    std::array<std::vector<uint8_t>, 2> slot_{};
    std::array<uint32_t, 2> slot_len_{0, 0};
    int64_t last_seq_ = 0; /* worker-only stale-drop tracker */

    /* --- session-first snapshot latch (see publish()) -------------------- */
    std::atomic<uint64_t> first_epoch_{0}; /* even = published, odd = writing */
    std::vector<uint8_t> first_slot_{};
    uint32_t first_len_ = 0;
    std::atomic<bool> first_pending_{false};

    /* --- SPSC uplink ring ---------------------------------------------- */
    std::array<UplinkMsg, kRingDepth> ring_{};
    std::atomic<uint32_t> wp_{0}; /* render publishes, worker observes */
    std::atomic<uint32_t> rp_{0}; /* worker publishes, render observes */
    /* Manual pace only: CMD_TICKs the render thread could not queue because
     * the ring was full (push_tick). Never dropped — the worker flushes it
     * after draining the ring (frame_loop step 1b). */
    std::atomic<uint32_t> pace_debt_{0};

    /* --- async notices (worker writes once, render reads) --------------- */
    std::atomic<uint32_t> server_err_code_{0};
    std::atomic<uint32_t> server_err_count_{0};
    char server_err_msg_[256] = {0};
    std::atomic<bool> protocol_err_{false};
    std::atomic<int> conn_errno_{0};
    std::atomic<uint32_t> input_drops_{0};
    std::atomic<uint32_t> queue_full_notices_{0};

    /* --- supervision (0008 §1.1 / AP-18) -------------------------------- */
    std::atomic<pid_t> child_pid_{-1}; /* our server, -1 = none */
    std::atomic<uint32_t> spawn_count_{0};
    std::atomic<uint32_t> restart_count_{0}; /* fresh sessions after the first */
    std::atomic<uint32_t> conn_loss_count_{0};
    std::atomic<uint32_t> snaps_since_restart_{0};
    std::atomic<bool> fatal_{false};
    char fatal_msg_[512] = {0};
    /* restart timestamps of the last 30 s — worker-thread only */
    std::deque<std::chrono::steady_clock::time_point> restart_times_;

    /* render-thread "already printed" trackers */
    uint32_t reported_server_err_ = 0;
    uint32_t reported_conn_loss_ = 0;
    uint32_t reported_restart_count_ = 0;
    uint32_t reported_spawn_count_ = 0;
    bool awaiting_resumed_ = false;
    bool reported_fatal_ = false;
    bool reported_protocol_err_ = false;
    uint32_t reported_input_drops_ = 0;
    uint32_t reported_queue_full_ = 0;
    bool reported_pace_ = false;

    /* versions from the handshake (written before init() returns) */
    uint32_t proto_ = 0;
    uint32_t abi_ = 0;
    uint32_t schema_ = 0;

    /* init()-time error message */
    std::string err_;
};

} // namespace

ITransport *scr_create_socket_transport(const char *path, const char *server_bin,
                                        const char *repo_root) {
    return new SocketTransport(path, server_bin, repo_root);
}
