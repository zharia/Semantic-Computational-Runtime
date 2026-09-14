# M10: Audit & Release

**Gate:** H (Release Reproducibility)
**Status:** COMPLETE.
**Spec:** Sections 50-62

## Sprint 10.1 — Invariant Audit
**Report:** `reports/INVARIANT_AUDIT.md` (18 invariants)
- [x] Routing authority invariant (R1)
- [x] Ownership invariant (R2, R15)
- [x] Delivery state invariant (R13, R14)
- [x] Resource bounds invariant (R6, R7, R9, R12, R17, R18)
- [x] Persistence invariant (R5)
- [x] Security invariant (R10, R16)
- Result: 16/18 fully enforced + tested; R16 (ACL) and R18 (resource limits)
  code-verified only.

## Sprint 10.2 — Documentation Truth Audit
**Report:** `reports/DOC_TRUTH_AUDIT.md`, `reports/SECURITY_AUDIT.md`
- [x] All claims verified against implementation (4 false claims corrected)
- [x] All known limitations documented
- [x] All unsupported claims removed

## Sprint 10.3 — Release Engineering
- [x] Clean checkout / clean build test (`rm -rf build && pixi run hyrxmq-listen`)
- [x] Reproducible build (`build/hyrxmq-listen`, ~1 MB)
- [x] Complete test suite pass (68/69; 1 expected self-test)
- [x] Release artifact (`build/hyrxmq-listen`)
- [x] Release notes (`RELEASE_NOTES.md`)
- [x] Changelog (`CHANGELOG.md`)

## Exit Criteria
- [x] Gate H pass → production-ready artifact
- See `reports/RELEASE_CHECKLIST.md` for commands, results and known gaps.