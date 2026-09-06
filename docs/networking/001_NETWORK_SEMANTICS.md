# Network Semantics

## 1. Network as execution substrate

Networks provide communication resources between field participants. IP addresses, ports, sockets and routes are physical/network manifestations rather than semantic identity by default.

## 2. Endpoint identity

A semantic endpoint SHOULD have a stable identity independent of its current network location. Location may change through migration, failover or routing.

## 3. Communication contract

Network communication may constrain latency, ordering, reliability, confidentiality, integrity, bandwidth and availability. These become semantic requirements when declared by the application contract.

## 4. Distributed references

A semantic reference may be realised as a URI, service identity, broker route, handle or address. Resolution is a transformation from semantic identity to current physical location.

## 5. Failure

Timeout, partition, packet loss and endpoint failure are execution conditions. Their semantic consequences MUST be specified rather than inferred from a particular transport protocol.
