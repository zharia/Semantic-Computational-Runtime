# M7: Kubernetes Composability

**Gate:** Part of Gate E
**Status:** PARTIAL — manifests and probes present and structurally validated;
StatefulSet absent and no live-cluster lifecycle run.
**Spec:** Section 45

## Sprint 7.1 — Kubernetes Manifests
**Dir:** `k8s/`
- [x] Deployment manifest (stateless broker mode) — `k8s/deployment.yaml`
- [ ] StatefulSet manifest (persistent storage mode) — **NOT DONE**: only
  Deployment exists; no StatefulSet / PVC template.
- [x] Service manifest (`k8s/service.yaml`)
- [x] ConfigMap template (`k8s/configmap.yaml`)
- [x] Secret template (credentials, TLS certs) — `k8s/secret.yaml`
- [x] Namespace manifest (`k8s/namespace.yaml`)

## Sprint 7.2 — Lifecycle Validation
- [x] Resource limits declared + validated in manifest
- [x] Graceful termination hooks present (`preStop` drain sleep + SIGTERM shim)
- [x] Readiness/liveness/startup probes declared
- [ ] Pod startup test — **NOT DONE**: no cluster available; manifest not applied.
- [ ] Readiness transition test — **NOT DONE**: no live-cluster run.
- [ ] Graceful termination test — **NOT DONE** on-cluster; process-level shim
  verified in M6.
- [ ] Persistent volume remount test — **NOT DONE**: no StatefulSet/PVC.

## Sprint 7.3 — Documentation
- [ ] `KUBERNETES.md` deployment guide — **NOT DONE**: no such file;
  `docs/DEPLOYMENT.md` documents packaging instead.
- [x] Health check configuration (probes in `deployment.yaml`)
- [x] Resource limit recommendations (requests/limits in `deployment.yaml`)

## Exit Criteria
- [x] K8s manifests present and structurally valid
- [x] Health probes declared
- [ ] Manifests deployable / validated on a live cluster
- [ ] StatefulSet mode