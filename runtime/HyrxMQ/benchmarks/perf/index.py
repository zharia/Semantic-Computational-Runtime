"""Single headline Performance Rating + transport matrix for the fair bench.

Reads a `results.json` produced by harness.py and prints/computes:

  1. the Performance Rating R — ONE dimensionless number, higher = HyrxMQ
     faster, computed ONLY on the fair pair `rabbit-tcp` vs `hyrx-tcp-docker`
     (both reached through an identical docker port-published network path, so
     the difference is the engine, not the wiring);
  2. the transport matrix — every cell side by side, with % overhead against
     HyrxMQ-TCP-native (the UDS advantage and the docker tax made visible);
  3. the floor-subtracted view.

FORMULA (also printed by `main`):

    G_T = exp( mean_p[ ln( T_hyrx(p) / T_rabbit(p) ) ] )      (throughput)
    G_L = exp( mean_p[ ln( L_rabbit(p) / L_hyrx(p) ) ] )      (latency, lower
                                                                is better)
    R   = ( G_T + G_L ) / 2

  * p runs over the payload sizes; `mean[ln(...)]` + `exp` = geometric mean, so
    a 2x win on one payload and a 2x loss on another cancel out exactly.
  * the two factors are averaged arithmetically, so a protocol that is exactly
    as fast gives R = (1+1)/2 = 1.000 (parity); R = 1.050 means HyrxMQ is 5%
    better on the geometric average of throughput and latency.
  * T = median msgs/sec of the rep set at that payload; L = p50 round-trip µs
    at that payload.
  * CI: rep-aligned per-rep R values (rep i of HyrxMQ against rep i of
    RabbitMQ) -> Student-t 95% interval on ln R. Only as good as the rep count.

R does NOT claim (audit §48): see `--not-claimed` for the printed list.

    /tmp/amqp-venv/bin/python benchmarks/perf/index.py benchmarks/perf/results.json
"""
import argparse
import json
import math
import os
import statistics
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

FAIR_BASE = 'rabbit-tcp'
FAIR_HYRX = 'hyrx-tcp-docker'
NATIVE = 'hyrx-tcp-native'
CELL_ORDER = ('rabbit-tcp', 'hyrx-tcp-docker', 'hyrx-tcp-hostnet',
              'hyrx-tcp-native', 'hyrx-uds')
CELL_LABEL = {
    'rabbit-tcp': 'RabbitMQ (docker-published TCP)',
    'hyrx-tcp-docker': 'HyrxMQ (docker-published TCP) [fair pair]',
    'hyrx-tcp-hostnet': 'HyrxMQ (docker host-network TCP, no proxy hop)',
    'hyrx-tcp-native': 'HyrxMQ (native loopback TCP)',
    'hyrx-uds': 'HyrxMQ (AF_UNIX)',
}
NOT_CLAIMED = (
    'R does NOT claim:',
    '  * production readiness, durability, TLS, clustering or heartbeat safety',
    '    (ack persistence is deliberately excluded: auto_ack on the rate cell).',
    '  * open-loop producer throughput: the workload is a closed-loop',
    '    publish->get(auto_ack) cycle, because our broker has no push-to-idle-',
    '    subscriber path and drops silently at 1024 queued entries (§32).',
    '  * concurrent producers/consumers or multi-connection scaling (single',
    '    connection at a time by design).',
    '  * any RabbitMQ-over-Unix-socket figure: RabbitMQ has no UDS listener, so',
    '    hyrx-uds is compared only against hyrx-tcp-native.',
    '  * a machine-independent number: R is only comparable between runs that',
    '    share the host signature (see compare.py).',
)

T95 = {1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365,
       8: 2.306, 9: 2.262, 10: 2.228}


def _payloads(cell):
    return sorted(int(p) for p in cell.get('throughput', {}))


def _rates(cell, payload):
    return [r['msgs_per_s'] for r in cell['throughput'][str(payload)]['per_rep']]


def _latency(cell, payload):
    lat = cell.get('latency', {}).get(str(payload))
    if not lat:
        return None
    return lat['summary']


def usable(data, cell):
    rec = data['cells'].get(cell)
    if not rec or rec.get('status') != 'OK':
        return None
    if not rec.get('throughput'):
        return None
    return rec


def rating(data):
    """Return dict with R + factors, or {'error': ...} if the fair pair is
    unavailable (never a fabricated number)."""
    base = usable(data, FAIR_BASE)
    hyrx = usable(data, FAIR_HYRX)
    if base is None or hyrx is None:
        why = []
        for name, rec in ((FAIR_BASE, base), (FAIR_HYRX, hyrx)):
            if rec is None:
                cell = data['cells'].get(name) or {}
                why.append(f'{name} unavailable ({cell.get("status", "missing")}'
                           f'{": " + cell["error"] if cell.get("error") else ""})')
        return {'error': '; '.join(why), 'fair_pair': [FAIR_BASE, FAIR_HYRX]}

    # Throughput factor uses EVERY payload measured in both fair-pair cells;
    # the latency factor uses the payload(s) the latency cell ran on (256B by
    # default). They are deliberately not intersected: dropping 4 of 5
    # throughput points because latency is sampled at one size would make the
    # headline number a single-payload number.
    payloads = [p for p in _payloads(base) if p in _payloads(hyrx)]
    lat_payloads = [p for p in payloads if _latency(base, p) is not None
                    and _latency(hyrx, p) is not None]
    if not payloads or not lat_payloads:
        return {'error': f'no common throughput payloads={payloads} or latency '
                         f'payloads={lat_payloads} in the fair pair',
                'fair_pair': [FAIR_BASE, FAIR_HYRX]}

    per_rep = min(len(_rates(base, p)) for p in payloads)
    per_rep = min(per_rep, min(len(_rates(hyrx, p)) for p in payloads))

    per_payload = {}
    for p in payloads:
        tb = statistics.median(_rates(base, p))
        th = statistics.median(_rates(hyrx, p))
        entry = {'T_rabbit': tb, 'T_hyrx': th, 'ratio_T': th / tb,
                 'latency': p in lat_payloads}
        if p in lat_payloads:
            lb = _latency(base, p)['p50_us']
            lh = _latency(hyrx, p)['p50_us']
            entry.update({'L_rabbit': lb, 'L_hyrx': lh, 'ratio_L': lb / lh})
        per_payload[p] = entry

    g_t = math.exp(statistics.fmean(math.log(v['ratio_T'])
                                    for v in per_payload.values()))
    g_l = math.exp(statistics.fmean(
        math.log(per_payload[p]['ratio_L']) for p in lat_payloads))
    r = (g_t + g_l) / 2.0

    rs = []
    for i in range(per_rep):
        gt = math.exp(statistics.fmean(
            math.log(_rates(hyrx, p)[i] / _rates(base, p)[i]) for p in payloads))
        gl = g_l  # latency is one measurement per cell, not per rep
        rs.append((gt + gl) / 2.0)
    ci = None
    if len(rs) >= 2:
        logs = [math.log(x) for x in rs]
        m = statistics.fmean(logs)
        sd = statistics.stdev(logs)
        half = T95.get(len(rs) - 1, 1.96) * sd / math.sqrt(len(rs))
        ci = {'n_reps': len(rs), 'R_rep_values': [round(x, 4) for x in rs],
              'R_median': round(statistics.median(rs), 4),
              'ci95_lo': round(math.exp(m - half), 4),
              'ci95_hi': round(math.exp(m + half), 4)}
    return {'R': round(r, 3), 'G_T': round(g_t, 3), 'G_L': round(g_l, 3),
            'fair_pair': [FAIR_BASE, FAIR_HYRX], 'payloads': payloads,
            'latency_payloads': lat_payloads,
            'per_payload': per_payload, 'reps_used': per_rep, 'ci': ci}


def transport_matrix(data):
    """cells x payloads with overhead vs the native loopback cell."""
    cells = [c for c in CELL_ORDER if usable(data, c)]
    ref = usable(data, NATIVE)
    payloads = sorted({p for c in cells for p in _payloads(usable(data, c))})
    rows = []
    for p in payloads:
        row = {'payload': p}
        for c in cells:
            rec = usable(data, c)
            rates = _rates(rec, p) if str(p) in rec.get('throughput', {}) else []
            if rates:
                row[c] = {'msgs_per_s': statistics.median(rates),
                          'bytes_per_s': statistics.median(rates) * p}
        if ref is not None and str(p) in ref.get('throughput', {}):
            base_rate = statistics.median(_rates(ref, p))
            for c in cells:
                if c in row:
                    row[c]['overhead_vs_native_pct'] = \
                        round(100.0 * (base_rate / row[c]['msgs_per_s'] - 1.0), 1)
        rows.append(row)
    return rows


def print_report(data, show_hidden=False):
    print('=' * 78)
    print('FAIR RABBITMQ-vs-HYRXMQ AMQP BENCHMARK')
    print('=' * 78)
    h = data.get('host', {})
    print(f"host          : {h.get('cpu_model')} ({h.get('nproc')} cores, "
          f"{h.get('kernel')}, governor={h.get('governor')})")
    print(f"client        : pika {h.get('pika_version')} / python "
          f"{h.get('python')}   load1m@start={h.get('loadavg_1m')}")
    print(f"reference     : {h.get('rabbit_image')} ({h.get('rabbit_version')})")
    print(f"under test    : HyrxMQ git {h.get('hyrxmq_git_head')}")
    print(f"run           : {data.get('started_utc')} -> "
          f"{data.get('finished_utc')} ({data.get('duration_s')}s)")
    cfg = data.get('protocol', {})
    print(f"protocol      : heartbeat={cfg.get('heartbeat')} "
          f"frame_max={cfg.get('frame_max')} delivery_mode="
          f"{cfg.get('delivery_mode')} auto_ack(get)=True "
          f"durable=False confirms=False")
    print()

    print('-- transport matrix: median msgs/s (overhead vs HyrxMQ-native) --')
    cells = [c for c in CELL_ORDER if usable(data, c)]
    hdr = f"{'payload':>8} " + ''.join(f'{c:>22}' for c in cells)
    print(hdr)
    for row in transport_matrix(data):
        line = f"{row['payload']:>6}B  "
        for c in cells:
            v = row.get(c)
            if not v:
                line += f"{'--':>22}"
            else:
                ov = v.get('overhead_vs_native_pct')
                if ov is None:
                    line += f"{v['msgs_per_s']:>12.0f} {'--':>8}"
                else:
                    line += (f"{v['msgs_per_s']:>12.0f} "
                             f"({0.0 if c == NATIVE else ov:+6.1f}%)")
        print(line)
    print()

    print('-- round-trip latency, p50/p99 µs (publish->get->ack) --')
    print(f"{'cell':>18} {'payload':>8} {'n':>7} {'p50':>9} {'p95':>9} "
          f"{'p99':>9} {'p99.9':>9}")
    for c in cells:
        rec = usable(data, c)
        for p in sorted(int(k) for k in rec.get('latency', {})):
            s = rec['latency'][str(p)]['summary']
            print(f"{c:>18} {p:>6}B {s['n']:>7} {s['p50_us']:>9.1f} "
                  f"{s['p95_us']:>9.1f} {s['p99_us']:>9.1f} "
                  f"{s['p99_9_us']:>9.1f}")
    print()

    print('-- floors (measured, µs) --')
    print(f"{'cell':>18} {'amqp_open_close':>16} {'bare_connect':>13} "
          f"{'empty_get':>10}")
    for c in cells:
        f = usable(data, c).get('floor', {})
        oc = f.get('summary', {}).get('p50_us')
        bc = (f.get('bare_tcp_connect') or f.get('bare_uds_connect')
              or {}).get('summary', {}).get('p50_us')
        eg = (f.get('empty_get') or {}).get('summary', {}).get('p50_us')
        kind = 'AF_UNIX' if c == 'hyrx-uds' else 'TCP'
        print(f"{c:>18} {(f'{oc:,.1f}' if oc else '--'):>16} "
              f"{(f'{bc:,.1f} ({kind})' if bc else '--'):>13} "
              f"{(f'{eg:,.1f}' if eg else '--'):>10}")
    print()

    print('-- floor-subtracted view (per-message cost above the empty_get '
          'floor) --')
    print(f"{'cell':>18} {'payload':>8} {'p50 raw':>9} {'p50-floor':>10} "
          f"{'x floor':>8}")
    for c in cells:
        rec = usable(data, c)
        floor = (rec.get('floor', {}).get('empty_get')
                 or {}).get('summary', {}).get('p50_us')
        for p in sorted(int(k) for k in rec.get('latency', {})):
            s = rec['latency'][str(p)]['summary']
            if not floor:
                continue
            print(f"{c:>18} {p:>6}B {s['p50_us']:>9.1f} "
                  f"{s['p50_us'] - floor:>10.1f} "
                  f"{(s['p50_us'] - floor) / floor:>8.2f}")
    print()

    print('-- per-payload throughput detail --')
    for c in cells:
        rec = usable(data, c)
        for p in _payloads(rec):
            blk = rec['throughput'][str(p)]
            print(f"{c:>18} {p:>6}B count={blk['count']:<7} reps={blk['reps']} "
                  f"median={blk['median_msgs_per_s']:>9.0f}/s "
                  f"spread={blk['spread_pct']:>5.1f}% "
                  f"verified={blk['all_verified']} "
                  f"restarts={rec.get('restarts', 0)}")
    print()

    rt = rating(data)
    print('-- PERFORMANCE RATING (fair pair only) --')
    if 'error' in rt:
        print(f'R = NOT COMPUTED: {rt["error"]}')
        print('  The rating is never fabricated from a substitute pair; fix the '
              'blocked cell (see run log) and re-run.')
    else:
        print('  G_T = exp(mean_p ln(T_hyrx/T_rabbit)) ; '
              'G_L = exp(mean_p ln(L_rabbit/L_hyrx))')
        print('  R   = (G_T + G_L) / 2      [1.000 = parity, >1 = HyrxMQ faster]')
        for p in rt['payloads']:
            v = rt['per_payload'][p]
            line = (f"    {p:>6}B  T {v['T_rabbit']:>9.0f} -> "
                    f"{v['T_hyrx']:>9.0f} ({v['ratio_T']:.3f}x)")
            if v['latency']:
                line += (f"   L {v['L_rabbit']:>7.1f} -> {v['L_hyrx']:>7.1f} us "
                         f"({v['ratio_L']:.3f}x)")
            else:
                line += '   L not sampled'
            print(line)
        print(f"  G_T = {rt['G_T']:.3f}   G_L = {rt['G_L']:.3f}")
        print(f"  R   = {rt['R']:.3f}   "
              f"(fair pair: {' vs '.join(rt['fair_pair'])})")
        if rt.get('ci'):
            ci = rt['ci']
            print(f"  95% CI (rep-aligned, n={ci['n_reps']}): "
                  f"[{ci['ci95_lo']:.3f}, {ci['ci95_hi']:.3f}]  "
                  f"median R={ci['R_median']:.3f}")
    print()
    print('What the number does NOT claim:')
    for line in NOT_CLAIMED[1:]:
        print(line)
    print()

    for c in CELL_ORDER:
        rec = data['cells'].get(c)
        if rec is None:
            print(f'CELL {c}: NOT RUN (not requested)')
        elif rec.get('status') != 'OK':
            print(f'CELL {c}: {rec.get("status")} -> {rec.get("error")}')
    return rt


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('results', nargs='?',
                    default=os.path.join(ROOT, 'benchmarks', 'perf',
                                         'results.json'))
    ap.add_argument('--json', action='store_true', help='emit the rating JSON')
    args = ap.parse_args()

    with open(args.results) as fh:
        data = json.load(fh)
    if args.json:
        out = {'rating': rating(data), 'matrix': transport_matrix(data)}
        print(json.dumps(out, indent=1))
        return 0
    rt = print_report(data)
    return 0 if 'error' not in rt else 3


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

if __name__ == '__main__':
    sys.exit(main())
