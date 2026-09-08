# AMQP 0-9-1 connection and channel state machines.
#
# State constants and the storage/accessor scaffolding exist; method ids used
# with them are the normative ones from amqp0-9-1.xml (see
# src/hyrx/amqp/constants.mojo).
#
# NOT IMPLEMENTED — connection-negotiation gaps (deliberate Phase 7 scope cut):
# - 8-octet protocol header (`AMQP\x00\x00\x09\x01`) detection/rejection at the
#   start of the stream (connection.start is only legal after it is accepted).
# - SASL negotiation: connection.start (10,10) / start-ok (10,11) /
#   secure (10,20) / secure-ok (10,21) round trips (mechanism + locale choice).
# - tune (10,30) / tune-ok (10,31) round trip: negotiate() below stores values
#   but no tune frame is ever encoded, sent or parsed, so channel_max/frame_max/
#   heartbeat stay un-negotiated defaults.
# - close handshake: connection.close (10,50) / close-ok (10,51) and the
#   channel close (20,40)/(20,41) reply sequencing.
# - frame_max enforcement in AMQPFrameCodec (a peer may request >131072 bytes or
#   sizes the receiver never checks) and channel_max enforcement.
# - heartbeat (frame type 8) send/receive timers.
# The states below are therefore reachable only by direct set_state() calls from
# the service layer, not by a negotiated handshake.

# Connection states
def CONN_STATE_CLOSED() -> Int:
    return 0

def CONN_STATE_START_SENT() -> Int:
    return 1

def CONN_STATE_START_RECEIVED() -> Int:
    return 2

def CONN_STATE_TUNE_SENT() -> Int:
    return 3

def CONN_STATE_TUNE_RECEIVED() -> Int:
    return 4

def CONN_STATE_OPEN_SENT() -> Int:
    return 5

def CONN_STATE_OPEN_RECEIVED() -> Int:
    return 6

def CONN_STATE_OPEN() -> Int:
    return 7

def CONN_STATE_CLOSING() -> Int:
    return 8

# Channel states
def CHAN_STATE_CLOSED() -> Int:
    return 0

def CHAN_STATE_OPEN_SENT() -> Int:
    return 1

def CHAN_STATE_OPEN() -> Int:
    return 2

def CHAN_STATE_CLOSING() -> Int:
    return 3


struct AMQPConnectionState:
    """Tracks the state of an AMQP connection."""

    var _state: Int
    var _channel_max: UInt16
    var _frame_max: UInt32
    var _heartbeat: UInt16

    def __init__(out self):
        self._state = CONN_STATE_CLOSED()
        self._channel_max = 0
        self._frame_max = 0
        self._heartbeat = 0

    def state(ref self) -> Int:
        return self._state

    def set_state(mut self, new_state: Int):
        self._state = new_state

    def is_closed(ref self) -> Bool:
        return self._state == CONN_STATE_CLOSED()

    def is_open(ref self) -> Bool:
        return self._state == CONN_STATE_OPEN()

    def negotiate(mut self, channel_max: UInt16, frame_max: UInt32, heartbeat: UInt16):
        """Server sends tune. Client responds with tune-ok."""
        self._channel_max = channel_max
        self._frame_max = frame_max
        self._heartbeat = heartbeat
        self._state = CONN_STATE_TUNE_RECEIVED()

    def channel_max(ref self) -> UInt16:
        return self._channel_max

    def frame_max(ref self) -> UInt32:
        return self._frame_max

    def heartbeat(ref self) -> UInt16:
        return self._heartbeat


struct AMQPChannelState:
    """Tracks the state of an AMQP channel."""

    var _state: Int
    var _channel_id: UInt16

    def __init__(out self, channel_id: UInt16):
        self._channel_id = channel_id
        self._state = CHAN_STATE_CLOSED()

    def channel_id(ref self) -> UInt16:
        return self._channel_id

    def state(ref self) -> Int:
        return self._state

    def set_state(mut self, new_state: Int):
        self._state = new_state

    def is_closed(ref self) -> Bool:
        return self._state == CHAN_STATE_CLOSED()

    def is_open(ref self) -> Bool:
        return self._state == CHAN_STATE_OPEN()
