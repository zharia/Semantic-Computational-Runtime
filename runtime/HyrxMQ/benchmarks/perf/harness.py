"""Fair RabbitMQ-vs-HyrxMQ AMQP benchmark harness (pika 1.4.4, no new deps).

Everything is driven from ONE process, with the SAME pika version, ONE
connection to ONE broker at a time, strictly sequential — no concurrency on
either side (audit §19/§20).

Cells (matrix = cells x payloads):

    rabbit-tcp       reference RabbitMQ 4.x, live container, 127.0.0.1:5672
                     (DOCKER port-published: userspace proxy hop)
    hyrx-tcp-docker  HyrxMQ in a throwaway container on the SAME bridge,
                     published 127.0.0.1:5700 -> container:5700, mirroring the
                     rabbit publish. THE FAIR PAIR with rabbit-tcp: identical
                     network path, so the delta is the engine.
    hyrx-tcp-native  HyrxMQ as a host process on loopback (no proxy hop).
    hyrx-uds         HyrxMQ over AF_UNIX (HyrxMQ-only: RabbitMQ has no
                     Unix-socket listener, so this cell is compared against
                     hyrx-tcp-native, never against a fabricated RabbitMQ-UDS).

Workload (fixed, identical for every cell):

  * throughput: closed-loop publish -> basic_get(auto_ack) cycle of `count`
    fixed-size messages through an explicit direct exchange + binding, in
    batches of _BATCH so the queue depth never approaches our broker's 1024
    entry capacity (a full queue drops publishes SILENTLY, which would make a
    producer-only rate meaningless). 5% of each run is untimed warm-up; count is
    auto-tuned so a rep lasts >= _MIN_REP_SECONDS and a whole cell stays under
    --max-cell-seconds.
  * latency: publish -> get -> ack round trip, _LATENCY_OPS samples, percentiles.
  * floors: empty round trip (connection open+close, per rep) and, for TCP
    cells, a bare connect()/close() with no AMQP at all. Both raw and
    floor-subtracted numbers are reported.

Fair protocol config (identical bytes on both brokers, §48): ephemeral topology,
non-durable queue+exchange, auto_ack=True on the get so no per-message ack
round-trip (this measures routing + content + transport, NOT ack persistence),
delivery_mode=1, heartbeat=0, frame_max=131072, no publisher confirms,
x-expires so leftover queues die on their own. Ack correctness is proven
separately by scripts/interop/pika_content.py, not here (§30).

Usage (normally driven by run_all.sh):

    /tmp/amqp-venv/bin/python benchmarks/perf/harness.py --out /tmp/res.json
    ... --cells rabbit-tcp,hyrx-tcp-native --payloads 64,1024 --quick
"""
import argparse
import contextlib
import gc
import json
import os
import platform
import signal
import socket
import statistics
import subprocess
import sys
import time
from datetime import datetime, timezone

import pika

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)

import docker_hyrx  # noqa: E402  (local module, benchmarks/perf/)
from pika_uds import connect as uds_connect  # noqa: E402

HYRX_BIN = os.environ.get('HYRXMQ_BIN', os.path.join(ROOT, 'build',
                                                     'hyrxmq-listen'))
RABBIT_HOST = '127.0.0.1'
RABBIT_PORT = 5672
HYRX_DOCKER_PORT = 5700
HYRX_NATIVE_PORT = 5701
USER = os.environ.get('HYRX_USER', 'admin')
PW = os.environ.get('HYRX_PASS', 'password')
VHOST = '/'

PAYLOADS = (64, 256, 1024, 4096, 16384)
REPS = 5
WARMUP_FRAC = 0.05
_MIN_REP_SECONDS = 2.0
_BATCH = 256            # publish batch; keeps queue depth <= _BATCH < 1024
_PROBE_BATCH = 64       # smaller batch for the count-calibration probe
_LATENCY_OPS = 2000
TARGET_REP_SECONDS = 2.5

CELLS = ('rabbit-tcp', 'hyrx-tcp-docker', 'hyrx-tcp-native', 'hyrx-uds')

# Apples-to-apples protocol configuration (§19). Both brokers get the SAME
# pika Parameters; the values below are chosen so that neither broker pays a
# cost the other does not.
PROTOCOL = {
    'heartbeat': 0,             # HyrxMQ: no heartbeats; RabbitMQ: disabled
    'frame_max': 131072,        # both advertise/accept this
    'delivery_mode': 1,         # non-persistent: no disk write on either side
    'queue_durable': False,
    'exchange_durable': False,
    'auto_ack': True,           # get-with-ack: measures routing+content+net
    'publisher_confirms': False,
    'queue_x_expires_ms': 60000,
}


# ---------------------------------------------------------------------------
# cell endpoints
# ---------------------------------------------------------------------------

class Endpoint:
    """How to reach one broker cell, and how to (re)start it if needed."""

    def __init__(self, cell):
        self.cell = cell
        self.kind = 'uds' if cell == 'hyrx-uds' else 'tcp'
        self.host = RABBIT_HOST
        self.port = {'rabbit-tcp': RABBIT_PORT,
                     'hyrx-tcp-docker': HYRX_DOCKER_PORT,
                     'hyrx-tcp-native': HYRX_NATIVE_PORT}.get(cell)
        self.uds_path = ''
        if cell == 'hyrx-uds':
            self.uds_path = os.environ.get('HYRX_BENCH_UDS',
                                           f'/tmp/hyrx-bench-{os.getpid()}.sock')
        self.proc = None
        self.proc_env = None
        self.container = None
        self.restarts = 0

    # -- lifecycle ----------------------------------------------------------
    def start(self):
        cell = self.cell
        if cell == 'rabbit-tcp':
            # NEVER started/stopped/reconfigured by this harness: it must
            # already be up. We only connect to it.
            if not self._wait_tcp(timeout=5):
                raise RuntimeError(f'RabbitMQ not reachable at '
                                   f'{self.host}:{self.port} (expected the live '
                                   f'node-rabbitmq container)')
            return
        if cell == 'hyrx-tcp-docker':
            self.container = docker_hyrx.ensure_fair_cell(port=HYRX_DOCKER_PORT)
            return
        # native process cells: HYRXMQ_FRAME_MAX is both the advertised tune
        # value and the codec ceiling (src/hyrxmq/main_listen.mojo).
        env = dict(os.environ, HYRXMQ_FRAME_MAX=str(PROTOCOL['frame_max']))
        if cell == 'hyrx-tcp-native':
            env.update(HYRXMQ_PORT=str(self.port), HYRXMQ_HOST='127.0.0.1')
        else:
            if self.uds_path and os.path.exists(self.uds_path):
                os.unlink(self.uds_path)
            env.update(HYRXMQ_UDS_PATH=self.uds_path)
        log = open(f'/tmp/hyrx-bench-{cell}.log', 'w')
        self.proc = subprocess.Popen([HYRX_BIN], env=env, stdout=log,
                                     stderr=subprocess.STDOUT)
        deadline = time.time() + 15
        while time.time() < deadline:
            if self.proc.poll() is not None:
                raise RuntimeError(f'{HYRX_BIN} exited immediately (rc='
                                   f'{self.proc.returncode}); see {log.name}')
            if cell == 'hyrx-uds':
                if os.path.exists(self.uds_path) and self._probe_uds():
                    break
            elif self._wait_tcp(timeout=0.5):
                break
            time.sleep(0.1)
        else:
            raise RuntimeError(f'{cell} did not become reachable; see {log.name}')

    def stop(self):
        if self.proc is not None:
            for sig in (signal.SIGTERM, signal.SIGKILL):
                try:
                    self.proc.send_signal(sig)
                except Exception:
                    pass
                try:
                    self.proc.wait(timeout=3)
                    break
                except Exception:
                    continue
            self.proc = None
        if self.uds_path and os.path.exists(self.uds_path):
            try:
                os.unlink(self.uds_path)
            except OSError:
                pass
        if self.container is not None:
            docker_hyrx.down()
            self.container = None

    def alive(self):
        """Cheap reachability probe; used to decide whether to restart."""
        if self.cell == 'hyrx-uds':
            return os.path.exists(self.uds_path) and self._probe_uds()
        return self._wait_tcp(timeout=1.0)

    def _probe_uds(self):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.settimeout(1.0)
            s.connect(self.uds_path)
            s.close()
            return True
        except OSError:
            return False

    def _wait_tcp(self, timeout):
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                s = socket.create_connection((self.host, self.port),
                                             timeout=0.4)
                s.close()
                return True
            except OSError:
                # refused / again / host-down / no-socket: keep waiting until
                # the deadline, then report unreachable (never assume "up")
                time.sleep(0.15)
        return False

    # -- connection ---------------------------------------------------------
    def parameters(self):
        return pika.ConnectionParameters(
            host=self.host, port=self.port or 1, virtual_host=VHOST,
            credentials=pika.PlainCredentials(USER, PW),
            heartbeat=PROTOCOL['heartbeat'], frame_max=PROTOCOL['frame_max'],
            channel_max=1, connection_attempts=1, blocked_connection_timeout=5,
            socket_timeout=10, stack_timeout=20)

    def connect(self):
        """Fresh single connection to this cell (never more than one at a time).
        If the connection is wedged or closed, raise ConnectionFailed so the
        caller can restart the cell process (our broker serves one connection
        at a time and does not negotiate heartbeats)."""
        try:
            if self.kind == 'uds':
                return uds_connect(self.uds_path, self.parameters())
            return pika.BlockingConnection(self.parameters())
        except Exception as exc:
            raise ConnectionFailed(f'{self.cell}: {type(exc).__name__}: {exc}')

    def describe(self):
        d = {'kind': self.kind, 'host': self.host, 'port': self.port,
             'uds_path': self.uds_path,
             'via': {'rabbit-tcp': 'docker port-publish (userspace proxy)',
                     'hyrx-tcp-docker': 'docker port-publish (userspace proxy)',
                     'hyrx-tcp-native': 'native loopback',
                     'hyrx-uds': 'AF_UNIX socket'}[self.cell]}
        if self.container:
            d['container'] = self.container
        return d


class ConnectionFailed(Exception):
    pass


class CellTimeout(Exception):
    """Watchdog: a stage that exceeded its budget (recorded, never faked)."""


@contextlib.contextmanager
def bounded(seconds, what):
    """SIGALRM watchdog around a blocking stage: pika's blocking calls have no
    per-call timeout once the connection is up."""

    def _fire(signum, frame):  # pragma: no cover - async signal handler
        raise CellTimeout(f'{what} exceeded {seconds}s')

    previous = signal.signal(signal.SIGALRM, _fire)
    signal.setitimer(signal.ITIMER_REAL, seconds)
    try:
        yield
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous)


# ---------------------------------------------------------------------------
# measurement primitives
# ---------------------------------------------------------------------------

_TAG_STATE = {'n': 0}


def _uniq():
    """Per-attempt unique topology name (an exclusive queue is locked to its
    connection, and a force-closed connection may still be finishing its
    cleanup on RabbitMQ, so reusing a name across reps is RESOURCE_LOCKED)."""
    _TAG_STATE['n'] += 1
    return f'{os.getpid()}-{_TAG_STATE["n"]}-{time.time_ns()}'


def _mkbody(payload):
    """Deterministic bytes; a wrong body is obvious (not random, so a
    mis-slice cannot accidentally match)."""
    return bytes((i * 31 + 7) & 0xFF for i in range(payload))


def _open_topology(conn, ep, tag):
    """Identical declare sequence for every cell."""
    ch = conn.channel()
    qname = f'bench.{ep.cell}.{tag}'
    xname = f'benchx.{ep.cell}.{tag}'
    ch.exchange_declare(exchange=xname, exchange_type='direct',
                        durable=PROTOCOL['exchange_durable'],
                        auto_delete=True)
    ch.queue_declare(queue=qname, durable=PROTOCOL['queue_durable'],
                     exclusive=True, auto_delete=True,
                     arguments={'x-expires': PROTOCOL['queue_x_expires_ms']})
    ch.queue_bind(queue=qname, exchange=xname, routing_key='rk')
    return ch, qname, xname


def _close(conn, ch):
    """Drop the connection by closing the fd on EVERY cell.

    Our broker does not implement channel.close-ok / connection.close-ok
    (src/hyrxmq/amqp_service.mojo:27), so a graceful pika close blocks forever
    there; using the same abrupt teardown on both brokers keeps the two sides
    byte-symmetric and keeps connection teardown out of every timed window.
    """
    _force_socket_close(conn)


def _force_socket_close(conn):
    """Close the raw socket under the connection (frees the single-at-a-time
    server accept loop: its next recv returns 0)."""
    try:
        impl = getattr(conn, '_impl', None)
        transport = getattr(impl, '_transport', None) if impl else None
        sock = getattr(transport, '_sock', None) if transport else None
        if sock is not None:
            try:
                sock.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            sock.close()
    except Exception:
        pass


def _props():
    return pika.BasicProperties(delivery_mode=PROTOCOL['delivery_mode'],
                                content_type='application/octet-stream')


def throughput_run(ep, payload, count, batch=_BATCH, verify=True):
    """Closed-loop publish -> get(auto_ack) cycle for `count` messages.

    Returns a dict with wall seconds, msgs/sec, delivered count, body-verified
    flag and the empty-round-trip (connect/open/close) floor of this rep.
    Raises ConnectionFailed if the broker cannot be reached.
    """
    body = _mkbody(payload)
    t_open0 = time.perf_counter()
    conn = ep.connect()
    ch, qname, xname = _open_topology(conn, ep, f'tp{payload}.{_uniq()}')
    t_open1 = time.perf_counter()

    warm = int(count * WARMUP_FRAC)
    mismatch = []
    try:
        # untimed warm-up: same publish/drain shape as the timed window
        for i in range(warm):
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
            if (i + 1) % batch == 0:
                _drain(ch, qname, batch, body, mismatch)
        if warm % batch:
            _drain(ch, qname, warm % batch, body, mismatch)

        t0 = time.perf_counter()
        done = 0
        while done < count:
            n = min(batch, count - done)
            for _ in range(n):
                ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                                 properties=_props())
            _drain(ch, qname, n, body if verify else None, mismatch)
            done += n
        t1 = time.perf_counter()
    finally:
        _close(conn, ch)

    wall = t1 - t0
    return {
        'payload': payload,
        'count': count,
        'batch': batch,
        'warmup_msgs': warm,
        'wall_s': round(wall, 6),
        'msgs_per_s': round(count / wall, 1) if wall > 0 else 0.0,
        'bytes_per_s': round((count * payload) / wall, 1) if wall > 0 else 0.0,
        'delivered': count,
        'body_mismatch': len(mismatch),
        'empty_round_trip_us': round((t_open1 - t_open0) * 1e6, 1),
        'max_queue_depth': batch,
    }


def _drain(ch, qname, n, expect_body, mismatch):
    """Get exactly n messages with auto_ack.

    An under-delivery means a silent drop at the 1024-entry queue capacity or a
    wedged server, and every rate measured after that would be meaningless, so
    it raises rather than reporting a number.
    """
    got = 0
    deadline = time.time() + 30
    while got < n:
        if time.time() > deadline:
            raise ConnectionFailed(f'{qname}: only {got}/{n} messages delivered '
                                   f'in 30 s (wedged or dropped?)')
        method, _props_got, body = ch.basic_get(queue=qname, auto_ack=True)
        if method is None:
            time.sleep(0.0002)
            continue
        if expect_body is not None and body != expect_body:
            mismatch.append(got)
        got += 1
    return got


def latency_run(ep, payload, ops=_LATENCY_OPS):
    """publish -> get -> ack round-trip latency samples (per-op microseconds).

    Explicit ack here (auto_ack=False + basic_ack), unlike the throughput cell:
    this is the "the ack path works at all" + RTT measurement, one message in
    flight. Ack correctness on both brokers is proven separately by
    scripts/interop/pika_content.py (§30); the rate benchmark deliberately
    excludes it.
    """
    body = _mkbody(payload)
    conn = ep.connect()
    ch, qname, xname = _open_topology(conn, ep, f'lat{payload}.{_uniq()}')
    samples = []
    try:
        for _ in range(ops):
            t0 = time.perf_counter()
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
            method, _p, got = ch.basic_get(queue=qname, auto_ack=False)
            if method is not None:
                ch.basic_ack(delivery_tag=method.delivery_tag)
            t1 = time.perf_counter()
            if method is None:
                raise ConnectionFailed('basic_get returned empty on a queue we '
                                       'just published to')
            if got != body:
                raise AssertionError('latency body mismatch')
            samples.append((t1 - t0) * 1e6)
    finally:
        _close(conn, ch)
    return {'payload': payload, 'ops': ops, 'samples_us': samples,
            'summary': _pct_summary(samples)}


def floor_run(ep, ops=50):
    """Three floors, all measured, none assumed.

    amqp_open_close : connect + AMQP handshake + teardown, no traffic.
    bare_connect    : raw TCP (or AF_UNIX) connect + close, NO AMQP at all —
                      the transport-only part of the floor above, and the
                      docker-proxy tax when taken through a published port.
    empty_get       : get-empty method round trip on an ESTABLISHED connection:
                      the per-message latency floor (no content frame, no
                      routing), which is what the latency cell is subtracted by.
    """
    samples = []
    for _ in range(ops):
        t0 = time.perf_counter()
        conn = ep.connect()
        _close(conn, None)
        samples.append((time.perf_counter() - t0) * 1e6)
    out = {'kind': 'amqp_open_close', 'ops': ops, 'samples_us': samples,
           'summary': _pct_summary(samples)}
    empty = []
    conn = ep.connect()
    ch, qname, xname = _open_topology(conn, ep, f'floor.{_uniq()}')
    try:
        for _ in range(200):
            t0 = time.perf_counter()
            ch.basic_get(queue=qname, auto_ack=True)
            empty.append((time.perf_counter() - t0) * 1e6)
    finally:
        _close(conn, ch)
    out['empty_get'] = {'ops': len(empty), 'samples_us': empty,
                        'summary': _pct_summary(empty)}
    if ep.kind == 'tcp':
        bare = []
        for _ in range(ops):
            t0 = time.perf_counter()
            s = socket.create_connection((ep.host, ep.port), timeout=5)
            s.close()
            bare.append((time.perf_counter() - t0) * 1e6)
        out['bare_tcp_connect'] = {'ops': ops, 'samples_us': bare,
                                   'summary': _pct_summary(bare)}
    else:
        bare = []
        for _ in range(ops):
            t0 = time.perf_counter()
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(ep.uds_path)
            s.close()
            bare.append((time.perf_counter() - t0) * 1e6)
        out['bare_uds_connect'] = {'ops': ops, 'samples_us': bare,
                                   'summary': _pct_summary(bare)}
    return out


def _pct_summary(samples):
    if not samples:
        return {}
    xs = sorted(samples)

    def pct(q):
        if len(xs) == 1:
            return xs[0]
        idx = min(len(xs) - 1, max(0, int(round(q * (len(xs) - 1)))))
        return xs[idx]

    return {'n': len(xs), 'p50_us': round(pct(0.50), 3),
            'p95_us': round(pct(0.95), 3), 'p99_us': round(pct(0.99), 3),
            'p99_9_us': round(pct(0.999), 3),
            'mean_us': round(statistics.fmean(xs), 3),
            'min_us': round(xs[0], 3), 'max_us': round(xs[-1], 3)}


def _calibrate(ep, payload, cap_seconds, quick=False):
    """Pick a message count so one rep lasts >= _MIN_REP_SECONDS and the whole
    cell stays under cap_seconds. Measured, never assumed."""
    probe_count = 400 if quick else 1500
    rate = None
    for _ in range(3):
        try:
            r = throughput_run(ep, payload, probe_count, batch=_PROBE_BATCH,
                               verify=False)
            rate = r['msgs_per_s']
            break
        except ConnectionFailed:
            _restart(ep)
    if rate is None or rate <= 0:
        raise RuntimeError(f'{ep.cell}: calibration failed at payload {payload}')
    count = int(rate * TARGET_REP_SECONDS)
    count = max(probe_count, count)
    per_rep = count / rate
    reps = REPS
    while per_rep * reps > cap_seconds and reps > 2:
        reps -= 1
    while per_rep * reps > cap_seconds and count > probe_count:
        count = int(count * 0.8)
        per_rep = count / rate
    return count, reps, rate


def _restart(ep):
    """Restart a native/UDS cell process after a wedge (never the rabbit or a
    container: those are torn down and rebuilt by their own paths)."""
    if ep.cell in ('hyrx-tcp-native', 'hyrx-uds'):
        ep.stop()
        ep.start()
        ep.restarts += 1
        return True
    return False


# ---------------------------------------------------------------------------
# host signature
# ---------------------------------------------------------------------------

def _rabbit_version():
    """Read-only GET /api/overview on the live management listener (15672).
    Falls back to parsing `rabbitmqctl status`. Neither writes anything: the
    reference broker is never reconfigured, restarted or stopped here."""
    import base64
    import json as _json
    import urllib.request
    try:
        req = urllib.request.Request('http://127.0.0.1:15672/api/overview')
        req.add_header('Authorization', 'Basic ' + base64.b64encode(
            f'{USER}:{PW}'.encode()).decode())
        with urllib.request.urlopen(req, timeout=5) as resp:
            return _json.load(resp).get('rabbitmq_version')
    except Exception:
        status = sh_docker('docker', 'exec', 'node-rabbitmq', 'rabbitmqctl',
                           'status')
        if not status:
            return None
        return status.split('RabbitMQ version:')[-1].splitlines()[0] \
            .strip().rstrip(',')


def sh_docker(*args):
    try:
        return subprocess.run(list(args), capture_output=True, text=True,
                              timeout=20).stdout.strip()
    except Exception:
        return None


def host_signature():
    def sh(*args):
        try:
            return subprocess.run(list(args), capture_output=True, text=True,
                                  timeout=10).stdout.strip()
        except Exception:
            return None

    cpu = None
    try:
        with open('/proc/cpuinfo') as fh:
            for line in fh:
                if line.startswith('model name'):
                    cpu = line.split(':', 1)[1].strip()
                    break
    except OSError:
        pass
    return {
        'cpu_model': cpu,
        'nproc': os.cpu_count(),
        'kernel': platform.release(),
        'machine': platform.machine(),
        'python': platform.python_version(),
        'pika_version': pika.__version__,
        'rabbit_image': sh('docker', 'inspect', '-f', '{{.Config.Image}}',
                           'node-rabbitmq'),
        'rabbit_version': _rabbit_version(),
        'hyrxmq_git_head': sh('git', '-C', ROOT, 'rev-parse', '--short', 'HEAD'),
        'governor': sh('cat', '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'),
        'loadavg_1m': round(os.getloadavg()[0], 2),
    }


# ---------------------------------------------------------------------------
# driver
# ---------------------------------------------------------------------------

def run_cell(cell, payloads, cap_seconds, quick=False):
    ep = Endpoint(cell)
    out = {'endpoint': None, 'status': 'pending', 'reps': REPS,
           'restarts': 0, 'throughput': {}, 'latency': {}, 'floor': {}}
    print(f'=== CELL {cell} ===', flush=True)
    try:
        ep.start()
    except Exception as exc:
        msg = f'{type(exc).__name__}: {exc}'
        print(f'  BLOCKED at start: {msg}', flush=True)
        out.update(status='BLOCKED', error=msg)
        try:  # never leave the throwaway container/image behind on a BLOCKED cell
            ep.stop()
            if cell == 'hyrx-tcp-docker':
                docker_hyrx.down()
        except Exception:
            pass
        return out
    out['endpoint'] = ep.describe()
    try:
        with bounded(120, f'{cell} floors'):
            out['floor'] = floor_run(ep)
        print(f'  floor amqp_open_close p50='
              f'{out["floor"]["summary"]["p50_us"]}us', flush=True)
        for payload in payloads:
            with bounded(120, f'{cell} calibrate {payload}B'):
                count, reps, est = _calibrate(ep, payload, cap_seconds, quick)
            rows = []
            for rep in range(reps):
                if not ep.alive():
                    _restart(ep)
                for attempt in (0, 1):
                    try:
                        with bounded(max(30.0, cap_seconds),
                                     f'{cell} {payload}B rep{rep}'):
                            rows.append(throughput_run(ep, payload, count))
                        break
                    except (ConnectionFailed, CellTimeout) as exc:
                        if attempt or not _restart(ep):
                            raise
                        print(f'  retry {payload}B rep{rep} after restart: '
                              f'{type(exc).__name__}: {exc}', flush=True)
            rates = [r['msgs_per_s'] for r in rows]
            rtts = [r['empty_round_trip_us'] for r in rows]
            out['throughput'][str(payload)] = {
                'count': count, 'reps': reps, 'calibrated_rate': round(est, 1),
                'rates': [round(r, 1) for r in rates],
                'median_msgs_per_s': round(statistics.median(rates), 1),
                'min_msgs_per_s': round(min(rates), 1),
                'max_msgs_per_s': round(max(rates), 1),
                'spread_pct': round(100 * (max(rates) - min(rates))
                                    / statistics.median(rates), 2)
                if len(rates) > 1 else 0.0,
                'empty_round_trip_p50_us': round(statistics.median(rtts), 1),
                'all_verified': all(r['body_mismatch'] == 0 and
                                    r['delivered'] == r['count'] for r in rows),
                'per_rep': rows,
            }
            print(f'  {payload:>6}B count={count:<7} '
                  f'{statistics.median(rates):>10.0f} msg/s '
                  f'(spread {out["throughput"][str(payload)]["spread_pct"]:.1f}%)',
                  flush=True)
        lp = 256 if not quick else 64
        with bounded(180, f'{cell} latency {lp}B'):
            out['latency'] = {str(lp): latency_run(
                ep, lp, 600 if quick else _LATENCY_OPS)}
        out['status'] = 'OK'
    except Exception as exc:
        out.update(status='FAILED', error=f'{type(exc).__name__}: {exc}')
        import traceback
        traceback.print_exc()
    finally:
        out['restarts'] = ep.restarts
        ep.stop()
    return out


def main():
    ap = argparse.ArgumentParser(description='fair AMQP benchmark harness')
    ap.add_argument('--cells', default=','.join(CELLS))
    ap.add_argument('--payloads', default=','.join(str(p) for p in PAYLOADS))
    ap.add_argument('--out', default=os.path.join(ROOT, 'benchmarks', 'perf',
                                                 'results.json'))
    ap.add_argument('--max-cell-seconds', type=float, default=90.0)
    ap.add_argument('--quick', action='store_true',
                    help='smallest useful matrix (dev smoke test)')
    args = ap.parse_args()

    cells = [c for c in args.cells.split(',') if c]
    payloads = [int(p) for p in args.payloads.split(',')]
    for cell in cells:
        if cell not in CELLS:
            ap.error(f'unknown cell {cell!r}; choose from {CELLS}')

    sig = host_signature()
    print('HOST', json.dumps(sig), flush=True)
    started = datetime.now(timezone.utc).isoformat()
    t_all = time.time()
    result = {
        'schema': 1,
        'started_utc': started,
        'host': sig,
        'protocol': PROTOCOL,
        'method': {
            'throughput': 'closed-loop publish -> basic_get(auto_ack) cycle, '
                          f'batch<={_BATCH} msgs in flight (queue depth bound '
                          'for the 1024-entry capacity of the reference-free '
                          'broker), 5% warm-up, count auto-calibrated per '
                          'cell/payload',
            'latency': 'publish -> get -> ack round trip, one msg in flight',
            'floor': 'connection open+close (all cells) and bare '
                     'TCP/UDS connect+close with no AMQP at all',
            'single_connection': 'one connection per broker at a time, '
                                 'sequential, same process, same pika',
        },
        'cells': {},
    }
    for cell in cells:
        cap = args.max_cell_seconds
        result['cells'][cell] = run_cell(cell, payloads, cap, quick=args.quick)
        # save after every cell: a cell that dies must not lose the cells that
        # already measured.
        with open(args.out, 'w') as fh:
            json.dump(result, fh, indent=1)
        gc.collect()
        time.sleep(0.5)  # let the previous cell's socket/accept state settle
    result['duration_s'] = round(time.time() - t_all, 1)
    result['finished_utc'] = datetime.now(timezone.utc).isoformat()

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, 'w') as fh:
        json.dump(result, fh, indent=1)
    print(f'WROTE {args.out} ({result["duration_s"]}s)', flush=True)

    bad = [c for c, r in result['cells'].items() if r['status'] != 'OK']
    if bad:
        print('NON-OK CELLS: ' + ', '.join(f'{c}={result["cells"][c]["status"]}'
                                           for c in bad))
    return 0


if __name__ == '__main__':
    sys.exit(main())
