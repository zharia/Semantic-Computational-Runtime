# Message Semantics

## 1. Message as semantic structure

A message is a semantic transmission of information between field participants. It is not merely a byte buffer.

A message may contain:

- identity;
- sender and intended recipient(s);
- payload;
- schema/type;
- correlation identity;
- causality metadata;
- temporal metadata;
- delivery requirements;
- ordering requirements;
- expiry;
- acknowledgement state.

## 2. Delivery semantics

The semantic contract MUST distinguish at-least-once, at-most-once and effectively-once processing where those properties matter.

## 3. Ordering

Ordering is meaningful only relative to a declared scope: producer, stream, key, relationship, partition or global sequence.

## 4. Causality

Message relationships MAY encode causal dependencies. Transport ordering MUST NOT automatically be interpreted as semantic causality.

## 5. Payload representation

Payload encoding is a representation. Schema compatibility and semantic meaning remain independent of wire format.
