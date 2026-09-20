# SCR Runtime Transport — 101 Specification

## Purpose
Define provider-independent IPC semantics for SCR process communication.

## Reference provider
Hyrx over AF_UNIX on Linux. The semantic contract does not depend on Hyrx or Unix sockets.

## Logical planes
Control, semantic state, and resource metadata. They may share a connection but must have explicit ordering, reliability and backpressure semantics.

## Session lifecycle
`CONNECT -> HELLO -> NEGOTIATE -> AUTHENTICATE -> SUBSCRIBE -> SNAPSHOT -> STREAM -> GOODBYE`

## Message envelope (conceptual)
- message ID and type;
- protocol/schema version;
- source/destination session/process SIDs;
- world version, generation, tick, time, determinism epoch where applicable;
- semantic SID and content ID where applicable;
- spatial context;
- priority/reliability class;
- encoding and payload/resource reference.

This is a field inventory, not yet a wire schema. Required/optional fields, canonical encoding, limits and compatibility rules must be specified before implementation.

## Required message families
Session: HELLO, CAPABILITIES, NEGOTIATE, AUTHENTICATE, GOODBYE.  
Subscription: SUBSCRIBE, UNSUBSCRIBE, SUBSCRIPTION_UPDATED.  
State: SNAPSHOT_REQUEST, SNAPSHOT, STATE_COMMITTED, ENTITY_CREATED/UPDATED/REMOVED, FIELD_UPDATED, DOMAIN_UPDATED, RESYNC_REQUIRED.  
Resource: RESOURCE_OFFER, RESOURCE_ACCEPT, RESOURCE_RELEASE, RESOURCE_INVALIDATED.  
Error: ACK, ERROR.

## Ordering and recovery
Define ordering scope (session, subscription, World, or stream). Receivers must detect duplicate, stale and missing generations. Snapshot establishment must provide an unambiguous delta continuation point.

## Resource transfer
Use out-of-band shared-memory or OS/GPU handles for large payloads where supported. File descriptors are transferred using platform facilities and validated; their numeric values are not portable identifiers.

## Security and robustness
Authenticate local peer credentials; authorize semantic operations; validate schemas, lengths, resource descriptors and capability claims. Define socket permissions, stale endpoint cleanup, quotas and denial-of-service limits.

## Required tests
Handshake/version mismatch, ordering/gaps, snapshot cut, reconnect, malformed frames, resource lifetime, backpressure, authorization and multiple clients.
