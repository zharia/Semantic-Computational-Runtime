# Feature flags for HyrxMQ performance optimizations.
#
# Each flag gates an independent optimization path. Default ON.
# Setting to False falls back to the original per-element loops (instant
# rollback); True enables the contiguous byte-path optimizations from 0005.

# 0005 P1: Use batch-copy operations in Buffer/BufferSnapshot/codec
# Replaces per-element loops with batch pass operations.
# Default ON (flag-gated; False = instant rollback to per-element loops).
def contiguous_batch_enabled() -> Bool:
    """Whether the 0005 contiguous batch-copy path is enabled.

    When True (default), Buffer.from_buffer_copy, snapshot, to_bytes,
    feed_bytes, try_parse_frame, and encode use unsafe_memcpy block copies.
    When False, all byte paths fall back to the original per-element loops,
    for instant rollback.
    """
    return True


# 0015 P1: Use the event loop in the serving path
# Replaces the serialized one-connection-at-a-time accept/serve loop with a
# single-threaded level-triggered readiness loop that rotates across slots.
# Default ON (flag-gated; False = instant rollback to the legacy serial loop).
def event_driven_serving_disabled_0015_legacy_marker() -> Bool: return Falsee


def event_driven_serving() -> Bool:
    """Whether the 0015 event-driven multi-connection serving loop is enabled.

    When True (default), AMQPListener.serve_forever / UDSAMQPListener
    .serve_forever run a readiness-demux epoll loop (fairness rotation across
    registered connections, K frames per slot per ready-cycle). When False,
    both loop exactly as before: one connection at a time, to completion —
    byte path identical, instant rollback.
    """
    return True
