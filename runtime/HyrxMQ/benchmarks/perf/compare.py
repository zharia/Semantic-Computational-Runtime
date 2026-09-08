"""Regression gate for the fair AMQP benchmark.

    /tmp/amqp-venv/bin/python benchmarks/perf/compare.py \
        --baseline benchmarks/perf/baseline.json --now benchmarks/perf/results.json
    /tmp/amqp-venv/bin/python benchmarks/perf/compare.py --update-baseline \
        --now benchmarks/perf/results.json          # explicit human step only

Compares, per cell and per payload: median msgs/sec and the round-trip p99 µs,
plus the headline Performance Rating R (benchmarks/perf/index.py).

Exit status:
    0  every gate PASSed
    1  at least one gate REGRESSION
    2  the comparison could not be made (missing baseline/cell, no common
       payload) — reported as INCONCLUSIVE, never as a pass
    3  reserved: `--fail-on-host-mismatch` and the host signature changed

A changed host signature is ALWAYS warned about (§48): R is a machine-relative
number, so a cross-machine delta is not evidence of a regression.
"""
import argparse
import datetime
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)

import index as rating_mod  # noqa: E402  (rating() + transport_matrix())

# ---------------------------------------------------------------------------
# thresholds (single block; tune here, nowhere else)
# ---------------------------------------------------------------------------
THROUGHPUT_DROP_PCT = 10.0   # fail if a HyrxMQ cell loses more than this
P99_RISE_PCT = 25.0          # fail if a HyrxMQ cell's p99 grows more than this
RATING_DELTA = 0.10          # fail if |R - R_baseline| exceeds this
RABBIT_DRIFT_WARN_PCT = 25.0 # reference broker moved -> environment warning only
HOST_KEYS = ('cpu_model', 'nproc', 'pika_version', 'rabbit_version',
             'hyrxmq_git_head')
HYRX_CELLS = ('hyrx-tcp-docker', 'hyrx-tcp-native', 'hyrx-uds')


def _cell(data, name):
    rec = (data.get('cells') or {}).get(name)
    if rec and rec.get('status') == 'OK':
        return rec
    return None


def _median(xs):
    import statistics
    return statistics.median(xs) if xs else None


def compare_cells(baseline, now):
    """[(cell, payload, metric, base, now, delta_pct, verdict, gated)]"""
    rows = []
    for cell in rating_mod.CELL_ORDER:
        b, n = _cell(baseline, cell), _cell(now, cell)
        if b is None or n is None:
            missing = [nm for nm, rec in (('baseline', b), ('now', n))
                       if rec is None]
            rows.append((cell, '-', '-', None, None, None,
                         f'INCONCLUSIVE ({"+".join(missing)} cell absent)',
                         False))
            continue
        payloads = sorted(set(b.get('throughput', {})) & set(n.get('throughput', {})),
                          key=int)
        for p in payloads:
            br = _median([r['msgs_per_s']
                          for r in b['throughput'][p]['per_rep']])
            nr = _median([r['msgs_per_s']
                          for r in n['throughput'][p]['per_rep']])
            rows.append(_row(cell, int(p), 'msgs_per_s', br, nr,
                              gated=cell in HYRX_CELLS))
        lp = sorted(set(b.get('latency', {})) & set(n.get('latency', {})),
                    key=int)
        for p in lp:
            bp = b['latency'][p]['summary']['p99_us']
            np_ = n['latency'][p]['summary']['p99_us']
            # p99: lower is better -> a RISE is the regression direction
            rows.append(_row(cell, int(p), 'p99_us', bp, np_,
                              higher_is_better=False,
                              gated=cell in HYRX_CELLS))
    return rows


def _row(cell, payload, metric, base, now, higher_is_better=True, gated=True):
    if not base or not now:
        return (cell, payload, metric, base, now, None, 'INCONCLUSIVE', gated)
    delta = 100.0 * (now / base - 1.0)
    if not higher_is_better:
        delta = -delta  # normalize: positive delta == improvement
    if gated:
        limit = THROUGHPUT_DROP_PCT if metric == 'msgs_per_s' else P99_RISE_PCT
        verdict = 'PASS' if -delta <= limit else 'REGRESSION'
    else:
        verdict = 'PASS (reference, not gated)'
        if abs(delta) > RABBIT_DRIFT_WARN_PCT:
            verdict = f'WARN drift>{RABBIT_DRIFT_WARN_PCT:.0f}% (reference)'
    return (cell, payload, metric, base, now, round(delta, 2), verdict, gated)


def compare_rating(baseline, now):
    rb = rating_mod.rating(baseline)
    rn = rating_mod.rating(now)
    if 'error' in rb or 'error' in rn:
        return {'verdict': 'INCONCLUSIVE',
                'reason': (rb.get('error') or rn.get('error'))}
    delta = rn['R'] - rb['R']
    return {'baseline_R': rb['R'], 'now_R': rn['R'], 'delta': round(delta, 3),
            'threshold': RATING_DELTA,
            'verdict': 'PASS' if abs(delta) <= RATING_DELTA else 'REGRESSION',
            'ci_now': rn.get('ci'), 'ci_baseline': rb.get('ci')}


def compare_host(baseline, now):
    hb, hn = baseline.get('host', {}), now.get('host', {})
    diffs = {k: (hb.get(k), hn.get(k)) for k in HOST_KEYS
             if hb.get(k) != hn.get(k)}
    extra = {k: (hb.get(k), hn.get(k)) for k in ('kernel', 'governor',
                                                 'python')
             if hb.get(k) != hn.get(k)}
    return {'changed': diffs, 'environment_changed': extra,
            'same': not diffs,
            'baseline_ts': baseline.get('started_utc'),
            'now_ts': now.get('started_utc')}


def report(baseline, now):
    rows = compare_cells(baseline, now)
    rt = compare_rating(baseline, now)
    host = compare_host(baseline, now)

    print(f'baseline {host["baseline_ts"]}  vs  now {host["now_ts"]}')
    if not host['same']:
        print('!! HOST SIGNATURE CHANGED — the comparison is NOT trustworthy:')
        for k, (a, b) in host['changed'].items():
            print(f'   {k}: {a!r} -> {b!r}')
        print('   (R is machine-relative; re-capture the baseline on this host '
              'with --update-baseline if the move is intended.)')
    elif host['environment_changed']:
        print('note: environment fields differ (not gated): ' +
              ', '.join(f'{k}={v[0]!r}->{v[1]!r}'
                        for k, v in host['environment_changed'].items()))
    print()
    print(f"{'cell':>18} {'payload':>8} {'metric':>11} {'baseline':>11} "
          f"{'now':>11} {'delta%':>8}  verdict")
    failed = []
    inconclusive = []
    for cell, payload, metric, b, n, delta, verdict, gated in rows:
        fmt = ('{:>18} {:>8} {:>11} {:>11} {:>11} {:>8}  {}')
        print(fmt.format(cell, payload, metric,
                         '--' if b is None else f'{b:,.1f}',
                         '--' if n is None else f'{f"{n:,.1f}"}',
                         '--' if delta is None else f'{delta:+.2f}', verdict))
        if verdict == 'REGRESSION':
            failed.append((cell, payload, metric, delta))
        elif verdict == 'INCONCLUSIVE' or verdict.startswith('INCONCLUSIVE'):
            inconclusive.append((cell, payload, metric))
    print()
    print('PERFORMANCE RATING gate:')
    if rt.get('verdict') == 'INCONCLUSIVE':
        print(f'  INCONCLUSIVE: {rt["reason"]}')
        inconclusive.append(('rating', '-', '-'))
    else:
        ci = rt.get('ci_now') or {}
        print(f"  R {rt['baseline_R']:.3f} -> {rt['now_R']:.3f} "
              f"(delta {rt['delta']:+.3f}, threshold +-"
              f"{rt['threshold']:.2f})  {rt['verdict']}"
              + (f"  [95% CI now: {ci.get('ci95_lo')}-{ci.get('ci95_hi')}]"
                 if ci else ''))
        if rt['verdict'] == 'REGRESSION':
            failed.append(('rating', '-', 'R', rt['delta']))
    print()
    if inconclusive:
        print(f'{len(inconclusive)} comparison(s) INCONCLUSIVE (no numbers '
              f'invented): ' + ', '.join(f'{c}/{p}/{m}'
                                         for c, p, m in inconclusive))
    return rows, rt, host, failed


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--baseline',
                    default=os.path.join(HERE, 'baseline.json'))
    ap.add_argument('--now', default=os.path.join(HERE, 'results.json'))
    ap.add_argument('--update-baseline', action='store_true',
                    help='write --now as the new baseline and exit')
    ap.add_argument('--fail-on-host-mismatch', action='store_true')
    ap.add_argument('--json-out', default=None)
    args = ap.parse_args()

    with open(args.now) as fh:
        now = json.load(fh)

    if args.update_baseline:
        now = dict(now)
        now['baseline_captured_utc'] = \
            datetime.datetime.now(datetime.timezone.utc).isoformat()
        now['baseline_note'] = ('captured explicitly by compare.py '
                                '--update-baseline; regenerate only after a '
                                'human review of the run')
        with open(args.baseline, 'w') as fh:
            json.dump(now, fh, indent=1)
        print(f'BASELINE UPDATED: {args.baseline}')
        return 0

    if not os.path.exists(args.baseline):
        print(f'no baseline at {args.baseline}; run '
              f'"python benchmarks/perf/compare.py --update-baseline" after a '
              f'clean run')
        return 2

    with open(args.baseline) as fh:
        baseline = json.load(fh)

    rows, rt, host, failed = report(baseline, now)
    if args.json_out:
        with open(args.json_out, 'w') as fh:
            json.dump({'rows': [dict(zip(
                ('cell', 'payload', 'metric', 'baseline', 'now', 'delta_pct',
                 'verdict', 'gated'), r)) for r in rows],
                'rating': rt, 'host': host, 'thresholds': {
                    'throughput_drop_pct': THROUGHPUT_DROP_PCT,
                    'p99_rise_pct': P99_RISE_PCT,
                    'rating_delta': RATING_DELTA}}, fh, indent=1)

    if failed:
        print(f'GATE FAIL: {len(failed)} regression(s)')
        return 1
    print('GATE PASS')
    if not host['same'] and args.fail_on_host_mismatch:
        return 3
    return 0


if __name__ == '__main__':
    sys.exit(main())
