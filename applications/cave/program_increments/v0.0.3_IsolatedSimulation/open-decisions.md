# Open Decisions — Simulation/Presentation IPC

These decisions are intentionally not fabricated in the architecture draft. Resolve and record them before freezing a wire schema.

1. **Canonical serialization:** existing SCR/Hyrx encoding versus a dedicated schema; versioning and canonical form.
2. **Physical channels:** one multiplexed AF_UNIX connection or separate control/data connections.
3. **Hyrx contract:** which Hyrx features are reused directly and which SCR semantics sit above them.
4. **Generation model:** global World generation versus per-domain generations; ordering and overflow.
5. **Snapshot cut:** exact synchronization algorithm between snapshot and delta stream.
6. **Time representation:** unit, precision, fixed/variable timestep representation and rounding.
7. **Commands:** whether presentation can issue simulation commands, and the authorization/validation model.
8. **Spatial semantics:** subscription boundary inclusion, hierarchy inheritance, moving-observer updates and hysteresis.
9. **Resource lifetime:** leases, acknowledgements, process-crash cleanup and stale-resource policy.
10. **GPU interop:** supported CUDA/Vulkan/driver/device combinations, synchronization and fallback criteria.
11. **Compression:** allowed codecs, negotiation and limits.
12. **Security:** socket path, permissions, peer credentials, quotas and trust model.
13. **Determinism:** whether the requirement is deterministic projection, deterministic replay, or bitwise solver reproducibility.
14. **Fluid freshness:** which representations may be coalesced and which temporal samples must be retained.
15. **Naming and placement:** align directory names with the repository's current canonical library taxonomy before merging.
