# HyrxMQ on Kubernetes

Operational guide for the manifests in [`k8s/`](k8s/). HyrxMQ is a
single-instance broker; the layout below deploys exactly one broker process
with AMQP and web listeners, configurable through a ConfigMap and credentials
through a Secret.

## 1. Manifest overview

| File | Kind | Purpose |
|------|------|---------|
| `k8s/namespace.yaml` | `Namespace` | Isolates all resources in the `hyrxmq` namespace. Labels it `app.kubernetes.io/part-of: messaging`. |
| `k8s/configmap.yaml` | `ConfigMap` | `hyrxmq-config` — non-secret broker settings injected as environment variables (`envFrom.configMapRef`). |
| `k8s/secret.yaml` | `Secret` | `hyrxmq-credentials` — `Opaque` secret holding `HYRXMQ_USERS` (`stringData`, injected via `envFrom.secretRef`). |
| `k8s/deployment.yaml` | `Deployment` | `hyrxmq` — one broker pod, `Recreate` strategy, health probes, resource limits, graceful-shutdown lifecycle. |
| `k8s/service.yaml` | `Service` | `hyrxmq` — `ClusterIP` exposing `amqp` (5672) and `web` (8080) to in-cluster clients. |

The Deployment selects pods by `app.kubernetes.io/name: hyrxmq`. Both the
ConfigMap and Secret are referenced with `envFrom`, so every key becomes an
environment variable in the container.

## 2. Applying the manifests

Apply the whole directory in one command. `kubectl` orders the namespace and
its dependents automatically:

```bash
kubectl apply -f k8s/
```

Verify:

```bash
kubectl -n hyrxmq get all
kubectl -n hyrxmq get configmap,secret
kubectl -n hyrxmq describe deployment hyrxmq
```

Remove everything:

```bash
kubectl delete -f k8s/
```

> `secret.yaml` ships a placeholder credential (`admin/password`). Replace it
> with a real secret before applying to any shared cluster — see §4.

## 3. Configuration — ConfigMap (`hyrxmq-config`)

All keys below are injected verbatim into the pod environment.

| Variable | Default in ConfigMap | Meaning |
|----------|----------------------|---------|
| `HYRXMQ_HOST` | `0.0.0.0` | Bind address for the AMQP listener. `0.0.0.0` is required inside a pod so the kubelet and Service can reach it. |
| `HYRXMQ_PORT` | `5672` | AMQP listener port (container port `amqp`). |
| `HYRXMQ_WEB_PORT` | `8080` | Web dashboard / management listener port (container port `web`); serves the probe endpoints. |
| `HYRXMQ_NODE_NAME` | `hyrxmq@localhost` | Node identity used in logging and management output. |
| `HYRXMQ_STORAGE_MODE` | `disabled` | Persistence mode: `disabled`, `memory`, or `file`. `file` requires `HYRXMQ_STORAGE_PATH` (see §7). |
| `HYRXMQ_HEARTBEAT_SECS` | `60` | AMQP heartbeat interval in seconds. |
| `HYRXMQ_FRAME_MAX` | `131072` | Maximum AMQP frame size in bytes (128 KiB). |
| `HYRXMQ_MAX_CONNECTIONS` | `1024` | Maximum concurrent client connections. |
| `HYRXMQ_MAX_MESSAGE_SIZE` | `134217728` | Maximum message size in bytes (128 MiB). |
| `HYRXMQ_MAX_QUEUES` | `65535` | Maximum number of queues. |
| `HYRXMQ_MAX_EXCHANGES` | `65535` | Maximum number of exchanges. |
| `HYRXMQ_IDLE_TIMEOUT_SECS` | `300` | Idle connection timeout in seconds. |
| `HYRXMQ_MAX_MEMORY_BYTES` | `536870912` | Broker memory ceiling in bytes (512 MiB); keep at or below the container memory limit. |

Edit the ConfigMap to change any value, then restart the pod:

```bash
kubectl -n hyrxmq edit configmap hyrxmq-config
kubectl -n hyrxmq rollout restart deployment/hyrxmq
```

### Advanced variables (not set by default)

The broker also reads these variables. They are intentionally omitted from the
default ConfigMap; add them only when the corresponding feature is used.

| Variable | Purpose |
|----------|---------|
| `HYRXMQ_STORAGE_PATH` | Filesystem path for the WAL when `HYRXMQ_STORAGE_MODE=file`. |
| `HYRXMQ_TLS_ENABLED`, `HYRXMQ_TLS_CERT`, `HYRXMQ_TLS_KEY` | TCP-tier TLS material. |
| `HYRXMQ_WSS_LISTEN`, `HYRXMQ_WSS_TLS_MODE`, `HYRXMQ_WSS_TLS_PATH`, `HYRXMQ_WSS_TLS_KEY`, `HYRXMQ_WSS_ORIGIN` | WebSocket listener and TLS settings. |
| `HYRXMQ_UDS_PATH` | UNIX-domain-socket listener path. |
| `HYRXMQ_ADMIN_HTTP` | Management HTTP endpoint binding. |
| `HYRXMQ_USERS` | Operator-supplied credential table. Comma-separated `username:password[:vhost[:configure,write,read]]` entries (vhost default `/`, perms default all). Non-empty REPLACES the built-in `admin/password` default; empty/absent keeps it. A malformed entry aborts startup. Delivered through the `hyrxmq-credentials` Secret (§4), not the ConfigMap. |

## 4. Secrets handling

Credentials live in `Secret/hyrxmq-credentials`, not in the ConfigMap.
The manifest uses `stringData` for readability, but `stringData` is
write-only sugar — Kubernetes stores the value base64-encoded in `data`.

- Do **not** commit real credentials. The checked-in `secret.yaml` is a
  placeholder for local clusters only.
- For real deployments, create the secret out-of-band and delete the
  `secretRef` from source control, e.g.:

```bash
kubectl -n hyrxmq create secret generic hyrxmq-credentials \
  --from-literal=HYRXMQ_USERS='admin:<strong-password>'
```

- `HYRXMQ_USERS` encodes the credential list. The placeholder value is
  `admin/password`; replace it.
- To rotate, update the secret and restart: `kubectl -n hyrxmq rollout restart deployment/hyrxmq`.
- For GitOps, manage the secret with SealedSecrets / SOPS / an external secret
  operator rather than plaintext YAML.

## 5. Probe semantics

All three probes hit the web listener (`port: web`, i.e. `HYRXMQ_WEB_PORT`,
default `8080`).

| Probe | Path | initialDelay | period | timeout | failureThreshold |
|-------|------|--------------|--------|---------|------------------|
| `startupProbe` | `/health` | 5s | 5s | (default 1s) | 10 |
| `livenessProbe` | `/health` | 10s | 15s | 5s | 3 |
| `readinessProbe` | `/ready` | 5s | 10s | 3s | 2 |

- **startupProbe** — disables the other probes until `/health` first succeeds.
  With `periodSeconds: 5` and `failureThreshold: 10`, the pod gets up to ~55s
  to start before the kubelet gives up and restarts it.
- **livenessProbe** — `/health` proves the process is alive; 3 consecutive
  failures restart the container.
- **readinessProbe** — `/ready` gates Service traffic. A pod that is not ready
  is removed from the `hyrxmq` Service endpoints but is not restarted.

Both endpoints are served by the web listener. If `/health` nor `/ready`
responds, the pod never becomes Ready — see §10.

## 6. Graceful shutdown

Graceful shutdown combines a `preStop` hook, the container signal, and the
pod's termination grace period:

```yaml
terminationGracePeriodSeconds: 30
lifecycle:
  preStop:
    exec:
      command: ["sh", "-c", "sleep 5 && kill -SIGTERM 1"]
```

Sequence:

1. Kubernetes removes the pod from Service endpoints (traffic drains).
2. `preStop` runs: it waits 5s, then sends `SIGTERM` to PID 1 in the
   container.
3. HyrxMQ's C shim (`src/hyrxmq/shutdown_shim.c`, linked into
   `hyrxmq-listen`) installs `SIGTERM`/`SIGINT` handlers. The handler sets an
   async-signal-safe `volatile sig_atomic_t` flag; the serving loop polls
   `hyrxmq_shutdown_requested()` and calls `begin_shutdown()`.
4. The broker finishes in-flight work and exits. If it has not exited within
   `terminationGracePeriodSeconds` (30s), the kubelet sends `SIGKILL`.

The 5s `preStop` sleep gives endpoint propagation time before the process
begins shutting down. Keep `terminationGracePeriodSeconds` comfortably above
`preStop sleep + drain time`.

## 7. Resource requests and limits

```yaml
resources:
  requests:
    cpu: 500m
    memory: 256Mi
  limits:
    cpu: "2"
    memory: 512Mi
```

- **Requests** (500m CPU / 256Mi) drive scheduling.
- **Limits** (2 CPU / 512Mi) cap the container. `HYRXMQ_MAX_MEMORY_BYTES`
  defaults to `536870912` (512 MiB), matching the memory limit — the broker's
  own ceiling and the cgroup limit align. If you raise the memory limit, raise
  `HYRXMQ_MAX_MEMORY_BYTES` to match (leave headroom for runtime overhead).

## 8. Storage — file mode with a PersistentVolumeClaim

`HYRXMQ_STORAGE_MODE=file` persists the write-ahead log to
`HYRXMQ_STORAGE_PATH`. The default ConfigMap uses `disabled`; switch to `file`
and mount a PVC at that path.

**PVC manifest** (save as `k8s/pvc.yaml`, or add to your overlay):

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hyrxmq-data
  namespace: hyrxmq
  labels:
    app.kubernetes.io/name: hyrxmq
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # storageClassName: <your-class>   # omit to use the cluster default
```

**Wire it up** — set the mode and path in the ConfigMap:

```yaml
# k8s/configmap.yaml (data)
HYRXMQ_STORAGE_MODE: "file"
HYRXMQ_STORAGE_PATH: "/var/lib/hyrxmq"
```

and mount the claim in the Deployment container:

```yaml
# k8s/deployment.yaml (spec.template.spec)
volumes:
  - name: hyrxmq-data
    persistentVolumeClaim:
      claimName: hyrxmq-data
containers:
  - name: hyrxmq
    # ...
    volumeMounts:
      - name: hyrxmq-data
        mountPath: /var/lib/hyrxmq
```

Notes:

- `ReadWriteOnce` is sufficient — one replica owns the volume.
- The process must be able to write `HYRXMQ_STORAGE_PATH`. If the image runs
  as a non-root UID, set `spec.template.spec.securityContext.fsGroup` to a
  group that owns the volume so the mount is writable (see §10).
- `HYRXMQ_STORAGE_MODE=file` **requires** `HYRXMQ_STORAGE_PATH`; the broker
  raises at startup if the path is empty.

## 9. Scaling

HyrxMQ is **single-instance by design**. Clustering, replication, and
horizontal sharding are explicit non-goals; a broker instance owns its
queues, state, and WAL.

- Keep `replicas: 1`. Multiple replicas would each be an independent broker
  and would corrupt shared storage under `file` mode.
- The strategy is `Recreate` (not `RollingUpdate`): the old pod is terminated
  before the new one starts, which is required for `ReadWriteOnce` volumes and
  single-writer state.
- To scale capacity, scale the *node* (CPU/memory) — not the replica count.
- Availability is achieved by running independent brokers on separate
  namespaces/volumes, with clients connecting to the relevant Service.

## 10. Troubleshooting

**Pod never becomes Ready / probe failures**
- Confirm the web listener is up: `kubectl -n hyrxmq exec deploy/hyrxmq -- curl -sf localhost:8080/ready`.
- `/ready` and `/health` are served on `HYRXMQ_WEB_PORT` (8080). If you change
  the port in the ConfigMap, the probe `port: web` name still resolves to the
  container port — keep `containerPort`/`HYRXMQ_WEB_PORT` consistent.
- Slow startup: raise `startupProbe.failureThreshold` or `periodSeconds`.
- `kubectl -n hyrxmq logs deploy/hyrxmq` and `kubectl -n hyrxmq describe pod <pod>` show probe events and restart reasons.

**Port conflicts**
- `hyrxmq` binds `HYRXMQ_PORT` (5672) and `HYRXMQ_WEB_PORT` (8080) inside the
  pod. A second container in the same pod cannot reuse those ports.
- A `ClusterIP` Service needs no host ports; only use `NodePort`/`LoadBalancer`
  when external access is required.
- "address already in use" at startup usually means a stale process in the
  image or a changed `HYRXMQ_PORT` that collides with a sidecar.

**Storage permission errors (`HYRXMQ_STORAGE_MODE=file`)**
- Symptom: startup error mentioning `HYRXMQ_STORAGE_PATH`, or WAL open/write
  failures.
- Verify the PVC is `Bound`: `kubectl -n hyrxmq get pvc hyrxmq-data`.
- Ensure the mount path exists and is writable by the container UID. Add:

```yaml
spec:
  template:
    spec:
      securityContext:
        fsGroup: 1000
```

- Do not point `HYRXMQ_STORAGE_PATH` at an `emptyDir` and expect durability.

**Credential/authentication failures**
- Check the `hyrxmq-credentials` secret is present and injected:
  `kubectl -n hyrxmq exec deploy/hyrxmq -- printenv HYRXMQ_USERS`.
- After rotating the secret, restart the deployment.

**Graceful shutdown hangs to `SIGKILL`**
- If the container is killed at the 30s grace deadline, increase
  `terminationGracePeriodSeconds` or reduce drain time. Confirm the image links
  the signal shim (`hyrxmq-listen`) — the plain `mojo run` JIT path does not.
