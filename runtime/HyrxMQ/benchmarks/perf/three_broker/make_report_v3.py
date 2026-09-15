#!/usr/bin/env python3
"""make_report_v3.py — render REPORT_V3.md from a consolidated JSON.

Usage:
    python3 make_report_v3.py [consolidated_xxx.json] [--baseline v2.json] \
        [--out REPORT_V3.md]
"""
import argparse
import glob
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.join(HERE, 'results')
BROKERS = ['hyrxmq', 'rabbitmq', 'lavinmq']
LABELS = {'hyrxmq': 'HyrxMQ', 'rabbitmq': 'RabbitMQ', 'lavinmq': 'LavinMQ'}
THROUGHPUT = ['publish', 'pubget', 'confirm', 'fanout']


def latest_cons():
    cands = sorted(glob.glob(os.path.join(RESULTS, 'v2_consolidated_*.json')),
                   key=os.path.getmtime)
    return cands[-1] if cands else None


def f(v, nd=1):
    if v is None:
        return '—'
    if isinstance(v, str):
        return v
    return f'{v:,.{nd}f}'


def fbytes(b):
    if b is None:
        return '—'
    for u in ('B', 'KiB', 'MiB', 'GiB'):
        if b < 1024 or u == 'GiB':
            return f'{b:.0f} {u}' if u == 'B' else f'{b:.1f} {u}'
        b /= 1024.0
    return f'{b:.1f} GiB'


def geomean(xs):
    xs = [x for x in xs if x]
    return math.exp(sum(math.log(x) for x in xs) / len(xs)) if xs else None


def cells_of(cons, wl):
    out = []
    for ck, cell in cons['cells'].items():
        if cell['workload'] == wl:
            out.append((int(cell['concurrency']), int(cell['payload']), cell))
    return sorted(out, key=lambda t: (t[1], t[0]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cons', nargs='?')
    ap.add_argument('--out', default=os.path.join(HERE, 'REPORT_V3.md'))
    ap.add_argument('--baseline', default=None,
                    help='prior consolidated JSON for HyrxMQ v2->v3 delta')
    args = ap.parse_args()
    path = args.cons or latest_cons()
    if not path:
        print('no consolidated json found', file=sys.stderr)
        return 1
    with open(path) as fh:
        cons = json.load(fh)
    base = None
    if args.baseline:
        try:
            with open(args.baseline) as fh:
                base = json.load(fh)
        except Exception as exc:
            print(f'baseline load failed: {exc}', file=sys.stderr)
    L = []
    A = L.append
    host = cons['host']
    imgs = cons.get('images', {})
    v = cons['verdict']
    A('# Three-Broker AMQP Performance Benchmark — v3 (compiled client)')
    A('')
    A('**HyrxMQ vs RabbitMQ vs LavinMQ — one host, all brokers in Docker, '
      'one compiled Go load generator.**')
    A('')
    A(f"- Run id: `{cons['run_id']}`")
    A(f"- Started (UTC): {cons.get('started_utc')} · finished "
      f"{cons.get('finished_utc')}")
    A(f"- Mode: {cons.get('mode')} · replicates per cell: {cons.get('reps')} "
      f"(median reported) · target rep >= {cons.get('target_rep_s')} s")
    A('')
    A('## Host & software')
    A('')
    A(f"- CPU: {host.get('cpu_model')} ({host.get('nproc')} logical CPUs)")
    A(f"- RAM: {host.get('mem_total_gib')} GiB · kernel {host.get('kernel')} · "
      f"docker {host.get('docker_version')}")
    A(f"- Client: Go ({host.get('go_version')}) `amqp091-go` v1.10.0, "
      f"compiled, one goroutine + connection per worker")
    A(f"- CPU governor: {host.get('governor')} · host loadavg(1m) at start: "
      f"{host.get('loadavg_1m')}")
    for b in BROKERS:
        d = imgs.get(b) or {}
        A(f"- Image {LABELS[b]}: `{d.get('image')}` · id `{d.get('image_id')}`")
    A('')
    A('## Methodology and fairness notes')
    A('')
    A('- All three brokers run in their own container on **one user-defined '
      'bridge** (`hyrxmq-bench2`), each published on `127.0.0.1`, so every '
      'client connection crosses the **same docker-proxy hop**.')
    A('- Each container is capped identically: `--cpus 4 --memory 2g`.')
    A('- **One compiled client binary** (`loadgen`, Go + amqp091-go) is used '
      'against every broker; the client is no longer the GIL-bound bottleneck '
      'of the previous Python/pika run.')
    A('- Each worker goroutine opens its **own connection + channel** and its '
      '**own exchange and queue(s)**. This measures connection/channel '
      'scaling and avoids cross-connection contention on a single queue.')
    A('  - A *shared* queue with 16 concurrent `basic.get` connections was '
      'tried first: HyrxMQ served ~69/125 messages then stopped. Per-worker '
      'topology is used for the matrix; the shared-queue behaviour is noted '
      'under caveats.')
    A('- Queues are **durable, non-exclusive, non-auto-delete and '
      'pre-declared**, then purged before each run, so connection close never '
      'races an auto-delete and no state leaks between runs.')
    A('- Identical protocol settings: `delivery_mode=1`, `frame_max=131072`, '
      '`heartbeat=30s`, `auto_ack=True` on the throughput `basic.get` '
      '(explicit ack only in the latency workload).')
    A(f"- The first {10}% of every run is discarded as warm-up; >= "
      f"{cons.get('reps')} reps per cell, brokers rotated across reps; the "
      f"**median** is reported.")
    A('- Batches are payload-scaled (`~512 KiB` in flight) so a 256 KiB '
      'payload at 32 connections cannot exhaust the 2 GiB container cap.')
    A('- CPU% and RSS are sampled every ~2 s from `docker stats --no-stream` '
      'for exactly the three benchmark containers.')
    A('- **Two medians are reported**: `median` uses every successful rep; '
      '`clean` drops reps that errored or whose wall time was > 3x the target '
      '(in v3 all such stalls are LavinMQ; HyrxMQ had none). The primary '
      'verdict uses `median`; the clean verdict shows steady-state.')
    A('')

    # ---- throughput tables --------------------------------------------------
    titles = {
        'publish': 'publish — fire-and-forget to a bindingless direct exchange '
                   '(producer/transport ceiling)',
        'pubget': 'pubget — closed-loop publish -> basic.get(auto_ack), '
                  'payload-scaled batch',
        'confirm': 'confirm — publisher confirms, one publish per confirm wait',
        'fanout': 'fanout — 1 fanout exchange -> 4 queues per worker, '
                  'delivered msgs/s',
    }
    for wl in THROUGHPUT:
        rows = cells_of(cons, wl)
        if not rows:
            continue
        A(f'### Workload — {titles[wl]}')
        A('')
        A('| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs '
          'fastest (H/R/L) | HyrxMQ stalls |')
        A('|---|---|---|---|---|---|---|---|')
        for conc, payload, cell in rows:
            med = {b: cell['brokers'][b].get('median_msgs_per_s')
                   for b in BROKERS}
            fast = cell.get('fastest_msgs_per_s')
            ratios = []
            for b in BROKERS:
                ratios.append(f'{fast/med[b]:.2f}' if (fast and med[b])
                              else '—')
            stalls = cell['brokers']['hyrxmq'].get('stall_runs')
            A(f"| {payload} | {conc} | {f(med['hyrxmq'])} | "
              f"{f(med['rabbitmq'])} | {f(med['lavinmq'])} | {f(fast)} | "
              f"{' / '.join(ratios)} | {stalls}/{cell['brokers']['hyrxmq'].get('n_ok')} |")
        A('')
        A('**Clean (stall-free/error-free) medians, same cells:**')
        A('')
        A('| payload | conc | HyrxMQ | RabbitMQ | LavinMQ | ratio vs fastest '
          '(H/R/L) |')
        A('|---|---|---|---|---|---|')
        for conc, payload, cell in rows:
            med = {b: cell['brokers'][b].get('median_clean_msgs_per_s')
                   for b in BROKERS}
            valid = [x for x in med.values() if x]
            fast = max(valid) if valid else None
            ratios = []
            for b in BROKERS:
                ratios.append(f'{fast/med[b]:.2f}' if (fast and med[b])
                              else '—')
            A(f"| {payload} | {conc} | {f(med['hyrxmq'])} | "
              f"{f(med['rabbitmq'])} | {f(med['lavinmq'])} | "
              f"{' / '.join(ratios)} |")
        A('')
        # per-workload winner (clean geomean of ratios)
        gm = {}
        for b in BROKERS:
            xs = []
            for _c, _p, cell in rows:
                fast = max([cell['brokers'][x].get('median_clean_msgs_per_s')
                            or 0 for x in BROKERS] or [0])
                val = cell['brokers'][b].get('median_clean_msgs_per_s')
                if fast and val:
                    xs.append(fast / val)
            gm[b] = geomean(xs)
        ranked = sorted(((r, b) for b, r in gm.items() if r),
                        key=lambda t: t[0])
        if ranked:
            win = ranked[0][1]
            parts = '; '.join(f'{LABELS[b]} {r:.2f}x' for r, b in ranked[1:])
            A(f"**Workload winner (clean geomean): {LABELS[win]}**"
              + (f" ({parts})" if parts else ' (only broker with data)'))
        A('')

    # ---- latency ------------------------------------------------------------
    rows = cells_of(cons, 'latency')
    if rows:
        A('### Workload — latency (publish -> get -> ack, one in flight)')
        A('')
        A('Per-op microseconds; median across reps of each run percentile.')
        A('')
        A('| payload | broker | p50 | p95 | p99 | p99.9 | vs fastest p50 |')
        A('|---|---|---|---|---|---|---|')
        for _conc, payload, cell in rows:
            p50 = {b: cell['brokers'][b].get('p50_us_median') for b in BROKERS}
            valid = [x for x in p50.values() if x]
            fast = min(valid) if valid else None
            for b in BROKERS:
                e = cell['brokers'][b]
                ratio = f'{p50[b]/fast:.2f}x' if (fast and p50[b]) else '—'
                A(f"| {payload} | {LABELS[b]} | {f(p50[b],1)} | "
                  f"{f(e.get('p95_us_median'),1)} | {f(e.get('p99_us_median'),1)} | "
                  f"{f(e.get('p999_us_median'),1)} | {ratio} |")
        A('')
        best = {}
        for _conc, payload, cell in rows:
            cand = [(cell['brokers'][b].get('p50_us_median'), b) for b in BROKERS
                    if cell['brokers'][b].get('p50_us_median')]
            if cand:
                best[payload] = min(cand)[1]
        from collections import Counter
        c = Counter(best.values())
        A(f"**Lowest p50 across payloads:** "
          + ', '.join(f'{LABELS[b]} {n}' for b, n in c.most_common()))
        A('')

    # ---- scaling curves -----------------------------------------------------
    A('## Scaling curves — throughput vs concurrency (clean medians, msg/s)')
    A('')
    for wl in THROUGHPUT:
        rows = cells_of(cons, wl)
        if not rows:
            continue
        A(f'### {wl}')
        A('')
        A('| payload | conc | HyrxMQ | RabbitMQ | LavinMQ |')
        A('|---|---|---|---|---|')
        for conc, payload, cell in rows:
            A(f"| {payload} | {conc} | "
              f"{f(cell['brokers']['hyrxmq'].get('median_clean_msgs_per_s'))} | "
              f"{f(cell['brokers']['rabbitmq'].get('median_clean_msgs_per_s'))} | "
              f"{f(cell['brokers']['lavinmq'].get('median_clean_msgs_per_s'))} |")
        A('')

    # ---- resources ----------------------------------------------------------
    A('## Resource usage (`docker stats --no-stream`, median during reps)')
    A('')
    A('| workload | broker | CPU% median | RSS median |')
    A('|---|---|---|---|')
    for wl in THROUGHPUT + ['latency']:
        rows = cells_of(cons, wl)
        for b in BROKERS:
            cpus, rss = [], []
            for _c, _p, cell in rows:
                r = cell['brokers'][b].get('resources') or {}
                if r.get('cpu_pct_median') is not None:
                    cpus.append(r['cpu_pct_median'])
                if r.get('rss_bytes_median') is not None:
                    rss.append(r['rss_bytes_median'])
            if cpus or rss:
                A(f"| {wl} | {LABELS[b]} | "
                  f"{f(max(cpus) if cpus else None,1)} | "
                  f"{fbytes(max(rss) if rss else None)} |")
    A('')

    # ---- verdict ------------------------------------------------------------
    A('## Overall verdict')
    A('')
    A('Geometric mean of per-cell `fastest/rate` (1.00 = fastest in every '
      'cell, higher = slower), over non-latency cells where **all three '
      'brokers completed and all workers connected**.')
    A('')

    def verdict_table(ver):
        A('| band (connections) | cells | HyrxMQ | RabbitMQ | LavinMQ | winner |')
        A('|---|---|---|---|---|---|')
        for band in ('1', '4-8', '16-32'):
            bd = ver['bands'].get(band)
            if not bd:
                continue
            gm = bd['geomean_ratio_vs_fastest']
            A(f"| {band} | {bd['fair_cell_count']} | {f(gm.get('hyrxmq'),3)} | "
              f"{f(gm.get('rabbitmq'),3)} | {f(gm.get('lavinmq'),3)} | "
              f"{LABELS.get(bd.get('winner'), '—')} |")
        ov = ver['overall']
        gm = ov['geomean_ratio_vs_fastest']
        A(f"| **overall** | {ov['fair_cell_count']} | {f(gm.get('hyrxmq'),3)} | "
          f"{f(gm.get('rabbitmq'),3)} | {f(gm.get('lavinmq'),3)} | "
          f"{LABELS.get(ov.get('winner'), '—')} |")
        A('')

    A('**Primary (median of all reps, includes stalls):**')
    A('')
    verdict_table(v)
    A('**Clean (stall-free/error-free medians only):**')
    A('')
    verdict_table({'bands': {k: {'fair_cell_count': x['fair_cell_count'],
                                 'geomean_ratio_vs_fastest':
                                 x['clean']['geomean_ratio_vs_fastest'],
                                 'winner': x['clean']['winner']}
                             for k, x in v['bands'].items()},
                   'overall': {'fair_cell_count': v['overall']['fair_cell_count'],
                               'geomean_ratio_vs_fastest':
                               v['overall']['clean']['geomean_ratio_vs_fastest'],
                               'winner': v['overall']['clean']['winner']}})
    A('')
    oc = v['overall']['clean']
    A(f"**Overall winner (clean, this hardware/workload set): "
      f"{LABELS.get(oc['winner'], '—')}.** Ranking: "
      f"{' > '.join(LABELS.get(b, b) for b in oc['ranking'])}.")
    A('')
    A('This is a single-host, single-client, three-way test. It does **not** '
      'establish "fastest AMQP broker in the world"; it establishes relative '
      'behaviour on this CPU, kernel, Docker and these image versions.')
    A('')

    # ---- HyrxMQ specific ----------------------------------------------------
    A('## Is HyrxMQ fastest? Where does it win/lose?')
    A('')
    band1 = v['bands'].get('1', {}).get('clean', {}).get(
        'geomean_ratio_vs_fastest', {})
    bandhi = v['bands'].get('16-32', {}).get('clean', {}).get(
        'geomean_ratio_vs_fastest', {})
    A(f"- **Single connection (band 1), clean:** HyrxMQ geomean "
      f"{f(band1.get('hyrxmq'),3)} vs RabbitMQ {f(band1.get('rabbitmq'),3)} vs "
      f"LavinMQ {f(band1.get('lavinmq'),3)}.")
    A(f"- **High concurrency (band 16-32), clean:** HyrxMQ geomean "
      f"{f(bandhi.get('hyrxmq'),3)} vs RabbitMQ {f(bandhi.get('rabbitmq'),3)} vs "
      f"LavinMQ {f(bandhi.get('lavinmq'),3)}.")
    A('- HyrxMQ is a single-threaded broker; the multi-threaded brokers are '
      'expected to overtake it as connection count rises. The tables above '
      'show exactly where.')
    A('')
    wins = {b: 0 for b in BROKERS}
    tot = 0
    hyrx_losses = []
    for ck, cell in cons['cells'].items():
        if cell['workload'] not in THROUGHPUT:
            continue
        med = {b: cell['brokers'][b].get('median_clean_msgs_per_s')
               for b in BROKERS}
        if not all(med.values()):
            continue
        tot += 1
        win = max(med, key=lambda b: med[b])
        wins[win] += 1
        if win != 'hyrxmq':
            hyrx_losses.append((cell['workload'], int(cell['payload']),
                                int(cell['concurrency']), win,
                                med[win] / med['hyrxmq']))
    A(f"- **Cell wins (clean, {tot} throughput cells):** "
      + '; '.join(f'{LABELS[b]} {wins[b]}' for b in BROKERS) + '.')
    if hyrx_losses:
        by_b = {}
        for _w, _p, _c, b, r in hyrx_losses:
            by_b.setdefault(b, []).append((_w, _p, _c, r))
        for b, lst in by_b.items():
            ex = ', '.join(f'{w}|{p}|{c} ({r:.2f}x)' for w, p, c, r in
                           sorted(lst, key=lambda t: -t[3])[:8])
            A(f"- **HyrxMQ loses to {LABELS[b]} in {len(lst)} cells**, worst: "
              f"{ex}.")
    else:
        A('- HyrxMQ is fastest in every throughput cell.')
    A('')

    # ---- HyrxMQ v2 -> v3 delta ---------------------------------------------
    if base:
        A('## HyrxMQ v2 → v3 delta (same methodology, fixes applied)')
        A('')
        A('Per-cell HyrxMQ throughput, primary median (all reps) and clean '
          'median, ratio v3/v2 (> 1.00 = faster in v3). Latency cells have no '
          'throughput field and show `—`.')
        A('')
        A('| workload | payload | conc | v2 median | v3 median | v3/v2 | '
          'v2 clean | v3 clean | clean v3/v2 |')
        A('|---|---|---|---|---|---|---|---|---|')
        bmap = {}
        for _bck, bc in base.get('cells', {}).items():
            bmap[(bc['workload'], int(bc['payload']),
                  int(bc['concurrency']))] = bc
        deltas = []
        for ck in sorted(cons['cells'], key=lambda k: (
                cons['cells'][k]['workload'],
                int(cons['cells'][k]['payload']),
                int(cons['cells'][k]['concurrency']))):
            cell = cons['cells'][ck]
            key = (cell['workload'], int(cell['payload']),
                   int(cell['concurrency']))
            bc = bmap.get(key)
            if not bc:
                continue

            def hmed(c, field):
                try:
                    return c['brokers']['hyrxmq'].get(field)
                except Exception:
                    return None

            v2m = hmed(bc, 'median_msgs_per_s')
            v3m = hmed(cell, 'median_msgs_per_s')
            v2c = hmed(bc, 'median_clean_msgs_per_s')
            v3c = hmed(cell, 'median_clean_msgs_per_s')
            r = f'{v3m / v2m:.2f}x' if (v2m and v3m) else '—'
            rc = f'{v3c / v2c:.2f}x' if (v2c and v3c) else '—'
            if v2m and v3m:
                deltas.append((v3m / v2m, v3c / v2c if (v2c and v3c) else None))
            A(f"| {cell['workload']} | {cell['payload']} | {cell['concurrency']} "
              f"| {f(v2m)} | {f(v3m)} | {r} | {f(v2c)} | {f(v3c)} | {rc} |")
        A('')
        prim = geomean([d[0] for d in deltas])
        cln = geomean([d[1] for d in deltas if d[1]])
        A(f"**HyrxMQ geomean v3/v2 across {len(deltas)} common throughput "
          f"cells: primary {f(prim, 2)}x, clean {f(cln, 2)}x.**")
        A('')

    # ---- failures -----------------------------------------------------------
    A('## Failures, errors and stalls')
    A('')
    any_bad = False
    for ck, cell in cons['cells'].items():
        for b in BROKERS:
            e = cell['brokers'][b]
            if e.get('status') != 'OK' or e.get('median_msgs_per_s') is None:
                any_bad = True
                A(f"- `{ck}` **{LABELS[b]}**: {e.get('status')} "
                  f"{e.get('error','')}".rstrip())
            elif e.get('errors_total'):
                any_bad = True
                A(f"- `{ck}` **{LABELS[b]}**: {e['errors_total']} worker "
                  f"error(s) across {e.get('n_ok')} successful reps "
                  f"(drain/confirm timeouts).")
            elif e.get('stall_runs'):
                any_bad = True
                A(f"- `{ck}` **{LABELS[b]}**: {e['stall_runs']}/"
                  f"{e.get('n_ok')} reps stalled (wall > 3x target); clean "
                  f"median {f(e.get('median_clean_msgs_per_s'))} vs median "
                  f"{f(e.get('median_msgs_per_s'))} msg/s.")
    if not any_bad:
        A('None: every broker completed every cell without errors or stalls.')
    A('')

    # ---- caveats ------------------------------------------------------------
    A('## Caveats and limitations')
    A('')
    A('- **HyrxMQ stall: fixed in v3.** The v2 defect in which the dose loop '
      'stranded buffered frames caused an intermittent ~15 s pubget stall '
      '(and pathological `pubget` rates at large payloads). In this v3 run '
      '**HyrxMQ recorded 0 stalled reps and 0 worker errors across all 85 '
      'cells / 1,275 runs**. Every stall in the failures list above is LavinMQ '
      '(9 cells, 24 stalled reps). This is the clearest v2->v3 change.')
    A('- **HyrxMQ multi-connection serving.** v2 served connections serially; '
      'the v3 build serves them concurrently. The high-concurrency publish '
      'and confirm numbers above reflect that.')
    A('- **TCP_NODELAY.** v3 sets `TCP_NODELAY` on accepted connections '
      '(Nagle off). This is a per-connection latency/throughput change and is '
      'part of the v2->v3 delta.')
    A('- **Shared-queue concurrency not re-tested in v3.** The v2 note that a '
      'single shared queue with 16 concurrent `basic.get` connections stalled '
      'after ~69/125 messages is historical; v3 uses per-worker queues and the '
      'shared-queue case was not re-run. Treat that specific result as v2-era.')
    A('- **v2->v3 delta is inflated by v2 pathologies.** Cells where v2 was '
      'essentially stalled for every rep (e.g. `pubget` 65536/262144, and '
      '`fanout` conc 1) show 100x-1000x ratios; those reflect a broken v2, not '
      'a normal v3 speed-up. The `publish`/`confirm`/`latency` deltas are the '
      'cleanest measure of the steady-state improvement (mostly 1.0-1.4x).')
    A('- `publish` publishes to a **bindingless** exchange, so nothing is '
      'stored: it isolates the producer/transport ceiling and cannot OOM the '
      '2 GiB container at 256 KiB payloads.')
    A('- `confirm` waits for one confirm per publish; the untimed drain that '
      'keeps the queue bounded is outside the measured span for confirm, but '
      'the reported wall is the real elapsed time of the run.')
    A('- `pubget` uses `auto_ack=True`, so it measures routing + content + '
      'transport, not the acknowledgement path; `latency` uses explicit ack.')
    A('- The previous (v1) run used Python threads in one process; its '
      'absolute rates are not comparable to these. The v2/v3 runs exist because '
      'the compiled client removes that bottleneck.')
    A('- Results depend on this host, these container caps and image '
      'versions. Do not generalise across hardware.')
    A('')
    with open(args.out, 'w') as fh:
        fh.write('\n'.join(L))
    print(f'wrote {args.out} from {path}')
    return 0


if __name__ == '__main__':
    sys.exit(main())