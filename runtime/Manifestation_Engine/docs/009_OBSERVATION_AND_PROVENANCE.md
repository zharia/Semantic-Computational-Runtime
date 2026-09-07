# Manifestation Engine — Observation and Provenance

## 1. Observation

Observation records what execution produced or what happened during manifestation.

Observation is not identical to internal telemetry.

## 2. Observation classes

- semantic result;
- semantic state transition;
- execution outcome;
- provider decision;
- resource telemetry;
- physical event;
- provenance;
- diagnostic event;
- security event.

## 3. Provenance chain

The Engine SHOULD preserve a chain such as:

`semantic identity → operation → context → capability → provider → manifestation → resource → observation`

## 4. Reproducibility

Reproducible execution SHOULD record:

- semantic specification/version;
- input identities and versions;
- context identity;
- provider and capability versions;
- random seed where applicable;
- representation choice;
- relevant precision;
- execution environment facts.

## 5. Telemetry

Telemetry may include latency, throughput, memory, bandwidth, queue depth, device utilization and failures.

Telemetry MUST NOT be mistaken for semantic state unless explicitly promoted into semantic observation.

## 6. Privacy and security

Observability is subject to authority policy. Detailed physical telemetry may reveal sensitive information and MUST be scoped accordingly.

## 7. Audit

Security-relevant manifestation decisions SHOULD be auditable, including who/what requested a capability, what policy was applied, which provider was selected and what physical resources were touched.
