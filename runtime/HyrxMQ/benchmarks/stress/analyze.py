"""Analysis and reporting for AMQP stress test results.

Reads results JSON from harness.py and produces:
1. Per-broker throughput summary table
2. Failure scenario pass/fail matrix
3. Cross-broker comparison (HyrxMQ vs RabbitMQ ratios)
4. Throughput stability analysis (CV%, min/max spread)
5. Exportable JSON for CI gates
"""
import argparse
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def load(path):
    with open(path) as f:
        return json.load(f)


def throughput_table(data):
    """Extract throughput per size into a flat dict."""
    out = {}
    for size, wl in data.get('workloads', {}).items():
        # find the pub workload entry
        for tag, info in wl.get('workloads', {}).items():
            if 'pub' in tag or 'soak' in tag or 'burst' in tag:
                out[size] = {
                    'throughput': info.get('avg_throughput', 0),
                    'total_count': info.get('total_count', 0),
                    'body_size': info.get('body_size', int(size)),
                    'stability': info.get('stability', {}),
                }
                break
        else:
            # fallback: take any workload
            for tag, info in wl.get('workloads', {}).items():
                out[size] = {
                    'throughput': info.get('avg_throughput', 0),
                    'total_count': info.get('total_count', 0),
                    'body_size': info.get('body_size', int(size)),
                    'stability': info.get('stability', {}),
                }
                break
    return out


def scenario_summary(data):
    """Extract scenario results."""
    out = {}
    for name, result in data.get('scenarios', {}).items():
        if isinstance(result, dict):
            has_error = 'error' in result or any(
                'error' in str(v) for v in result.values()
                if isinstance(v, dict))
            out[name] = {
                'status': 'FAIL' if has_error else 'PASS',
                'details': result,
            }
    return out


def cross_broker_compare(rabbit, hyrx):
    """Compare throughput and scenario results across brokers."""
    r_tp = throughput_table(rabbit)
    h_tp = throughput_table(hyrx)
    r_sc = scenario_summary(rabbit)
    h_sc = scenario_summary(hyrx)

    comparison = {
        'throughput': {},
        'scenarios': {},
    }

    for size in sorted(set(r_tp.keys()) | set(h_tp.keys())):
        r = r_tp.get(size, {}).get('throughput', 0)
        h = h_tp.get(size, {}).get('throughput', 0)
        ratio = h / r if r > 0 else float('inf') if h > 0 else 0
        comparison['throughput'][size] = {
            'rabbit': round(r, 1),
            'hyrx': round(h, 1),
            'ratio': round(ratio, 3),
        }

    for name in sorted(set(r_sc.keys()) | set(h_sc.keys())):
        comparison['scenarios'][name] = {
            'rabbit': r_sc.get(name, {}).get('status', 'NOT_RUN'),
            'hyrx': h_sc.get(name, {}).get('status', 'NOT_RUN'),
        }

    return comparison


def print_report(data, label=''):
    broker = data.get('broker', 'unknown')
    title = f'{broker.upper()} STRESS TEST RESULTS'
    if label:
        title += f' ({label})'
    print(f'\n{"="*60}')
    print(f'  {title}')
    print(f'{"="*60}')

    # throughput
    tp = throughput_table(data)
    if tp:
        print(f'\n  {"size":>8} {"throughput":>12} {"stability":>12} {"cv%":>8}')
        print(f'  {"-"*44}')
        for size in sorted(tp.keys(), key=lambda x: int(x)):
            t = tp[size]
            stab = t.get('stability', {})
            cv = stab.get('cv_pct', 0)
            print(f'  {size:>6}B {t["throughput"]:>10.0f}/s '
                  f'{stab.get("median", 0):>10.0f}/s {cv:>6.1f}%')

    # scenarios
    sc = scenario_summary(data)
    if sc:
        print(f'\n  Failure Scenarios:')
        print(f'  {"scenario":<22} {"status":>8}')
        print(f'  {"-"*32}')
        for name, info in sc.items():
            print(f'  {name:<22} {info["status"]:>8}')

    # errors
    errors = data.get('workloads', {})
    total_errors = 0
    for size_data in errors.values():
        for err_tag, err_info in size_data.get('errors', {}).items():
            total_errors += err_info.get('count', 0)
    if total_errors:
        print(f'\n  Total errors during workload: {total_errors}')

    # soak
    soak = data.get('soak', {})
    if soak:
        print(f'\n  Soak Test:')
        for tag, info in soak.get('workloads', {}).items():
            print(f'    {tag}: {info.get("avg_throughput", 0):.0f}/s '
                  f'over {info.get("elapsed_s", 0):.0f}s '
                  f'({info.get("total_count", 0)} messages)')

    print()


def print_comparison(rabbit, hyrx):
    comp = cross_broker_compare(rabbit, hyrx)
    print(f'\n{"="*60}')
    print(f'  CROSS-BROKER COMPARISON (HyrxMQ / RabbitMQ)')
    print(f'{"="*60}')

    if comp['throughput']:
        print(f'\n  {"size":>8} {"rabbit":>12} {"hyrx":>12} {"ratio":>8}')
        print(f'  {"-"*44}')
        for size in sorted(comp['throughput'].keys(), key=lambda x: int(x)):
            t = comp['throughput'][size]
            print(f'  {size:>6}B {t["rabbit"]:>10.0f}/s '
                  f'{t["hyrx"]:>10.0f}/s {t["ratio"]:>6.2f}x')

    if comp['scenarios']:
        print(f'\n  Failure Scenarios:')
        print(f'  {"scenario":<22} {"rabbit":>8} {"hyrx":>8}')
        print(f'  {"-"*40}')
        for name, info in comp['scenarios'].items():
            print(f'  {name:<22} {info["rabbit"]:>8} {info["hyrx"]:>8}')

    print()


def gate_check(results, thresholds=None):
    """CI gate: pass/fail based on throughput and scenario criteria."""
    if thresholds is None:
        thresholds = {
            'min_throughput_ratio': 0.5,  # hyrx must be >= 50% of rabbit
            'required_scenarios_pass': ['connection_drop', 'rapid_reconnect'],
        }

    all_pass = True
    reasons = []

    if len(results) == 2:
        rabbit = results.get('rabbit', {})
        hyrx = results.get('hyrx', {})
        comp = cross_broker_compare(rabbit, hyrx)

        for size, t in comp.get('throughput', {}).items():
            if t['ratio'] < thresholds['min_throughput_ratio']:
                all_pass = False
                reasons.append(
                    f'{size}B ratio {t["ratio"]:.2f} < '
                    f'{thresholds["min_throughput_ratio"]:.2f}')

        for sc_name in thresholds.get('required_scenarios_pass', []):
            sc = comp.get('scenarios', {}).get(sc_name, {})
            if sc.get('hyrx') != 'PASS':
                all_pass = False
                reasons.append(f'{sc_name}: hyrx={sc.get("hyrx", "NOT_RUN")}')

    return {
        'pass': all_pass,
        'reasons': reasons,
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('results', nargs='*',
                    help='Paths to stress test result JSON files')
    ap.add_argument('--compare', action='store_true',
                    help='Compare two result files (rabbit + hyrx)')
    ap.add_argument('--gate', action='store_true',
                    help='Run CI gate check and exit with status')
    ap.add_argument('--json', action='store_true',
                    help='Output comparison as JSON')
    args = ap.parse_args()

    files = args.results
    if not files:
        # auto-discover from results/
        results_dir = os.path.join(HERE, 'results')
        if os.path.isdir(results_dir):
            files = sorted(os.path.join(results_dir, f)
                           for f in os.listdir(results_dir)
                           if f.endswith('.json'))

    if not files:
        print('no result files found')
        return 1

    results = {}
    for f in files:
        data = load(f)
        broker = data.get('broker', os.path.basename(f).split('_')[0])
        results[broker] = data
        print_report(data, label=os.path.basename(f))

    if args.compare and len(results) >= 2:
        rabbit = results.get('rabbit', results.get(list(results.keys())[0]))
        hyrx = results.get('hyrx', results.get(list(results.keys())[1]))
        print_comparison(rabbit, hyrx)

    if args.gate:
        g = gate_check(results)
        if args.json:
            print(json.dumps(g, indent=1))
        else:
            print(f'GATE: {"PASS" if g["pass"] else "FAIL"}')
            for r in g['reasons']:
                print(f'  {r}')
        return 0 if g['pass'] else 1

    if args.json and len(results) >= 2:
        rabbit = results.get('rabbit', results.get(list(results.keys())[0]))
        hyrx = results.get('hyrx', results.get(list(results.keys())[1]))
        print(json.dumps(cross_broker_compare(rabbit, hyrx), indent=1))

    return 0


if __name__ == '__main__':
    sys.exit(main())
