# Tests for Hyrx-native frame serialization/deserialization.

from std.collections import List
from hyrx.transport.framing import (
    FrameHeader, Frame,
    FRAME_TYPE_MESSAGE, FRAME_TYPE_ACK, FRAME_TYPE_REJECT,
    FRAME_TYPE_HEARTBEAT, FRAME_TYPE_FLOW_CONTROL
)

def test_frame_type_constants() raises:
    assert FRAME_TYPE_MESSAGE() == 0x01
    assert FRAME_TYPE_ACK() == 0x02
    assert FRAME_TYPE_REJECT() == 0x03
    assert FRAME_TYPE_HEARTBEAT() == 0x04
    assert FRAME_TYPE_FLOW_CONTROL() == 0x05
    print("  frame type constants: OK")

def test_header_roundtrip() raises:
    var header = FrameHeader(0x01, 100)
    assert header.frame_type == 0x01
    assert header.payload_length == 100

    var encoded = header.to_bytes()
    assert len(encoded) == 8

    # Verify big-endian encoding
    assert encoded[0] == 0x00  # type byte 0
    assert encoded[1] == 0x00  # type byte 1
    assert encoded[2] == 0x00  # type byte 2
    assert encoded[3] == 0x01  # type byte 3
    assert encoded[4] == 0x00  # length byte 0
    assert encoded[5] == 0x00  # length byte 1
    assert encoded[6] == 0x00  # length byte 2
    assert encoded[7] == 100   # length byte 3

    var decoded = FrameHeader.from_bytes(encoded^)
    assert decoded.frame_type == 0x01
    assert decoded.payload_length == 100
    print("  header roundtrip: OK")

def test_header_large_values() raises:
    var header = FrameHeader(0xFF, 0x00010000)  # type=255, length=65536
    var encoded = header.to_bytes()
    assert len(encoded) == 8

    # type: 0x00 0x00 0x00 0xFF
    assert encoded[3] == 0xFF
    # length: 0x00 0x01 0x00 0x00
    assert encoded[5] == 0x01
    assert encoded[6] == 0x00
    assert encoded[7] == 0x00

    var decoded = FrameHeader.from_bytes(encoded^)
    assert decoded.frame_type == 0xFF
    assert decoded.payload_length == 0x00010000
    print("  header large values: OK")

def test_header_too_short() raises:
    var bad = List[UInt8]()
    bad.append(0x01)
    bad.append(0x02)
    var threw = False
    try:
        _ = FrameHeader.from_bytes(bad^)
    except:
        threw = True
    assert threw
    print("  header too short: OK")

def test_frame_roundtrip() raises:
    var payload = List[UInt8]()
    payload.append(0xDE)
    payload.append(0xAD)
    payload.append(0xBE)
    payload.append(0xEF)

    var frame = Frame.from_raw(FRAME_TYPE_MESSAGE(), payload^)
    assert frame.header.frame_type == 0x01
    assert frame.header.payload_length == 4
    assert len(frame.payload) == 4

    var encoded = frame.to_bytes()
    assert len(encoded) == 12  # 8 header + 4 payload

    var decoded = Frame.from_bytes(encoded^)
    assert decoded.header.frame_type == 0x01
    assert decoded.header.payload_length == 4
    assert len(decoded.payload) == 4
    assert decoded.payload[0] == 0xDE
    assert decoded.payload[1] == 0xAD
    assert decoded.payload[2] == 0xBE
    assert decoded.payload[3] == 0xEF
    print("  frame roundtrip: OK")

def test_frame_empty_payload() raises:
    var frame = Frame.from_raw(FRAME_TYPE_HEARTBEAT(), List[UInt8]())
    assert frame.header.frame_type == 0x04
    assert frame.header.payload_length == 0

    var encoded = frame.to_bytes()
    assert len(encoded) == 8

    var decoded = Frame.from_bytes(encoded^)
    assert decoded.header.frame_type == 0x04
    assert decoded.header.payload_length == 0
    assert len(decoded.payload) == 0
    print("  frame empty payload: OK")

def test_frame_types_roundtrip() raises:
    # ACK frame
    var ack_payload = List[UInt8]()
    ack_payload.append(0x00)
    ack_payload.append(0x01)
    var ack = Frame.from_raw(FRAME_TYPE_ACK(), ack_payload^)
    var ack_encoded = ack.to_bytes()
    var ack_decoded = Frame.from_bytes(ack_encoded^)
    assert ack_decoded.header.frame_type == 0x02
    assert len(ack_decoded.payload) == 2

    # REJECT frame
    var rej_payload = List[UInt8]()
    rej_payload.append(0x00)
    rej_payload.append(0x01)
    var rej = Frame.from_raw(FRAME_TYPE_REJECT(), rej_payload^)
    var rej_encoded = rej.to_bytes()
    var rej_decoded = Frame.from_bytes(rej_encoded^)
    assert rej_decoded.header.frame_type == 0x03

    # FLOW_CONTROL frame
    var fc_payload = List[UInt8]()
    fc_payload.append(0x00)
    fc_payload.append(0x00)
    fc_payload.append(0x10)
    fc_payload.append(0x00)  # window=4096
    var fc = Frame.from_raw(FRAME_TYPE_FLOW_CONTROL(), fc_payload^)
    var fc_encoded = fc.to_bytes()
    var fc_decoded = Frame.from_bytes(fc_encoded^)
    assert fc_decoded.header.frame_type == 0x05
    assert fc_decoded.header.payload_length == 4
    print("  all frame types roundtrip: OK")

def test_frame_truncated_payload() raises:
    # Manually build truncated data
    var data = List[UInt8]()
    # Header says 10 bytes payload
    data.append(0x00)  # type byte 0
    data.append(0x00)  # type byte 1
    data.append(0x00)  # type byte 2
    data.append(0x01)  # type = MESSAGE
    data.append(0x00)  # len byte 0
    data.append(0x00)  # len byte 1
    data.append(0x00)  # len byte 2
    data.append(0x0A)  # payload_length = 10
    # Only 3 bytes of payload (should be 10)
    data.append(0xAA)
    data.append(0xBB)
    data.append(0xCC)

    var threw = False
    try:
        _ = Frame.from_bytes(data^)
    except:
        threw = True
    assert threw
    print("  frame truncated payload: OK")

def test_frame_too_short() raises:
    var data = List[UInt8]()
    data.append(0x01)
    data.append(0x02)
    data.append(0x03)

    var threw = False
    try:
        _ = Frame.from_bytes(data^)
    except:
        threw = True
    assert threw
    print("  frame too short: OK")

def test_large_payload() raises:
    var payload = List[UInt8](capacity=1000)
    for i in range(1000):
        payload.append(UInt8(i & 0xFF))

    var frame = Frame.from_raw(FRAME_TYPE_MESSAGE(), payload^)
    assert frame.header.payload_length == 1000

    var encoded = frame.to_bytes()
    assert len(encoded) == 1008  # 8 + 1000

    var decoded = Frame.from_bytes(encoded^)
    assert decoded.header.payload_length == 1000
    assert len(decoded.payload) == 1000
    assert decoded.payload[0] == 0x00
    assert decoded.payload[999] == (999 & 0xFF)
    print("  large payload: OK")

def main() raises:
    print("FRAMING_TEST")
    test_frame_type_constants()
    test_header_roundtrip()
    test_header_large_values()
    test_header_too_short()
    test_frame_roundtrip()
    test_frame_empty_payload()
    test_frame_types_roundtrip()
    test_frame_truncated_payload()
    test_frame_too_short()
    test_large_payload()
    print("FRAMING_TEST=PASS")
