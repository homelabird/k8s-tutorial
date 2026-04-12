#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_URL="${BASE_URL:-http://127.0.0.1:30080}"
CURRENT_EXAM=""
HTTP_WAIT_ATTEMPTS="${HTTP_WAIT_ATTEMPTS:-90}"
HEALTH_WAIT_ATTEMPTS="${HEALTH_WAIT_ATTEMPTS:-180}"
EXAM_STATUS_WAIT_ATTEMPTS="${EXAM_STATUS_WAIT_ATTEMPTS:-300}"
EVALUATED_WAIT_ATTEMPTS="${EVALUATED_WAIT_ATTEMPTS:-180}"
CLEANUP_WAIT_ATTEMPTS="${CLEANUP_WAIT_ATTEMPTS:-180}"
SUITE_TIMEOUT_SECONDS="${SUITE_TIMEOUT_SECONDS:-1800}"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/verify/run-cka-2026-single-domain-drills.sh
  ./scripts/verify/run-cka-2026-single-domain-drills.sh cka-006 cka-021
  ./scripts/verify/run-cka-2026-single-domain-drills.sh --list

Supported suites:
  cka-006  RBAC least-privilege drill
  cka-007  Deployment rollout and rollback drill
  cka-008  Scheduling constraints drill
  cka-009  NetworkPolicy troubleshooting drill
  cka-010  Persistent storage troubleshooting drill
  cka-011  ConfigMap and Secret repair drill
  cka-012  HPA troubleshooting drill
  cka-013  Node troubleshooting and maintenance drill
  cka-014  Gateway API traffic management drill
  cka-015  Logs and resource usage triage drill
  cka-016  Kubeadm lifecycle planning drill
  cka-017  CRD and operator installation checks drill
  cka-018  etcd backup and restore workflow drill
  cka-019  scheduler and controller-manager troubleshooting drill
  cka-020  service and pod connectivity diagnostics drill
  cka-021  service exposure and endpoint debugging drill

Notes:
  - The runner executes the selected suites sequentially.
  - Each suite resets the local Podman stack before exam create/evaluate/cleanup.
  - You can override BASE_URL before running the script.
  - Set SUITE_TIMEOUT_SECONDS=0 to disable the per-suite timeout wrapper.
USAGE
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

compose_cmd() {
  sudo podman compose -f "$ROOT_DIR/docker-compose.yaml" -f "$ROOT_DIR/docker-compose.podman.yaml" "$@"
}

cleanup() {
  if [ -n "$CURRENT_EXAM" ]; then
    curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/terminate" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

wait_for_http() {
  local attempt
  for attempt in $(seq 1 "$HTTP_WAIT_ATTEMPTS"); do
    if [ "$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/")" = "200" ]; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for web stack HTTP readiness at $BASE_URL/" >&2
  return 1
}

wait_for_health() {
  local attempt
  local status_output=""
  for attempt in $(seq 1 "$HEALTH_WAIT_ATTEMPTS"); do
    status_output="$(sudo podman ps --format '{{.Names}} {{.Status}}')"
    if printf '%s\n' "$status_output" | grep -qE '^(kind-cluster|k8s-tutorial_jumphost_1|k8s-tutorial_facilitator_1) ' \
      && ! printf '%s\n' "$status_output" \
        | grep -E '^(kind-cluster|k8s-tutorial_jumphost_1|k8s-tutorial_facilitator_1) ' \
        | grep -vq '(healthy)'; then
      return 0
    fi
    sleep 2
  done
  printf '%s\n' "$status_output" >&2
  echo "Timed out waiting for stack health" >&2
  return 1
}

wait_for_exam_status() {
  local expected_status="$1"
  local attempt
  local observed_status=""
  for attempt in $(seq 1 "$EXAM_STATUS_WAIT_ATTEMPTS"); do
    observed_status="$(curl -s "$BASE_URL/facilitator/api/v1/exams/current" | jq -r '.status // empty')"
    if [ "$observed_status" = "$expected_status" ]; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for exam status '$expected_status' (last status: '${observed_status:-empty}')" >&2
  return 1
}

wait_for_evaluated() {
  local attempt
  local observed_status=""
  for attempt in $(seq 1 "$EVALUATED_WAIT_ATTEMPTS"); do
    observed_status="$(curl -s "$BASE_URL/facilitator/api/v1/exams/current" | jq -r '.status // empty')"
    if [ "$observed_status" = "EVALUATED" ]; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for exam evaluation (last status: '${observed_status:-empty}')" >&2
  return 1
}

wait_for_no_current_exam() {
  local attempt
  local observed_message=""
  for attempt in $(seq 1 "$CLEANUP_WAIT_ATTEMPTS"); do
    observed_message="$(curl -s "$BASE_URL/facilitator/api/v1/exams/current" | jq -r '.message // empty')"
    if [ "$observed_message" = "No current exam is active" ]; then
      return 0
    fi
    sleep 2
  done
  echo "Timed out waiting for exam cleanup (last message: '${observed_message:-empty}')" >&2
  return 1
}

wait_for_no_inner_clusters() {
  local attempt
  local cluster_output=""
  for attempt in $(seq 1 "$CLEANUP_WAIT_ATTEMPTS"); do
    cluster_output="$(sudo podman ps --format '{{.Names}}' | grep '^k3d-cluster' || true)"
    if [ -z "$cluster_output" ]; then
      return 0
    fi
    sleep 2
  done
  printf '%s\n' "$cluster_output" >&2
  echo "Timed out waiting for inner k3d cluster cleanup" >&2
  return 1
}

shared_exec() {
  sudo podman exec k8s-tutorial_jumphost_1 bash -lc "export KUBECONFIG=/home/candidate/.kube/kubeconfig; $*"
}

wait_for_validation_script() {
  local script_name="$1"
  local attempt
  for attempt in $(seq 1 30); do
    if shared_exec "bash /tmp/exam-assets/scripts/validation/${script_name}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "Timed out waiting for validation script ${script_name} to pass" >&2
  return 1
}

post_solve_check() {
  case "$1" in
    cka-006)
      wait_for_validation_script q1_s3_validate_least_privilege.sh
      ;;
    cka-008)
      wait_for_validation_script q1_s2_validate_scheduled_node.sh
      wait_for_validation_script q1_s3_validate_constraint_scope.sh
      ;;
    cka-009)
      wait_for_validation_script q1_s2_validate_allowed_paths.sh
      wait_for_validation_script q1_s3_validate_denied_path.sh
      ;;
    *) return 0 ;;
  esac
}

resolve_suite_namespace() {
  case "$1" in
    cka-006) printf '%s\n' 'rbac-lab' ;;
    cka-007) printf '%s\n' 'rollout-lab' ;;
    cka-008) printf '%s\n' 'scheduling-lab' ;;
    cka-009) printf '%s\n' 'netpol-lab' ;;
    cka-010) printf '%s\n' 'storage-lab' ;;
    cka-011) printf '%s\n' 'config-lab' ;;
    cka-012) printf '%s\n' 'autoscale-lab' ;;
    cka-013) printf '%s\n' 'node-lab' ;;
    cka-014) printf '%s\n' 'gateway-lab' ;;
    cka-015) printf '%s\n' 'triage-lab' ;;
    cka-016) printf '%s\n' 'kubeadm-lab' ;;
    cka-017) printf '%s\n' 'operator-lab' ;;
    cka-018) printf '%s\n' 'etcd-lab' ;;
    cka-019) printf '%s\n' 'controlplane-lab' ;;
    cka-020) printf '%s\n' 'connectivity-lab' ;;
    cka-021) printf '%s\n' 'service-debug-lab' ;;
    *)
      echo "Unknown suite: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

resolve_solve_command() {
  case "$1" in
    cka-006)
      cat <<'COMMAND'
cat <<'EOF_ROLE' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: report-reader
  namespace: rbac-lab
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
EOF_ROLE

cat <<'EOF_ROLEBINDING' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: report-reader
  namespace: rbac-lab
subjects:
- kind: ServiceAccount
  name: report-reader
  namespace: rbac-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: report-reader
EOF_ROLEBINDING
COMMAND
      ;;
    cka-007)
      cat <<'COMMAND'
mkdir -p /tmp/exam/q1
kubectl patch deployment web-app -n rollout-lab --type merge -p '{
  "spec": {
    "strategy": {
      "type": "RollingUpdate",
      "rollingUpdate": {
        "maxUnavailable": 1,
        "maxSurge": 1
      }
    }
  }
}'

kubectl annotate deployment web-app -n rollout-lab \
  kubernetes.io/change-cause='update image to nginx:1.25.5' \
  --overwrite

kubectl set image deployment/web-app nginx=nginx:1.25.5 -n rollout-lab
kubectl rollout status deployment/web-app -n rollout-lab --timeout=180s
kubectl rollout history deployment/web-app -n rollout-lab > /tmp/exam/q1/rollout-history.txt
kubectl rollout undo deployment/web-app -n rollout-lab
kubectl rollout status deployment/web-app -n rollout-lab --timeout=180s
COMMAND
      ;;
    cka-008)
      cat <<'COMMAND'
kubectl patch deployment metrics-agent -n scheduling-lab --type merge -p '{
  "spec": {
    "template": {
      "spec": {
        "nodeSelector": {
          "workload": "ops"
        },
        "tolerations": [
          {
            "key": "dedicated",
            "operator": "Equal",
            "value": "ops",
            "effect": "NoSchedule"
          }
        ]
      }
    }
  }
}'
kubectl rollout status deployment metrics-agent -n scheduling-lab --timeout=180s
COMMAND
      ;;
    cka-009)
      cat <<'COMMAND'
cat <<'EOF_API' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  - to:
    - podSelector:
        matchLabels:
          app: db
    ports:
    - protocol: TCP
      port: 5432
EOF_API

cat <<'EOF_DB' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-policy
  namespace: netpol-lab
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 5432
EOF_DB
COMMAND
      ;;
    cka-010)
      cat <<'COMMAND'
kubectl delete pvc app-data -n storage-lab --wait=true
cat <<'EOF_PVC' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
  namespace: storage-lab
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: manual
  volumeName: app-data-pv
EOF_PVC
kubectl rollout status deployment/reporting-app -n storage-lab --timeout=180s
COMMAND
      ;;

    cka-011)
      cat <<'COMMAND'
kubectl set env deployment/report-viewer -n config-lab APP_MODE- REPORT_USER- REPORT_PASS-
kubectl patch deployment report-viewer -n config-lab --type strategic -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "viewer",
            "env": [
              {
                "name": "APP_MODE",
                "valueFrom": {
                  "configMapKeyRef": {
                    "name": "report-config",
                    "key": "APP_MODE"
                  }
                }
              },
              {
                "name": "REPORT_USER",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "report-credentials",
                    "key": "username"
                  }
                }
              },
              {
                "name": "REPORT_PASS",
                "valueFrom": {
                  "secretKeyRef": {
                    "name": "report-credentials",
                    "key": "password"
                  }
                }
              }
            ]
          }
        ]
      }
    }
  }
}'
kubectl rollout status deployment/report-viewer -n config-lab --timeout=180s
COMMAND
      ;;
    cka-012)
      cat <<'COMMAND'
kubectl set resources deployment worker-api -n autoscale-lab --containers=api --requests=cpu=200m
cat <<'EOF_HPA' | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-api-hpa
  namespace: autoscale-lab
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker-api
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
EOF_HPA
mkdir -p /tmp/exam/q1
kubectl get hpa worker-api-hpa -n autoscale-lab -o yaml > /tmp/exam/q1/worker-api-hpa.yaml
kubectl rollout status deployment/worker-api -n autoscale-lab --timeout=180s
COMMAND
      ;;
    cka-013)
      cat <<'COMMAND'
TARGET_NODE="$(kubectl get nodes -l maintenance-lab=target -o jsonpath='{.items[0].metadata.name}')"
kubectl uncordon "$TARGET_NODE"
kubectl rollout status deployment/queue-consumer -n node-lab --timeout=180s
mkdir -p /tmp/exam/q1
kubectl get node "$TARGET_NODE" -o wide > /tmp/exam/q1/node-status.txt
COMMAND
      ;;
    cka-014)
      cat <<'COMMAND'
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
mkdir -p /tmp/exam/q1
kubectl get httproute app-routes -n gateway-lab -o yaml > /tmp/exam/q1/app-routes.yaml
COMMAND
      ;;
    cka-015)
      cat <<'COMMAND'
mkdir -p /tmp/exam/q1
BROKEN_POD=""
for attempt in $(seq 1 30); do
  BROKEN_POD="$(kubectl get pods -n triage-lab -l app=ops-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "$BROKEN_POD" ] && kubectl logs "$BROKEN_POD" -n triage-lab -c log-agent --previous > /tmp/exam/q1/log-agent-previous.log 2>/dev/null; then
    break
  fi
  sleep 2
done
[ -s /tmp/exam/q1/log-agent-previous.log ]
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
kubectl rollout status deployment/ops-api -n triage-lab --timeout=180s
for attempt in $(seq 1 30); do
  POD_NAME="$(kubectl get pods -n triage-lab -l app=ops-api -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"|"}{.status.phase}{"\n"}{end}' | awk -F'|' '$2=="" && $3=="Running" {print $1; exit}')"
  if [ -n "$POD_NAME" ] && kubectl top pod "$POD_NAME" -n triage-lab --containers > /tmp/exam/q1/ops-api-top.txt 2>/dev/null; then
    break
  fi
  sleep 2
done
[ -s /tmp/exam/q1/ops-api-top.txt ]
COMMAND
      ;;
    cka-016)
      cat <<'COMMAND'
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
mkdir -p /tmp/exam/q1
cat <<'EOF_PLAN' > /tmp/exam/q1/upgrade-plan.txt
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
kubectl get configmap upgrade-brief -n kubeadm-lab -o yaml > /tmp/exam/q1/upgrade-brief.yaml
[ -s /tmp/exam/q1/upgrade-plan.txt ]
[ -s /tmp/exam/q1/upgrade-brief.yaml ]
COMMAND
      ;;
    cka-017)
      cat <<'COMMAND'
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

mkdir -p /tmp/exam/q1
kubectl get crd widgets.training.cka.io -o yaml > /tmp/exam/q1/widget-crd.yaml
[ -s /tmp/exam/q1/widget-crd.yaml ]
COMMAND
      ;;
    cka-018)
      cat <<'COMMAND'
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
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/etcd-recovery-checklist.txt
Snapshot
- ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/backups/etcd/snapshot.db

Restore
- ETCDCTL_API=3 etcdctl snapshot restore /var/backups/etcd/snapshot.db --data-dir=/var/lib/etcd-restore

Static Pod Update
- edit /etc/kubernetes/manifests/etcd.yaml to point at /var/lib/etcd-restore

Verification
- ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint health
EOF_CHECKLIST
kubectl get configmap etcd-recovery-plan -n etcd-lab -o yaml > /tmp/exam/q1/etcd-recovery-plan.yaml
[ -s /tmp/exam/q1/etcd-recovery-plan.yaml ]
[ -s /tmp/exam/q1/etcd-recovery-checklist.txt ]
COMMAND
      ;;
    cka-019)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: component-repair-brief
  namespace: controlplane-lab
data:
  schedulerManifest: /etc/kubernetes/manifests/kube-scheduler.yaml
  controllerManagerManifest: /etc/kubernetes/manifests/kube-controller-manager.yaml
  schedulerHealthz: https://127.0.0.1:10259/healthz
  controllerManagerHealthz: https://127.0.0.1:10257/healthz
  schedulerKubeconfig: /etc/kubernetes/scheduler.conf
  controllerManagerKubeconfig: /etc/kubernetes/controller-manager.conf
  schedulerLogHint: journalctl -u kubelet | grep kube-scheduler
  controllerManagerLogHint: journalctl -u kubelet | grep kube-controller-manager
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/control-plane-checklist.txt
Scheduler
- inspect /etc/kubernetes/manifests/kube-scheduler.yaml
- confirm /etc/kubernetes/scheduler.conf
- curl -k https://127.0.0.1:10259/healthz
- journalctl -u kubelet | grep kube-scheduler

Controller Manager
- inspect /etc/kubernetes/manifests/kube-controller-manager.yaml
- confirm /etc/kubernetes/controller-manager.conf
- curl -k https://127.0.0.1:10257/healthz
- journalctl -u kubelet | grep kube-controller-manager

Verification
- kubectl get pods -n kube-system -l component=kube-scheduler
- kubectl get pods -n kube-system -l component=kube-controller-manager
- kubectl get --raw='/readyz?verbose'
EOF_CHECKLIST
kubectl get configmap component-repair-brief -n controlplane-lab -o yaml > /tmp/exam/q1/component-repair-brief.yaml
[ -s /tmp/exam/q1/component-repair-brief.yaml ]
[ -s /tmp/exam/q1/control-plane-checklist.txt ]
COMMAND
      ;;
    cka-020)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: connectivity-brief
  namespace: connectivity-lab
data:
  debugPod: net-debug
  serviceName: echo-api
  servicePort: "8080"
  headlessServiceName: echo-api-headless
  podDnsName: echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local
  serviceProbe: kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz
  podProbe: kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz
  dnsProbe: kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_MATRIX' > /tmp/exam/q1/connectivity-matrix.txt
Service Path
- kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api:8080/healthz

Pod Path
- kubectl exec -n connectivity-lab net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz

DNS Checks
- kubectl exec -n connectivity-lab net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local
- kubectl get svc echo-api -n connectivity-lab
- kubectl get svc echo-api-headless -n connectivity-lab
EOF_MATRIX
kubectl get configmap connectivity-brief -n connectivity-lab -o yaml > /tmp/exam/q1/connectivity-brief.yaml
[ -s /tmp/exam/q1/connectivity-brief.yaml ]
[ -s /tmp/exam/q1/connectivity-matrix.txt ]
COMMAND
      ;;
    cka-021)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-exposure-brief
  namespace: service-debug-lab
data:
  serviceName: echo-api
  serviceType: ClusterIP
  selectorKey: app
  selectorValue: echo-api
  servicePort: "8080"
  targetPort: "8080"
  endpointCheck: kubectl get endpoints echo-api -n service-debug-lab -o wide
  selectorCheck: kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.selector.app}'
  reachabilityCheck: kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/service-exposure-checklist.txt
Selector Audit
- kubectl get svc echo-api -n service-debug-lab -o yaml
- kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.selector.app}'

Endpoint Audit
- kubectl get endpoints echo-api -n service-debug-lab -o wide
- kubectl get endpointslices -n service-debug-lab -l kubernetes.io/service-name=echo-api

Reachability
- kubectl exec -n service-debug-lab net-debug -- wget -qO- http://echo-api:8080/healthz
- kubectl get svc echo-api -n service-debug-lab -o jsonpath='{.spec.ports[0].targetPort}'
EOF_CHECKLIST
kubectl get configmap service-exposure-brief -n service-debug-lab -o yaml > /tmp/exam/q1/service-exposure-brief.yaml
[ -s /tmp/exam/q1/service-exposure-brief.yaml ]
[ -s /tmp/exam/q1/service-exposure-checklist.txt ]
COMMAND
      ;;
    *)
      echo "Unknown suite: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

run_suite() {
  local suite="$1"
  local expected_namespace="$2"
  local solve_command="$3"

  if [ "$(sudo systemctl is-active podman.socket || true)" != "active" ]; then
    log "Starting podman.socket"
    sudo systemctl start podman.socket
  fi

  log "Resetting stack for ${suite}"
  compose_cmd down -v >/dev/null 2>&1 || true
  compose_cmd up -d --build --force-recreate >/dev/null

  log "Waiting for stack readiness"
  wait_for_http
  wait_for_health

  log "Creating ${suite} exam"
  local create_response
  create_response="$(curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams" \
    -H 'Content-Type: application/json' \
    -d "{\"examId\":\"${suite}\"}")"
  CURRENT_EXAM="$(printf '%s' "$create_response" | jq -r '.id')"

  wait_for_exam_status READY

  log "Validating question routing metadata"
  local question_response
  question_response="$(curl -fsS "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/questions")"
  printf '%s' "$question_response" | jq -e '.questions | length == 1' >/dev/null
  printf '%s' "$question_response" | jq -e --arg namespace "$expected_namespace" '.questions[0].namespace == $namespace' >/dev/null
  printf '%s' "$question_response" | jq -e '.questions[0].machineHostname == "ckad9999"' >/dev/null

  log "Applying the expected solution for ${suite}"
  shared_exec "$solve_command"
  post_solve_check "$suite"

  log "Running evaluation for ${suite}"
  curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/evaluate" \
    -H 'Content-Type: application/json' \
    -d '{}' >/dev/null
  wait_for_evaluated

  local result
  result="$(curl -fsS "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/result")"
  printf '%s' "$result" | jq -e '
    (.data // .) as $result |
    $result.percentageScore == 100 and
    ([$result.evaluationResults[].verificationResults[].validAnswer] | all)
  ' >/dev/null || {
    printf '%s\n' "$result" >&2
    exit 1
  }

  log "Terminating ${suite} exam and verifying cleanup"
  curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/terminate" >/dev/null
  CURRENT_EXAM=""
  wait_for_no_current_exam
  wait_for_no_inner_clusters

  log "${suite} single-domain drill passed"
}

run_suite_with_timeout() {
  local suite="$1"
  local expected_namespace="$2"
  local solve_command="$3"
  local started_at elapsed exit_code

  started_at="$(date +%s)"
  set +e
  if [ "$SUITE_TIMEOUT_SECONDS" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    timeout --foreground "${SUITE_TIMEOUT_SECONDS}s" bash -lc "$(printf '%q ' declare -f log require_command compose_cmd cleanup wait_for_http wait_for_health wait_for_exam_status wait_for_evaluated wait_for_no_current_exam wait_for_no_inner_clusters shared_exec post_solve_check run_suite); CURRENT_EXAM=''; ROOT_DIR=$(printf '%q' "$ROOT_DIR"); BASE_URL=$(printf '%q' "$BASE_URL"); HTTP_WAIT_ATTEMPTS=$(printf '%q' "$HTTP_WAIT_ATTEMPTS"); HEALTH_WAIT_ATTEMPTS=$(printf '%q' "$HEALTH_WAIT_ATTEMPTS"); EXAM_STATUS_WAIT_ATTEMPTS=$(printf '%q' "$EXAM_STATUS_WAIT_ATTEMPTS"); EVALUATED_WAIT_ATTEMPTS=$(printf '%q' "$EVALUATED_WAIT_ATTEMPTS"); CLEANUP_WAIT_ATTEMPTS=$(printf '%q' "$CLEANUP_WAIT_ATTEMPTS"); trap cleanup EXIT; run_suite $(printf '%q' "$suite") $(printf '%q' "$expected_namespace") $(printf '%q' "$solve_command")"
    exit_code=$?
  else
    run_suite "$suite" "$expected_namespace" "$solve_command"
    exit_code=$?
  fi
  set -e

  elapsed="$(( $(date +%s) - started_at ))"
  if [ "$exit_code" -eq 0 ]; then
    log "${suite} smoke completed successfully in ${elapsed}s"
    return 0
  fi

  if [ "$SUITE_TIMEOUT_SECONDS" -gt 0 ] && [ "$exit_code" -eq 124 ]; then
    log "${suite} smoke timed out after ${SUITE_TIMEOUT_SECONDS}s"
  else
    log "${suite} smoke failed after ${elapsed}s with exit code ${exit_code}"
  fi

  return "$exit_code"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if ! [[ "$SUITE_TIMEOUT_SECONDS" =~ ^[0-9]+$ ]]; then
  echo "SUITE_TIMEOUT_SECONDS must be a non-negative integer: $SUITE_TIMEOUT_SECONDS" >&2
  exit 1
fi

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013 cka-014 cka-015 cka-016 cka-017 cka-018 cka-019 cka-020 cka-021
  exit 0
fi

require_command curl
require_command jq
require_command sudo
require_command podman

SUITES=("$@")
if [ "${#SUITES[@]}" -eq 0 ]; then
  SUITES=(cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013 cka-014 cka-015 cka-016 cka-017 cka-018 cka-019 cka-020 cka-021)
fi

for suite in "${SUITES[@]}"; do
  namespace="$(resolve_suite_namespace "$suite")"
  solve_command="$(resolve_solve_command "$suite")"
  log "Running ${suite} single-domain smoke"
  run_suite_with_timeout "$suite" "$namespace" "$solve_command"
done

log "Selected CKA 2026 single-domain drill smokes completed"
