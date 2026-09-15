# Sprint 02: Zero-Copy Execution Path Verification

**Parent Milestone:** [Milestone 007: PI-CAVE-001G Zero-Copy DMA-BUF](../spec.md)  
**Derived from:** `spec.md` (Section 20)  
**Governing Documents:** [`docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md`](file:///home/kobus/Projects/Semantic-Computational-Runtime/docs/119_SEMANTIC_REPRESENTATION_AND_INTERCHANGE_MODEL.md)  
**Status:** Planned  

---

## 1. Mission

Instrument and verify the zero-copy execution path, proving with automated profiling data that client graphics buffers traverse directly to compositor GPU textures with zero host CPU memory copying in the steady state.

---

## 2. Technical Requirements & Verification Method

### 2.1 The Zero-Copy Invariant
$$\text{CPU\_Memcpy\_Bytes}(\text{Frame}) = 0$$
During steady-state rendering of an active Wayland application, pixel data must remain exclusively within VRAM / unified memory:
```text
Client GPU Drawing ──[DMA-BUF FD]──> Kernel DRM ──[EGLImage]──> Compositor GL Texture
                                   │
                                   └── X (No CPU read/write)
```

### 2.2 Profiling Instrumentation
* **Kernel Probe:** Attach `perf` / `ftrace` probes to `memcpy` and `copy_user_generic_string` in the compositor process.
* **Page Fault Counter:** Monitor minor page faults (`getrusage(RUSAGE_SELF)`) per frame.
* **GPU Memory Bus Monitor:** Verify that bandwidth matches direct texture sampling rates without CPU memory bus saturation.

---

## 3. Verification & Testing Tasks

1. **Memcpy Counter Assertion:** Render 1000 consecutive frames of a 4K Wayland video playback client; assert that total CPU pixel memcpy calls equal 0.
2. **Fallback Detection:** Verify that if an unsupported client format is provided, a graceful error is raised rather than falling back to an uninstrumented software copy path.
3. **Performance Report:** Output benchmark results in `reports/cave_zerocopy_verification_report.md`.
