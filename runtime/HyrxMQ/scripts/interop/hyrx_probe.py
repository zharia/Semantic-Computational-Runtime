#!/usr/bin/env python3
"""HyrxMQ real-client interop probe (audit 11/12).

Starts our own broker as a SUBPROCESS on a free port (HYRXMQ_PORT), waits for
it to bind, then points the SAME real AMQP client (pika) flow at it and records
EXACTLY where the client fails: TCP connect, the 8-byte protocol header, or the
first method (connection.start).

This is a NEGATIVE-CONTROL probe: HyrxMQ has not implemented AMQP connection
negotiation, so a real client is expected to fail at the header/first-method
boundary. The probe documents the precise failure point rather than skipping it.

Run:
    /tmp/amqp-venv/bin/python scripts/interop/hyrx_probe.py
Always kills the subprocess (try/finally) and never leaves it holding a port.
"""
import os
import select
import socket
import subprocess
import sys
import tempfile
import time

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BINARY = os.path.join(REPO, "build", "hyrxmq-listen")
AMQP_HEADER = b"AMQP\x00\x00\x09\x01"   # pika's default 0-9-1 protocol header
HOST = "127.0.0.1"
PROBE_PORT = int(os.environ.get("HYRX_PROBE_PORT", "5699"))


def free_port(preferred):
    """Return a free TCP port (prefer `preferred` if bindable)."""
    for cand in (preferred, 0):
        s = socket.socket()
        try:
            s.bind((HOST, cand))
            return s.getsockname()[1]
        except OSError:
            continue
        finally:
            s.close()
    raise RuntimeError("no free port")


def start_broker(port):
    env = dict(os.environ)
    env["HYRXMQ_HOST"] = HOST
    env["HYRXMQ_PORT"] = str(port)
    err = tempfile.NamedTemporaryFile(prefix="hyrxmq-probe-", suffix=".stderr",
                                      delete=False)
    p = subprocess.Popen([BINARY], env=env, cwd=REPO,
                         stdout=subprocess.DEVNULL, stderr=err)
    return p, err


def wait_ready(port, proc, err_path, timeout=5.0):
    """Poll TCP connect until the broker accepts, or fail on process exit."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if proc.poll() is not None:
            return False, "broker exited early rc=%s" % proc.returncode
        s = socket.socket()
        s.settimeout(0.5)
        try:
            s.connect((HOST, port))
            s.close()
            return True, "accepted"
        except OSError:
            time.sleep(0.05)
        finally:
            try:
                s.close()
            except OSError:
                pass
    return False, "timeout waiting for bind"


def probe_raw_header(port):
    """Send the AMQP protocol header and see if connection.start comes back."""
    detail = {}
    s = socket.socket()
    s.settimeout(3.0)
    try:
        t0 = time.monotonic()
        s.connect((HOST, port))
        detail["tcp_connect_ms"] = round((time.monotonic() - t0) * 1000)
        detail["tcp_connect"] = "OK"
        # nothing from broker before we speak
        r, _, _ = select.select([s], [], [], 0.3)
        detail["broker_preheader_bytes"] = (s.recv(1024) if r else b"")
        # send the 8-byte header, wait for a connection.start frame
        s.sendall(AMQP_HEADER)
        r, _, _ = select.select([s], [], [], 3.0)
        if r:
            data = s.recv(4096)
            detail["after_header"] = ("closed (EOF)" if data == b""
                                      else "bytes %d" % len(data))
            detail["header_response"] = data[:64].hex() or "(none/EOF)"
        else:
            detail["after_header"] = "no response (timeout 3s)"
            detail["header_response"] = "(none/timeout)"
    except Exception as e:
        detail["tcp_connect"] = "FAIL"
        detail["error"] = "%s: %s" % (type(e).__name__, e)
    finally:
        s.close()
    return detail


def probe_pika(port):
    """Attempt a real pika connection; classify the failure stage."""
    import pika
    out = {"pika_version": pika.__version__}
    params = pika.ConnectionParameters(
        host=HOST, port=port, virtual_host="/",
        credentials=pika.PlainCredentials("guest", "guest"),
        connection_attempts=1, retry_delay=0.2, socket_timeout=4,
        blocked_connection_timeout=4, heartbeat=60,
    )
    try:
        c = pika.BlockingConnection(params)
        out["result"] = "UNEXPECTED: connected"
        out["stage"] = "none"
        try:
            c.close()
        except Exception:
            pass
    except Exception as e:
        out["exc_type"] = type(e).__name__
        out["exc_msg"] = str(e).strip().replace("\n", "\\n")[:400]
        msg = out["exc_msg"].lower()
        # pika opens a TCP socket and sends the 8-byte protocol header BEFORE
        # it can receive connection.start. If the socket connect itself failed
        # we would be at the socket stage; otherwise the header was sent and
        # the handshake died waiting for the broker's first method.
        if any(k in msg for k in ("refused", "connection reset",
                                  "errconnrefused", "timed out connecting",
                                  "connection aborted")):
            out["stage"] = "socket"
        elif any(k in msg for k in ("header", "protocol version",
                                    "incompatible")):
            out["stage"] = "header"
        else:
            out["stage"] = "method (header sent, no connection.start reply)"
    return out


def main():
    print("HyrxMQ interop probe")
    print("  binary  : %s" % BINARY)
    if not os.path.exists(BINARY):
        print("BINARY MISSING - build first:")
        print("  pixi run mojo build -I src -I vendor/flare "
              "src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen")
        return 2
    port = free_port(PROBE_PORT)
    print("  port    : %d (chosen free)" % port)
    proc = err = None
    rc = 0
    try:
        proc, err = start_broker(port)
        ready, why = wait_ready(port, proc, err.name)
        print("  broker  : pid=%d ready=%s (%s)" % (proc.pid, ready, why))
        if not ready:
            print("\nBROKER DID NOT BECOME READY; stderr:")
            sys.stdout.flush()
            proc.kill(); proc.wait()
            with open(err.name) as f:
                print(f.read()[:2000])
            return 3

        print("\n--- STEP A: real client, raw AMQP protocol header ---")
        raw = probe_raw_header(port)
        for k, v in raw.items():
            print("   %-22s %s" % (k + ":", v))
        time.sleep(0.4)  # let broker finish that connection + return to accept

        print("\n--- STEP B: pika BlockingConnection full handshake ---")
        pk = probe_pika(port)
        for k, v in pk.items():
            print("   %-22s %s" % (k + ":", v))

        print("\n--- VERDICT ---")
        if raw.get("tcp_connect") == "OK":
            print("   TCP connect            : REACHED")
        if raw.get("after_header", "").startswith("closed") or \
                raw.get("after_header", "").startswith("no response"):
            print("   AMQP protocol header    : sent by client, NO connection.start from broker")
        if pk.get("stage", "none") != "none":
            print("   Failure stage           : %s" % pk["stage"])
            print("   -> HyrxMQ does NOT implement connection negotiation;")
            print("      a real AMQP client cannot complete the handshake.")
            rc = 4   # BLOCKED (documented), not a crash
    finally:
        if proc is not None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        if err is not None:
            try:
                with open(err.name) as f:
                    stderr_txt = f.read().strip()
                print("\n--- BROKER STDERR (%s) ---" % err.name)
                print(stderr_txt if stderr_txt else "(empty)")
                print("--- broker held port %d? post-kill check ---" % port)
                s = socket.socket(); s.settimeout(0.3)
                try:
                    s.connect((HOST, port))
                    print("   port STILL bound (bad)")
                except OSError:
                    print("   port released (OK)")
                finally:
                    s.close()
            finally:
                try:
                    os.unlink(err.name)
                except OSError:
                    pass
    print("\nPROBE EXIT CODE: %d  (0=unexpected-pass, 4=blocked-as-expected)" % rc)
    return rc


if __name__ == "__main__":
    sys.exit(main())
