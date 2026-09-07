# Failure Semantics

Failure behavior is part of the public contract.

## Classes

### Client/network

- disconnect
- half-open connection
- malformed frame
- connection timeout
- transport reset

### Consumer

- consumer disconnect
- acknowledgement timeout where configured
- rejection/nack
- cancellation

### Publisher

- unroutable publish
- mandatory return
- confirm failure
- flow-control blocking

### Resource

- memory pressure
- queue limit
- connection limit
- channel limit
- disk full

### Process

- crash
- forced termination
- restart

### Storage

- write failure
- fsync failure
- corruption
- incomplete record

## Requirements

For every failure class specify:

- observable behavior
- state retained
- messages retained/lost
- redelivery behavior
- client-visible result
- recovery behavior

Never leave failure behavior implicit.
