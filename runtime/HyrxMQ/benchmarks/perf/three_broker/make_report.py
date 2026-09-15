#!/usr/bin/env python3
"""Render REPORT.md + consolidated.json from the latest raw run JSON.

Kept separate from harness.py so the report can be regenerated (with the
current fairness/verdict logic) from raw evidence without re-running the
benchmark.

Usage:
    /tmp/amqp-venv/bin/python make_report.py [raw_xxx.json]
"""
import glob
import json
import os
import sys

import harness as H

HERE = os.path.dirname(os.path.abspath(__file__))
RESULTS = os.path.join(HERE, 'results')
LABELS = {b: H.BROKERS[b]['label'] for b in H.BROKER_ORDER}


def _latest_raw():
    if len(sys.argv) > 1:
        return sys.argv[1]
    cands = sorted(glob.glob(os.path.join(RESULTS, 'raw_*.json')),
                   key=os.path.getmtime)
    # newest non-quick run wins; fall back to newest
    full = [c for c in cands if not _is_quick(c)]
    return (full or cands)[-1]


def _is_quick(path):
    try:
        with open(path) as fh:
            return bool(json.load(fh).get('quick'))
    except Exception:
        return False


def fmt(v, nd=1):
    if v is None:
        return '—'
    if isinstance(v, str):
        return v
    return f'{v:,.{nd}f}'


def fmt_bytes(b):
    if b is None:
        return '—'
    for unit in ('B', 'KiB', 'MiB', 'GiB'):
        if b < 1024 or unit == 'GiB':
            return f'{b / 1:.0f} {unit}' if unit == 'B' else f'{b:.1f} {unit}'
        b /= 1024.0
    return f'{b:.1f} GiB'


def cell_rate(cons, wl, pkey, broker):
    return (cons['workloads'].get(wl, {}).get('params', {})
            .get(pkey, {}).get(broker, {}).get('median_msgs_per_s'))


def build(cons):
    m = cons['method']
    L = []
    A = L.append
    A('# Three-Broker AMQP Performance Benchmark')
    A('')
    A('**HyrxMQ vs RabbitMQ vs LavinMQ — single host, all brokers in Docker.**')
    A('')
    A(f"- Run id: `{cons['run_id']}`")
    A(f"- Started (UTC): {cons.get('started_utc')} · "
      f"duration {cons.get('duration_s')}s")
    A(f"- Mode: {'quick smoke' if cons['quick'] else 'full'} · "
      f"replicates per cell: {cons['reps']} (median reported)")
    A('')
    A('## Host & software')
    A('')
    h = cons['host']
    A(f"- CPU: {h.get('cpu_model')} ({h.get('nproc')} logical CPUs)")
    A(f"- RAM: {h.get('mem_total_gib')} GiB · kernel {h.get('kernel')} · "
      f"docker {h.get('docker_version')}")
    A(f"- Client: pika {h.get('pika_version')} on Python {h.get('python')}")
    A(f"- HyrxMQ git: `{h.get('hyrxmq_git_head')}` · "
      f"CPU governor: {h.get('governor')}")
    imgs = h.get('broker_images', {})
    A(f"- Images: {imgs.get('hyrxmq')}, {imgs.get('rabbitmq')}, "
      f"{imgs.get('lavinmq')}")
    A('')
    A('## Methodology (fairness notes)')
    A('')
    A('- All three brokers run in their own container on **one user-defined '
      'bridge** (`hyrxmq-bench`), each published to `127.0.0.1`, so every '
      'client connection crosses the **same docker-proxy hop**.')
    A('- Each container is capped identically: `--cpus 4 --memory 2g`. '
      '(HyrxMQ is single-threaded, so it cannot use more than one core.)')
    A('- Credentials are `admin`/`password` on all three. RabbitMQ and LavinMQ '
      'users are created at container start; HyrxMQ\'s built-in default is '
      '`admin`/`password` (its `HYRXMQ_USERS` env var is not read by this '
      'build but the default already matches). Auth happens once per '
      'connection and is outside every timed window.')
    A('- Identical protocol config on all three: ephemeral (auto-delete, '
      'non-durable, **exclusive**) direct/fanout exchange + queue + binding, '
      '`delivery_mode=1`, `heartbeat=0`, `frame_max=131072`, `auto_ack=True` '
      'on the throughput `basic_get`.')
    A('  - `exclusive=True` is required because RabbitMQ 4.3 refuses transient '
      '*non-exclusive* queues (`transient_nonexcl_queues` deprecated). An '
      'exclusive+auto-delete queue is still fully ephemeral.')
    A('- One pika version, **one connection to one broker at a time** (the '
      'concurrency workload is the only exception: N thread pairs, each with '
      'its own connection).')
    A(f"- Every cell: first {int(H.WARMUP_FRAC * 100)}% of each rep is "
      f"discarded as warm-up; `{cons['reps']}` reps; **median** reported; count "
      f"auto-tuned so a rep lasts >= {H.TARGET_REP_SECONDS:.0f}s.")
    A('- Brokers run in a **rotated order across reps** to spread order/thermal '
      'bias. CPU% and RSS are sampled from `docker stats --no-stream` during '
      'each rep.')
    A('')
    A('## Workload definitions')
    A('')
    for k, v in m.items():
        A(f'- **{k}**: {v}')
    A('')
    A('## Results')
    A('')
    A('Rates are the median of the reps; `ratio` is relative to the fastest '
      'broker in that row. Every result — including where HyrxMQ loses — is '
      'shown.')
    A('')

    # ---- throughput-style workloads ----------------------------------------
    titles = {'publish_get': 'Workload 1 — publish + get (closed loop, '
                             'auto_ack)',
              'publish_only': 'Workload 2 — publish-only '
                              '(fire-and-forget producer ceiling)',
              'confirms': 'Workload 4 — publisher confirms '
                          '(confirm wait)',
              'fanout': 'Workload 5 — fanout (1 exchange -> 4 queues, '
                        'delivered)'}

    def emit_rate(wl):
        if wl not in cons['workloads']:
            return
        A(f"### {titles[wl]}")
        A('')
        A('| param | HyrxMQ | RabbitMQ | LavinMQ | fastest | ratio vs fastest '
          '(H / R / L) |')
        A('|---|---|---|---|---|---|')
        params = cons['workloads'][wl]['params']
        for pkey in sorted(params, key=H._param_key):
            row = params[pkey]
            rates = {b: row.get(b, {}).get('median_msgs_per_s')
                     for b in H.BROKER_ORDER}
            fastest = max((r for r in rates.values() if r), default=None)
            ratios = []
            for b in H.BROKER_ORDER:
                r = rates[b]
                ratios.append(fmt(fastest / r, 2) if (r and fastest) else '—')
            label = f'{pkey}B' if wl != 'confirms' else f'{pkey}B'
            A(f"| {label} | {fmt(rates['hyrxmq'])} | {fmt(rates['rabbitmq'])} | "
              f"{fmt(rates['lavinmq'])} | {fmt(fastest)} | "
              f"{' / '.join(ratios)} |")
        A('')
        A('**Which is faster:**')
        for pkey in sorted(params, key=H._param_key):
            row = params[pkey]
            rates = {b: row.get(b, {}).get('median_msgs_per_s')
                     for b in H.BROKER_ORDER}
            fastest_b = max((b for b in rates if rates[b]),
                            key=lambda b: rates[b], default=None)
            if fastest_b is None:
                A(f'- {pkey}: no broker completed this cell.')
                continue
            fr = rates[fastest_b]
            parts = []
            for b in H.BROKER_ORDER:
                if b == fastest_b or not rates[b]:
                    continue
                parts.append(f'{LABELS[b]} {fr / rates[b]:.2f}x slower')
            A(f'- **{pkey}**: {LABELS[fastest_b]} fastest at {fmt(fr)} '
              f'msg/s ({"; ".join(parts)})')
        A('')

    emit_rate('publish_get')
    emit_rate('publish_only')

    # ---- latency -----------------------------------------------------------
    if 'latency' in cons['workloads']:
        A('### Workload 3 — latency (publish -> get -> ack round trip, '
          'one in flight)')
        A('')
        A('Per-op microseconds, pooled across reps:')
        A('')
        A('| payload | broker | p50 | p95 | p99 | p99.9 | mean |')
        A('|---|---|---|---|---|---|---|')
        params = cons['workloads']['latency']['params']
        for pkey in sorted(params, key=H._param_key):
            for b in H.BROKER_ORDER:
                s = params[pkey].get(b, {})
                lat = s.get('latency_us') or {}
                A(f"| {pkey}B | {LABELS[b]} | {fmt(lat.get('p50_us'))} | "
                  f"{fmt(lat.get('p95_us'))} | {fmt(lat.get('p99_us'))} | "
                  f"{fmt(lat.get('p99_9_us'))} | {fmt(lat.get('mean_us'))} |")
        A('')
        A('**Which is faster (by p50):**')
        for pkey in sorted(params, key=H._param_key):
            row = params[pkey]
            p50 = {b: (row.get(b, {}).get('latency_us') or {}).get('p50_us')
                   for b in H.BROKER_ORDER}
            cand = [(p50[b], b) for b in H.BROKER_ORDER
                    if p50[b] is not None]
            if not cand:
                A(f'- {pkey}: no data.')
                continue
            f, fastest_b = min(cand)
            parts = []
            for b in H.BROKER_ORDER:
                v = p50.get(b)
                if b != fastest_b and v is not None:
                    parts.append(f'{LABELS[b]} {v / f:.2f}x')
            A(f'- **{pkey}**: {LABELS[fastest_b]} lowest p50 ({f:.1f}us) '
              f'({"; ".join(parts)})')
        A('')

    emit_rate('confirms')
    emit_rate('fanout')

    # ---- concurrency -------------------------------------------------------
    if 'concurrency' in cons['workloads']:
        A('### Workload 6 — concurrency (N producer+consumer thread pairs)')
        A('')
        A('| pairs | broker | aggregate msg/s | pairs connected | '
          'errors/rep (median) |')
        A('|---|---|---|---|---|')
        params = cons['workloads']['concurrency']['params']
        for pkey in sorted(params, key=H._param_key):
            for b in H.BROKER_ORDER:
                s = params[pkey].get(b, {})
                per = s.get('thread_errors_per_rep') or []
                nerr = fmt(H._median(per), 0)
                A(f"| {pkey} | {LABELS[b]} | {fmt(s.get('median_msgs_per_s'))} | "
                  f"{fmt(s.get('pairs_connected_median'), 0)} | {nerr} |")
        A('')
        A('**Which is faster:**')
        for pkey in sorted(params, key=H._param_key):
            row = params[pkey]
            rates = {b: row.get(b, {}).get('median_msgs_per_s')
                     for b in H.BROKER_ORDER}
            pc = {b: row.get(b, {}).get('pairs_connected_median')
                  for b in H.BROKER_ORDER}
            fastest_b = max((b for b in rates if rates[b]),
                            key=lambda b: rates[b], default=None)
            if fastest_b is None:
                A(f'- {pkey}: no data.')
                continue
            fr = rates[fastest_b]
            parts = []
            for b in H.BROKER_ORDER:
                if b == fastest_b or not rates[b]:
                    continue
                extra = (f' (only {pc[b]:.0f}/{pkey} pairs connected)'
                         if pc.get(b) is not None and pc[b] < int(pkey) else '')
                parts.append(f'{LABELS[b]} {fr / rates[b]:.2f}x{extra}')
            note = ''
            if (pc.get(fastest_b) is not None and
                    pc[fastest_b] < int(pkey)):
                note = (f' — note: {LABELS[fastest_b]} connected only '
                        f'{pc[fastest_b]:.0f}/{pkey} pairs, so this is a '
                        f'single-pair rate, not an aggregate')
            A(f'- **{pkey}**: {LABELS[fastest_b]} highest at {fmt(fr)} '
              f'msg/s ({"; ".join(parts)}){note}')
        A('')

    # ---- resource usage ----------------------------------------------------
    A('## Resource usage (docker stats --no-stream, median during reps)')
    A('')
    A('| workload | broker | CPU% (median) | CPU% (max) | RSS (median) | '
      'RSS (max) |')
    A('|---|---|---|---|---|---|')
    for wl in ('publish_get', 'publish_only', 'latency', 'confirms', 'fanout',
               'concurrency'):
        if wl not in cons['workloads']:
            continue
        cpu, rss = [], []
        for pkey, row in cons['workloads'][wl]['params'].items():
            for b in H.BROKER_ORDER:
                r = row.get(b, {}).get('resources') or {}
                if r.get('cpu_pct_median') is not None:
                    cpu.append((b, r))
        for b in H.BROKER_ORDER:
            vals = [r for bb, r in cpu if bb == b]
            if not vals:
                continue
            cpu_med = max(v['cpu_pct_median'] for v in vals)
            cpu_max = max((v['cpu_pct_max'] or 0) for v in vals)
            rss_med = max((v['rss_bytes_median'] or 0) for v in vals)
            rss_max = max((v['rss_bytes_max'] or 0) for v in vals)
            A(f"| {wl} | {LABELS[b]} | {fmt(cpu_med, 1)} | {fmt(cpu_max, 1)} | "
              f"{fmt_bytes(rss_med)} | {fmt_bytes(rss_max)} |")
    A('')

    # ---- overall verdict ---------------------------------------------------
    A('## Overall verdict')
    A('')
    v = cons['verdict']
    gm = v.get('geomean_ratio_vs_fastest', {})
    A(f"Geometric mean of \"ratio vs fastest\" over the **{v.get('fair_cell_count', 0)} "
      f"fair cells** (all brokers completed; for concurrency, all brokers "
      f"connected all requested pairs):")
    A('')
    A('| broker | geomean ratio vs fastest | interpretation |')
    A('|---|---|---|')
    for b in H.BROKER_ORDER:
        g = gm.get(b)
        interp = ('fastest overall' if g is not None and g <= 1.0001
                  else '—' if g is None else f'{g:.3f}x slower than the '
                  f'per-cell fastest on average')
        A(f'| {LABELS[b]} | {fmt(g, 4)} | {interp} |')
    A('')
    if v.get('winner'):
        A(f"**Winner on this hardware/workload set: {LABELS[v['winner']]}.** "
          f"Ranking: {' > '.join(LABELS[b] for b in v.get('ranking', []))}.")
    A('')
    A('This is a single-host, single-client, 3-way test. It does **not** '
      'establish "fastest AMQP broker in the world"; it establishes relative '
      'behaviour on this CPU, this kernel, this Docker, these images and this '
      'pika client.')
    A('')

    # ---- failures ----------------------------------------------------------
    A('## Failures and non-OK cells')
    A('')
    any_fail = False
    for wl, w in cons['workloads'].items():
        for pkey, row in w['params'].items():
            for b in H.BROKER_ORDER:
                s = row.get(b, {})
                if s.get('status') != 'OK' or s.get('median_msgs_per_s') is None:
                    any_fail = True
                    A(f"- `{wl}` {pkey} **{LABELS[b]}**: "
                      f"{s.get('status')} {s.get('error', '')}".rstrip())
                else:
                    per = s.get('thread_errors_per_rep') or []
                    if per and max(per) > 0:
                        any_fail = True
                        sample = (s.get('thread_errors') or [''])[0][:160]
                        A(f"- `{wl}` {pkey} **{LABELS[b]}**: "
                          f"{H._median(per):.0f} thread error(s) per rep "
                          f"(median); first: {sample}")
    if not any_fail:
        A('None: every broker completed every cell.')
    A('')

    # ---- caveats -----------------------------------------------------------
    A('## Caveats and limitations')
    A('')
    A('- **HyrxMQ serves one connection at a time** in this build. At pairs>1 '
      'it completes exactly one handshake and the rest time out; the reported '
      'concurrency "aggregate" for HyrxMQ is therefore a single-pair rate. '
      'This is excluded from the overall verdict.')
    A('- The concurrency workload runs all thread pairs **inside one Python '
      'process with blocking pika**. The interpreter GIL limits how far any '
      'broker can scale there, so the multi-threaded brokers\' aggregate does '
      'not represent their true scaling. A multi-process client would be '
      'needed to measure broker-side scaling.')
    A('- HyrxMQ\'s `hyrxmq:latest` default CMD is `hyrxmq-web`; in this build '
      'its embedded AMQP listener does not complete a client handshake. The '
      'identical image\'s dedicated binary `/app/build/hyrxmq-listen` (used '
      'here) does. HyrxMQ numbers are for that dedicated broker process.')
    A('- `publish_only` publishes to an exchange with **no bound queue**, so '
      'nothing is stored: it isolates the producer/transport ceiling. A '
      'single Python producer is itself a ceiling; these numbers are not '
      'broker receive-path limits.')
    A('- `confirms` times only the confirm-publish span; the drain that keeps '
      'the queue bounded runs outside the timed window.')
    A('- **LavinMQ large-payload behaviour**: in the batched `publish_get` '
      'shape (queue depth <= 128) LavinMQ throughput collapses at payloads '
      '>= 16 KiB (to tens of msg/s), and its per-op latency develops a heavy '
      '~42 ms tail. The pattern was consistent across every rep and is '
      'reported as measured; it is most likely message-store segment pressure '
      'in LavinMQ, not a harness artifact.')
    A('- `publish_get` uses auto_ack=True, so it measures routing + content + '
      'transport, **not** the acknowledgement path. `latency` uses explicit '
      'ack.')
    A('- Results depend on this client, this host, container CPU/mem caps and '
      'the specific image versions. Do not generalise across hardware.')
    A('')
    return '\n'.join(L)


def main():
    raw_path = _latest_raw()
    with open(raw_path) as fh:
        raw = json.load(fh)
    cons = H.consolidate(raw)
    cons_path = os.path.join(RESULTS, 'consolidated.json')
    with open(cons_path, 'w') as fh:
        json.dump(cons, fh, indent=1)
    report = build(cons)
    report_path = os.path.join(HERE, 'REPORT.md')
    with open(report_path, 'w') as fh:
        fh.write(report)
    print(f'raw        : {raw_path}')
    print(f'consolidated: {cons_path}')
    print(f'report     : {report_path}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
