# Milestone: Web Management Plane — Tier 3 (Next)

**Status:** PLANNED  
**Priority:** HIGH  
**Blocked by:** Thread model (receipt 0023)

---

## Objective

Wire live broker internals through the web management plane. The Tier 1+2
foundation is in place (BrokerStatus fields, listing accessors, `/queues` +
`/exchanges` endpoints). This milestone closes the gap between placeholder
data and live broker introspection.

---

## Blocked Items (need thread model)

These require cross-loop reads from the listener's serving thread into the
broker's state. The single-loop model (receipt 0023) prevents this today.

### 1. Live Queue Listing

**Current:** `/queues` returns empty array + "requires broker IPC" note.  
**Target:** `/queues` returns real queue names, depth, consumers, config.

Implementation:
- `AMQPService` exposes `list_queue_names()` → `Router.list_queue_names()`  
- Wire through `AMQPConnServing` → listener → HTTP admin handler
- Per-queue: `depth()`, `consumer_count()`, `durable()`, config fields

### 2. Live Exchange Listing

**Current:** `/exchanges` returns empty array + "requires broker IPC" note.  
**Target:** `/exchanges` returns real exchange names, type, binding count.

Implementation:
- `AMQPService` exposes `list_exchange_names()` → `Router.list_exchange_names()`
- Per-exchange: `exchange_type()`, `binding_count()`, `exchange_binding_count()`

### 3. Per-Connection Introspection

**Current:** `active_connections` / `refused_connections` are counters only.  
**Target:** `/connections` returns per-connection detail.

Implementation:
- `AMQPConnServing` exposes connection slot metadata:
  - Remote address (from accepted socket)
  - AMQP state (CLOSED/START_SENT/TUNE_SENT/OPEN)
  - Channel count, negotiated heartbeat, frame_max
  - Client identity (from connection.open, when available)

### 4. Per-Channel State

**Current:** No visibility.  
**Target:** `/connections/{id}/channels` returns per-channel detail.

Implementation:
- `AMQPService._confirms` → publisher-confirm mode per channel
- `AMQPService._tx` → transaction staging per channel
- `AMQPService._closed_channels` → closed channel numbers

### 5. Consumer Detail

**Current:** Only aggregate `active_consumers` count.  
**Target:** `/consumers` returns per-consumer detail.

Implementation:
- `Router._consumers` → `Consumer.queue_name()`, `prefetch`, `active_deliveries`
- Wire through engine → adapter → service → HTTP

---

## Non-Blocked Items (can proceed now)

### 6. Config Exposure

Forward read-only config values to `BrokerStatus`:
- `max_connections` (operational)
- `heartbeat_secs` (operational)
- `frame_max` (already accessible via `frame_max()`)
- `storage_mode` (mode string only, not path)

Implementation: Add fields to `BrokerStatus`, populate in `broker.status()`.

### 7. Journal Mode

Expose `Router.journal_mode()` through status:
- 0 = disabled (default)
- 1 = memory WAL
- 2 = file WAL

Implementation: Add `journal_mode: Int` to `BrokerStatus`.

### 8. Prom Dashboard (Prometheus → Grafana)

The `/metrics` endpoint already outputs Prometheus text format via
`BrokerStatus.to_prometheus()`. Add:
- Wire `/metrics` route in `hyrxmq_web.mojo`
- Document Grafana dashboard import JSON
- Alert rules for: connections > threshold, rejected > 0, pool exhaustion

---

## Architecture Constraint

All Tier 3 items that touch live broker state require one of:

1. **Thread model** (receipt 0023): Listener serving thread shares state
   with admin HTTP thread via atomic snapshots or lock-free queues.
2. **IPC bridge**: Web server queries broker process via Unix socket or
   shared memory. Broker publishes status snapshots periodically.
3. **Embedded mode**: Web server embeds broker in-process (current design
   intent, but single-process only).

Option 3 is the current design — the web entry point embeds the broker.
The gap is that `hyrxmq_web.mojo` doesn't instantiate a broker yet (it
serves static files + hardcoded API). Wiring a live broker into the web
process is the immediate next step.

---

## Acceptance Criteria

- [ ] `/queues` returns live queue data when broker is embedded
- [ ] `/exchanges` returns live exchange data
- [ ] `/connections` returns per-connection detail
- [ ] `/consumers` returns per-consumer detail
- [ ] Config fields visible in status
- [ ] `/metrics` endpoint serves Prometheus format
- [ ] Dashboard tabs show live data (not placeholders)
- [ ] All existing tests continue to pass
- [ ] New integration tests for live-data endpoints
