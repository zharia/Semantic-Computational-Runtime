# AMQP 0-9-1 protocol constants.

struct MethodID:
    """A class_id + method_id pair identifying an AMQP method."""
    var class_id: UInt16
    var method_id: UInt16

    def __init__(out self, cid: UInt16, mid: UInt16):
        self.class_id = cid
        self.method_id = mid

    def __eq__(self, other: MethodID) -> Bool:
        return self.class_id == other.class_id and self.method_id == other.method_id


# Frame types
def FRAME_METHOD() -> UInt8:
    return 1

def FRAME_HEADER() -> UInt8:
    return 2

def FRAME_BODY() -> UInt8:
    return 3

def FRAME_HEARTBEAT() -> UInt8:
    return 8

def FRAME_END() -> UInt8:
    return 0xCE

# Connection class (10)
def CONNECTION_START() -> MethodID:
    return MethodID(10, 1)

def CONNECTION_START_OK() -> MethodID:
    return MethodID(10, 2)

def CONNECTION_TUNE() -> MethodID:
    return MethodID(10, 3)

def CONNECTION_TUNE_OK() -> MethodID:
    return MethodID(10, 4)

def CONNECTION_OPEN() -> MethodID:
    return MethodID(10, 5)

def CONNECTION_OPEN_OK() -> MethodID:
    return MethodID(10, 6)

def CONNECTION_CLOSE() -> MethodID:
    return MethodID(10, 10)

def CONNECTION_CLOSE_OK() -> MethodID:
    return MethodID(10, 11)

# Channel class (20)
def CHANNEL_OPEN() -> MethodID:
    return MethodID(20, 1)

def CHANNEL_OPEN_OK() -> MethodID:
    return MethodID(20, 2)

def CHANNEL_CLOSE() -> MethodID:
    return MethodID(20, 40)

def CHANNEL_CLOSE_OK() -> MethodID:
    return MethodID(20, 41)

# Exchange class (40)
def EXCHANGE_DECLARE() -> MethodID:
    return MethodID(40, 10)

def EXCHANGE_DECLARE_OK() -> MethodID:
    return MethodID(40, 11)

# Queue class (50)
def QUEUE_DECLARE() -> MethodID:
    return MethodID(50, 10)

def QUEUE_DECLARE_OK() -> MethodID:
    return MethodID(50, 11)

def QUEUE_BIND() -> MethodID:
    return MethodID(50, 20)

def QUEUE_BIND_OK() -> MethodID:
    return MethodID(50, 21)

# Basic class (60)
def BASIC_PUBLISH() -> MethodID:
    return MethodID(60, 40)

def BASIC_DELIVER() -> MethodID:
    return MethodID(60, 60)

def BASIC_ACK() -> MethodID:
    return MethodID(60, 80)

def BASIC_NACK() -> MethodID:
    return MethodID(60, 120)

def BASIC_CONSUME() -> MethodID:
    return MethodID(60, 20)

def BASIC_CONSUME_OK() -> MethodID:
    return MethodID(60, 21)

def BASIC_CANCEL() -> MethodID:
    return MethodID(60, 30)

def BASIC_CANCEL_OK() -> MethodID:
    return MethodID(60, 31)

# Reply codes
def REPLY_SUCCESS() -> UInt16:
    return 200

def REPLY_PROTOCOL_ERROR() -> UInt16:
    return 502

def REPLY_NOT_IMPLEMENTED() -> UInt16:
    return 540

def REPLY_RESOURCE_ERROR() -> UInt16:
    return 541
