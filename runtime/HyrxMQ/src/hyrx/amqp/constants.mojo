# AMQP 0-9-1 protocol constants.
#
# Method indices (class-id, method-id) are taken verbatim from the normative
# AMQP 0-9-1 XML definition, amqp0-9-1.xml
# (https://www.rabbitmq.com/resources/specs/amqp0-9-1.xml): each <class> and
# <method> carries an `index` attribute; those indices are the wire values.
# Frame-type / frame-end constants come from the same file's <constant> block.
#
# Note: the `confirm` class (index 85) is a RabbitMQ extension; it is not in
# amqp0-9-1.xml and its indices below follow the published extension table.

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
    return MethodID(10, 10)

def CONNECTION_START_OK() -> MethodID:
    return MethodID(10, 11)

def CONNECTION_SECURE() -> MethodID:
    return MethodID(10, 20)

def CONNECTION_SECURE_OK() -> MethodID:
    return MethodID(10, 21)

def CONNECTION_TUNE() -> MethodID:
    return MethodID(10, 30)

def CONNECTION_TUNE_OK() -> MethodID:
    return MethodID(10, 31)

def CONNECTION_OPEN() -> MethodID:
    return MethodID(10, 40)

def CONNECTION_OPEN_OK() -> MethodID:
    return MethodID(10, 41)

def CONNECTION_CLOSE() -> MethodID:
    return MethodID(10, 50)

def CONNECTION_CLOSE_OK() -> MethodID:
    return MethodID(10, 51)

# Channel class (20)
def CHANNEL_OPEN() -> MethodID:
    return MethodID(20, 10)

def CHANNEL_OPEN_OK() -> MethodID:
    return MethodID(20, 11)

def CHANNEL_FLOW() -> MethodID:
    return MethodID(20, 20)

def CHANNEL_FLOW_OK() -> MethodID:
    return MethodID(20, 21)

def CHANNEL_CLOSE() -> MethodID:
    return MethodID(20, 40)

def CHANNEL_CLOSE_OK() -> MethodID:
    return MethodID(20, 41)

# Exchange class (40)
def EXCHANGE_DECLARE() -> MethodID:
    return MethodID(40, 10)

def EXCHANGE_DECLARE_OK() -> MethodID:
    return MethodID(40, 11)

def EXCHANGE_DELETE() -> MethodID:
    return MethodID(40, 20)

def EXCHANGE_DELETE_OK() -> MethodID:
    return MethodID(40, 21)

def EXCHANGE_BIND() -> MethodID:
    return MethodID(40, 30)

def EXCHANGE_BIND_OK() -> MethodID:
    return MethodID(40, 31)

def EXCHANGE_UNBIND() -> MethodID:
    return MethodID(40, 40)

def EXCHANGE_UNBIND_OK() -> MethodID:
    return MethodID(40, 51)

# Queue class (50)
def QUEUE_DECLARE() -> MethodID:
    return MethodID(50, 10)

def QUEUE_DECLARE_OK() -> MethodID:
    return MethodID(50, 11)

def QUEUE_BIND() -> MethodID:
    return MethodID(50, 20)

def QUEUE_BIND_OK() -> MethodID:
    return MethodID(50, 21)

def QUEUE_PURGE() -> MethodID:
    return MethodID(50, 30)

def QUEUE_PURGE_OK() -> MethodID:
    return MethodID(50, 31)

def QUEUE_DELETE() -> MethodID:
    return MethodID(50, 40)

def QUEUE_DELETE_OK() -> MethodID:
    return MethodID(50, 41)

def QUEUE_UNBIND() -> MethodID:
    return MethodID(50, 50)

def QUEUE_UNBIND_OK() -> MethodID:
    return MethodID(50, 51)

# Basic class (60)

# The basic class id; every content-bearing method on the wire (publish,
# deliver, get-ok) is class 60, and its content HEADER frame MUST carry the
# same class-id (amqp0-9-1.xml §2.3.5.2).
def BASIC_CLASS_ID() -> UInt16:
    return 60

def BASIC_QOS() -> MethodID:
    return MethodID(60, 10)

def BASIC_QOS_OK() -> MethodID:
    return MethodID(60, 11)

def BASIC_PUBLISH() -> MethodID:
    return MethodID(60, 40)

def BASIC_RETURN() -> MethodID:
    return MethodID(60, 50)

def BASIC_DELIVER() -> MethodID:
    return MethodID(60, 60)

def BASIC_GET() -> MethodID:
    return MethodID(60, 70)

def BASIC_GET_OK() -> MethodID:
    return MethodID(60, 71)

def BASIC_GET_EMPTY() -> MethodID:
    return MethodID(60, 72)

def BASIC_ACK() -> MethodID:
    return MethodID(60, 80)

def BASIC_REJECT() -> MethodID:
    return MethodID(60, 90)

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

# Confirm class (85) — RabbitMQ extension, not present in amqp0-9-1.xml.
def CONFIRM_SELECT() -> MethodID:
    return MethodID(85, 10)

def CONFIRM_SELECT_OK() -> MethodID:
    return MethodID(85, 11)

# Tx class (90)
def TX_SELECT() -> MethodID:
    return MethodID(90, 10)

def TX_SELECT_OK() -> MethodID:
    return MethodID(90, 11)

def TX_COMMIT() -> MethodID:
    return MethodID(90, 20)

def TX_COMMIT_OK() -> MethodID:
    return MethodID(90, 21)

def TX_ROLLBACK() -> MethodID:
    return MethodID(90, 30)

def TX_ROLLBACK_OK() -> MethodID:
    return MethodID(90, 31)

# Reply codes

# Reply-code 312 NO_ROUTE: basic.return (60,50) reply-code for a mandatory=1
# publish routed to NO queue (amqp0-9-1.xml response-code table).
def REPLY_NO_ROUTE() -> UInt16:
    return 312

# Reply-code 404 NOT_FOUND: channel-level error close for a missing queue /
# exchange / binding under the normative error table.
def REPLY_NOT_FOUND() -> UInt16:
    return 404

# Reply-code 406 PRECONDITION_FAILED: refused queue.delete if_empty /
# if_unused and exchange.delete if_unused.
def REPLY_PRECONDITION_FAILED() -> UInt16:
    return 406

def REPLY_SUCCESS() -> UInt16:
    return 200

def REPLY_PROTOCOL_ERROR() -> UInt16:
    return 502

def REPLY_NOT_IMPLEMENTED() -> UInt16:
    return 540

def REPLY_RESOURCE_ERROR() -> UInt16:
    return 541
