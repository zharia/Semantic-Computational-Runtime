"""AF_UNIX transport for pika — no new dependencies, no pika source changes.

pika 1.4.4 can only bring AMQP up over TCP: `AMQPConnector.start()` builds the
socket from a `getaddrinfo()`-shaped record, calls
`setsockopt(SOL_TCP, TCP_NODELAY)` plus `tcp_options`, and hands it to
`nbio.connect_socket()`, whose `_AsyncSocketConnector` validates the peer with
`socket.inet_pton(sock.family, addr[0])`. All three are meaningless (or raise)
for `AF_UNIX`, so a Unix-domain AMQP connection cannot be expressed through
`ConnectionParameters` alone.

This module adds it by subclassing only three pika hooks:

  * `UnixAMQPConnector(AMQPConnector)` — overrides `start()`: create a
    non-blocking `AF_UNIX` stream socket, `connect_ex()` to the path from the
    address record, then re-enter the *inherited* pipeline at
    `_on_tcp_connection_done(None)`. That single re-entry point is what skips
    the TCP-only setsockopt and the `inet_pton` validation while leaving
    everything after it — `create_streaming_connection()` (family-agnostic: it
    only needs a connected fd), `_StreamingProtocolShim`, the AMQP 0-9-1
    handshake and all frame handling — exactly pika's own code. Loopback
    `AF_UNIX` connect to a listening socket completes in-kernel immediately;
    `EINPROGRESS` is finished through the adapter's own writer watcher, so the
    event loop is never blocked.

  * `UnixSocketAMQPConnectionWorkflow(AMQPConnectionWorkflow)` — replaces the
    DNS step with one AF_UNIX record (`_try_next_config_async`) and swaps the
    connector class the workflow's inherited attempt loop instantiates
    (`start()` wrapping `connector_factory`). Retries, timeouts and config
    sequencing stay the inherited ones.

  * `BlockingUnixConnection(BlockingConnection)` — `_create_connection()`
    mirrors pika 1.4.4's (blocking_connection.py:425-486) with the sole change
    of passing `workflow=UnixSocketAMQPConnectionWorkflow(path)` to
    `SelectConnection.create_connection()`. The blocking API reached afterwards
    (`channel()`, `basic_publish`, `basic_get`, `basic_consume`, `close`) is
    pika's, byte-for-byte identical to the TCP path.

`python pika_uds.py <path>` runs the built-in self-probe (publish + get one
message over AF_UNIX against our broker); exit 0 means the patch works, a
non-zero exit prints the real error.

Verified: same `basic_publish` -> `basic_get` byte-equality flow that
`scripts/interop/pika_content.py` runs over TCP, run over the AF_UNIX listener.
"""
import errno
import socket
import sys
from collections import namedtuple
from typing import Any, Optional, Sequence, Union

from pika.adapters import blocking_connection, select_connection
from pika.adapters.utils import connection_workflow
from pika.connection import ConnectionParameters

# `getaddrinfo()`-shaped record for AF_UNIX: (family, type, proto, canonname,
# sockaddr) where sockaddr is the path string.
def uds_addr_record(path: str) -> tuple:
    return (socket.AF_UNIX, socket.SOCK_STREAM, 0, '', path)


class UnixAMQPConnector(connection_workflow.AMQPConnector):
    """`AMQPConnector` that dials a Unix-domain socket instead of TCP."""

    def start(  # type: ignore[override]
            self,
            addr_record: tuple,
            conn_params: ConnectionParameters,
            on_done,
    ) -> None:
        if self._state != self._STATE_INIT:  # pylint: disable=W0212
            raise connection_workflow.AMQPConnectorWrongState(
                f'Already in progress or finished; state={self._state}')

        self._addr_record = addr_record
        self._conn_params = conn_params
        self._on_done = on_done
        path = addr_record[4]

        # Same state transition as the TCP connector, minus the TCP-only
        # socket options (SOL_TCP / TCP_NODELAY / tcp_options are meaningless
        # — and the first would raise — on a non-INET family).
        self._state = self._STATE_TCP  # pylint: disable=W0212
        self._sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self._sock.setblocking(False)

        # Arm the same timeouts the parent arms, before connecting, so
        # `_on_tcp_connection_done()` cancels them exactly as in pika's own
        # async path.
        self._tcp_timeout_ref = None  # pylint: disable=W0212
        if conn_params.socket_timeout is not None:
            self._tcp_timeout_ref = self._nbio.call_later(  # pylint: disable=W0212
                conn_params.socket_timeout,
                self._on_tcp_connection_timeout)  # pylint: disable=W0212
        self._stack_timeout_ref = None  # pylint: disable=W0212
        if conn_params.stack_timeout is not None:
            self._stack_timeout_ref = self._nbio.call_later(  # pylint: disable=W0212
                conn_params.stack_timeout,
                self._on_overall_timeout)  # pylint: disable=W0212

        err = self._sock.connect_ex(path)
        if err == 0:
            self._task_ref = None  # pylint: disable=W0212
            self._on_tcp_connection_done(None)  # -> transport -> AMQP
            return
        if err in (errno.EINPROGRESS, errno.EALREADY, errno.EWOULDBLOCK):
            # Not connected yet: let the adapter's loop tell us when writable.
            self._task_ref = None  # pylint: disable=W0212
            self._nbio.set_writer(  # pylint: disable=W0212
                self._sock.fileno(), self._on_uds_writable)
            return
        self._report_completion_and_cleanup(  # pylint: disable=W0212
            connection_workflow.AMQPConnectorSocketConnectError(
                OSError(err, f'AF_UNIX connect to {path!r} failed')))

    def _on_uds_writable(self) -> None:
        sock = self._sock
        if sock is None:
            return
        self._nbio.remove_writer(sock.fileno())  # pylint: disable=W0212
        so_error = sock.getsockopt(socket.SOL_SOCKET, socket.SO_ERROR)
        if so_error:
            self._report_completion_and_cleanup(  # pylint: disable=W0212
                connection_workflow.AMQPConnectorSocketConnectError(
                    OSError(so_error, 'AF_UNIX connect failed')))
            return
        self._on_tcp_connection_done(None)  # pylint: disable=W0212


class UnixSocketAMQPConnectionWorkflow(
        connection_workflow.AMQPConnectionWorkflow):
    """`AMQPConnectionWorkflow` that resolves to one AF_UNIX record."""

    def __init__(self, path: str) -> None:
        super().__init__()
        self._path = path

    def start(  # type: ignore[override]
            self,
            connection_configs: Sequence[ConnectionParameters],
            connector_factory,
            native_loop,
            on_done,
    ) -> None:
        # Inject UnixAMQPConnector into pika's own connector factory: the
        # returned instance already closes over the adapter's connection
        # factory and nbio, so only its dial behaviour is replaced.
        base_factory = connector_factory

        def unix_connector_factory():
            connector = base_factory()
            connector.__class__ = UnixAMQPConnector
            return connector

        super().start(connection_configs, unix_connector_factory, native_loop,
                      on_done)

    def _try_next_config_async(self) -> None:
        """`AMQPConnectionWorkflow._try_next_config_async()` (pika 1.4.4)
        with the `nbio.getaddrinfo()` call replaced by a single AF_UNIX
        record. Index/cycle bookkeeping is unchanged."""
        self._task_ref = None  # pylint: disable=W0212

        if self._current_config_index is None:  # pylint: disable=W0212
            self._current_config_index = 0
        else:
            self._current_config_index += 1  # pylint: disable=W0212

        if self._current_config_index >= len(
                self._connection_configs):  # pylint: disable=W0212
            self._start_new_cycle_async(first=False)  # pylint: disable=W0212
            return

        self._addrinfo_iter = iter([uds_addr_record(self._path)])  # pylint: disable=W0212
        self._try_next_resolved_address()  # pylint: disable=W0212


class BlockingUnixConnection(blocking_connection.BlockingConnection):
    """`BlockingConnection` over a Unix-domain socket.

    Identical API to pika's BlockingConnection; only the socket family
    differs. `parameters.host`/`port` are unused (the path decides), while
    credentials / heartbeat / frame_max / channel_max apply exactly as over
    TCP.
    """

    def __init__(self,
                 uds_path: str,
                 parameters: Optional[Union[ConnectionParameters,
                                            Sequence[ConnectionParameters]]] = None
                 ) -> None:
        self._uds_path = uds_path
        super().__init__(parameters=parameters)

    def _create_connection(  # pylint: disable=W0221
            self,
            configs: Any = None,
            impl_class: Any = None) -> select_connection.SelectConnection:
        # Mirror of pika 1.4.4 BlockingConnection._create_connection(); the
        # only difference is the injected `workflow=` argument.
        if configs is None:
            configs = (ConnectionParameters(),)
        if isinstance(configs, ConnectionParameters):
            configs = (configs,)
        if not configs:
            raise ValueError('Expected a non-empty sequence of connection '
                             'parameters, but got {!r}.'.format(configs))

        on_cw_done_result = blocking_connection._CallbackResult(
            namedtuple('BlockingConnection_OnConnectionWorkflowDoneArgs',
                       'result'))

        impl_class = impl_class or select_connection.SelectConnection
        ioloop = select_connection.IOLoop()
        ioloop.activate_poller()
        try:
            impl_class.create_connection(
                configs,
                on_done=on_cw_done_result.set_value_once,
                custom_ioloop=ioloop,
                workflow=UnixSocketAMQPConnectionWorkflow(self._uds_path))

            while not on_cw_done_result.ready:
                ioloop.poll()
                ioloop.process_timeouts()

            if isinstance(on_cw_done_result.value.result, BaseException):
                error = on_cw_done_result.value.result
                raise self._reap_last_connection_workflow_error(error)
            return on_cw_done_result.value.result
        except Exception:
            ioloop.close()
            self._cleanup()
            raise


def connect(uds_path: str, parameters: ConnectionParameters) -> BlockingUnixConnection:
    """Open a `BlockingUnixConnection` to `uds_path` with AMQP `parameters`."""
    return BlockingUnixConnection(uds_path, parameters=parameters)


def _self_probe(path: str) -> int:
    """Publish + get one message over AF_UNIX. 0 == the patch works.

    Topology is an explicit direct exchange + bind (not the default exchange):
    default-exchange auto-binding is a broker-specific behaviour our broker
    does not implement, so a `routing_key=<queue>` publish to `exchange=''`
    would not route here and would make the probe look broken.
    """
    body = b'pika-uds-probe'
    params = ConnectionParameters(host='localhost', port=0, virtual_host='/',
                                  heartbeat=0, frame_max=131072,
                                  socket_timeout=10, stack_timeout=20)
    conn = connect(path, params)
    try:
        ch = conn.channel()
        ch.exchange_declare(exchange='pika-uds-probe-x', exchange_type='direct',
                            durable=False, auto_delete=False)
        ch.queue_declare(queue='pika-uds-probe-q', durable=False,
                         exclusive=True, auto_delete=False)
        ch.queue_bind(queue='pika-uds-probe-q', exchange='pika-uds-probe-x',
                      routing_key='rk')
        ch.basic_publish(exchange='pika-uds-probe-x', routing_key='rk',
                         body=body)
        meth, _props, got = ch.basic_get(queue='pika-uds-probe-q',
                                         auto_ack=True)
        assert got == body, f'body mismatch: {got!r}'
        print(f'PIKA_UDS_OK path={path} body={got!r} reply={type(meth).__name__}')
        return 0
    finally:
        # HyrxMQ does not answer connection.close, so a graceful close can
        # wedge: drop the raw socket (same backstop scripts/interop uses).
        try:
            transport = getattr(conn._impl, '_transport', None)
            raw = getattr(transport, '_sock', None) if transport else None
            if raw is not None:
                raw.close()
        except Exception:
            pass


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(_self_probe(sys.argv[1]))
