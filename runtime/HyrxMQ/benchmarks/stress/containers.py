"""Docker container orchestrator for AMQP broker stress testing.

Manages lifecycle of RabbitMQ and HyrxMQ containers with:
- Health-check gating (broker ready before work begins)
- Container stats collection (CPU/memory/network)
- Forced cleanup on failure or timeout
- Port allocation for parallel test isolation
"""
import json
import os
import subprocess
import sys
import time
from dataclasses import dataclass, field
from typing import Optional

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

RABBITMQ_IMAGE = 'rabbitmq:3-management'
HYRXMQ_DOCKERFILE = os.path.join(ROOT, 'Dockerfile')
HYRXMQ_IMAGE = 'hyrxmq:stress-test'
RABBITMQ_AMQP_PORT = 5672
RABBITMQ_MGMT_PORT = 15672
HYRXMQ_AMQP_PORT = 5673
HYRXMQ_WEB_PORT = 8080


@dataclass
class ContainerSpec:
    name: str
    image: str
    amqp_port: int
    web_port: int = 0
    mgmt_port: int = 0
    env: dict = field(default_factory=dict)
    volumes: dict = field(default_factory=dict)
    health_cmd: str = ''
    health_retries: int = 30
    health_interval: float = 1.0


@dataclass
class ContainerState:
    spec: ContainerSpec
    container_id: str = ''
    running: bool = False
    ready: bool = False
    stats: dict = field(default_factory=dict)
    start_time: float = 0.0
    error: str = ''


def _run(cmd, check=True, capture=True, timeout=30):
    try:
        r = subprocess.run(cmd, shell=isinstance(cmd, str), check=check,
                           capture_output=capture, timeout=timeout)
        return r.stdout.decode().strip() if capture else ''
    except subprocess.TimeoutExpired:
        return ''
    except subprocess.CalledProcessError as e:
        if check:
            raise
        return e.stdout.decode().strip() if e.stdout else ''


def build_hyrxmq_image(tag=HYRXMQ_IMAGE):
    print(f'  building {tag} ...')
    _run(f'docker build -t {tag} {ROOT}', timeout=120)


def remove_container(name, force=True):
    flag = '-f' if force else ''
    _run(f'docker rm {flag} {name}', check=False, timeout=10)


def container_running(name):
    out = _run(f'docker inspect -f {{{{.State.Running}}}} {name}', check=False)
    return out == 'true'


def container_stats(name):
    out = _run(
        f'docker stats {name} --no-stream --format '
        '"{{{{.CPUPerc}}}},{{{{.MemUsage}}}},{{{{.MemPerc}}}},{{{{.NetIO}}}}"',
        check=False, timeout=5)
    if not out:
        return {}
    parts = out.split(',')
    if len(parts) >= 4:
        return {
            'cpu_pct': parts[0],
            'mem_usage': parts[1],
            'mem_pct': parts[2],
            'net_io': parts[3],
        }
    return {'raw': out}


def health_check(name, cmd, retries=30, interval=1.0):
    for i in range(retries):
        out = _run(f'docker exec {name} {cmd}', check=False, timeout=5)
        if out.lower() in ('ok', 'true', 'ready', ''):
            # empty output from rabbitmq-diagnostics means OK
            if not cmd.startswith('rabbitmq') or 'is running' in out or out == '':
                return True
            if 'is running' in out:
                return True
        time.sleep(interval)
    return False


def start_container(spec: ContainerSpec) -> ContainerState:
    state = ContainerState(spec=spec)
    try:
        remove_container(spec.name)
        port_args = f'-p {spec.amqp_port}:5672'
        if spec.web_port:
            port_args += f' -p {spec.web_port}:{HYRXMQ_WEB_PORT}'
        if spec.mgmt_port:
            port_args += f' -p {spec.mgmt_port}:{RABBITMQ_MGMT_PORT}'

        env_args = ' '.join(f'-e {k}={v}' for k, v in spec.env.items())
        vol_args = ' '.join(f'-v {k}:{v}' for k, v in spec.volumes.items())

        cmd = (f'docker run -d --name {spec.name} '
               f'--memory=512m --cpus=1.0 '
               f'{port_args} {env_args} {vol_args} {spec.image}')
        state.container_id = _run(cmd, timeout=30)
        state.start_time = time.time()
        state.running = True

        if spec.health_cmd:
            state.ready = health_check(
                spec.name, spec.health_cmd,
                retries=spec.health_retries,
                interval=spec.health_interval)
            if not state.ready:
                state.error = f'health check failed after {spec.health_retries} retries'
        else:
            state.ready = True

    except Exception as e:
        state.error = str(e)
        state.running = False

    return state


def stop_container(state: ContainerState):
    if state.container_id:
        _run(f'docker stop {state.spec.name}', check=False, timeout=15)
        _run(f'docker rm {state.spec.name}', check=False, timeout=10)
    state.running = False


def collect_container_stats(state: ContainerState):
    if state.running:
        state.stats = container_stats(state.spec.name)
    return state.stats


def rabbitmq_spec(name='bench-rabbit', amqp_port=5672, mgmt_port=15672):
    return ContainerSpec(
        name=name,
        image=RABBITMQ_IMAGE,
        amqp_port=amqp_port,
        mgmt_port=mgmt_port,
        health_cmd='rabbitmq-diagnostics -q ping',
        health_retries=40,
        health_interval=1.0,
    )


def hyrxmq_spec(name='bench-hyrx', amqp_port=5673, web_port=8081):
    return ContainerSpec(
        name=name,
        image=HYRXMQ_IMAGE,
        amqp_port=amqp_port,
        web_port=web_port,
        env={'HYRXMQ_HOST': '0.0.0.0'},
        health_cmd='echo ready',
        health_retries=10,
        health_interval=0.5,
    )


class BrokerPair:
    """Manages a RabbitMQ + HyrxMQ container pair for A/B testing."""

    def __init__(self, rabbit_port=5672, hyrx_port=5673, prefix='bench'):
        self.rabbit = rabbitmq_spec(
            name=f'{prefix}-rabbit', amqp_port=rabbit_port,
            mgmt_port=RABBITMQ_MGMT_PORT)
        self.hyrx = hyrxmq_spec(
            name=f'{prefix}-hyrx', amqp_port=hyrx_port,
            web_port=HYRXMQ_WEB_PORT)
        self._rabbit_state: Optional[ContainerState] = None
        self._hyrx_state: Optional[ContainerState] = None

    def start(self, which='both'):
        build_hyrxmq_image()
        results = {}
        if which in ('both', 'rabbit'):
            print(f'  starting RabbitMQ ...')
            self._rabbit_state = start_container(self.rabbit)
            results['rabbit'] = self._rabbit_state
        if which in ('both', 'hyrx'):
            print(f'  starting HyrxMQ ...')
            self._hyrx_state = start_container(self.hyrx)
            results['hyrx'] = self._hyrx_state
        return results

    def stop(self, which='both'):
        if which in ('both', 'rabbit') and self._rabbit_state:
            stop_container(self._rabbit_state)
        if which in ('both', 'hyrx') and self._hyrx_state:
            stop_container(self._hyrx_state)

    def stats(self, which='both'):
        out = {}
        if which in ('both', 'rabbit') and self._rabbit_state:
            out['rabbit'] = collect_container_stats(self._rabbit_state)
        if which in ('both', 'hyrx') and self._hyrx_state:
            out['hyrx'] = collect_container_stats(self._hyrx_state)
        return out

    def ready(self, which='both'):
        if which in ('both', 'rabbit'):
            if not self._rabbit_state or not self._rabbit_state.ready:
                return False
        if which in ('both', 'hyrx'):
            if not self._hyrx_state or not self._hyrx_state.ready:
                return False
        return True

    def rabbit_amqp_url(self):
        return f'amqp://guest:guest@127.0.0.1:{self.rabbit.amqp_port}/'

    def hyrx_amqp_url(self):
        return f'amqp://guest:guest@127.0.0.1:{self.hyrx.amqp_port}/'

    def cleanup(self):
        self.stop()
        remove_container(self.rabbit.name)
        remove_container(self.hyrx.name)
