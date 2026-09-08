"""Throwaway HyrxMQ-in-container helper (fairness cell, audit §19/§20).

Primary confound in a RabbitMQ-vs-HyrxMQ benchmark: the reference RabbitMQ is
reached through DOCKER port publishing (userspace `docker-proxy` hop) while a
natively-started HyrxMQ process is reached over plain loopback. That difference
is a *network path* difference, not an engine difference, so the headline
comparison must put BOTH brokers behind the same path.

This module builds and runs exactly that: a throwaway container image holding
`build/hyrxmq-listen` plus the shared libraries it needs, on the SAME docker
bridge as `node-rabbitmq`, published `127.0.0.1:5700 -> container:5700`
(mirroring how `node-rabbitmq` publishes 5672).

Design notes / invariants:
  * The binary is glibc-linked against the *host* glibc (CachyOS). The pixi env
    and the host glibc/loader are copied into the image, so the container runs
    the identical binary with the identical libc — the only thing that changes
    between `hyrx-tcp-native` and `hyrx-tcp-docker` is the network path. (A
    distro base's own glibc is older than the host's and the binary will not
    load against it; that is why the libs are copied rather than apt-installed.)
  * Every name created here starts with `hyrx-bench`. `node-rabbitmq` is never
    referenced, restarted, reconfigured or stopped by this module; teardown is
    `docker rm -f hyrx-bench-*` + `docker rmi hyrx-bench:*` only.
  * Teardown is idempotent and also callable standalone (`python docker_hyrx.py
    cleanup`) so a crashed run never leaves a container or image behind.
"""
import argparse
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BIN = os.path.join(REPO_ROOT, 'build', 'hyrxmq-listen')
IMAGE = 'hyrx-bench'
CONTAINER = 'hyrx-bench-listen'
PORT = 5700
BASE_IMAGE = 'alpine:latest'
FRAME_MAX = 131072

# `ldd` lines we must copy: everything the binary resolves outside the image.
# ld.so itself is placed at /lib64 so the ELF PT_INTERP resolves.
_SKIP_PREFIXES = ('linux-vdso', 'libcut_preload', 'statically linked', 'not a dynamic')


def _sh(*args, **kw):
    """Run a command, returning CompletedProcess (check=False by default)."""
    kw.setdefault('text', True)
    kw.setdefault('capture_output', True)
    return subprocess.run(list(args), **kw)


def required_libs(binary=BIN):
    """Resolve the binary's shared-library paths via ldd (host paths)."""
    out = _sh('ldd', binary)
    if out.returncode != 0:
        raise RuntimeError(f'ldd failed on {binary}: {out.stderr}')
    libs = []
    for line in out.stdout.splitlines():
        line = line.strip()
        if any(line.startswith(p) for p in _SKIP_PREFIXES):
            continue
        parts = line.split()
        path = next((p for p in parts if p.startswith('/')), None)
        if path and os.path.exists(path):
            libs.append(path)
    if not libs:
        raise RuntimeError(f'ldd produced no resolvable libraries for {binary}')
    return libs


def build_context(dest=None):
    """Copy binary + libraries + Dockerfile into `dest`; return dest."""
    dest = dest or tempfile.mkdtemp(prefix='hyrx-bench-ctx-')
    os.makedirs(os.path.join(dest, 'bin'), exist_ok=True)
    os.makedirs(os.path.join(dest, 'lib'), exist_ok=True)
    shutil.copy2(BIN, os.path.join(dest, 'bin', 'hyrxmq-listen'))
    for lib in required_libs():
        dst = os.path.join(dest, 'lib', os.path.basename(lib))
        if not os.path.exists(dst):
            shutil.copy2(lib, dst)
    loader = os.path.join(dest, 'lib', 'ld-linux-x86-64.so.2')
    if not os.path.exists(loader):
        raise RuntimeError('host ELF loader (ld-linux-x86-64.so.2) not found in '
                           'ldd output; container cannot be built')
    with open(os.path.join(dest, 'Dockerfile'), 'w') as fh:
        fh.write(
            f'FROM {BASE_IMAGE}\n'
            'RUN mkdir -p /opt/hyrx/bin /opt/hyrx/lib /lib64\n'
            'COPY bin/hyrxmq-listen /opt/hyrx/bin/\n'
            'COPY lib/ /opt/hyrx/lib/\n'
            'RUN cp /opt/hyrx/lib/ld-linux-x86-64.so.2 /lib64/ '
            '&& chmod 0755 /opt/hyrx/bin/hyrxmq-listen\n'
            f'ENV LD_LIBRARY_PATH=/opt/hyrx/lib \\\n'
            f'    HYRXMQ_HOST=0.0.0.0 HYRXMQ_PORT={PORT} '
            f'HYRXMQ_FRAME_MAX={FRAME_MAX}\n'
            f'EXPOSE {PORT}\n'
            'ENTRYPOINT ["/opt/hyrx/bin/hyrxmq-listen"]\n')
    return dest


def image_tag():
    head = _sh('git', '-C', REPO_ROOT, 'rev-parse', '--short', 'HEAD').stdout.strip()
    return f'{IMAGE}:{head or "dev"}'


def build_image(tag=None, ctx=None, quiet=True):
    """Build the throwaway image; returns (tag, ctxdir)."""
    tag = tag or image_tag()
    ctx = build_context(ctx)
    cmd = ['docker', 'build', '-t', tag, ctx]
    if quiet:
        cmd.insert(2, '-q')
    res = _sh(*cmd)
    if res.returncode != 0:
        raise RuntimeError(f'docker build failed:\n{res.stdout}\n{res.stderr}')
    return tag, ctx


def wait_port(host='127.0.0.1', port=PORT, timeout=20.0):
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with socket.create_connection((host, port), timeout=0.5):
                return True
        except OSError:
            time.sleep(0.1)
    return False


def up(tag=None, port=PORT, name=CONTAINER):
    """Start the container on the default bridge, published like node-rabbitmq."""
    tag = tag or image_tag()
    _sh('docker', 'rm', '-f', name)  # idempotent
    res = _sh('docker', 'run', '-d', '--name', name, '--network', 'bridge',
              '-p', f'127.0.0.1:{port}:{port}', tag)
    if res.returncode != 0:
        raise RuntimeError(f'docker run failed: {res.stderr.strip()}')
    if not wait_port(port=port):
        log = _sh('docker', 'logs', name).stdout + _sh('docker', 'logs',
                                                       name).stderr
        raise RuntimeError(f'container {name} not accepting on :{port}; '
                           f'logs:\n{log}')
    return {'container': name, 'id': res.stdout.strip()[:12], 'image': tag,
            'port': port, 'published': f'127.0.0.1:{port}->{port}',
            'network': 'bridge'}


def down(name=CONTAINER, tag=None):
    """Remove container + image + any leftover hyrx-bench-* containers."""
    actions = []
    res = _sh('docker', 'ps', '-a', '--format', '{{.Names}}')
    for existing in res.stdout.split():
        if existing.startswith('hyrx-bench'):
            actions.append(('rm', existing,
                            _sh('docker', 'rm', '-f', existing).returncode == 0))
    tags = [tag] if tag else []
    ls = _sh('docker', 'images', '--format', '{{.Repository}}:{{.Tag}}')
    tags += [t for t in ls.stdout.split() if t.startswith(IMAGE + ':')]
    for t in filter(None, dict.fromkeys(tags)):
        actions.append(('rmi', t, _sh('docker', 'rmi', '-f', t).returncode == 0))
    return actions


def leftovers():
    out = _sh('docker', 'ps', '-a', '--format', '{{.Names}}').stdout.split()
    imgs = _sh('docker', 'images', '--format',
               '{{.Repository}}:{{.Tag}}').stdout.split()
    return {'containers': [n for n in out if n.startswith('hyrx-bench')],
            'images': [i for i in imgs if i.startswith(IMAGE + ':')]}


def ensure_fair_cell(port=PORT):
    """build -> up -> return info dict; caller must call `down` (see harness)."""
    tag, ctx = build_image()
    try:
        try:
            info = up(tag=tag, port=port)
        except Exception:
            # never leave a half-started fairness container behind
            down(tag=tag)
            raise
    finally:
        shutil.rmtree(ctx, ignore_errors=True)
    info['context_dir_removed'] = True
    return info


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    sub.add_parser('libs', help='show libraries the image must carry')
    b = sub.add_parser('build', help='build the throwaway image')
    b.add_argument('--keep-context', action='store_true')
    u = sub.add_parser('up', help='build + start the container')
    u.add_argument('--port', type=int, default=PORT)
    d = sub.add_parser('down', help='remove every hyrx-bench* container/image')
    d.add_argument('--tag', default=None)
    sub.add_parser('status', help='report leftovers')
    args = ap.parse_args()

    if args.cmd == 'libs':
        for lib in required_libs():
            print(lib)
    elif args.cmd == 'build':
        tag, ctx = build_image(quiet=False)
        print('BUILT', tag)
        if not args.keep_context:
            shutil.rmtree(ctx, ignore_errors=True)
    elif args.cmd == 'up':
        print(ensure_fair_cell(args.port))
    elif args.cmd == 'down':
        for kind, what, ok in down(tag=args.tag):
            print(f'{kind} {what}: {"ok" if ok else "FAILED"}')
        print('LEFTOVERS', leftovers())
    elif args.cmd == 'status':
        print(leftovers())
    return 0


if __name__ == '__main__':
    sys.exit(main())
