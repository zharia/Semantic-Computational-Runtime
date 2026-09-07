# Manifestation Engine — Identity and Addressing

## 1. Principle

Semantic identity and physical address are different kinds of identity.

## 2. Identity classes

The Engine SHOULD distinguish:

- semantic entity ID;
- graph/region ID;
- operation ID;
- execution ID;
- context ID;
- capability ID;
- provider ID;
- manifestation ID;
- physical resource ID;
- message ID;
- effect ID.

## 3. Semantic references

A semantic reference resolves within semantic scope. It MUST NOT be required to contain a physical locator.

## 4. Physical addresses

Physical addresses may include:

- pointer;
- file path;
- database key;
- socket address;
- queue name;
- GPU allocation;
- process ID.

They are manifestation metadata.

## 5. Indirection

The Engine's indirection layer permits provider replacement, migration, caching, replication and failover.

## 6. Stability

Semantic identity SHOULD remain stable across physical migration. Physical identity SHOULD be allowed to change without semantic graph mutation.

## 7. Equality

Semantic equality MUST NOT be inferred from physical address equality, and physical co-location MUST NOT imply semantic identity.
