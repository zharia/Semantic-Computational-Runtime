"""Metrics collector for AMQP stress testing.

Thread-safe time-series collector that runs during workloads, recording:
- Throughput samples (msgs/sec at N-second intervals)
- Latency percentiles (if publisher-confirms or request-reply pattern used)
- Error counts per second
- Broker container stats (CPU, memory, net IO)
- Scenario results (recovery times, data loss)

Produces a structured results dict compatible with analyze.py.
"""
import json
import os
import statistics
import sys
import threading
import time
from collections import defaultdict


class MetricsCollector:
    """Thread-safe metrics collection during benchmark runs."""

    def __init__(self, sample_interval=1.0):
        self.sample_interval = sample_interval
        self._lock = threading.Lock()
        self._series = defaultdict(list)  # tag -> [(t, count, elapsed, size)]
        self._errors = defaultdict(list)  # tag -> [(t, msg, elapsed)]
        self._scenarios = {}  # name -> result dict
        self._samples = defaultdict(list)  # tag -> [(t, msgs_per_sec)]
        self._start = time.monotonic()
        self._sample_thread = None
        self._stop_event = threading.Event()

    def record(self, tag, count, elapsed, body_size, final=False):
        with self._lock:
            self._series[tag].append({
                't': round(elapsed, 3),
                'count': count,
                'size': body_size,
                'final': final,
            })

    def record_error(self, tag, msg, elapsed):
        with self._lock:
            self._errors[tag].append({
                't': round(elapsed, 3),
                'msg': str(msg)[:200],
            })

    def record_scenario(self, name, result):
        with self._lock:
            self._scenarios[name] = result

    def start_sampling(self):
        self._start = time.monotonic()
        self._stop_event.clear()
        self._sample_thread = threading.Thread(target=self._sample_loop,
                                                daemon=True)
        self._sample_thread.start()

    def stop_sampling(self):
        self._stop_event.set()
        if self._sample_thread:
            self._sample_thread.join(timeout=2)

    def _sample_loop(self):
        last_counts = {}
        last_time = time.monotonic()
        while not self._stop_event.is_set():
            self._stop_event.wait(timeout=self.sample_interval)
            now = time.monotonic()
            dt = now - last_time
            if dt < 0.1:
                continue
            with self._lock:
                for tag, entries in self._series.items():
                    if not entries:
                        continue
                    last_count = last_counts.get(tag, 0)
                    current_count = entries[-1]['count']
                    delta = current_count - last_count
                    if delta > 0:
                        self._samples[tag].append({
                            't': round(now - self._start, 3),
                            'msgs_per_sec': round(delta / dt, 1),
                        })
                    last_counts[tag] = current_count
            last_time = now

    def summary(self):
        with self._lock:
            return self._build_summary()

    def _build_summary(self):
        out = {
            'workloads': {},
            'errors': {},
            'scenarios': dict(self._scenarios),
            'time_series': {},
        }

        for tag, entries in self._series.items():
            if not entries:
                continue
            final = [e for e in entries if e.get('final')]
            if final:
                f = final[-1]
                total_count = f['count']
                total_elapsed = f['t']
                body_size = f['size']
                throughput = total_count / total_elapsed if total_elapsed > 0 else 0

                # compute throughput stability from time-series samples
                samples = self._samples.get(tag, [])
                rates = [s['msgs_per_sec'] for s in samples if s['msgs_per_sec'] > 0]
                stability = {
                    'median': round(statistics.median(rates), 1) if rates else 0,
                    'p5': round(sorted(rates)[len(rates)//20] if len(rates) >= 20
                               else (min(rates) if rates else 0), 1),
                    'p95': round(sorted(rates)[int(len(rates)*0.95)]
                                if len(rates) >= 20
                                else (max(rates) if rates else 0), 1),
                    'cv_pct': round(statistics.stdev(rates) / statistics.mean(rates) * 100
                                   if len(rates) >= 2 and statistics.mean(rates) > 0
                                   else 0, 2),
                    'samples': len(rates),
                }

                out['workloads'][tag] = {
                    'total_count': total_count,
                    'elapsed_s': round(total_elapsed, 3),
                    'avg_throughput': round(throughput, 1),
                    'body_size': body_size,
                    'total_bytes': total_count * body_size,
                    'avg_throughput_bytes': round(throughput * body_size, 0),
                    'stability': stability,
                }
                out['time_series'][tag] = samples

        for tag, errs in self._errors.items():
            out['errors'][tag] = {
                'count': len(errs),
                'messages': [e['msg'] for e in errs[:10]],
            }

        return out


def save_results(results, path):
    os.makedirs(os.path.dirname(path) or '.', exist_ok=True)
    with open(path, 'w') as f:
        json.dump(results, f, indent=1)


def load_results(path):
    with open(path) as f:
        return json.load(f)
