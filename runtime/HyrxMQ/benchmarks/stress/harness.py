"""AMQP stress/soak benchmark harness.

Orchestrates containers, workloads, and failure scenarios against
RabbitMQ and HyrxMQ to measure production carrying capacity.

Usage:
    python benchmarks/stress/harness.py --broker both --duration 60
    python benchmarks/stress/harness.py --broker hyrx --scenarios connection_drop,rapid_reconnect
    python benchmarks/stress/harness.py --broker rabbit --workload saturated --sizes 64,1024,65536
"""
import argparse
import json
import os
import sys
import time
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)

import containers
import failures
import workloads
from metrics import MetricsCollector, save_results

DEFAULT_SIZES = [64, 256, 1024, 4096, 65536, 1048576]
DEFAULT_DURATION = 60
DEFAULT_SCENARIOS = [
    'connection_drop', 'channel_error', 'rapid_reconnect',
    'consumer_storm', 'queue_exhaustion', 'malformed_frame',
    'heartbeat_starve',
]
DEFAULT_WORKLOAD = 'saturated'
SOAK_DURATION = 3600  # 1 hour default for soak tests


def run_workload_suite(url, broker_name, sizes, duration, metrics,
                       workload_name=DEFAULT_WORKLOAD):
    """Run a workload across all message sizes against one broker."""
    print(f'\n  === {broker_name} workload={workload_name} ===')
    results = {}

    for size in sizes:
        qname = f'stress_{workload_name}_{broker_name}_{size}_{uuid.uuid4().hex[:6]}'
        label = f'{workload_name}_{broker_name}_{size}B'
        print(f'    {size}B ... ', end='', flush=True)

        m = MetricsCollector(sample_interval=1.0)
        m.start_sampling()

        try:
            if workload_name == 'saturated':
                # run pub and sub in sequence; sub drains what pub created
                t_pub = workloads.workload_saturated(
                    url, qname, size, duration, m, tag='pub')
                # brief pause then drain
                time.sleep(0.5)
                workloads.workload_saturated(
                    url, qname, size, min(duration, 30), m, tag='sub')
            elif workload_name == 'steady':
                rate = max(100, 100000 // max(size, 1))
                t_pub = workloads.workload_steady(
                    url, qname, size, duration, rate, m, tag='pub')
                time.sleep(0.5)
                workloads.workload_steady(
                    url, qname, size, min(duration, 30), rate, m, tag='sub')
            elif workload_name == 'bursty':
                workloads.workload_bursty(
                    url, qname, size, duration,
                    burst_size=max(50, 5000 // max(size, 1)),
                    burst_interval_s=2.0, metrics=m)
            elif workload_name == 'fanout':
                ex_name = f'fanout_{qname}'
                workloads.workload_fanout(
                    url, ex_name, size, duration, num_consumers=4, metrics=m)
            elif workload_name == 'mixed':
                workloads.workload_mixed(url, size, duration, m)
            elif workload_name == 'large':
                workloads.workload_large(url, qname, size, duration, m)
            else:
                print(f'unknown workload {workload_name}')
                continue

            s = m.summary()
            results[str(size)] = s
            wl = s.get('workloads', {})
            throughput = 0
            for k, v in wl.items():
                throughput = max(throughput, v.get('avg_throughput', 0))
            print(f'{throughput:.0f} msg/s')

        except Exception as e:
            print(f'ERROR: {e}')
            results[str(size)] = {'error': str(e)}
        finally:
            m.stop_sampling()

    return results


def run_scenario_suite(url, broker_name, scenarios, body_size, metrics):
    """Run failure scenarios against one broker."""
    print(f'\n  === {broker_name} failure scenarios ===')
    results = {}

    for scenario_name in scenarios:
        qname = f'scen_{broker_name}_{scenario_name}_{uuid.uuid4().hex[:6]}'
        print(f'    {scenario_name} ... ', end='', flush=True)

        m = MetricsCollector()
        try:
            if scenario_name == 'connection_drop':
                failures.scenario_connection_drop(
                    url, qname, body_size, num_messages=1000,
                    drop_at=500, metrics=m)
            elif scenario_name == 'channel_error':
                failures.scenario_channel_error(
                    url, body_size, num_messages=1000, error_at=300,
                    metrics=m)
            elif scenario_name == 'rapid_reconnect':
                failures.scenario_rapid_reconnect(
                    url, qname, num_cycles=100, metrics=m)
            elif scenario_name == 'consumer_storm':
                failures.scenario_consumer_storm(
                    url, qname, body_size, num_consumers=8,
                    num_messages=5000, metrics=m)
            elif scenario_name == 'queue_exhaustion':
                failures.scenario_queue_exhaustion(
                    url, qname, body_size, publish_count=5000,
                    prefetch=10, metrics=m)
            elif scenario_name == 'malformed_frame':
                parsed = url.split('@')[-1] if '@' in url else url
                host = parsed.split(':')[0].replace('amqp://', '')
                port = int(parsed.split(':')[-1].split('/')[0])
                failures.scenario_malformed_frame(
                    host, port, num_frames=50, metrics=m)
            elif scenario_name == 'heartbeat_starve':
                failures.scenario_heartbeat_starve(
                    url, qname, body_size, duration_s=10, metrics=m)
            else:
                print(f'unknown scenario {scenario_name}')
                continue

            s = m.summary()
            results[scenario_name] = s.get('scenarios', {})
            errors = s.get('errors', {})
            if errors:
                results[scenario_name]['errors'] = errors

            print('OK')

        except Exception as e:
            print(f'ERROR: {e}')
            results[scenario_name] = {'error': str(e)}

    return results


def run_soak_test(url, broker_name, body_size, duration_s, metrics):
    """Extended duration soak: sustained throughput + container stats sampling."""
    print(f'\n  === {broker_name} soak {duration_s}s ===')
    qname = f'soak_{broker_name}_{uuid.uuid4().hex[:6]}'

    m = MetricsCollector(sample_interval=5.0)
    m.start_sampling()

    start = time.monotonic()
    try:
        workloads.workload_saturated(url, qname, body_size, duration_s,
                                     m, tag='soak_pub')
    except Exception as e:
        m.record_error('soak_pub', str(e), time.monotonic() - start)
    finally:
        m.stop_sampling()

    return m.summary()


def build_result_json(broker_name, workload_results, scenario_results,
                      soak_results, sizes, duration):
    return {
        'broker': broker_name,
        'timestamp': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'config': {
            'sizes': sizes,
            'duration_s': duration,
        },
        'workloads': workload_results,
        'scenarios': scenario_results,
        'soak': soak_results,
    }


def main():
    ap = argparse.ArgumentParser(
        description='AMQP stress/soak benchmark for RabbitMQ vs HyrxMQ')
    ap.add_argument('--broker', choices=['rabbit', 'hyrx', 'both'],
                    default='both', help='Which broker(s) to test')
    ap.add_argument('--duration', type=int, default=DEFAULT_DURATION,
                    help='Workload duration in seconds (default: 60)')
    ap.add_argument('--soak', type=int, default=0,
                    help='Soak test duration in seconds (0=skip, 3600=1hr)')
    ap.add_argument('--sizes', default=','.join(str(s) for s in DEFAULT_SIZES),
                    help=f'Comma-separated message sizes in bytes '
                         f'(default: {",".join(str(s) for s in DEFAULT_SIZES)})')
    ap.add_argument('--workload', default=DEFAULT_WORKLOAD,
                    choices=list(workloads.WORKLOAD_REGISTRY.keys()),
                    help=f'Workload pattern (default: {DEFAULT_WORKLOAD})')
    ap.add_argument('--scenarios', default=','.join(DEFAULT_SCENARIOS),
                    help=f'Comma-separated failure scenarios '
                         f'(default: all)')
    ap.add_argument('--skip-scenarios', action='store_true',
                    help='Skip failure scenario testing')
    ap.add_argument('--skip-workloads', action='store_true',
                    help='Skip workload throughput testing')
    ap.add_argument('--output', default=None,
                    help='Output JSON path (default: results/<broker>_stress.json)')
    args = ap.parse_args()

    sizes = [int(s) for s in args.sizes.split(',') if s.strip()]
    scenarios = [s.strip() for s in args.scenarios.split(',') if s.strip()]

    # ensure HyrxMQ image is built
    containers.build_hyrxmq_image()

    brokers_to_test = []
    if args.broker in ('rabbit', 'both'):
        brokers_to_test.append('rabbit')
    if args.broker in ('hyrx', 'both'):
        brokers_to_test.append('hyrx')

    all_results = {}

    for broker in brokers_to_test:
        print(f'\n{"="*60}')
        print(f'  BROKER: {broker.upper()}')
        print(f'{"="*60}')

        # start container
        if broker == 'rabbit':
            spec = containers.rabbitmq_spec(name=f'stress-rabbit')
            state = containers.start_container(spec)
            url = containers.BrokerPair(rabbit_port=spec.amqp_port).rabbit_amqp_url()
        else:
            spec = containers.hyrxmq_spec(name=f'stress-hyrx')
            state = containers.start_container(spec)
            url = containers.BrokerPair(hyrx_port=spec.amqp_port).hyrx_amqp_url()

        if not state.ready:
            print(f'  {broker} not ready: {state.error}')
            containers.stop_container(state)
            continue

        print(f'  {broker} ready at {url}')

        workload_results = {}
        scenario_results = {}
        soak_results = {}

        try:
            if not args.skip_workloads:
                workload_results = run_workload_suite(
                    url, broker, sizes, args.duration,
                    MetricsCollector(), args.workload)

            if not args.skip_scenarios:
                scenario_results = run_scenario_suite(
                    url, broker, scenarios, 1024, MetricsCollector())

            if args.soak > 0:
                soak_results = run_soak_test(
                    url, broker, 1024, args.soak, MetricsCollector())

        except KeyboardInterrupt:
            print('\n  interrupted')
        except Exception as e:
            print(f'  suite error: {e}')
        finally:
            containers.stop_container(state)

        result = build_result_json(
            broker, workload_results, scenario_results,
            soak_results, sizes, args.duration)

        out_path = args.output
        if not out_path:
            out_dir = os.path.join(HERE, 'results')
            os.makedirs(out_dir, exist_ok=True)
            ts = time.strftime('%Y%m%d_%H%M%S')
            out_path = os.path.join(out_dir, f'{broker}_stress_{ts}.json')

        save_results(result, out_path)
        all_results[broker] = result
        print(f'\n  results saved to {out_path}')

    # cross-broker summary
    if len(all_results) == 2:
        print(f'\n{"="*60}')
        print(f'  CROSS-BROKER SUMMARY')
        print(f'{"="*60}')
        for workload_name in all_results.get('rabbit', {}).get('workloads', {}):
            r_data = all_results['rabbit']['workloads'].get(workload_name, {})
            h_data = all_results['hyrx']['workloads'].get(workload_name, {})
            r_t = r_data.get('avg_throughput', 0)
            h_t = h_data.get('avg_throughput', 0)
            ratio = h_t / r_t if r_t > 0 else 0
            print(f'  {workload_name}: rabbit={r_t:.0f} hyrx={h_t:.0f} ratio={ratio:.2f}x')

        for sc_name in DEFAULT_SCENARIOS:
            r_sc = all_results.get('rabbit', {}).get('scenarios', {}).get(sc_name, {})
            h_sc = all_results.get('hyrx', {}).get('scenarios', {}).get(sc_name, {})
            r_ok = 'error' not in r_sc
            h_ok = 'error' not in h_sc
            print(f'  {sc_name}: rabbit={"OK" if r_ok else "FAIL"} '
                  f'hyrx={"OK" if h_ok else "FAIL"}')

    print('\ndone.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
