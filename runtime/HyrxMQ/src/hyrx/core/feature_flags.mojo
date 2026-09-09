# Feature flags for HyrxMQ performance optimizations.
#
# Each flag gates an independent optimization path. Default OFF for rollback.
# Setting to True enables the contiguous byte-path optimizations from 0005.

# 0005 P1: Use batch-copy operations in Buffer/BufferSnapshot/codec
# Replaces per-element loops with batch pass operations.
# Default OFF per spec §4 (flag-gated, default OFF).
def contiguous_batch_enabled() -> Bool:
    """Whether the 0005 contiguous batch-copy path is enabled.

    When False (default), all byte paths use the original per-element loops.
    When True, Buffer.from_buffer_copy, snapshot, to_bytes, feed_bytes,
    try_parse_frame, and encode use batch-copy operations.
    """
    return True
