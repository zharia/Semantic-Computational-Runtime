#!/usr/bin/env python3
"""collect_v2.py — fold v2 NDJSON runs + docker-stats samples into one raw JSON,
then consolidate (medians, ratios, per-concurrency-band geomean verdict).

Usage:
    python3 collect_v2.py --runs RUNS.ndjson --stats STATS.ndjson \
        --raw v2_raw.json --consolidated v2_consolidated.json \
        --reps 5 --target 2.0 --started ... --finished ... --mode full \
        --containers C1 C2 C3 --payloads "..." --concs "..." --workloads "..."
"""
import argparse
import json
import math
import re
import statistics
import subprocess
import sys
from datetime import datetime, timezone

BROKER_ORDER = ['hyrxmq', 'rabbitmq', 'lavinmq']


def sh(*args):
    try:
        return subprocess.run(list(args), capture_output=True, text=True,
                              timeout=20).stdout.strip()
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
    import os
    return {
        'cpu_model': cpu,
        'nproc': os.cpu_count(),
        'mem_total_gib': round(mem_kb / 1024 / 1024, 2) if mem_kb else None,
        'kernel': os.uname().release,
        'machine': os.uname().machine,
        'docker_version': sh('docker', 'version', '--format',
                             '{{.Server.Version}}'),
        'go_version': sh('go', 'version'),
        'governor': sh('cat', '/sys/devices/system/cpu/cpu0/cpufreq/'
                       'scaling_governor'),
        'loadavg_1m': round(os.getloadavg()[0], 2),
    }


def image_digest(container):
    ref = sh('docker', 'inspect', '-f', '{{.Config.Image}}', container)
    dig = sh('docker', 'inspect', '-f', '{{.Image}}', container)
    return {'image': ref, 'image_id': dig}


_MEM_RE = re.compile(r'([\d.]+)\s*([KMGTP]?i?B)')
_MEM_MULT = {'b': 1.0, 'kb': 1e3, 'kib': 1024.0, 'mb': 1e6,
             'mib': 1024.0 ** 2, 'gb': 1e9, 'gib': 1024.0 ** 3,
             'tb': 1e12, 'tib': 1024.0 ** 4}


def mem_bytes(text):
    m = _MEM_RE.search(text or '')
    if not m:
        return None
    return float(m.group(1)) * _MEM_MULT.get(m.group(2).lower(), 1.0)


def broker_for_container(name):
    n = name.lower()
    if 'rabbit' in n:
        return 'rabbitmq'
    if 'lavin' in n:
        return 'lavinmq'
    if 'hyrx' in n:
        return 'hyrxmq'
    return name


def load_stats(path):
    """Return list of {ts, broker, cpu_pct, rss_bytes}."""
    out = []
    try:
        with open(path) as fh:
            for line in fh:
                parts = line.rstrip('\n').split('|', 3)
                if len(parts) != 4:
                    continue
                ts_s, name, cpu, mem = parts
                try:
                    ts = float(ts_s)
                    cpu_v = float(cpu.strip().rstrip('%'))
                except ValueError:
                    continue
                out.append({'ts': ts, 'broker': broker_for_container(name),
                            'cpu_pct': cpu_v,
                            'rss_bytes': mem_bytes(mem.split('/')[0])})
    except OSError:
        pass
    return out


def median(xs):
    xs = [x for x in xs if x is not None]
    return statistics.median(xs) if xs else None


def r1(x):
    return round(x, 1) if x is not None else None


def r3(x):
    return round(x, 3) if x is not None else None


def cell_key(wl, payload, conc):
    return f'{wl}|{payload}|{conc}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--runs', required=True)
    ap.add_argument('--stats', required=True)
    ap.add_argument('--raw', required=True)
    ap.add_argument('--consolidated', required=True)
    ap.add_argument('--reps', type=int, default=5)
    ap.add_argument('--target', type=float, default=2.0)
    ap.add_argument('--started', default='')
    ap.add_argument('--finished', default='')
    ap.add_argument('--mode', default='full')
    ap.add_argument('--containers', nargs='*', default=[])
    ap.add_argument('--payloads', default='')
    ap.add_argument('--concs', default='')
    ap.add_argument('--workloads', default='')
    args = ap.parse_args()

    runs = []
    with open(args.runs) as fh:
        for line in fh:
            line = line.strip()
            if line:
                runs.append(json.loads(line))
    stats = load_stats(args.stats)

    raw = {
        'schema': 2,
        'run_id': args.raw.rsplit('_', 1)[-1].split('.')[0],
        'started_utc': args.started,
        'finished_utc': args.finished,
        'mode': args.mode,
        'reps': args.reps,
        'target_rep_s': args.target,
        'host': host_signature(),
        'images': {broker_for_container(c): image_digest(c)
                   for c in args.containers},
        'config': {'payloads': args.payloads.split(),
                   'concs': args.concs.split(),
                   'workloads': args.workloads.split()},
        'cells': {},
        'runs': [],
    }

    # Index stats windows per run for per-run resource attribution.
    for run in runs:
        run['resources'] = resources_for_run(run, stats)
        raw['runs'].append(run)

    # Build cells.
    keys = []
    for run in runs:
        wl = run['workload']
        pl = run['payload']
        cc = run['concurrency']
        ck = cell_key(wl, pl, cc)
        if ck not in raw['cells']:
            raw['cells'][ck] = {'workload': wl, 'payload': pl,
                                'concurrency': cc,
                                'brokers': {b: {'runs': []}
                                            for b in BROKER_ORDER}}
            keys.append((wl, pl, cc))
        raw['cells'][ck]['brokers'][run['broker']]['runs'].append(run)

    for ck in list(raw['cells']):
        cell = raw['cells'][ck]
        for b in BROKER_ORDER:
            entry = cell['brokers'][b]
            ok = [r for r in entry['runs']
                  if r.get('result') and r['rc'] == 0]
            rates = [r['result'].get('msgs_per_sec') for r in ok]
            entry['n_ok'] = len(ok)
            entry['n_total'] = len(entry['runs'])
            entry['median_msgs_per_s'] = (round(statistics.median(rates), 1)
                                          if rates else None)
            # "clean" set drops stalled reps (wall far above target). HyrxMQ
            # intermittently stalls ~15 s at connection setup; the primary
            # median includes those, the clean median exposes steady state.
            stall_thresh = max(3.0 * args.target, 5.0)
            clean = [r for r in ok
                     if not r['result'].get('errors')
                     and (r['result'].get('wall_s') or 0.0) <= stall_thresh]
            crates = [r['result'].get('msgs_per_sec') for r in clean]
            entry['stall_runs'] = len(ok) - len(clean)
            entry['clean_n'] = len(clean)
            entry['median_clean_msgs_per_s'] = (
                round(statistics.median(crates), 1) if crates else
                entry['median_msgs_per_s'])
            entry['min_msgs_per_s'] = r1(min(rates)) if rates else None
            entry['max_msgs_per_s'] = r1(max(rates)) if rates else None
            entry['rates'] = [r1(x) for x in rates]
            entry['errors_total'] = sum(r['result'].get('errors', 0)
                                        for r in ok)
            entry['workers_connected'] = [r['result'].get('workers_connected')
                                          for r in ok]
            entry['count'] = [r['result'].get('count') for r in ok]
            entry['wall_s'] = [r['result'].get('wall_s') for r in ok]
            entry['status'] = 'OK' if ok else 'FAILED'
            if not ok:
                errs = [r for r in entry['runs'] if r.get('result') is None]
                entry['error'] = (f'{len(errs)}/{entry["n_total"]} runs failed'
                                  if errs else 'no successful runs')
            if cell['workload'] == 'latency':
                for pct in ('p50_us', 'p95_us', 'p99_us', 'p999_us'):
                    vals = [r['result'].get(pct) for r in ok
                            if r['result'].get(pct) is not None]
                    entry[pct + '_median'] = r3(median(vals))
            if cell['workload'] == 'fanout':
                entry['delivered_median'] = median(
                    [r['result'].get('delivered') for r in ok])
            entry['resources'] = resources_for_broker(entry, stats)

        rates = {b: cell['brokers'][b]['median_msgs_per_s']
                 for b in BROKER_ORDER}
        valid = [v for v in rates.values() if v]
        fastest = max(valid) if valid else None
        cell['fastest_msgs_per_s'] = r1(fastest)
        cell['fastest_broker'] = None
        for b in BROKER_ORDER:
            v = rates[b]
            if fastest and v:
                cell['brokers'][b]['ratio_vs_fastest'] = round(fastest / v, 3)
                cell['brokers'][b]['pct_of_fastest'] = round(100 * v / fastest, 1)
                if abs(v - fastest) < 1e-9:
                    cell['fastest_broker'] = b
            else:
                cell['brokers'][b]['ratio_vs_fastest'] = None
                cell['brokers'][b]['pct_of_fastest'] = None

    # ---- verdict: geomean ratio over fair non-latency cells, by band --------
    def band(conc):
        c = int(conc)
        if c == 1:
            return '1'
        if c <= 8:
            return '4-8'
        return '16-32'

    verdict = {'bands': {}, 'overall': {}}
    fair_by_band = {}
    fair_all = []
    for ck, cell in raw['cells'].items():
        if cell['workload'] == 'latency':
            continue
        rates = {b: cell['brokers'][b]['median_msgs_per_s']
                 for b in BROKER_ORDER}
        if not all(rates[b] for b in BROKER_ORDER):
            continue
        # HyrxMQ/new: require every broker connected all requested workers
        want = int(cell['concurrency'])
        if any((cell['brokers'][b]['workers_connected'] or [0]) and
               max(cell['brokers'][b]['workers_connected']) < want
               for b in BROKER_ORDER):
            continue
        fair_all.append((ck, cell))
        fair_by_band.setdefault(band(cell['concurrency']), []).append((ck, cell))
    for bname, items in fair_by_band.items():
        geos = {b: [] for b in BROKER_ORDER}
        for ck, cell in items:
            fastest = cell['fastest_msgs_per_s']
            for b in BROKER_ORDER:
                v = cell['brokers'][b]['median_msgs_per_s']
                if fastest and v:
                    geos[b].append(fastest / v)
        gm = {b: (round(math.exp(sum(math.log(x) for x in xs) / len(xs)), 4)
                  if xs else None) for b, xs in geos.items()}
        ranked = sorted(((r, b) for b, r in gm.items() if r),
                        key=lambda x: x[0])
        verdict['bands'][bname] = {
            'fair_cell_count': len(items),
            'geomean_ratio_vs_fastest': gm,
            'ranking': [b for _r, b in ranked],
            'winner': ranked[0][1] if ranked else None,
            'cells': [ck for ck, _c in items],
            'clean': geomean_verdict(items, 'median_clean_msgs_per_s'),
        }
    geos = {b: [] for b in BROKER_ORDER}
    for ck, cell in fair_all:
        fastest = cell['fastest_msgs_per_s']
        for b in BROKER_ORDER:
            v = cell['brokers'][b]['median_msgs_per_s']
            if fastest and v:
                geos[b].append(fastest / v)
    gm = {b: (round(math.exp(sum(math.log(x) for x in xs) / len(xs)), 4)
              if xs else None) for b, xs in geos.items()}
    ranked = sorted(((r, b) for b, r in gm.items() if r), key=lambda x: x[0])
    verdict['overall'] = {
        'fair_cell_count': len(fair_all),
        'geomean_ratio_vs_fastest': gm,
        'ranking': [b for _r, b in ranked],
        'winner': ranked[0][1] if ranked else None,
        'cells': [ck for ck, _c in fair_all],
        'clean': geomean_verdict(fair_all, 'median_clean_msgs_per_s'),
    }
    raw['verdict'] = verdict

    with open(args.raw, 'w') as fh:
        json.dump(raw, fh, indent=1)
    with open(args.consolidated, 'w') as fh:
        json.dump({'schema': 2, 'run_id': raw['run_id'], 'host': raw['host'],
                   'images': raw['images'], 'cells': raw['cells'],
                   'verdict': verdict, 'reps': args.reps,
                   'target_rep_s': args.target, 'mode': args.mode,
                   'started_utc': args.started, 'finished_utc': args.finished},
                  fh, indent=1)
    print(f'collected {len(runs)} runs, {len(raw["cells"])} cells, '
          f'{verdict["overall"]["fair_cell_count"]} fair cells')
    return 0


def spread(items, key):
    """Geomean of per-cell ratio-to-fastest for one rate key."""
    geos = {b: [] for b in BROKER_ORDER}
    for _ck, cell in items:
        vals = {b: cell['brokers'][b].get(key) for b in BROKER_ORDER}
        valid = [v for v in vals.values() if v]
        fastest = max(valid) if valid else None
        for b in BROKER_ORDER:
            if fastest and vals[b]:
                geos[b].append(fastest / vals[b])
    gm = {b: (round(math.exp(sum(math.log(x) for x in xs) / len(xs)), 4)
              if xs else None) for b, xs in geos.items()}
    ranked = sorted(((r, b) for b, r in gm.items() if r), key=lambda x: x[0])
    return {'geomean_ratio_vs_fastest': gm,
            'ranking': [b for _r, b in ranked],
            'winner': ranked[0][1] if ranked else None}


def geomean_verdict(items, key):
    return spread(items, key)


def resources_for_run(run, stats):
    """Samples whose timestamp falls inside [t_start, t_start+wall+1.0]."""
    t0 = run.get('t_start')
    if t0 is None:
        return {}
    try:
        t0 = float(t0)
    except (TypeError, ValueError):
        return {}
    res = run.get('result') or {}
    wall = res.get('wall_s') or 0.0
    lo, hi = t0, t0 + wall + 1.0
    broker = run['broker']
    cpus, rss = [], []
    for s in stats:
        if s['broker'] == broker and lo <= s['ts'] <= hi:
            cpus.append(s['cpu_pct'])
            if s['rss_bytes'] is not None:
                rss.append(s['rss_bytes'])
    return {'cpu_pct_median': r1(median(cpus)), 'cpu_pct_max':
            r1(max(cpus)) if cpus else None,
            'rss_bytes_median': median(rss),
            'rss_bytes_max': max(rss) if rss else None,
            'samples': len(cpus)}


def resources_for_broker(entry, stats):
    cpus = [r['resources'].get('cpu_pct_median')
            for r in entry['runs'] if r.get('resources')]
    cpus = [c for c in cpus if c is not None]
    rss = [r['resources'].get('rss_bytes_median')
           for r in entry['runs'] if r.get('resources')]
    rss = [x for x in rss if x is not None]
    return {'cpu_pct_median': r1(median(cpus)),
            'rss_bytes_median': median(rss)}


if __name__ == '__main__':
    sys.exit(main())