/* transport_inproc.cpp — InprocTransport (milestone_0008, 0008 §1.1).
 *
 * The milestone_0002 path, extracted verbatim behind ITransport: dlopen the
 * sim library, bind the ABI-1 contract symbols + scr_edit_submit (ABI 2),
 * run the shared startup version gate (scr_sim_loader.h), then forward
 * step / snapshot_write / edit_submit to the C ABI. Behavior must stay
 * byte-for-byte identical to the pre-split adapter (default transport;
 * safety default invariant, 0008 §6.7).
 *
 * Engine-free: Godot types never appear here (the adapter resolves the
 * library path with ProjectSettings and hands it over — AP-4/AP-1).
 */

#include "scr_transport.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#include "scr_sim_loader.h"

namespace {

class InprocTransport final : public ITransport {
public:
    explicit InprocTransport(const char *path)
        : path_(path != nullptr ? path : "") {}

    const char *name() const override { return "InprocTransport"; }

    int32_t init(uint32_t seed) override {
        err_.clear();
        if (path_.empty()) {
            err_ = "in-process transport: empty library path";
            return SCR_TPORT_ERR_CONFIG;
        }

        char loader_err[512] = {0};
        const int rc = scr_sim_load(&api_, path_.c_str(), loader_err,
                                    sizeof(loader_err));
        if (rc != SCR_LOAD_OK) {
            err_ = loader_err;
            if (err_.empty()) {
                err_ = scr_sim_load_strerror(rc);
            }
            err_ += " [" + path_ + "]";
            return rc;
        }

        /* Ninth contract symbol (ABI 2): not part of the shared loader's
         * 7-symbol list (scr_sim_loader.h header note) — bind it here and
         * refuse loudly if a library claiming ABI 2 does not export it. */
        {
            (void)dlerror();
            void *sym = dlsym(api_.handle, "scr_edit_submit");
            if (sym == nullptr || dlerror() != nullptr) {
                err_ =
                    "missing symbol scr_edit_submit on an ABI-2 library — "
                    "refusing to run (edit uplink unavailable)";
                scr_sim_unload(&api_);
                return SCR_LOAD_ERR_SYMBOL;
            }
            memcpy(&edit_submit_, &sym, sizeof(sym));
        }

        const int32_t irc = api_.init(seed);
        if (irc != 0) {
            char buf[128];
            snprintf(buf, sizeof(buf), "scr_sim_init failed with code %d",
                     static_cast<int>(irc));
            err_ = buf;
            scr_sim_unload(&api_);
            edit_submit_ = nullptr;
            return irc;
        }

        proto_ = 0; /* no framing handshake on this path */
        abi_ = api_.abi_version();
        schema_ = api_.schema_version();
        inited_ = true;
        return 0;
    }

    void shutdown() override {
        if (inited_) {
            api_.shutdown();
            inited_ = false;
        }
        if (loaded()) {
            scr_sim_unload(&api_);
            edit_submit_ = nullptr;
        }
    }

    bool ready() const override { return inited_; }

    int32_t step(double frame_dt, const scr_input_batch *in) override {
        if (!inited_) {
            return SCR_ERR_NOT_INIT;
        }
        return api_.step(frame_dt, in);
    }

    int32_t snapshot_write(uint8_t *buf, uint32_t cap) override {
        if (!inited_) {
            return SCR_ERR_NOT_INIT;
        }
        return api_.snapshot_write(buf, cap);
    }

    uint32_t snapshot_size() override {
        if (!inited_) {
            return 0;
        }
        return api_.snapshot_size();
    }

    int32_t edit_submit(const scr_edit_batch *batch) override {
        if (!inited_ || edit_submit_ == nullptr) {
            return SCR_ERR_NOT_INIT;
        }
        return edit_submit_(batch);
    }

    const char *last_error() const override { return err_.c_str(); }

    void poll_notices(std::string &info, std::string &error) override {
        info.clear();
        error.clear();
        /* synchronous path — all errors surface through init()/last_error */
    }

    void get_versions(uint32_t &proto, uint32_t &abi,
                      uint32_t &schema) const override {
        proto = proto_;
        abi = abi_;
        schema = schema_;
    }

private:
    bool loaded() const { return api_.handle != nullptr; }

    std::string path_;
    std::string err_;
    scr_sim_api api_ = {};
    int32_t (*edit_submit_)(const scr_edit_batch *batch) = nullptr;
    bool inited_ = false;
    uint32_t proto_ = 0;
    uint32_t abi_ = 0;
    uint32_t schema_ = 0;
};

} // namespace

ITransport *scr_create_inproc_transport(const char *path) {
    return new InprocTransport(path);
}
