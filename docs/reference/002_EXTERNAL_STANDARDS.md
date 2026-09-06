# External Standards and Technical References

## 1. Principle

External standards are sources of interoperable representations, protocols and established terminology. They do not override SCR semantic authority.

## 2. Primary reference classes

SCR may map to, among others:

- MLIR for IR construction, transformation and lowering;
- AMQP for messaging semantics and transport topology;
- Unicode for text and character semantics;
- IEEE 754 for floating-point representation and arithmetic behaviour where appropriate;
- ISO/IEC and W3C specifications for data, networking, identifiers and interoperability;
- GPU/accelerator APIs for physical execution;
- standard serialization formats where their contracts are suitable.

## 3. Mapping requirements

Every normative external dependency SHOULD identify:

1. the external concept;
2. the SCR concept it maps to;
3. whether the mapping is lossless;
4. which external assumptions are rejected;
5. version/compatibility constraints.

## 4. MLIR boundary

MLIR is an implementation and representation substrate for SCR semantic structures. SCR MUST NOT define semantic truth solely by reference to MLIR operation syntax, SSA identity, dialect structure or pass behaviour.

## 5. AMQP boundary

AMQP provides the messaging realisation model. SCR's message semantics remain authoritative over broker-specific configuration.
