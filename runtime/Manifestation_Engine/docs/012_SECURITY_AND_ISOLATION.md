# Manifestation Engine — Security and Isolation

## 1. Security boundary

The Manifestation Engine is a privileged boundary because it translates semantic requests into physical effects.

Semantic identity MUST NOT be treated as authorization.

## 2. Capability security

Physical access MUST be mediated by explicit capabilities and policy.

Capabilities SHOULD be:

- scoped;
- least-privilege;
- revocable;
- auditable;
- bound to context;
- time-limited where appropriate.

## 3. Provider isolation

Providers MUST execute with only the physical authority required for their declared capabilities.

Where practical, providers SHOULD be isolated by process, sandbox, container, hardware protection or equivalent mechanisms.

## 4. Graph isolation

An executable graph MUST NOT directly access provider handles, file descriptors, sockets, pointers, database connections or OS APIs unless those are intentionally surfaced through a semantic capability and controlled adapter.

## 5. Data isolation

Data manifestations MUST enforce access policy independently of graph identity.

## 6. Cross-tenant isolation

If the Engine supports multiple independent semantic execution principals, resource, identity, data and observation isolation MUST be enforced at the manifestation boundary.

## 7. Resource exhaustion

The Engine MUST defend against semantic requests that consume unbounded physical resources. Admission control and quotas are execution concerns, not semantic rewrites.

## 8. Supply chain

Provider identity and provenance SHOULD be recorded so execution can be audited against approved implementations.

## 9. Secrets

Secrets MUST NOT be embedded as semantic graph literals unless the semantic contract explicitly requires secret material. Physical credentials belong in controlled provider/context mechanisms.
