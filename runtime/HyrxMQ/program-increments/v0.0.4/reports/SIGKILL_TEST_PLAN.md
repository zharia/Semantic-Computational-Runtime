# SIGKILL Testing Plan — HyrxMQ WAL Persistence

## Overview

SIGKILL testing validates that the WAL-based persistence layer survives abrupt
process termination and recovers to a consistent state on restart.

## Why SIGKILL Cannot Be Sent From Within Mojo

Mojo programs cannot send signals to themselves via the standard library. A
SIGKILL is a kernel-level signal (`kill -9 <pid>`) that must be sent by an
external process. Within a Mojo test, we can:

1. **Simulate crash via process exit** — the in-process tests at
   `tests/phase10/sigkill_test.mojo` exercise the same recovery code path
   that runs after an actual SIGKILL restart (WAL replay, tail truncation,
   tombstone resolution).
2. **Document external orchestration** — the real SIGKILL test requires a
   wrapper (Docker, shell script, or CI pipeline) that:
   - Starts the broker
   - Publishes messages
   - Sends `kill -9 <pid>`
   - Restarts the broker
   - Verifies recovered message count

## Testing Methodology

### Phase 1: In-Process Crash Simulation

**File:** `tests/phase10/sigkill_test.mojo`

Tests the WAL recovery path without external signals:

| Test | Validates |
|------|-----------|
| `test_sync_before_crash` | All 100 messages survive a simulated crash + restart |
| `test_unsyncd_tail_truncation` | Torn final record detected and truncated, good records survive |
| `test_compaction_after_crash_recovery` | WAL compaction strips tombstones after crash recovery |
| `test_write_ahead_invariant` | MSG recovers without preceding DECLARE_QUEUE (write-ahead) |

These tests create a `MemoryStorage` journal, write records, then create a
**fresh** `MessageJournal.memory_from_bytes()` from the same pages — this is
the identical code path that runs after a real SIGKILL + broker restart.

### Phase 2: External Orchestration (Docker Kill)

#### Prerequisites

- Docker with hyrxmq image built (`pixi run docker-build`)
- `pika` Python client (AMQP 0-9-1)
- Shell script or CI pipeline

#### Test Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

IMAGE="hyrxmq"
CONTAINER="hyrxmq-sigkill-test"
PORT=5674
MSG_COUNT=1000

# 1. Start broker
docker run -d --name "$CONTAINER" -p "$PORT:5673" "$IMAGE"
sleep 2  # wait for startup

# 2. Publish N durable messages
python3 -c "
import pika
conn = pika.BlockingConnection(
    pika.ConnectionParameters('localhost', $PORT)
)
ch = conn.channel()
ch.queue_declare(queue='sigkill-q', durable=True)
for i in range($MSG_COUNT):
    ch.basic_publish(
        exchange='', routing_key='sigkill-q',
        body=f'msg-{i}'.encode(),
        properties=pika.BasicProperties(delivery_mode=2),
    )
conn.close()
print(f'Published {$MSG_COUNT} messages')
"

# 3. SIGKILL the broker (no graceful shutdown, no fsync)
docker kill --signal=SIGKILL "$CONTAINER"

# 4. Restart the broker
docker rm "$CONTAINER"
docker run -d --name "$CONTAINER" -p "$PORT:5673" "$IMAGE"
sleep 2

# 5. Verify recovery: consume all messages from the durable queue
python3 -c "
import pika
conn = pika.BlockingConnection(
    pika.ConnectionParameters('localhost', $PORT)
)
ch = conn.channel()
count = 0
for method, props, body in ch.consume('sigkill-q', inactivity_timeout=5):
    if method is None:
        break
    ch.basic_ack(method.delivery_tag)
    count += 1
conn.close()
print(f'Recovered {count} messages')
assert count == $MSG_COUNT, f'Expected {$MSG_COUNT}, got {count}'
"

# 6. Cleanup
docker rm -f "$CONTAINER"
```

#### Expected Behavior

| Scenario | Expected Recovery |
|----------|-------------------|
| `sync()` called before SIGKILL | All `$MSG_COUNT` messages recover |
| No `sync()` (last N bytes un-fsynced) | Torn tail truncated, remaining messages recover |
| SIGKILL during compaction | Pre-compaction WAL intact, compaction retried on next start |

### Phase 3: WAL Compaction Interaction

After SIGKILL recovery, calling `compact()` (milestone 0020) strips resolved
tombstones and dead MSG records from the WAL, reducing its size for the
next run. The compaction test at `tests/phase10/wal_compaction_test.mojo`
validates this path.

## Coverage Matrix

| Component | In-Process Test | External Test |
|-----------|----------------|---------------|
| WAL framing + CRC | `storage_test.mojo` | — |
| Tombstone resolution | `storage_test.mojo`, `sigkill_test.mojo` | Docker kill |
| Tail truncation | `sigkill_test.mojo` | Docker kill |
| Write-ahead invariant | `sigkill_test.mojo` | Docker kill |
| WAL compaction | `wal_compaction_test.mojo` | Post-restart compact |
| Multi-queue recovery | `persistence_crash_test.mojo` | Docker kill |

## References

- Milestone 0018: Pluggable storage (`src/hyrx/core/storage.mojo`)
- Milestone 0020: WAL compaction (`compact()` method)
- `tests/phase8/storage_test.mojo`: Journal framing and recovery
- `tests/phase10/persistence_crash_test.mojo`: Crash/corruption tests
- `tests/phase10/sigkill_test.mojo`: In-process crash simulation
- `tests/phase10/wal_compaction_test.mojo`: WAL compaction tests
