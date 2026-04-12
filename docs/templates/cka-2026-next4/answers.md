## Question 401: Gateway API traffic management

Repair the Gateway API contract in `gateway-lab` without recreating the backend workloads.

```bash
cat <<'EOF_GATEWAY' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1beta1
kind: GatewayClass
metadata:
  name: cka-014-gc
spec:
  controllerName: example.com/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: main-gateway
  namespace: gateway-lab
spec:
  gatewayClassName: cka-014-gc
  listeners:
  - name: http
    port: 80
    protocol: HTTP
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: app-routes
  namespace: gateway-lab
spec:
  hostnames:
  - apps.example.local
  parentRefs:
  - name: main-gateway
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /app1
    backendRefs:
    - name: app1-svc
      port: 8080
  - matches:
    - path:
        type: PathPrefix
        value: /app2
    backendRefs:
    - name: app2-svc
      port: 8080
EOF_GATEWAY

mkdir -p /tmp/exam/q401
kubectl get httproute app-routes -n gateway-lab -o yaml > /tmp/exam/q401/app-routes.yaml
```

Expected checks:

- `GatewayClass` `cka-014-gc` exists and uses controller `example.com/gateway-controller`
- `Gateway` `main-gateway` listens on HTTP port `80` and uses GatewayClass `cka-014-gc`
- `HTTPRoute` `app-routes` attaches to `main-gateway`
- `/app1` routes to `app1-svc:8080` and `/app2` routes to `app2-svc:8080`
- no `/legacy` route remains
- backend Deployments and Services stay ready
- the repaired manifest is exported to `/tmp/exam/q401/app-routes.yaml`

## Question 402: logs and resource usage triage

Capture the crashing sidecar evidence first, then repair the Deployment contract and export pod resource usage for the healthy pod.

```bash
mkdir -p /tmp/exam/q402
BROKEN_POD=""
for attempt in $(seq 1 30); do
  BROKEN_POD="$(kubectl get pods -n triage-lab -l app=ops-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "$BROKEN_POD" ] && kubectl logs "$BROKEN_POD" -n triage-lab -c log-agent --previous > /tmp/exam/q402/log-agent-previous.log 2>/dev/null; then
    break
  fi
  sleep 2
done

kubectl patch deployment ops-api -n triage-lab --type strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "api",
            "ports": [{"containerPort": 80}],
            "resources": {
              "requests": {"cpu": "50m", "memory": "128Mi"},
              "limits": {"cpu": "100m", "memory": "256Mi"}
            },
            "livenessProbe": {
              "httpGet": {"path": "/", "port": 80},
              "initialDelaySeconds": 3,
              "periodSeconds": 3
            }
          },
          {
            "name": "log-agent",
            "env": [{"name": "LOG_TARGET", "value": "/var/log/ops/app.log"}]
          }
        ]
      }
    }
  }
}'

kubectl rollout status deployment/ops-api -n triage-lab

for attempt in $(seq 1 30); do
  POD_NAME="$(kubectl get pods -n triage-lab -l app=ops-api -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"|"}{.status.phase}{"\n"}{end}' | awk -F'|' '$2=="" && $3=="Running" {print $1; exit}')"
  if [ -n "$POD_NAME" ] && kubectl top pod "$POD_NAME" -n triage-lab --containers > /tmp/exam/q402/ops-api-top.txt 2>/dev/null; then
    break
  fi
  sleep 2
done
```

Expected checks:

- `api` uses port `80`, memory limit `256Mi`, and a liveness probe on port `80`
- `log-agent` now uses `LOG_TARGET=/var/log/ops/app.log`
- `/tmp/exam/q402/log-agent-previous.log` contains the crashing sidecar evidence
- `/tmp/exam/q402/ops-api-top.txt` contains `kubectl top` output for the active pod and both containers
- the repaired Deployment becomes Available and the active `log-agent` stops restarting

## Question 403: kubeadm lifecycle planning

Repair the upgrade planning brief and export both the repaired manifest and a plain-text execution checklist.

```bash
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: upgrade-brief
  namespace: kubeadm-lab
data:
  currentVersion: v1.31.5
  targetVersion: v1.31.8
  controlPlaneEndpoint: k8s-api-server:6443
  maintenanceNode: cp-maint-0
  planCommand: kubeadm upgrade plan v1.31.8
  applyCommand: kubeadm upgrade apply v1.31.8 -y
  drainCommand: kubectl drain cp-maint-0 --ignore-daemonsets --delete-emptydir-data
  uncordonCommand: kubectl uncordon cp-maint-0
  backupPaths: /etc/kubernetes/admin.conf,/etc/kubernetes/pki,/var/lib/etcd
EOF_BRIEF

mkdir -p /tmp/exam/q403
cat <<'EOF_PLAN' > /tmp/exam/q403/upgrade-plan.txt
Pre-flight
- kubectl get nodes -o wide
- kubeadm upgrade plan v1.31.8

Backups
- /etc/kubernetes/admin.conf
- /etc/kubernetes/pki
- /var/lib/etcd

Execution
- kubectl drain cp-maint-0 --ignore-daemonsets --delete-emptydir-data
- kubeadm upgrade apply v1.31.8 -y

Post-upgrade
- kubectl uncordon cp-maint-0
- kubectl get nodes -o wide
EOF_PLAN

kubectl get configmap upgrade-brief -n kubeadm-lab -o yaml > /tmp/exam/q403/upgrade-brief.yaml
```

Expected checks:

- `upgrade-brief` contains the intended target version, endpoint, backup paths, and safe command sequence
- `/tmp/exam/q403/upgrade-plan.txt` contains the required sections and exact kubeadm / drain / uncordon commands
- `/tmp/exam/q403/upgrade-brief.yaml` exports the repaired manifest
- stale commands such as `kubeadm upgrade node` and `kubectl cordon cp-maint-0` are removed

## Question 404: CRD and operator installation checks

Repair the installation bundle so the CRD, operator Deployment, and custom resource all use the intended contract.

```bash
cat <<'EOF_CRD' | kubectl apply -f -
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.training.cka.io
spec:
  group: training.cka.io
  scope: Namespaced
  names:
    plural: widgets
    singular: widget
    kind: Widget
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required:
            - image
            - replicas
            properties:
              image:
                type: string
              replicas:
                type: integer
EOF_CRD

kubectl wait --for=condition=established --timeout=120s crd/widgets.training.cka.io

cat <<'EOF_OPERATOR' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: widget-operator
  namespace: operator-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: widget-operator
  template:
    metadata:
      labels:
        app: widget-operator
    spec:
      containers:
      - name: manager
        image: busybox:1.36.1
        command:
        - sh
        - -c
        - sleep 3600
EOF_OPERATOR

kubectl rollout status deployment/widget-operator -n operator-lab --timeout=180s

cat <<'EOF_WIDGET' | kubectl apply -f -
apiVersion: training.cka.io/v1alpha1
kind: Widget
metadata:
  name: sample-widget
  namespace: operator-lab
spec:
  image: nginx:1.25.5
  replicas: 2
EOF_WIDGET

mkdir -p /tmp/exam/q404
kubectl get crd widgets.training.cka.io -o yaml > /tmp/exam/q404/widget-crd.yaml
```

Expected checks:

- the CRD uses group `training.cka.io`, kind `Widget`, plural `widgets`, scope `Namespaced`, and requires `spec.image` and `spec.replicas`
- `spec.image` is a string and `spec.replicas` is an integer in the CRD schema
- `widget-operator` runs one ready replica with image `busybox:1.36.1` and a long-running `sleep 3600` command
- `sample-widget` uses `training.cka.io/v1alpha1`, `nginx:1.25.5`, and `replicas: 2`
- the repaired CRD manifest is exported to `/tmp/exam/q404/widget-crd.yaml`

## Question 405: etcd backup and restore workflow

Repair the etcd recovery planning brief and export both the repaired manifest and a plain-text backup/restore checklist.

```bash
cat <<'EOF_PLAN' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: etcd-recovery-plan
  namespace: etcd-lab
data:
  snapshotPath: /var/backups/etcd/snapshot.db
  endpoint: https://127.0.0.1:2379
  caPath: /etc/kubernetes/pki/etcd/ca.crt
  certPath: /etc/kubernetes/pki/etcd/server.crt
  keyPath: /etc/kubernetes/pki/etcd/server.key
  snapshotCommand: ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/backups/etcd/snapshot.db
  restoreCommand: ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore
  staticPodManifest: /etc/kubernetes/manifests/etcd.yaml
EOF_PLAN

mkdir -p /tmp/exam/q405
cat <<'EOF_CHECKLIST' > /tmp/exam/q405/etcd-recovery-checklist.txt
Snapshot
- ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/backups/etcd/snapshot.db

Restore
- ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore

Static Pod Update
- edit /etc/kubernetes/manifests/etcd.yaml to point at /var/lib/etcd-restore

Verification
- ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint health
EOF_CHECKLIST

kubectl get configmap etcd-recovery-plan -n etcd-lab -o yaml > /tmp/exam/q405/etcd-recovery-plan.yaml
```

Expected checks:

- `etcd-recovery-plan` contains the intended snapshot path, certificates, endpoint, and exact snapshot/restore commands
- `/tmp/exam/q405/etcd-recovery-checklist.txt` contains the required sections and exact command lines
- `/tmp/exam/q405/etcd-recovery-plan.yaml` exports the repaired manifest
- stale unsafe paths such as `/backup/old.db`, `/etc/kubernetes/pki/etcd/peer.crt`, and commands that delete `/var/lib/etcd` are removed
