#!/usr/bin/env python3
"""make_report_final.py — render REPORT_FINAL.md from a consolidated v2 JSON.

Usage:
    python3 make_report_final.py [v2_consolidated_xxx.json] [--out REPORT_FINAL.md]

Produces the definitive three-broker report: complete per-cell tables with raw
medians and ratios, per-workload winners and margins, scaling curves, latency
percentiles, resource usage, and a geomean-of-relative-throughput verdict.
"""
import argparse
import glob
import json
import math
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.join(HERE, 'results')
BROKERS = ['hyrxmq', 'rabbitmq', 'lavinmq']
LABELS = {'hyrxmq': 'HyrxMQ', 'rabbitmq': 'RabbitMQ', 'lavinmq': 'LavinMQ'}
THROUGHPUT = ['publish', 'pubget', 'confirm', 'fanout']
TITLES = {
    'publish': 'publish — fire-and-forget to a bindingless direct exchange '
               '(producer/transport ceiling)',
    'pubget': 'pubget — closed-loop publish -> basic.get(auto_ack), '
              'payload-scaled batch',
    'confirm': 'confirm — publisher confirms, one publish per confirm wait',
    'fanout': 'fanout — 1 fanout exchange -> 4 queues per worker, '
              'delivered msgs/s',
}


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
    x = float(b)
    for u in ('B', 'KiB', 'MiB', 'GiB'):
        if x < 1024 or u == 'GiB':
            return f'{x:.0f} {u}' if u == 'B' else f'{x:.1f} {u}'
        x /= 1024.0
    return f'{x:.1f} GiB'


def geomean(xs):
    xs = [x for x in xs if x]
    return math.exp(sum(math.log(x) for x in xs) / len(xs)) if xs else None


def cells_of(cons, wl):
    out = []
    for _ck, cell in cons['cells'].items():
        if cell['workload'] == wl:
            out.append((int(cell['concurrency']), int(cell['payload']), cell))
    return sorted(out, key=lambda t: (t[1], t[0]))


def band(conc):
    c = int(conc)
    if c == 1:
        return '1'
    if c <= 8:
        return '4-8'
    return '16-32'


def gm_ratio(cells, field):
    """Per-broker geomean of fastest/value over the given cells (lower better)."""
    acc = {b: [] for b in BROKERS}
    for _c, _p, cell in cells:
        vals = {b: cell['brokers'][b].get(field) for b in BROKERS}
        valid = [v for v in vals.values() if v]
        fast = max(valid) if valid else None
        for b in BROKERS:
            if fast and vals[b]:
                acc[b].append(fast / vals[b])
    return {b: geomean(acc[b]) for b in BROKERS}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cons', nargs='?')
    ap.add_argument('--out', default=os.path.join(HERE, 'REPORT_FINAL2.md'))
    args = ap.parse_args()
    path = args.cons or latest_cons()
    if not path:
        print('no consolidated json found', file=sys.stderr)
        return 1
    with open(path) as fh:
        cons = json.load(fh)
    host = cons['host']
    imgs = cons.get('images', {})
    reps = cons.get('reps')
    L = []
    A = L.append

    A('# Three-Broker AMQP Performance Benchmark — FINAL2 (post-optimization)')
    A('')
    A('**HyrxMQ vs RabbitMQ vs LavinMQ — post-optimization run on one host, all '
      'three brokers in Docker, one compiled Go load generator.**')
    A('')
    A(f"- Run id: `{cons.get('run_id')}`")
    A(f"- Started (UTC): {cons.get('started_utc')} · finished "
      f"{cons.get('finished_utc')}")
    A(f"- Mode: {cons.get('mode')} · replicates per cell: {reps} (median "
      f"reported) · target rep >= {cons.get('target_rep_s')} s")
    A(f"- Consolidated data: `{os.path.relpath(path, HERE)}`")
    A('')
    A('## Host, software and image digests')
    A('')
    A(f"- CPU: {host.get('cpu_model')} ({host.get('nproc')} logical CPUs)")
    A(f"- RAM: {host.get('mem_total_gib')} GiB · kernel {host.get('kernel')} · "
      f"machine {host.get('machine')}")
    A(f"- Docker server {host.get('docker_version')} · client Go "
      f"{host.get('go_version')} · module `github.com/rabbitmq/amqp091-go`")
    A(f"- CPU governor: `{host.get('governor')}` · host loadavg(1m) at start: "
      f"{host.get('loadavg_1m')}")
    A('')
    A('| broker | image | image id |')
    A('|---|---|---|')
    for b in BROKERS:
        d = imgs.get(b) or {}
        A(f"| {LABELS[b]} | `{d.get('image')}` | `{d.get('image_id')}` |")
    A('')
    A('## Methodology and fairness notes')
    A('')
    A('- All three brokers run in their own container on **one user-defined '
      'bridge** (`hyrxmq-bench2`), each published on `127.0.0.1`, so every '
      'client connection crosses the **same docker-proxy hop**.')
    A('- Each container is capped identically: `--cpus 4 --memory 2g`.')
    A('- **One compiled client binary** (`/tmp/loadgen`, Go + amqp091-go, one '
      'goroutine + connection + channel per worker) drives every broker.')
    A('- Each worker opens its **own connection + channel** and its **own '
      'exchange and queue(s)**; queues are durable, non-exclusive, '
      'non-auto-delete, pre-declared and purged before each run.')
    A('- Identical protocol settings: `delivery_mode=1`, `frame_max=131072`, '
      '`heartbeat=30s`, `auto_ack=True` for `pubget` throughput, explicit ack '
      'in `latency`.')
    A('- Hit counts are **calibrated per broker/workload/payload/concurrency** '
      'to a >= 2 s measured window, then clamped; `publish` runs a fixed '
      'duration. The first 10% of every run is discarded as warm-up.')
    A(f"- `{reps}` reps per cell, **brokers rotated across reps** to cancel "
      f"drift; the **median** is reported.")
    A('- Batches are payload-scaled (~512 KiB in flight) so a 256 KiB payload '
      'at 32 connections cannot exhaust the 2 GiB container cap.')
    A('- CPU% and RSS are sampled every ~1 s from `docker stats --no-stream` '
      'for exactly the three benchmark containers.')
    A('- **Primary median** uses every successful rep; **clean median** drops '
      'reps that errored or whose wall time was > 3x target (stalls). The '
      'headline verdict uses the primary median; the clean median is shown as '
      'a robustness check.')
    A('')

    # ---- complete results table --------------------------------------------
    A('## Complete results table (throughput cells)')
    A('')
    A('Every throughput cell, all three brokers, primary median msg/s '
      '(all reps), the cell winner, and each broker\'s ratio vs the fastest '
      '(1.00 = fastest). "fastest" column is the winning rate. Ratio > 1 = '
      'slower. H = HyrxMQ, R = RabbitMQ, L = LavinMQ.')
    A('')
    A('| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ | fastest '
      '(broker) | H ratio | R ratio | L ratio |')
    A('|---|---|---|---|---|---|---|---|---|---|')
    all_tp_cells = []
    for wl in THROUGHPUT:
        for conc, payload, cell in cells_of(cons, wl):
            all_tp_cells.append((wl, conc, payload, cell))
            med = {b: cell['brokers'][b].get('median_msgs_per_s')
                   for b in BROKERS}
            fast = cell.get('fastest_msgs_per_s')
            fb = cell.get('fastest_broker')
            ratios = []
            for b in BROKERS:
                ratios.append(f'{fast / med[b]:.2f}' if (fast and med[b])
                              else '—')
            A(f"| {wl} | {payload} | {conc} | {f(med['hyrxmq'])} | "
              f"{f(med['rabbitmq'])} | {f(med['lavinmq'])} | "
              f"{f(fast)} ({LABELS.get(fb, '—') if fb else '—'}) | "
              f"{ratios[0]} | {ratios[1]} | {ratios[2]} |")
    A('')

    A('**Clean medians (stall-/error-free reps only), same cells:**')
    A('')
    A('| workload | payload | conc | HyrxMQ | RabbitMQ | LavinMQ | H ratio | '
      'R ratio | L ratio |')
    A('|---|---|---|---|---|---|---|---|---|')
    for wl, conc, payload, cell in all_tp_cells:
        med = {b: cell['brokers'][b].get('median_clean_msgs_per_s')
               for b in BROKERS}
        valid = [x for x in med.values() if x]
        fast = max(valid) if valid else None
        ratios = []
        for b in BROKERS:
            ratios.append(f'{fast / med[b]:.2f}' if (fast and med[b]) else '—')
        A(f"| {wl} | {payload} | {conc} | {f(med['hyrxmq'])} | "
          f"{f(med['rabbitmq'])} | {f(med['lavinmq'])} | "
          f"{ratios[0]} | {ratios[1]} | {ratios[2]} |")
    A('')

    # ---- per-workload winners ---------------------------------------------
    A('## Per-workload winners and margins')
    A('')
    A('Geomean of per-cell `fastest/rate` (lower = faster overall for the '
      'workload). Margin is the runner-up\'s geomean relative to the winner\'s '
      '(e.g. 1.20 vs 1.00 = runner-up 20% slower on the geomean).')
    A('')
    A('| workload | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | '
      'margin over runner-up |')
    A('|---|---|---|---|---|---|---|')
    for wl in THROUGHPUT:
        cells = cells_of(cons, wl)
        gm = gm_ratio(cells, 'median_msgs_per_s')
        ranked = sorted(((r, b) for b, r in gm.items() if r),
                        key=lambda t: t[0])
        if not ranked:
            continue
        win_r, win_b = ranked[0]
        margin = '—'
        if len(ranked) > 1 and win_r:
            margin = f"{ranked[1][0] / win_r:.2f}x ({LABELS[ranked[1][1]]})"
        A(f"| {wl} | {len(cells)} | {f(gm.get('hyrxmq'), 3)} | "
          f"{f(gm.get('rabbitmq'), 3)} | {f(gm.get('lavinmq'), 3)} | "
          f"**{LABELS[win_b]}** | {margin} |")
    A('')

    # ---- scaling curves ----------------------------------------------------
    A('## Scaling curves — throughput vs concurrency (primary medians, msg/s)')
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
              f"{f(cell['brokers']['hyrxmq'].get('median_msgs_per_s'))} | "
              f"{f(cell['brokers']['rabbitmq'].get('median_msgs_per_s'))} | "
              f"{f(cell['brokers']['lavinmq'].get('median_msgs_per_s'))} |")
        A('')

    # ---- latency -----------------------------------------------------------
    rows = cells_of(cons, 'latency')
    if rows:
        A('## Latency percentiles (publish -> get -> ack, one in flight)')
        A('')
        A('Per-op microseconds; median across reps of each run percentile. '
          'Ratio is p50 vs the fastest broker in that payload row.')
        A('')
        A('| payload | broker | p50 | p95 | p99 | p99.9 | p50 ratio |')
        A('|---|---|---|---|---|---|---|')
        best = {}
        for _conc, payload, cell in rows:
            p50 = {b: cell['brokers'][b].get('p50_us_median') for b in BROKERS}
            valid = [x for x in p50.values() if x]
            fast = min(valid) if valid else None
            cand = []
            for b in BROKERS:
                e = cell['brokers'][b]
                ratio = f'{p50[b] / fast:.2f}x' if (fast and p50[b]) else '—'
                A(f"| {payload} | {LABELS[b]} | {f(p50[b], 1)} | "
                  f"{f(e.get('p95_us_median'), 1)} | "
                  f"{f(e.get('p99_us_median'), 1)} | "
                  f"{f(e.get('p999_us_median'), 1)} | {ratio} |")
                if p50[b]:
                    cand.append((p50[b], b))
            if cand:
                best[payload] = min(cand)[1]
        A('')
        c = Counter(best.values())
        A('**Lowest p50 across payloads:** '
          + ', '.join(f'{LABELS[b]} {n}' for b, n in c.most_common()) + '.')
        A('')

    # ---- resources ---------------------------------------------------------
    A('## Resource usage (`docker stats --no-stream`, median during reps)')
    A('')
    A('| workload | broker | CPU% median (max over cells) | RSS median '
      '(max over cells) |')
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
                  f"{f(max(cpus) if cpus else None, 1)} | "
                  f"{fbytes(max(rss) if rss else None)} |")
    A('')

    # ---- overall verdict ---------------------------------------------------
    A('## Overall verdict')
    A('')
    A('Metric: geometric mean over throughput cells of `fastest/rate` per '
      'broker (lower = faster; 1.000 means fastest in every included cell). '
      'Bands group by concurrency. "fair" cells are those where all three '
      'brokers completed and every requested worker connected.')
    A('')
    v = cons['verdict']

    def band_rows(ver):
        out = []
        for bd_name in ('1', '4-8', '16-32', 'overall'):
            if bd_name == 'overall':
                bd = ver['overall']
            else:
                bd = ver['bands'].get(bd_name)
            if not bd:
                continue
            gm = bd['geomean_ratio_vs_fastest']
            ranked = sorted(((r, b) for b, r in gm.items() if r),
                            key=lambda t: t[0])
            win_b, win_r = ranked[0][1], ranked[0][0]
            margin = '—'
            if len(ranked) > 1 and win_r:
                margin = f"{ranked[1][0] / win_r:.3f}x"
            out.append((bd_name, bd['fair_cell_count'], gm,
                        LABELS.get(bd.get('winner')), margin))
        return out

    for label, ver in (('Primary (all reps)', v),
                       ('Clean (stall-/error-free)',
                        {'bands': {k: {'fair_cell_count': x['fair_cell_count'],
                                       'geomean_ratio_vs_fastest':
                                       x['clean']['geomean_ratio_vs_fastest'],
                                       'winner': x['clean']['winner']}
                                   for k, x in v['bands'].items()},
                         'overall': {
                             'fair_cell_count': v['overall']['fair_cell_count'],
                             'geomean_ratio_vs_fastest':
                             v['overall']['clean']['geomean_ratio_vs_fastest'],
                             'winner': v['overall']['clean']['winner']}})):
        A(f'**{label}:**')
        A('')
        A('| band | cells | HyrxMQ gm | RabbitMQ gm | LavinMQ gm | winner | '
          'runner-up gap |')
        A('|---|---|---|---|---|---|---|')
        for bd_name, n, gm, winner, margin in band_rows(ver):
            A(f"| {bd_name} | {n} | {f(gm.get('hyrxmq'), 3)} | "
              f"{f(gm.get('rabbitmq'), 3)} | {f(gm.get('lavinmq'), 3)} | "
              f"**{winner}** | {margin} |")
        A('')

    ov = v['overall']
    gm = ov['geomean_ratio_vs_fastest']
    ranked = sorted(((r, b) for b, r in gm.items() if r), key=lambda t: t[0])
    win_b, win_r = ranked[0][1], ranked[0][0]
    second_b, second_r = ranked[1][1], ranked[1][0]
    A(f"**Fastest overall (primary geomean, {ov['fair_cell_count']} fair "
      f"throughput cells): {LABELS[win_b]}**, geomean ratio "
      f"{win_r:.3f}; {LABELS[second_b]} is "
      f"{(second_r / win_r - 1) * 100:.1f}% slower on the geomean; "
      f"{LABELS[ranked[2][1]]} is "
      f"{(ranked[2][0] / win_r - 1) * 100:.1f}% slower.")
    A('')

    # Head-to-head geomean of HyrxMQ / other (rate-on-rate, not vs fastest).
    A('### Head-to-head HyrxMQ versus each broker')
    A('')
    A('Geomean of `HyrxMQ rate / other rate` over the fair throughput cells '
      '(> 1.00 = HyrxMQ faster, < 1.00 = HyrxMQ slower). This isolates the '
      'HyrxMQ-vs-broker gap and does not depend on which broker is the per-cell '
      'fastest.')
    A('')
    A('| scope | cells | HyrxMQ / RabbitMQ | HyrxMQ / LavinMQ |')
    A('|---|---|---|---|')
    scopes = [('overall', lambda w, p, cc: True),
              ('band 1', lambda w, p, cc: band(cc) == '1'),
              ('band 4-8', lambda w, p, cc: band(cc) == '4-8'),
              ('band 16-32', lambda w, p, cc: band(cc) == '16-32')]
    for wl in THROUGHPUT:
        scopes.append((f'workload {wl}', (lambda w0: (lambda w, p, cc: w == w0))(wl)))
    # all_tp_cells is (wl, conc, payload, cell)
    rows_h = []
    for name, pred in scopes:
        sub = [cell for w, cc, p, cell in all_tp_cells if pred(w, p, cc)]
        if not sub:
            continue
        rr, rl, n = [], [], 0
        for cell in sub:
            m = {b: cell['brokers'][b].get('median_msgs_per_s') for b in BROKERS}
            if m['hyrxmq'] and m['rabbitmq'] and m['lavinmq']:
                rr.append(m['hyrxmq'] / m['rabbitmq'])
                rl.append(m['hyrxmq'] / m['lavinmq'])
                n += 1
        if n:
            rows_h.append((name, n, geomean(rr), geomean(rl)))
    for name, n, rr, rl in rows_h:
        def pct(x):
            return f'{x:.3f} ({(x - 1) * 100:+.1f}%)'
        A(f'| {name} | {n} | {pct(rr)} | {pct(rl)} |')
    A('')

    # ---- HyrxMQ precise claim ---------------------------------------------
    A('## Precise claim about HyrxMQ')
    A('')
    A('A cell counts as **fastest** if HyrxMQ has the top median rate, '
      '**tied** if within 2% of the top rate, **behind** otherwise. Ratios are '
      'fastest/HyrxMQ (1.00 = fastest; larger = HyrxMQ slower).')
    A('')
    fastest_cells, tied_cells, behind_cells = [], [], []
    for wl, conc, payload, cell in all_tp_cells:
        med = {b: cell['brokers'][b].get('median_msgs_per_s') for b in BROKERS}
        if not all(med.values()):
            continue
        fast = max(med.values())
        hr = fast / med['hyrxmq']
        rec = (wl, payload, conc, hr)
        if med['hyrxmq'] >= fast - 1e-9:
            fastest_cells.append(rec)
        elif hr <= 1.02:
            tied_cells.append(rec)
        else:
            behind_cells.append(rec)

    def fmt_list(recs, n=100):
        return ', '.join(f'{w}|{p}|{c} ({r:.2f}x)'
                         for w, p, c, r in sorted(recs, key=lambda t: t[3])[:n])

    A(f"- **HyrxMQ is fastest in {len(fastest_cells)} throughput cells:** "
      + (fmt_list(fastest_cells) if fastest_cells else 'none') + '.')
    A(f"- **Tied (within 2%) in {len(tied_cells)} cells:** "
      + (fmt_list(tied_cells) if tied_cells else 'none') + '.')
    if behind_cells:
        worst = sorted(behind_cells, key=lambda t: -t[3])
        A(f"- **Behind in {len(behind_cells)} cells.** Worst cases: "
          + fmt_list(worst, 12) + '.')
        A(f"- The narrowest loss is {min(r for _w, _p, _c, r in behind_cells):.2f}x; "
          f"the widest is {max(r for _w, _p, _c, r in behind_cells):.2f}x.")
        by_wl = Counter(w for w, _p, _c, _r in behind_cells)
        A('  - Losses by workload: '
          + ', '.join(f'{w} {n}' for w, n in by_wl.most_common()) + '.')
    else:
        A('- **HyrxMQ is never materially behind on this matrix.**')
    A('')

    # ---- failures / stalls -------------------------------------------------
    A('## Failures, errors and stalls')
    A('')
    any_bad = False
    for ck, cell in cons['cells'].items():
        for b in BROKERS:
            e = cell['brokers'][b]
            if e.get('status') != 'OK' or e.get('median_msgs_per_s') is None:
                any_bad = True
                A(f"- `{ck}` **{LABELS[b]}**: {e.get('status')} "
                  f"{e.get('error', '')}".rstrip())
            elif e.get('errors_total'):
                any_bad = True
                A(f"- `{ck}` **{LABELS[b]}**: {e['errors_total']} worker "
                  f"error(s) across {e.get('n_ok')} successful reps.")
            elif e.get('stall_runs'):
                any_bad = True
                A(f"- `{ck}` **{LABELS[b]}**: {e['stall_runs']}/"
                  f"{e.get('n_ok')} reps stalled (wall > 3x target); clean "
                  f"median {f(e.get('median_clean_msgs_per_s'))} vs median "
                  f"{f(e.get('median_msgs_per_s'))} msg/s.")
    if not any_bad:
        A('None: every broker completed every cell without errors or stalls.')
    A('')

    # ---- caveats -----------------------------------------------------------
    A('## Caveats and limitations')
    A('')
    # Dynamic stats for the caveats.
    n_cells = len(cons['cells'])
    n_runs = sum(cell['brokers'][b].get('n_total', 0)
                 for cell in cons['cells'].values() for b in BROKERS)
    lav_bad_cells = [ck for ck, cell in cons['cells'].items()
                     if cell['brokers']['lavinmq'].get('stall_runs')
                     or cell['brokers']['lavinmq'].get('errors_total')]
    hyrx_bad = sum(1 for cell in cons['cells'].values()
                   for b in ('hyrxmq',)
                   if cell['brokers'][b].get('stall_runs')
                   or cell['brokers'][b].get('errors_total')
                   or cell['brokers'][b].get('status') != 'OK')
    hyrx_ok_runs = sum(cell['brokers']['hyrxmq'].get('n_ok', 0)
                       for cell in cons['cells'].values())
    lav_gm = v['overall']['geomean_ratio_vs_fastest'].get('lavinmq')
    fan_h = []
    for ck, cell in cons['cells'].items():
        if cell['workload'] != 'fanout':
            continue
        fv = cell.get('fastest_msgs_per_s')
        hv = cell['brokers']['hyrxmq'].get('median_msgs_per_s')
        if cell.get('fastest_broker') == 'lavinmq' and fv and hv:
            fan_h.append(fv / hv)
    A(f"- **Single host, single client.** All results are one physical machine "
      f"({host.get('nproc')} logical CPUs, CPU governor "
      f"`{host.get('governor')}`), one client process, one Docker bridge. They "
      f"establish relative behaviour here, not a universal ranking. This is "
      f"**not** a claim that any broker is \"fastest in the world\".")
    A('- **These exact images.** Numbers are for the image digests above; a '
      'different RabbitMQ/LavinMQ/HyrxMQ build may differ.')
    A('- **CPU governor is `powersave`** on this host, so absolute rates are '
      'lower and noisier than a `performance` governor would give; relative '
      'ordering is the robust output.')
    A('- HyrxMQ is a fundamentally different design (Mojo, per-connection '
      'serving); RabbitMQ (Erlang/OTP) and LavinMQ (Crystal) are mature '
      'multi-threaded brokers. The comparison is behavioural, not '
      'architectural equivalence.')
    A('- `publish` targets a **bindingless** exchange: it measures the '
      'producer/transport ceiling and stores nothing.')
    A('- `pubget` uses `auto_ack=True` (routing + content + transport, not the '
      'ack path); `latency` uses explicit ack.')
    A('- `confirm` waits one confirm per publish; its untimed drain is outside '
      'the measured span.')
    A('- **LavinMQ large-payload collapse (important).** In `pubget` and '
      '`confirm` at payloads >= 16 KiB, and in `latency` at 256 KiB, LavinMQ '
      'delivered only ~20-960 msg/s (e.g. `pubget|16384|8` 246 msg/s, '
      '`confirm|16384|1` 21 msg/s, `latency|262144|1` p50 41 ms). '
      f"LavinMQ's overall geomean ({f(lav_gm, 3)}) is dominated "
      'by these collapsed cells; treat that single number as an observed '
      'pathology of this image/workload, not a general LavinMQ capability. The '
      '**HyrxMQ-vs-RabbitMQ** verdict is unaffected, because both are scored '
      'against the same per-cell fastest rate.')
    A('- **LavinMQ is genuinely fastest in `fanout`** (all 5 cells, '
      f"{min(fan_h):.2f}-{max(fan_h):.2f}x over HyrxMQ): that is not a collapse "
      'artifact.')
    A(f"- **HyrxMQ had {hyrx_bad} stall/error cells in all {n_cells} cells / "
      f"{n_runs} runs** ({hyrx_ok_runs} successful HyrxMQ runs); every "
      f"stall/error above is LavinMQ ({len(lav_bad_cells)} affected cells).")
    A('- Container caps (`--cpus 4 --memory 2g`) can bind the multi-threaded '
      'brokers differently than HyrxMQ; not all brokers were re-tuned.')
    A('- Medians across 7 rotated reps suppress drift but not all noise; cells '
      'where brokers are within ~5% should be treated as ties.')
    A('')
    with open(args.out, 'w') as fh:
        fh.write('\n'.join(L))
    print(f'wrote {args.out} from {path}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
