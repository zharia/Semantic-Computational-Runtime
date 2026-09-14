#!/usr/bin/env bash
# HyrxMQ live Kubernetes lifecycle validation (M7.2) via kind.
#
# Builds (if absent) the image, stands up an ephemeral kind cluster, deploys
# k8s/ manifests, and exercises the pod lifecycle: rollout, readiness,
# liveness probes, resource limits, and graceful termination.
#
# Emits exactly one final line: KIND_E2E=PASS or KIND_E2E=FAIL.
# The cluster is always torn down (trap on EXIT) unless KEEP_CLUSTER=1.
#
# Usage: scripts/kind_e2e.sh
set -uo pipefail

CLUSTER="${CLUSTER:-hyrxmq-e2e}"
CTX="kind-${CLUSTER}"
IMAGE="${IMAGE:-hyrxmq:latest}"
NS=hyrxmq
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRACE="${GRACE:-45}"   # seconds to wait for graceful pod deletion

FAILURES=0
pass() { echo "  [PASS] $*"; }
fail() { echo "  [FAIL] $*"; FAILURES=$((FAILURES + 1)); }
info() { echo "  [info] $*"; }

cleanup() {
  local rc=$?
  if [ "${KEEP_CLUSTER:-0}" = "1" ]; then
    echo "== KEEP_CLUSTER=1: leaving kind cluster '${CLUSTER}' in place =="
  else
    echo "== teardown: deleting kind cluster '${CLUSTER}' =="
    kind delete cluster --name "${CLUSTER}" >/dev/null 2>&1 || true
  fi
  exit $rc
}
trap cleanup EXIT

echo "== HyrxMQ kind E2E (M7.2) =="
echo "cluster=${CLUSTER} ctx=${CTX} image=${IMAGE}"

# ── 1. image ────────────────────────────────────────────────────────────────
echo "== 1. image =="
if docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  pass "image ${IMAGE} present ($(docker image inspect "${IMAGE}" --format '{{.Id}}' | cut -c1-19))"
else
  info "image ${IMAGE} absent; building (may take minutes)..."
  if (cd "${ROOT}" && docker build -t "${IMAGE}" .); then
    pass "image ${IMAGE} built"
  else
    fail "docker build failed"
    echo "KIND_E2E=FAIL"
    exit 1
  fi
fi

# ── 2. cluster ──────────────────────────────────────────────────────────────
echo "== 2. kind cluster =="
if kind get clusters 2>/dev/null | grep -qx "${CLUSTER}"; then
  info "cluster ${CLUSTER} already exists; deleting for a clean run"
  kind delete cluster --name "${CLUSTER}" >/dev/null 2>&1 || true
fi
if kind create cluster --name "${CLUSTER}" --wait 120s; then
  pass "cluster ${CLUSTER} created"
else
  fail "kind create cluster failed"
  echo "KIND_E2E=FAIL"
  exit 1
fi

# ── 3. load image ───────────────────────────────────────────────────────────
echo "== 3. load image into kind =="
if kind load docker-image "${IMAGE}" --name "${CLUSTER}"; then
  pass "image loaded into kind"
else
  fail "kind load docker-image failed"
fi

# ── 4. apply manifests ──────────────────────────────────────────────────────
echo "== 4. apply manifests =="
APPLY_OK=1
for f in namespace configmap secret deployment service; do
  if kubectl --context "${CTX}" apply -f "${ROOT}/k8s/${f}.yaml" >/dev/null 2>&1; then
    info "applied k8s/${f}.yaml"
  else
    fail "apply k8s/${f}.yaml"; APPLY_OK=0
  fi
done
[ "${APPLY_OK}" = "1" ] && pass "all manifests applied"

# ── 5. rollout ──────────────────────────────────────────────────────────────
echo "== 5. rollout =="
if kubectl --context "${CTX}" -n "${NS}" rollout status deployment/hyrxmq --timeout=120s; then
  pass "rollout complete"
else
  fail "rollout did not complete"
fi

POD="$(kubectl --context "${CTX}" -n "${NS}" get pod \
  -l app.kubernetes.io/name=hyrxmq -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
if [ -z "${POD}" ]; then
  fail "no pod found"
  echo "KIND_E2E=FAIL"
  exit 1
fi
info "pod=${POD}"

# ── 6. pod Running + Ready ──────────────────────────────────────────────────
echo "== 6. pod phase + readiness =="
PHASE="$(kubectl --context "${CTX}" -n "${NS}" get pod "${POD}" -o jsonpath='{.status.phase}')"
[ "${PHASE}" = "Running" ] && pass "phase=Running" || fail "phase=${PHASE}"
READY="$(kubectl --context "${CTX}" -n "${NS}" get pod "${POD}" \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
[ "${READY}" = "True" ] && pass "Ready=True" || fail "Ready=${READY}"

# ── 7. liveness + readiness endpoints (in-pod) ──────────────────────────────
echo "== 7. probe endpoints =="
H="$(kubectl --context "${CTX}" -n "${NS}" exec "${POD}" -- \
  curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/health 2>/dev/null)"
[ "${H}" = "200" ] && pass "/health -> 200" || fail "/health -> ${H}"
R="$(kubectl --context "${CTX}" -n "${NS}" exec "${POD}" -- \
  curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/ready 2>/dev/null)"
[ "${R}" = "200" ] && pass "/ready -> 200" || fail "/ready -> ${R}"

# ── 8. resource limits ──────────────────────────────────────────────────────
echo "== 8. resource limits =="
RES="$(kubectl --context "${CTX}" -n "${NS}" get pod "${POD}" \
  -o jsonpath='{.spec.containers[0].resources}')"
echo "  resources=${RES}"
if echo "${RES}" | grep -q '"cpu":"2"' && echo "${RES}" | grep -q '"memory":"512Mi"' \
   && echo "${RES}" | grep -q '"cpu":"500m"' && echo "${RES}" | grep -q '"memory":"256Mi"'; then
  pass "requests 500m/256Mi + limits 2/512Mi confirmed"
else
  fail "resource requests/limits unexpected"
fi

# ── 9. graceful termination ─────────────────────────────────────────────────
echo "== 9. graceful termination =="
kubectl --context "${CTX}" -n "${NS}" logs "${POD}" > /tmp/kind_e2e_logs_before.txt 2>&1 || true
info "log before delete:"; sed 's/^/    /' /tmp/kind_e2e_logs_before.txt
T0=$(date -u +%s)
kubectl --context "${CTX}" -n "${NS}" delete pod "${POD}" --wait=false >/dev/null 2>&1
# Poll to capture the terminal container state before the object disappears.
LAST_JSON=""
for _ in $(seq 1 $((GRACE * 4))); do
  J="$(kubectl --context "${CTX}" -n "${NS}" get pod "${POD}" -o json 2>/dev/null)"
  [ -n "${J}" ] && LAST_JSON="${J}"
  [ -z "${J}" ] && break
  sleep 0.25
done
T1=$(date -u +%s); ELAPSED=$((T1 - T0))
EXIT_CODE="$(printf '%s' "${LAST_JSON}" | python3 -c \
  'import sys,json;
try:
 d=json.load(sys.stdin); c=d["status"]["containerStatuses"][0]["state"].get("terminated");
 print(c["exitCode"] if c else "none")
except Exception: print("unknown")' 2>/dev/null)"
echo "  deletion elapsed=${ELAPSED}s exitCode=${EXIT_CODE:-unknown}"
# Capture the terminating container's logs (may be empty if already reaped).
kubectl --context "${CTX}" -n "${NS}" logs "${POD}" --previous > /tmp/kind_e2e_logs_after.txt 2>&1 || true
kubectl --context "${CTX}" -n "${NS}" logs "${POD}" > /tmp/kind_e2e_logs_after.txt 2>&1 || true

PRESTOP_FAIL="$(kubectl --context "${CTX}" -n "${NS}" get events --field-selector \
  reason=FailedPreStopHook -o jsonpath='{.items[*].reason}' 2>/dev/null)"
SHUTDOWN_LOG="$(grep -iE 'shut|drain|terminat|bye|stopping' /tmp/kind_e2e_logs_before.txt /tmp/kind_e2e_logs_after.txt 2>/dev/null || true)"

case "${EXIT_CODE}" in
  0|143) pass "graceful exit code=${EXIT_CODE} (SIGTERM honoured)" ;;
  137)   fail "exit code=137 (SIGKILL after grace period; SIGTERM not honoured)" ;;
  *)     fail "unexpected exit code=${EXIT_CODE:-unknown}" ;;
esac
[ "${ELAPSED}" -lt "${GRACE}" ] && pass "terminated in ${ELAPSED}s (< ${GRACE}s grace)" \
  || fail "termination exceeded grace (${ELAPSED}s)"
[ -z "${PRESTOP_FAIL}" ] && pass "no FailedPreStopHook event" \
  || fail "FailedPreStopHook event present"
[ -n "${SHUTDOWN_LOG}" ] && pass "clean-shutdown log line observed" \
  || fail "no clean-shutdown log line (process never ran shutdown path)"

# ── 10. result ──────────────────────────────────────────────────────────────
echo "== result =="
if [ "${FAILURES}" -eq 0 ]; then
  echo "KIND_E2E=PASS"
else
  echo "KIND_E2E=FAIL (${FAILURES} check(s) failed)"
fi
exit 0
