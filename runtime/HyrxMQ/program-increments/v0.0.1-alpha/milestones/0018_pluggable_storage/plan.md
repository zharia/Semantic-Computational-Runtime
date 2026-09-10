# 0018 — pluggable storage; fs-free by default; injectable fs ops

**Status:** complete — suite 46/0 (storage_test in-suite); conformance 31 PASS/1 DIFF(event-loop row)/1 PARTIAL(heartbeat timers)
**Mode:** coordinator; T1 delegated (general); verify = coordinator

## Requirement (user-stated, binding)

1. Storage is OPTIONAL and CONFIGURABLE.
2. The service MUST run without touching the file system (default = in-memory
   lifecycle, exactly today's behavior).
3. When file-system activity is REQUIRED, it happens ONLY through supplied
   functions so the "filesystem" can be redirected (embedded environments,
   VFS, container mounts, test fakes).

## Design

- `src/hyrx/core/storage.mojo` (NEW): 
  - `trait FileSystemOps` — the injectable fs seam: `read_all(path)`,
    `open_append(path)`, `append(handle_view)`, `sync`, `truncate(path)`,
    `exists(path)`, `size(path)` (exact shapes negotiated in the delegate
    receipt; the trait owns BOTH path-based and handle-based calls; every fs
    touch anywhere below routes through it).
  - `MemoryStorage` — pure-host, built-AMQP-compatible storage (durable
    queues + designated persistent messages kept in RAM; survive nothing
    after process death by definition), same journal FORMAT as file so
    recovery semantics are testable without any device.
  - `FileStorage` — thin injectable WAL: journal pages appended through
    the supplied `FileSystemOps`; framed records (u32 len + type + payload
    + checksum-ish footer? per plan: crc32); recovery = replay.
- `HyrxMQConfig`: `storage_mode enum { disabled (default), memory, file }`,
  `storage_path: String` (empty disallowed in file mode; no path touched in
  disabled/memory). `main_listen` bootstraps accordingly: disabled/memory =
  byte-identical to today (NO journal writes at all); file = WAL enabled.
- Write path (only in `file` mode; memory mode writes to its RAM journal):
  durable queue declare + exchange declare + binding + a published message
  on a durable queue with delivery_mode=2 (and the ack-removal journal:
  messages removed from the tail once acked/consumed exist only
  transiently), plus queue-delete/purge/ttl expiry / x-args changes.
- Recovery: boot in `file` mode replays the journal order (declares,
  messages, acks/redeliveries, deletes). Byte-identical semantics with the
  in-memory tier; reloaded unacked-at-crash messages redelivered with the
  mechanism of `redelivered=1`.
- All other subsystems never touch the fs directly (the abstract-UDS
  precedent: name in kernel memory; NO unlink calls from the storage path).

## Verification

- NEW `tests/phase8/storage_test.mojo`: durable-declare → inject a message
  (delivery_mode=2) → recover via a NEW Engine in a second process-context =
  the same fixture semantics; BOTH MemoryStorage + FileStorage (with a test
  fake-op redirection) drive the SAME recovery assertions. The fake injects
  fs ops through a page list — **zero actual filesystem traffic** in suite.
- A `file`-mode real-run smoke (tmp-bindable via injected ops) recorded as
  manual evidence (not in the automated suite).
- Suite 45/0.. stays green in the DEFAULT tier (no fs + no storage flag:
  the default code path must be untouched by byte).
- Conformance: `durability` rows move from PARTIAL in 0017-T3 to PASS:
  the `declare-ok durable=True` round-trip + RESTART re-delivery test is
  the row, and the conformance matrix records the 0018-bound interpretation.

## Result (verified)

- build 0 errors; suite 46/0 (phase8 storage_test auto-discovered: the SAME
  assertions over MemoryStorage + FileStorage[FakeOps]; the fake ops IS the
  redirect evidence - no real device traffic in the automated tier).
- conformance rows moved from 0017-T4's 26: now 31 PASS / 1 DIFF
  (exclusive.second_conn_declare = the 0015 event loop's own feature row,
  still gated) / 1 PARTIAL (heartbeat.cyclic_and_miss = no timer subsystem).
- The 0017 pika capability-table gap FIXED (connection.start now carries
  server-properties + capabilities) -> confirm.ack / tx.commit /
  tx.rollback / auth.reject all PASS live.

## Explicitly NOT claimed

- Async fsync durability point: durability is the WRITE-BACK-safe append
  (closing the open append) per op; a strictly POSIX boilerplate fsync is
  left to the SUPPLIED function (the caller's fs seam owns its guarantees).
- RabbitMQ 3.x/4 disk-count semantics (dirt through `$use Mnesia`) — out of
  scope; the matrix records the difference.
- The 0017 leftover capability table (pika confirm/tx extension surface) is
  a SEPARATE small dispatch (see 0020 pom prior P1) — tracked remaining.
