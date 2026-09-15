#!/usr/bin/env python3
"""Fair three-broker AMQP benchmark: HyrxMQ vs RabbitMQ vs LavinMQ.

Methodology is deliberately identical on every broker so the measured delta is
the engine, not the setup:

  * all brokers live in their own container on ONE user-defined bridge,
    published to 127.0.0.1, so every client connection crosses the SAME
    docker-proxy (userspace) hop;
  * each container gets the SAME --cpus/--memory cap;
  * ONE pika version, ONE connection to ONE broker at a time (except the
    explicit concurrency workload, where each pair owns its own connection);
  * identical protocol config: ephemeral (auto_delete, non-durable,
    exclusive) direct/fanout exchange + queue + binding, delivery_mode=1,
    heartbeat=0, frame_max=131072, auto_ack=True on the throughput basic_get;
  * every cell is health-gated by the same pika connect + channel open before a
    single number is recorded;
  * the first 10% of every timed rep is discarded as warm-up; >=5 reps per
    cell; the MEDIAN is reported;
  * brokers are run in a rotated order across reps to spread order/thermal
    bias;
  * CPU% and RSS are sampled from `docker stats --no-stream` during each rep.

The harness does NOT start or stop brokers. The driver (run_three_broker.sh)
owns the containers and the network; this process only connects.

Usage:
    /tmp/amqp-venv/bin/python harness.py --out-dir results [--quick]
        [--brokers hyrxmq,rabbitmq,lavinmq] [--reps 5]
        [--payloads 64,1024,16384,65536,262144] [--workloads all]
"""
import argparse
import contextlib
import gc
import json
import os
import re
import signal
import socket
import statistics
import subprocess
import sys
import threading
import time
from datetime import datetime, timezone

import pika

HERE = os.path.dirname(os.path.abspath(__file__))

USER = 'admin'
PW = 'password'
VHOST = '/'

# Identical on every broker. `exclusive=True` is required: RabbitMQ 4.x refuses
# transient NON-exclusive queues (`transient_nonexcl_queues` deprecated) by
# default, and an exclusive+auto-delete queue is still fully ephemeral.
PROTOCOL = {
    'heartbeat': 0,
    'frame_max': 131072,
    'delivery_mode': 1,
    'auto_ack': True,
    'durable': False,
    'auto_delete': True,
    'exclusive': True,
}

BROKERS = {
    'hyrxmq': {'name': 'hyrxmq', 'label': 'HyrxMQ', 'host': '127.0.0.1',
               'port': 5711, 'container': 'hyrxmq-bench-hyrx'},
    'rabbitmq': {'name': 'rabbitmq', 'label': 'RabbitMQ', 'host': '127.0.0.1',
                 'port': 5712, 'container': 'hyrxmq-bench-rabbit'},
    'lavinmq': {'name': 'lavinmq', 'label': 'LavinMQ', 'host': '127.0.0.1',
                'port': 5713, 'container': 'hyrxmq-bench-lavin'},
}
BROKER_ORDER = ('hyrxmq', 'rabbitmq', 'lavinmq')

FULL_PAYLOADS = (64, 1024, 16384, 65536, 262144)
QUICK_PAYLOADS = (1024,)
FULL_CONC = (1, 4, 16)
QUICK_CONC = (1, 16)
ALL_WORKLOADS = ('publish_get', 'publish_only', 'latency', 'confirms',
                 'fanout', 'concurrency')

REPS = 5
QUICK_REPS = 3
WARMUP_FRAC = 0.10
TARGET_REP_SECONDS = 2.0
BATCH = 128
CONFIRM_BATCH = 64
FANOUT_QS = 4
FANOUT_BATCH = 64
CONC_BATCH = 64
LATENCY_MIN_OPS = 300


class ConnectionFailed(Exception):
    pass


class CellTimeout(Exception):
    pass


@contextlib.contextmanager
def bounded(seconds, what):
    """SIGALRM watchdog around a blocking stage (pika blocking calls have no
    per-call timeout once the connection is up)."""

    def _fire(signum, frame):
        raise CellTimeout(f'{what} exceeded {seconds}s')

    previous = signal.signal(signal.SIGALRM, _fire)
    signal.setitimer(signal.ITIMER_REAL, seconds)
    try:
        yield
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous)


_TAG_STATE = {'n': 0}


def _uniq():
    _TAG_STATE['n'] += 1
    return f'{os.getpid()}-{_TAG_STATE["n"]}-{time.time_ns()}'


def _mkbody(payload):
    return bytes((i * 31 + 7) & 0xFF for i in range(payload))


def _props():
    return pika.BasicProperties(delivery_mode=PROTOCOL['delivery_mode'],
                                content_type='application/octet-stream')


def _connect(spec, socket_timeout=10, stack_timeout=None):
    params = pika.ConnectionParameters(
        host=spec['host'], port=spec['port'], virtual_host=VHOST,
        credentials=pika.PlainCredentials(USER, PW),
        heartbeat=PROTOCOL['heartbeat'], frame_max=PROTOCOL['frame_max'],
        connection_attempts=1, socket_timeout=socket_timeout,
        stack_timeout=(stack_timeout if stack_timeout is not None
                       else socket_timeout + 10),
        blocked_connection_timeout=10)
    try:
        return pika.BlockingConnection(params)
    except Exception as exc:
        raise ConnectionFailed(f'{spec["name"]}: {type(exc).__name__}: {exc}')


def _force_socket_close(conn):
    """Close the raw socket under the connection. HyrxMQ does not implement
    connection.close-ok, so a graceful pika close can block; the same abrupt
    teardown is used on every broker (teardown is outside every timed window
    anyway)."""
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


def _open_direct(ch, tag):
    qname = f'bench.{tag}.q'
    xname = f'bench.{tag}.x'
    ch.exchange_declare(exchange=xname, exchange_type='direct',
                        durable=PROTOCOL['durable'],
                        auto_delete=PROTOCOL['auto_delete'])
    ch.queue_declare(queue=qname, durable=PROTOCOL['durable'],
                     exclusive=PROTOCOL['exclusive'],
                     auto_delete=PROTOCOL['auto_delete'])
    ch.queue_bind(queue=qname, exchange=xname, routing_key='rk')
    return xname, qname


def _drain(ch, qname, n, expect_body, mismatch, deadline_s=30):
    got = 0
    deadline = time.time() + deadline_s
    while got < n:
        if time.time() > deadline:
            raise ConnectionFailed(
                f'{qname}: only {got}/{n} messages delivered in {deadline_s}s '
                f'(wedged or silently dropped?)')
        method, _p, body = ch.basic_get(queue=qname, auto_ack=True)
        if method is None:
            time.sleep(0.0002)
            continue
        if expect_body is not None and body != expect_body:
            mismatch.append(got)
        got += 1
    return got


def _publish_drain(ch, xname, qname, body, n, batch, expect_body, mismatch):
    done = 0
    while done < n:
        b = min(batch, n - done)
        for _ in range(b):
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
        _drain(ch, qname, b, expect_body, mismatch)
        done += b


# ---------------------------------------------------------------------------
# workload implementations
# ---------------------------------------------------------------------------

def run_publish_get(spec, payload, count):
    """Closed-loop publish -> basic_get(auto_ack), batched so queue depth stays
    <= BATCH. Measures routing + content + transport, not the ack path."""
    body = _mkbody(payload)
    mismatch = []
    conn = _connect(spec)
    try:
        ch = conn.channel()
        xname, qname = _open_direct(ch, f'pg.{payload}.{_uniq()}')
        warm = int(count * WARMUP_FRAC)
        _publish_drain(ch, xname, qname, body, warm, BATCH, None, mismatch)
        t0 = time.perf_counter()
        _publish_drain(ch, xname, qname, body, count, BATCH, body, mismatch)
        t1 = time.perf_counter()
    finally:
        _force_socket_close(conn)
    wall = t1 - t0
    return {'msgs_per_s': count / wall if wall > 0 else 0.0,
            'wall_s': wall, 'count': count, 'payload': payload,
            'body_mismatch': len(mismatch),
            'all_verified': len(mismatch) == 0}


def run_publish_only(spec, payload, count):
    """Fire-and-forget publish to an exchange with NO bound queue: this isolates
    the producer-side protocol/transport ceiling with no queue growth and no
    drain. `basic_publish` flushes output on every call, so the socket (and
    broker) see every frame."""
    body = _mkbody(payload)
    conn = _connect(spec)
    try:
        ch = conn.channel()
        xname = f'bench.po.{_uniq()}.x'
        ch.exchange_declare(exchange=xname, exchange_type='direct',
                            durable=PROTOCOL['durable'],
                            auto_delete=PROTOCOL['auto_delete'])
        for _ in range(int(count * WARMUP_FRAC)):
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
        t0 = time.perf_counter()
        for _ in range(count):
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
        t1 = time.perf_counter()
    finally:
        _force_socket_close(conn)
    wall = t1 - t0
    return {'msgs_per_s': count / wall if wall > 0 else 0.0,
            'wall_s': wall, 'count': count, 'payload': payload,
            'failed_msgs': 0}


def run_latency(spec, payload, ops):
    """publish -> get -> ack round trip, one message in flight; per-op us."""
    body = _mkbody(payload)
    conn = _connect(spec)
    samples = []
    try:
        ch = conn.channel()
        xname, qname = _open_direct(ch, f'lat.{payload}.{_uniq()}')
        warm = int(ops * WARMUP_FRAC)
        for _ in range(warm):
            t0 = time.perf_counter()
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
            method, _p, got = ch.basic_get(queue=qname, auto_ack=False)
            if method is not None:
                ch.basic_ack(delivery_tag=method.delivery_tag)
            t1 = time.perf_counter()
        for _ in range(ops):
            t0 = time.perf_counter()
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
            method, _p, got = ch.basic_get(queue=qname, auto_ack=False)
            if method is None:
                raise ConnectionFailed('basic_get returned empty on a queue we '
                                       'just published to')
            if got != body:
                raise AssertionError('latency body mismatch')
            ch.basic_ack(delivery_tag=method.delivery_tag)
            t1 = time.perf_counter()
            samples.append((t1 - t0) * 1e6)
    finally:
        _force_socket_close(conn)
    return {'msgs_per_s': ops / (sum(samples) / 1e6) if samples and
            sum(samples) > 0 else 0.0,
            'ops': ops, 'payload': payload, 'samples_us': samples,
            'summary': _pct_summary(samples)}


def run_confirms(spec, payload, count):
    """confirm_select; publish and block on each confirm. Only the
    confirm-publish span is timed; the drain that keeps the queue bounded runs
    outside the timed window."""
    body = _mkbody(payload)
    conn = _connect(spec)
    try:
        ch = conn.channel()
        xname, qname = _open_direct(ch, f'cf.{payload}.{_uniq()}')
        ch.confirm_delivery()
        warm = int(count * WARMUP_FRAC)
        _confirm_block(ch, xname, qname, body, warm, CONFIRM_BATCH, timed=None)
        acc = [0.0]
        _confirm_block(ch, xname, qname, body, count, CONFIRM_BATCH, timed=acc)
    finally:
        _force_socket_close(conn)
    wall = acc[0]
    return {'msgs_per_s': count / wall if wall > 0 else 0.0,
            'wall_s': wall, 'count': count, 'payload': payload}


def _confirm_block(ch, xname, qname, body, n, batch, timed):
    done = 0
    while done < n:
        b = min(batch, n - done)
        t0 = time.perf_counter()
        for _ in range(b):
            ch.basic_publish(exchange=xname, routing_key='rk', body=body,
                             properties=_props())
        t1 = time.perf_counter()
        if timed is not None:
            timed[0] += t1 - t0
        _drain(ch, qname, b, None, [])
        done += b


def run_fanout(spec, payload, count):
    """1 fanout exchange -> FANOUT_QS bound queues. Reports delivered msgs/s
    (count*FANOUT_QS) and the publish msgs/s."""
    body = _mkbody(payload)
    conn = _connect(spec)
    try:
        ch = conn.channel()
        tag = _uniq()
        xname = f'bench.fan.{tag}.x'
        ch.exchange_declare(exchange=xname, exchange_type='fanout',
                            durable=PROTOCOL['durable'],
                            auto_delete=PROTOCOL['auto_delete'])
        qnames = []
        for i in range(FANOUT_QS):
            qn = f'bench.fan.{tag}.{i}'
            ch.queue_declare(queue=qn, durable=PROTOCOL['durable'],
                             exclusive=PROTOCOL['exclusive'],
                             auto_delete=PROTOCOL['auto_delete'])
            ch.queue_bind(queue=qn, exchange=xname, routing_key='')
            qnames.append(qn)
        warm = int(count * WARMUP_FRAC)
        _fanout_publish_drain(ch, xname, qnames, body, warm, FANOUT_BATCH)
        t0 = time.perf_counter()
        _fanout_publish_drain(ch, xname, qnames, body, count, FANOUT_BATCH)
        t1 = time.perf_counter()
    finally:
        _force_socket_close(conn)
    wall = t1 - t0
    delivered = count * FANOUT_QS
    return {'msgs_per_s': delivered / wall if wall > 0 else 0.0,
            'publish_per_s': count / wall if wall > 0 else 0.0,
            'delivered': delivered, 'published': count, 'queues': FANOUT_QS,
            'wall_s': wall, 'payload': payload}


def _fanout_publish_drain(ch, xname, qnames, body, n, batch):
    done = 0
    while done < n:
        b = min(batch, n - done)
        for _ in range(b):
            ch.basic_publish(exchange=xname, routing_key='', body=body,
                             properties=_props())
        for qn in qnames:
            _drain(ch, qn, b, None, [])
        done += b


def run_concurrency(spec, payload, pairs, duration):
    """`pairs` concurrent producer+consumer threads, each with its OWN
    connection + exclusive queue, running concurrently for `duration` seconds.
    Connections are established concurrently (setup is not part of the timed
    window; the start gate opens only after all setup attempts resolve or the
    setup budget expires). Reports aggregate msgs/s plus how many pairs
    actually connected, so a broker that cannot serve N simultaneous
    connections is recorded rather than silently averaged away.

    HyrxMQ 0.0.x serves exactly ONE connection at a time, so pairs>1 is
    expected to fail here; that is the measured result, not a harness fault."""
    body = _mkbody(payload)
    stop = threading.Event()
    start = threading.Event()
    ready = threading.Semaphore(0)
    counts = [0] * pairs
    errors = [None] * pairs
    connected = [0] * pairs

    def worker(idx):
        conn = None
        try:
            conn = _connect(spec, socket_timeout=4, stack_timeout=8)
            ch = conn.channel()
            xname, qname = _open_direct(ch, f'conc.{idx}.{_uniq()}')
            connected[idx] = 1
            ready.release()
            if not start.wait(timeout=30):
                raise ConnectionFailed('start gate never opened')
            n = 0
            while not stop.is_set():
                for _ in range(CONC_BATCH):
                    ch.basic_publish(exchange=xname, routing_key='rk',
                                     body=body, properties=_props())
                got = 0
                while got < CONC_BATCH and not stop.is_set():
                    method, _p, _b = ch.basic_get(queue=qname, auto_ack=True)
                    if method is None:
                        time.sleep(0.0002)
                        continue
                    got += 1
                n += got
            counts[idx] = n
        except Exception as exc:  # noqa: BLE001 - reported, never hidden
            errors[idx] = f'{type(exc).__name__}: {exc}'
            if not connected[idx]:
                ready.release()
        finally:
            if conn is not None:
                _force_socket_close(conn)

    threads = [threading.Thread(target=worker, args=(i,), daemon=True)
               for i in range(pairs)]
    for t in threads:
        t.start()
    setup_deadline = time.time() + 20.0
    for _ in range(pairs):
        remaining = setup_deadline - time.time()
        if remaining <= 0 or not ready.acquire(timeout=remaining):
            break
    t0 = time.perf_counter()
    start.set()
    time.sleep(duration)
    stop.set()
    for t in threads:
        t.join(timeout=10)
    wall = time.perf_counter() - t0
    live = [t for t in threads if t.is_alive()]  # never silently dropped
    total = sum(counts)
    errs = [e for e in errors if e]
    return {'msgs_per_s': total / wall if wall > 0 else 0.0,
            'total_msgs': total, 'pairs': pairs,
            'pairs_connected': sum(connected),
            'duration_s': round(wall, 3), 'payload': payload,
            'per_pair': counts, 'thread_errors': errs,
            'stuck_threads': len(live)}


# ---------------------------------------------------------------------------
# resource sampling via docker stats --no-stream
# ---------------------------------------------------------------------------

_MEM_RE = re.compile(r'([\d.]+)\s*([KMGTP]?i?B)')
_MEM_MULT = {'b': 1.0, 'kb': 1e3, 'kib': 1024.0, 'mb': 1e6, 'mib': 1024.0 ** 2,
             'gb': 1e9, 'gib': 1024.0 ** 3, 'tb': 1e12, 'tib': 1024.0 ** 4}


def _mem_bytes(text):
    m = _MEM_RE.search(text or '')
    if not m:
        return None
    return float(m.group(1)) * _MEM_MULT.get(m.group(2).lower(), 1.0)


def sample_stats(containers):
    """One `docker stats --no-stream` sample for exactly our containers."""
    try:
        res = subprocess.run(
            ['docker', 'stats', '--no-stream', '--format',
             '{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}', *containers],
            capture_output=True, text=True, timeout=20)
    except Exception:
        return {}
    out = {}
    for line in res.stdout.splitlines():
        parts = line.split('|')
        if len(parts) != 3:
            continue
        name, cpu, mem = parts
        try:
            cpu_v = float(cpu.strip().rstrip('%'))
        except ValueError:
            cpu_v = None
        out[name.strip()] = {'cpu_pct': cpu_v,
                             'rss_bytes': _mem_bytes(mem.split('/')[0])}
    return out


def with_stats(containers, fn):
    """Run fn() while sampling docker stats in a background thread."""
    samples = []
    stop = threading.Event()

    def loop():
        while not stop.is_set():
            s = sample_stats(containers)
            if s:
                samples.append(s)
            stop.wait(0.5)

    th = threading.Thread(target=loop, daemon=True)
    th.start()
    try:
        result = fn()
        result['status'] = 'OK'
    finally:
        stop.set()
        th.join(timeout=25)
    result['resource_samples'] = samples
    return result


# ---------------------------------------------------------------------------
# calibration
# ---------------------------------------------------------------------------

_COUNT_CACHE = {}
MAX_COUNT = 4_000_000


def probe_count(spec, wl, param):
    """Pick a count so one timed rep is >= TARGET_REP_SECONDS. Measured, never
    assumed. Cached per (broker, workload, param) so rep rotation does not
    recalibrate."""
    key = (spec['name'], wl, param)
    if key in _COUNT_CACHE:
        return _COUNT_CACHE[key]
    if wl == 'publish_get':
        r = run_publish_get(spec, param, 200)
    elif wl == 'publish_only':
        r = run_publish_only(spec, param, 400)
    elif wl == 'latency':
        r = run_latency(spec, param, LATENCY_MIN_OPS)
    elif wl == 'confirms':
        r = run_confirms(spec, param, 80)
    elif wl == 'fanout':
        r = run_fanout(spec, param, 100)
    else:
        raise ValueError(wl)
    rate = r.get('msgs_per_s') or 0.0
    base = {'publish_get': 200, 'publish_only': 400, 'latency': LATENCY_MIN_OPS,
            'confirms': 80, 'fanout': 100}[wl]
    if rate <= 0:
        count = base
    else:
        count = max(base, int(rate * TARGET_REP_SECONDS))
    count = min(count, MAX_COUNT)
    _COUNT_CACHE[key] = count
    return count


# ---------------------------------------------------------------------------
# pct summary (same shape as benchmarks/perf/harness.py)
# ---------------------------------------------------------------------------

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


def _median(xs):
    xs = [x for x in xs if x is not None]
    return round(statistics.median(xs), 3) if xs else None


def _aggregate_resources(rep_results, container):
    cpus, rss = [], []
    for r in rep_results:
        for s in r.get('resource_samples', []):
            d = s.get(container)
            if not d:
                continue
            if d.get('cpu_pct') is not None:
                cpus.append(d['cpu_pct'])
            if d.get('rss_bytes') is not None:
                rss.append(d['rss_bytes'])
    return {'cpu_pct_median': _median(cpus), 'cpu_pct_max':
            round(max(cpus), 3) if cpus else None,
            'rss_bytes_median': _median(rss),
            'rss_bytes_max': max(rss) if rss else None,
            'samples': len(cpus)}


# ---------------------------------------------------------------------------
# host signature
# ---------------------------------------------------------------------------

def _sh(*args):
    try:
        return subprocess.run(list(args), capture_output=True, text=True,
                              timeout=15).stdout.strip()
    except Exception:
        return None


def host_signature():
    cpu = None
    try:
        with open('/proc/cpuinfo') as fh:
            for line in fh:
                if line.startswith('model name'):
                    cpu = line.split(':', 1)[1].strip()
                    break
    except OSError:
        pass
    mem_kb = None
    try:
        with open('/proc/meminfo') as fh:
            for line in fh:
                if line.startswith('MemTotal'):
                    mem_kb = int(line.split()[1])
                    break
    except OSError:
        pass
    return {'cpu_model': cpu, 'nproc': os.cpu_count(),
            'mem_total_gib': round(mem_kb / 1024 / 1024, 2) if mem_kb else None,
            'kernel': os.uname().release, 'machine': os.uname().machine,
            'python': sys.version.split()[0], 'pika_version': pika.__version__,
            'docker_version': _sh('docker', 'version', '--format',
                                  '{{.Server.Version}}'),
            'governor': _sh('cat',
                            '/sys/devices/system/cpu/cpu0/cpufreq/'
                            'scaling_governor'),
            'loadavg_1m': round(os.getloadavg()[0], 2),
            'hyrxmq_git_head': _sh('git', '-C',
                                   os.path.abspath(os.path.join(HERE, '..',
                                                                '..', '..')),
                                   'rev-parse', '--short', 'HEAD')}


def broker_image(spec):
    c = spec.get('container')
    if not c:
        return None
    return _sh('docker', 'inspect', '-f', '{{.Config.Image}}', c)


# ---------------------------------------------------------------------------
# driver
# ---------------------------------------------------------------------------

def run_cell(spec, wl, param, reps):
    """One (broker, workload, param) cell. Calibration and every rep are
    individually watchdog-bounded so a broker that stops answering (observed:
    HyrxMQ intermittently never returns a publisher confirm) is recorded as a
    FAILED rep/cell instead of hanging the whole suite."""
    container = spec['container']
    if wl == 'concurrency':
        return _run_concurrency_cell(spec, param, reps)

    count = None
    last = None
    for _ in range(3):
        try:
            with bounded(30.0, f'calibrate {spec["name"]} {wl} {param}'):
                count = probe_count(spec, wl, param)
            break
        except (CellTimeout, ConnectionFailed) as exc:
            last = exc
            time.sleep(0.3)
    if count is None:
        raise ConnectionFailed(f'calibration failed for {spec["name"]} {wl} '
                               f'{param}: {last}')

    rows = []
    for rep in range(reps):
        def do():
            if wl == 'publish_get':
                return run_publish_get(spec, param, count)
            if wl == 'publish_only':
                return run_publish_only(spec, param, count)
            if wl == 'latency':
                return run_latency(spec, param, count)
            if wl == 'confirms':
                return run_confirms(spec, param, count)
            return run_fanout(spec, param, count)
        with bounded(max(30.0, TARGET_REP_SECONDS * 12), f'{spec["name"]} '
                     f'{wl} {param} rep{rep}'):
            rows.append(with_stats([container], do))
    return {'status': 'OK', 'calibrated_count': count, 'reps': rows}


def _run_concurrency_cell(spec, pairs, reps):
    rows = []
    for rep in range(reps):
        def do():
            return run_concurrency(spec, 1024, pairs, TARGET_REP_SECONDS)
        with bounded(60.0, f'{spec["name"]} concurrency {pairs} rep{rep}'):
            rows.append(with_stats([spec['container']], do))
    return {'status': 'OK', 'calibrated_count': None, 'reps': rows}


def _cell_summary(wl, cell):
    if cell.get('status') != 'OK':
        return {'status': cell.get('status', 'FAILED'),
                'error': cell.get('error')}
    rows = cell['reps']
    ok = [r for r in rows if r.get('status') == 'OK']
    rates = [r['msgs_per_s'] for r in ok if r.get('msgs_per_s') is not None]
    out = {'status': 'OK', 'reps_ok': len(ok), 'reps_total': len(rows),
           'calibrated_count': cell.get('calibrated_count'),
           'rates_msgs_per_s': [round(r, 1) for r in rates],
           'median_msgs_per_s': _median(rates),
           'min_msgs_per_s': round(min(rates), 1) if rates else None,
           'max_msgs_per_s': round(max(rates), 1) if rates else None,
           'resources': _aggregate_resources(ok, None)}
    # per-container resource aggregate computed in main after we know spec
    if wl == 'latency':
        pooled = []
        for r in ok:
            pooled.extend(r.get('samples_us', []))
        out['latency_us'] = _pct_summary(pooled)
        out['latency_per_rep'] = [r.get('summary', {}) for r in ok]
    if wl == 'fanout':
        out['publish_msgs_per_s'] = [round(r['publish_per_s'], 1) for r in ok]
        out['median_publish_msgs_per_s'] = _median(
            [r['publish_per_s'] for r in ok])
        out['queues'] = FANOUT_QS
    if wl == 'concurrency':
        out['pairs'] = ok[0]['pairs'] if ok else None
        out['pairs_connected_per_rep'] = [r.get('pairs_connected') for r in ok]
        out['pairs_connected_median'] = _median(
            [r.get('pairs_connected') for r in ok])
        out['thread_errors_per_rep'] = [
            len(r.get('thread_errors') or []) for r in ok]
        out['thread_errors'] = [e for r in ok for e in
                                (r.get('thread_errors') or [])][:6]
        out['stuck_threads'] = sum(r.get('stuck_threads', 0) for r in ok)
    if wl == 'publish_get':
        out['all_verified'] = all(r.get('all_verified') for r in ok) if ok \
            else False
    return out


def main():
    ap = argparse.ArgumentParser(description='three-broker AMQP benchmark')
    ap.add_argument('--brokers', default=','.join(BROKER_ORDER))
    ap.add_argument('--workloads', default='all')
    ap.add_argument('--payloads', default=None)
    ap.add_argument('--reps', type=int, default=None)
    ap.add_argument('--out-dir', default=os.path.join(HERE, 'results'))
    ap.add_argument('--quick', action='store_true')
    args = ap.parse_args()

    names = [b for b in args.brokers.split(',') if b]
    for n in names:
        if n not in BROKERS:
            ap.error(f'unknown broker {n!r}; choose from {tuple(BROKERS)}')
    if args.workloads == 'all':
        workloads = list(ALL_WORKLOADS)
    else:
        workloads = [w for w in args.workloads.split(',') if w]
        for w in workloads:
            if w not in ALL_WORKLOADS:
                ap.error(f'unknown workload {w!r}')
    if args.payloads:
        payloads = [int(p) for p in args.payloads.split(',')]
    else:
        payloads = list(QUICK_PAYLOADS if args.quick else FULL_PAYLOADS)
    concs = list(QUICK_CONC if args.quick else FULL_CONC)
    reps = args.reps or (QUICK_REPS if args.quick else REPS)

    os.makedirs(args.out_dir, exist_ok=True)
    run_id = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    sig = host_signature()
    for n in names:
        spec = BROKERS[n]
        sig.setdefault('broker_images', {})[n] = broker_image(spec)
    print('HOST', json.dumps(sig), flush=True)

    raw = {'schema': 1, 'run_id': run_id,
           'started_utc': datetime.now(timezone.utc).isoformat(),
           'host': sig, 'protocol': PROTOCOL, 'reps': reps,
           'quick': args.quick, 'brokers': names,
           'payloads': payloads, 'concurrency': concs,
           'workloads': workloads,
           'method': {
               'publish_get': 'closed-loop publish -> basic_get(auto_ack), '
                              f'batch {BATCH} so queue depth <= {BATCH}',
               'publish_only': 'fire-and-forget to an exchange with no bound '
                               'queue (producer-bound ceiling)',
               'latency': 'publish -> get -> ack round trip, one in flight',
               'confirms': 'confirm_select; timed span is confirm-publish '
                           f'only, drain ({CONFIRM_BATCH}) is untimed',
               'fanout': f'1 fanout exchange -> {FANOUT_QS} queues, '
                         'delivered msgs/s',
               'concurrency': 'N producer+consumer thread pairs, own '
                              'connection+queue each, fixed duration',
               'warmup': f'first {int(WARMUP_FRAC * 100)}% of each rep',
               'report': 'median of >=%d reps' % reps,
           }, 'cells': {}}

    # cells: list of (workload, param, key)
    cells = []
    for wl in workloads:
        if wl in ('publish_get', 'publish_only', 'latency'):
            for p in payloads:
                cells.append((wl, p, str(p)))
        elif wl == 'concurrency':
            for c in concs:
                cells.append((wl, c, str(c)))
        else:
            cells.append((wl, payloads[0], 'default'))
    # prefer the 1KB payload for single-payload workloads
    for i, (wl, param, key) in enumerate(cells):
        if wl in ('confirms', 'fanout') and 1024 in payloads:
            cells[i] = (wl, 1024, 'default')

    t_all = time.time()
    for wl, param, key in cells:
        cell_key = f'{wl}|{key}'
        raw['cells'][cell_key] = {'workload': wl, 'param': param,
                                  'brokers': {}}
        print(f'=== CELL {cell_key} ===', flush=True)
        # rotate broker order across reps to spread order/thermal bias
        for rep in range(reps):
            order = list(names[rep % len(names):] + names[:rep % len(names)])
            for name in order:
                spec = BROKERS[name]
                entry = raw['cells'][cell_key]['brokers'].setdefault(name, {
                    'broker': name, 'label': spec['label'],
                    'container': spec['container'],
                    'reps': []})
                try:
                    r = run_cell(spec, wl, param, 1)
                    row = r['reps'][0]
                    entry['calibrated_count'] = r.get('calibrated_count')
                    entry['reps'].append(row)
                    rate = row.get('msgs_per_s')
                    print(f'  rep{rep} {name:<9} {wl} {key} '
                          f'{rate if rate is None else round(rate, 1)}',
                          flush=True)
                except Exception as exc:  # noqa: BLE001
                    msg = f'{type(exc).__name__}: {exc}'
                    entry['reps'].append({'status': 'FAILED', 'error': msg,
                                          'payload': param})
                    print(f'  rep{rep} {name:<9} {wl} {key} FAILED {msg}',
                          flush=True)
                # save after every rep
                with open(os.path.join(args.out_dir, f'raw_{run_id}.json'),
                          'w') as fh:
                    json.dump(raw, fh, indent=1)
        # summarize this cell
        for name in names:
            entry = raw['cells'][cell_key]['brokers'][name]
            summary = _cell_summary(wl, {'status': 'OK', 'reps': entry['reps'],
                                         'calibrated_count':
                                         entry.get('calibrated_count')})
            # calibration is only meaningful when >1 rep ran
            entry['summary'] = summary
            entry['summary']['resources'] = _aggregate_resources(
                [r for r in entry['reps'] if r.get('status') == 'OK'],
                BROKERS[name]['container'])
            print(f'  {name:<9} MEDIAN {summary.get("median_msgs_per_s")} '
                  f'msg/s', flush=True)
        gc.collect()
        time.sleep(0.3)

    raw['duration_s'] = round(time.time() - t_all, 1)
    raw['finished_utc'] = datetime.now(timezone.utc).isoformat()
    raw_path = os.path.join(args.out_dir, f'raw_{run_id}.json')
    with open(raw_path, 'w') as fh:
        json.dump(raw, fh, indent=1)

    consolidated = consolidate(raw)
    cons_path = os.path.join(args.out_dir, 'consolidated.json')
    with open(cons_path, 'w') as fh:
        json.dump(consolidated, fh, indent=1)
    print(f'WROTE {raw_path}', flush=True)
    print(f'WROTE {cons_path}', flush=True)
    return 0


def consolidate(raw):
    """Turn raw per-rep rows into per-workload medians + ratios + verdict."""
    out = {'schema': 1, 'run_id': raw['run_id'], 'host': raw['host'],
           'started_utc': raw.get('started_utc'),
           'finished_utc': raw.get('finished_utc'),
           'duration_s': raw.get('duration_s'),
           'protocol': raw['protocol'], 'method': raw['method'],
           'quick': raw['quick'], 'reps': raw['reps'],
           'workloads': {}, 'verdict': {}}
    wl_keys = {}
    for cell_key, cell in raw['cells'].items():
        wl_keys.setdefault(cell['workload'], []).append(cell_key)
    fair_cells = []
    for wl, keys in wl_keys.items():
        out['workloads'][wl] = {'params': {}}
        for ck in sorted(keys, key=lambda k: _param_key(raw['cells'][k]['param'])):
            cell = raw['cells'][ck]
            pkey = str(cell['param'])
            row = {}
            for name, entry in cell['brokers'].items():
                ok = [r for r in entry['reps'] if r.get('status') == 'OK']
                for r in ok:
                    r.setdefault('payload', cell['param'])
                s = _cell_summary(wl, {'status': 'OK', 'reps': entry['reps'],
                                       'calibrated_count':
                                       entry.get('calibrated_count')})
                s['resources'] = _aggregate_resources(ok,
                                                      BROKERS[name]['container'])
                row[name] = s
            fastest = max((v.get('median_msgs_per_s') or 0.0)
                          for v in row.values())
            for name, v in row.items():
                rate = v.get('median_msgs_per_s')
                if rate and fastest > 0:
                    v['ratio_vs_fastest'] = round(fastest / rate, 4)
                else:
                    v['ratio_vs_fastest'] = None
            out['workloads'][wl]['params'][pkey] = row
            # A cell is FAIR only if every broker produced a median AND, for
            # concurrency, every broker actually connected all requested pairs.
            # (HyrxMQ serves one connection at a time, so its pairs>1 "rate" is
            # a single-pair rate and must not enter the overall verdict.)
            fair = all(v.get('median_msgs_per_s') for v in row.values())
            if fair and wl == 'concurrency':
                try:
                    want = int(pkey)
                except ValueError:
                    want = None
                if want is not None:
                    fair = all((v.get('pairs_connected_median') or 0) >= want
                               for v in row.values())
            if fair:
                fair_cells.append((wl, pkey, row))
    import math
    geos = {b: [] for b in raw['brokers']}
    for wl, pkey, row in fair_cells:
        fastest = max((v['median_msgs_per_s'] or 0.0) for v in row.values())
        for name, v in row.items():
            if fastest > 0 and v['median_msgs_per_s']:
                geos[name].append(fastest / v['median_msgs_per_s'])
    gm = {b: (round(math.exp(sum(math.log(x) for x in xs) / len(xs)), 4)
              if xs else None) for b, xs in geos.items()}
    out['verdict']['geomean_ratio_vs_fastest'] = gm
    out['verdict']['fair_cells'] = [f'{wl}|{pkey}' for wl, pkey, _ in fair_cells]
    out['verdict']['fair_cell_count'] = len(fair_cells)
    if gm:
        ranked = sorted(((r, b) for b, r in gm.items() if r), key=lambda x: x[0])
        out['verdict']['ranking'] = [b for _r, b in ranked]
        out['verdict']['winner'] = ranked[0][1] if ranked else None
    return out


def _param_key(p):
    try:
        return (0, int(p))
    except (TypeError, ValueError):
        return (1, str(p))


if __name__ == '__main__':
    sys.exit(main())
