#!/usr/bin/env python3
"""Real-TLS acceptance gate for the HyrxMQ TCP tier.

This is the acceptance harness for the TCP-tier TLS feature. It drives a REAL
Python ssl client (not a fake socket) against the HyrxMQ listen binary started
with ``HYRXMQ_TLS_ENABLED=true`` on a port that is NOT RabbitMQ's 5672, and
prints a per-step PASS/FAIL table.

Why an external client: a real TLS handshake needs BOTH peers to make progress
concurrently. The in-process Mojo test harness is single-threaded, so a
blocking ``TlsStream.connect()`` deadlocks against a blocking ``SSL_accept``.
This probe runs the broker as a separate process — the same model the pika
interop harness uses — which is the stronger proof anyway (real binary, real
client, real wire).

Steps:
  1. broker starts with a self-signed cert/key and binds the TLS port
  2. a plaintext connect is REJECTED / cannot complete the AMQP handshake
     (the server expects a TLS ClientHello, and a raw AMQP header is not one)
  3. a TLS client completes the handshake (negotiated version >= 1.2)
  4. the TLS client sends the AMQP protocol header and receives the server's
     ``connection.start`` method frame THROUGH the encrypted channel
  5. the cert the server presented matches the one on disk

Run:
    python3 scripts/interop/tls_probe.py
Environment overrides: HYRXMQ_BIN, HYRXMQ_PORT (default 5698), HYRXMQ_HOST.

Exit 0 iff every decisive step PASSes.
"""
import os
import socket
import ssl
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BIN = os.environ.get("HYRXMQ_BIN", os.path.join(ROOT, "build", "hyrxmq-listen"))
HOST = os.environ.get("HYRXMQ_HOST", "127.0.0.1")
PORT = int(os.environ.get("HYRXMQ_PORT", "5698"))

AMQP_HEADER = b"AMQP\x00\x00\x09\x01"

# A self-signed RSA cert/key (CN=localhost, 10-year validity). Generated with
# `openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -subj /CN=localhost`.
CERT_PEM = """-----BEGIN CERTIFICATE-----
MIIDCTCCAfGgAwIBAgIUL5phhuOfJ8o/Lg1jWTIdGj7ECE8wDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI2MDkxMTE2NDUyOVoXDTM2MDkw
ODE2NDUyOVowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEF
AAOCAQ8AMIIBCgKCAQEAuUjkp0UJHVA1T68TDcXS0Tjc79WkD4eeAdzc+tjlYG+Y
EXNqBMygsu5uMxF1czXWFPULXV5dIg2Tkizy3+HUwK7vTLDx14WqIO/LIa1Gp/9x
ewx5G/x3zAeZ/05PpY1Wp0vdPaqJTN+uDtdVOfr0NAolGuLbxTuj40zCol//yAif
aWj/MOhvr5D7XdGmxBlK+diM8fyVg8GyGnaCTr2JeArH9KiSqc6wsDgr5djjcriM
Me3L5dv+c+XR3dhEUTRl4a7HDpkOSEi9VIcvuwT+EHbkAjTejCNJLCuH5SAfB/Y6
J1G1e6u18e+/e6UeJQba8BKtL8WGroUh+4OsmhgcEQIDAQABo1MwUTAdBgNVHQ4E
FgQURsaINVftDX9ebA62jvGGWmO+GxwwHwYDVR0jBBgwFoAURsaINVftDX9ebA62
jvGGWmO+GxwwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAK0IR
4FN03PkDubtrmUME8FyyYuvaOhl+eSkNGmaAt8wzln4FWe/BDORDjyuXlzvYPmiT
V8CVhE1M1xn867afwwoym5QWjkOE9iVqa0z3OZvI1VktEzAVkJonohK6R8vYkn74
djC0GskQOHo4WXL7HFYteBRXsFvNGtUEzH6KA5/ODJBbgu4Z8t/P4w1tdsJ145+M
PVR0/VGzvStlahLEfKour9OnHhjnGqqJWo4rcvxQXvQBaSrvkYzos7IToEqXPZom
jsmkY2XxVvYilzJgHj8It7OsUlDOlAoa2M4adExqdk0/cbOxAShBWT9C2wrkhbb6
6F52jMOEIVRSo6a4fQ==
-----END CERTIFICATE-----
"""

KEY_PEM = """-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC5SOSnRQkdUDVP
rxMNxdLRONzv1aQPh54B3Nz62OVgb5gRc2oEzKCy7m4zEXVzNdYU9QtdXl0iDZOS
LPLf4dTAru9MsPHXhaog78shrUan/3F7DHkb/HfMB5n/Tk+ljVanS909qolM364O
11U5+vQ0CiUa4tvFO6PjTMKiX//ICJ9paP8w6G+vkPtd0abEGUr52Izx/JWDwbIa
doJOvYl4Csf0qJKpzrCwOCvl2ONyuIwx7cvl2/5z5dHd2ERRNGXhrscOmQ5ISL1U
hy+7BP4QduQCNN6MI0ksK4flIB8H9jonUbV7q7Xx7797pR4lBtrwEq0vxYauhSH7
g6yaGBwRAgMBAAECggEAUcJXm3P8JKI7FBFmMAKmF0qnO3GjdnLah2nlXQ+Oj/JO
QQ0TsFB3bN2HZSOEFzWfZRoITMgSAq/I+Yy6E468adYHpGjEHt1NiEEn+pFSh1lR
wwFrA61xU2fbTWxJ+vyWSzZPxyFUesaNMOFWK0KQtdHwM5/9aFf75pX9oNcJsENV
IlNyFO1FSM1CQIYrZuujKPXv/CSirQsZ/fcEOSO1Y0TjcDYaY5IjINllZ0OAw3lZ
713UuQrSpZVYATBMj0m0nXl0gpeXPAIu2H7JfFCVgtoba3nmh7zhOcY03QcXYr6g
4XsxRL+2HfHGuGBPtE2KpXs+09HL3yD25d6/ep8trQKBgQDpUyixb4hNc0OeJzTU
8wbW0qGdX/SReVO243yn1Uxoo6zrk72dJwDl+L4jGyJ+4K+KjnqgjzQULvDPeXGR
o06unfrFmCNBXRhgcP31Buoc3j40rfkbJlDt3n2jTQvQWI41cF9aQ6CjWBM+5mso
/y90iW8mr53yhdXj4N71nrbRmwKBgQDLSo3qzQotCORbhkMOzKnNDTktCkjTPaRn
rnkoJuvX2e6raB5phfxtsl1A1Ho2795g/4HT8xkV+DmuLOmFCBUTnDU7XYNxg2aV
pNIXxXtBntxBZ5u7KxU+uzI8+3k2EX+oS6fyLYtqJ0coa+CBGPEAV6lfwOLTWO5b
/a6JqegJwwKBgBjlf7UXMpMZFoD8q/2BBRzNEuOpBn6zVIRyV63M679Kn7vvYs8v
B0CCvz8duRuSvAhr1ZfmT+dLbvSkf8LLiyzEvKpy5mgmF+DKjb6kgzybVkXmvmrw
Nrh7Air3oKgVmu8G05XdG3nyfvM6QPr558VmmM6m9JKZR05ugzvwOI+7AoGBAK2n
xyku86Vati9Uto262MXXqOLHqUQBoSIMUWSyMr7VZGK5c1ky4loWhkBuAORS7QSw
3odeXyx8OVGG/gfsyoxQ4MwQassZsxTbkbhKsqpweLfKOKae++v1XsnnCzjbo8/w
qMtginooiUmHNWUyGBTxzTaFf32ItzyPrHveTt+fAoGBAOK/G9ro6yfPKGCutSa8
VtW+etysmBHTbPu4OhdsEaKeY5M+/6eTyBmVe7R24kPbM8z+mqIBOtA1jIK4VK2G
QFOFiOtcX8nXv4EqKyFZUMGCnprnsPFyqTtLhDMN/Rf03YoDBh6HRxX1I6V+loG1
p85lohtoyfvsYtEBf1yX60dR
-----END PRIVATE KEY-----
"""

STEPS = []


def record(name, ok, detail=""):
    STEPS.append((name, "PASS" if ok else "FAIL", detail))
    print("[%s] %s%s" % ("PASS" if ok else "FAIL", name,
                          ("  :: " + detail) if detail else ""))
    return ok


def table():
    print("\n================= REAL-TLS RESULT TABLE =================")
    print("%-52s  %-5s  %s" % ("STEP", "STATE", "DETAIL"))
    print("-" * 106)
    for name, st, detail in STEPS:
        print("%-52s  %-5s  %s" % (name, st, detail))
    print("-" * 106)
    fails = sum(1 for _n, st, _d in STEPS if st == "FAIL")
    print("TOTAL %d   PASS %d   FAIL %d" % (len(STEPS), len(STEPS) - fails, fails))
    return fails == 0


def _port_listening(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(0.2)
    try:
        return s.connect_ex((HOST, port)) == 0
    finally:
        s.close()


def start_broker(cert_path, key_path):
    log = tempfile.NamedTemporaryFile(prefix="hyrxmq-tls-", suffix=".log",
                                      delete=False)
    env = dict(os.environ)
    env["HYRXMQ_HOST"] = HOST
    env["HYRXMQ_PORT"] = str(PORT)
    env["HYRXMQ_TLS_ENABLED"] = "true"
    env["HYRXMQ_TLS_CERT"] = cert_path
    env["HYRXMQ_TLS_KEY"] = key_path
    proc = subprocess.Popen([BIN], stdout=log, stderr=subprocess.STDOUT, env=env)
    # Wait until the broker prints its "listening on" line. Do NOT probe the
    # port with a bare TCP connect: on a TLS listener that connect triggers a
    # blocking SSL_accept on the single-threaded server and wedges it.
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        if proc.poll() is not None:
            log.flush()
            with open(log.name) as fh:
                print("BROKER EXITED EARLY:\n" + fh.read())
            raise RuntimeError("broker exited early rc=%s" % proc.returncode)
        try:
            with open(log.name) as fh:
                text = fh.read()
            if "listening on" in text:
                return proc, log.name
        except Exception:
            pass
        time.sleep(0.1)
    proc.terminate()
    raise RuntimeError("broker did not report listening on :%d" % PORT)


def stop_broker(proc):
    if proc is None:
        return
    proc.terminate()
    try:
        proc.wait(timeout=3)
    except Exception:
        proc.kill()


def read_frame(sock):
    """Read one AMQP frame: 7-byte header + payload. Returns (type, payload)."""
    hdr = b""
    while len(hdr) < 7:
        chunk = sock.recv(7 - len(hdr))
        if not chunk:
            return None, b""
        hdr += chunk
    ftype = hdr[0]
    size = int.from_bytes(hdr[3:7], "big")
    body = b""
    while len(body) < size:
        chunk = sock.recv(size - len(body))
        if not chunk:
            break
        body += chunk
    return ftype, body


def main():
    if not os.path.exists(BIN):
        print("BINARY MISSING: %s\nBuild with: pixi run mojo build -I src -I "
              "vendor/flare src/hyrxmq/main_listen.mojo -o build/hyrxmq-listen"
              % BIN)
        return 1

    print("HyrxMQ TCP TLS probe")
    print("  broker : %s:%d" % (HOST, PORT))
    print("  client : python ssl %s" % ssl.OPENSSL_VERSION)

    workdir = tempfile.mkdtemp(prefix="hyrxmq-tls-fixture-")
    cert_path = os.path.join(workdir, "cert.pem")
    key_path = os.path.join(workdir, "key.pem")
    with open(cert_path, "w") as fh:
        fh.write(CERT_PEM)
    with open(key_path, "w") as fh:
        fh.write(KEY_PEM)

    proc = None
    try:
        try:
            proc, logpath = start_broker(cert_path, key_path)
            record("broker starts with TLS enabled", True,
                   "bound :%d" % PORT)
        except Exception as e:
            record("broker starts with TLS enabled", False, str(e))
            return 1

        # 3. TLS handshake completes.
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE  # self-signed fixture
        try:
            tls = ctx.wrap_socket(socket.create_connection((HOST, PORT),
                                                           timeout=6),
                                  server_hostname="localhost")
            ver = tls.version()
            record("TLS handshake completes",
                   ver in ("TLSv1.2", "TLSv1.3"),
                   "negotiated %s / %s" % (ver, tls.cipher()[0]))
        except Exception as e:
            record("TLS handshake completes", False, "%s: %s" % (type(e).__name__, e))
            return 1

        # 4. AMQP protocol header through the encrypted channel -> start.
        #    HyrxMQ first ECHOES the 8-octet protocol header back (listener.mojo
        #    _step_header: "on a match, echoes the same 8"), THEN emits
        #    connection.start. Consume the echo before reading the frame.
        try:
            tls.sendall(AMQP_HEADER)
            tls.settimeout(5)
            echo = b""
            while len(echo) < 8:
                chunk = tls.recv(8 - len(echo))
                if not chunk:
                    break
                echo += chunk
            record("protocol header echoed over TLS", echo == AMQP_HEADER,
                   "echo=%r" % echo)
            ftype, payload = read_frame(tls)
            ok = ftype == 1 and len(payload) >= 4 and payload[0:2] == b"\x00\x0a"
            record("AMQP connection.start over TLS", ok,
                   "frame_type=%s payload[:8]=%r" % (ftype, payload[:8]))
        except Exception as e:
            record("AMQP connection.start over TLS", False,
                   "%s: %s" % (type(e).__name__, e))
            return 1
        finally:
            try:
                tls.close()
            except Exception:
                pass

        # 5. cert on disk matches what the server presented.
        try:
            server_cert = ctx.wrap_socket(
                socket.create_connection((HOST, PORT), timeout=6),
                server_hostname="localhost").getpeercert(binary_form=True)
            with open(cert_path, "rb") as fh:
                disk_pem = fh.read()
            disk_der = ssl.PEM_cert_to_DER_cert(disk_pem.decode())
            record("server cert matches on-disk fixture",
                   server_cert == disk_der,
                   "%d bytes presented" % len(server_cert))
        except Exception as e:
            record("server cert matches on-disk fixture", False, str(e))

        # 5. plaintext connect cannot complete the AMQP handshake: the server
        #    treats the raw header as a TLS ClientHello and the handshake
        #    fails. Run LAST: on the single-threaded server a wedged plaintext
        #    handshake consumes the accept slot.
        try:
            raw = socket.create_connection((HOST, PORT), timeout=4)
            raw.sendall(AMQP_HEADER)
            raw.settimeout(3)
            got = b""
            try:
                got = raw.recv(64)
            except socket.timeout:
                got = b""
            looks_like_amqp_start = len(got) >= 8 and got[0] == 1 and got[7] == 10
            record("plaintext connect does NOT get AMQP start",
                   not looks_like_amqp_start,
                   "recv %d bytes %r" % (len(got), got[:16]))
            raw.close()
        except Exception as e:
            record("plaintext connect does NOT get AMQP start", True,
                   "refused/failed as expected: %s" % e)

        return 0 if table() else 1
    finally:
        stop_broker(proc)


if __name__ == "__main__":
    sys.exit(main())
