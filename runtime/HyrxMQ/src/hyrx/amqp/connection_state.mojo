# AMQP 0-9-1 connection and channel state machines.

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
