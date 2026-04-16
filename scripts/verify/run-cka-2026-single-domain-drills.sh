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
  ./scripts/verify/run-cka-2026-single-domain-drills.sh cka-006 cka-045
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
  cka-022  kubelet and node NotReady troubleshooting drill
  cka-023  PKI and certificate expiry troubleshooting drill
  cka-024  Resource quota and LimitRange troubleshooting drill
  cka-025  Container runtime and CRI endpoint diagnostics drill
  cka-026  StorageClass and dynamic provisioning diagnostics drill
  cka-027  PodDisruptionBudget and drain planning drill
  cka-028  StatefulSet identity and headless service diagnostics drill
  cka-029  DaemonSet rollout and node coverage diagnostics drill
  cka-030  CronJob schedule, suspend, and history diagnostics drill
  cka-031  Job completions, parallelism, and backoff diagnostics drill
  cka-032  Readiness, liveness, and startupProbe diagnostics drill
  cka-033  InitContainer and shared volume diagnostics drill
  cka-034  Pod anti-affinity and topology spread diagnostics drill
  cka-035  ServiceAccount identity and projected token diagnostics drill
  cka-036  Pod securityContext and fsGroup diagnostics drill
  cka-037  PriorityClass and preemption diagnostics drill
  cka-038  Pod resource requests, limits, and QoS diagnostics drill
  cka-039  ServiceAccount imagePullSecrets and private registry diagnostics drill
  cka-040  PersistentVolume reclaim policy and claimRef diagnostics drill
  cka-041  PersistentVolumeClaim expansion and resize diagnostics drill
  cka-042  Ephemeral containers and kubectl debug diagnostics drill
  cka-043  Static pod manifest and mirror pod diagnostics drill
  cka-044  Projected ConfigMap and Secret volume diagnostics drill
  cka-045  ConfigMap and Secret envFrom diagnostics drill

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
    cka-022) printf '%s\n' 'node-health-lab' ;;
    cka-023) printf '%s\n' 'pki-lab' ;;
    cka-024) printf '%s\n' 'quota-lab' ;;
    cka-025) printf '%s\n' 'runtime-lab' ;;
    cka-026) printf '%s\n' 'storageclass-lab' ;;
    cka-027) printf '%s\n' 'disruption-lab' ;;
    cka-028) printf '%s\n' 'stateful-lab' ;;
    cka-029) printf '%s\n' 'daemonset-lab' ;;
    cka-030) printf '%s\n' 'cronjob-lab' ;;
    cka-031) printf '%s\n' 'job-lab' ;;
    cka-032) printf '%s\n' 'probe-lab' ;;
    cka-033) printf '%s\n' 'init-lab' ;;
    cka-034) printf '%s\n' 'affinity-lab' ;;
    cka-035) printf '%s\n' 'identity-lab' ;;
    cka-036) printf '%s\n' 'securitycontext-lab' ;;
    cka-037) printf '%s\n' 'priority-lab' ;;
    cka-038) printf '%s\n' 'qos-lab' ;;
    cka-039) printf '%s\n' 'registry-auth-lab' ;;
    cka-040) printf '%s\n' 'pv-reclaim-lab' ;;
    cka-041) printf '%s\n' 'pv-resize-lab' ;;
    cka-042) printf '%s\n' 'debug-lab' ;;
    cka-043) printf '%s\n' 'staticpod-lab' ;;
    cka-044) printf '%s\n' 'projectedvolume-lab' ;;
    cka-045) printf '%s\n' 'envfrom-lab' ;;
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
    cka-022)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-recovery-brief
  namespace: node-health-lab
data:
  targetNode: kind-cluster-worker
  nodeConditionCheck: kubectl describe node kind-cluster-worker | grep -A3 Conditions
  kubeletServiceCheck: sudo systemctl status kubelet
  kubeletLogCheck: sudo journalctl -u kubelet -n 50
  configCheck: sudo test -f /var/lib/kubelet/config.yaml
  runtimeCheck: sudo crictl info
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/node-notready-checklist.txt
Node Conditions
- kubectl get nodes
- kubectl describe node kind-cluster-worker | grep -A3 Conditions

Kubelet Service
- sudo systemctl status kubelet
- sudo journalctl -u kubelet -n 50

Runtime and Config
- sudo crictl info
- sudo test -f /var/lib/kubelet/config.yaml
EOF_CHECKLIST
kubectl get configmap node-recovery-brief -n node-health-lab -o yaml > /tmp/exam/q1/node-recovery-brief.yaml
[ -s /tmp/exam/q1/node-recovery-brief.yaml ]
[ -s /tmp/exam/q1/node-notready-checklist.txt ]
COMMAND
      ;;
    cka-023)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: certificate-renewal-brief
  namespace: pki-lab
data:
  targetCertificate: /etc/kubernetes/pki/apiserver.crt
  expiryCheck: sudo kubeadm certs check-expiration
  dateInspection: sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
  kubeconfigCheck: sudo grep -n client-certificate-data /etc/kubernetes/admin.conf
  renewalCommand: sudo kubeadm certs renew apiserver
  readinessCheck: kubectl get --raw='/readyz?verbose'
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/certificate-expiry-checklist.txt
Certificate Inspection
- sudo kubeadm certs check-expiration
- sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
- sudo grep -n client-certificate-data /etc/kubernetes/admin.conf

Renewal Planning
- sudo kubeadm certs renew apiserver
- sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/exam/q1/kube-apiserver.yaml.bak

Post-Renewal Verification
- kubectl get --raw='/readyz?verbose'
- kubectl get pods -n kube-system -l component=kube-apiserver
EOF_CHECKLIST
kubectl get configmap certificate-renewal-brief -n pki-lab -o yaml > /tmp/exam/q1/certificate-renewal-brief.yaml
[ -s /tmp/exam/q1/certificate-renewal-brief.yaml ]
[ -s /tmp/exam/q1/certificate-expiry-checklist.txt ]
COMMAND
      ;;
    cka-024)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: resource-guardrails-brief
  namespace: quota-lab
data:
  targetNamespace: quota-lab
  quotaInspection: kubectl get resourcequota -n quota-lab
  quotaDescribe: kubectl describe resourcequota compute-quota -n quota-lab
  limitRangeInspection: kubectl describe limitrange default-limits -n quota-lab
  workloadInspection: kubectl describe deployment api -n quota-lab
  recommendedPatch: kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/resource-quota-checklist.txt
Quota Inspection
- kubectl get resourcequota -n quota-lab
- kubectl describe resourcequota compute-quota -n quota-lab

LimitRange Inspection
- kubectl describe limitrange default-limits -n quota-lab
- kubectl get limitrange default-limits -n quota-lab -o yaml

Workload Sizing Guidance
- kubectl describe deployment api -n quota-lab
- kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi
EOF_CHECKLIST
kubectl get configmap resource-guardrails-brief -n quota-lab -o yaml > /tmp/exam/q1/resource-guardrails-brief.yaml
[ -s /tmp/exam/q1/resource-guardrails-brief.yaml ]
[ -s /tmp/exam/q1/resource-quota-checklist.txt ]
COMMAND
      ;;
    cka-025)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: runtime-diagnostics-brief
  namespace: runtime-lab
data:
  targetNode: kind-cluster-control-plane
  kubeletConfigCheck: sudo grep -n containerRuntimeEndpoint /var/lib/kubelet/config.yaml
  runtimeSocketCheck: sudo test -S /run/containerd/containerd.sock
  crictlInfoCheck: sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info
  crictlPodsCheck: sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock pods
  runtimeServiceCheck: sudo systemctl status containerd
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/runtime-diagnostics-checklist.txt
Kubelet Wiring
- sudo grep -n containerRuntimeEndpoint /var/lib/kubelet/config.yaml
- sudo test -f /var/lib/kubelet/config.yaml

CRI Connectivity
- sudo test -S /run/containerd/containerd.sock
- sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info
- sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock pods

Runtime Service
- sudo systemctl status containerd
- sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock ps -a
EOF_CHECKLIST
kubectl get configmap runtime-diagnostics-brief -n runtime-lab -o yaml > /tmp/exam/q1/runtime-diagnostics-brief.yaml
[ -s /tmp/exam/q1/runtime-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/runtime-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-026)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: dynamic-provisioning-brief
  namespace: storageclass-lab
data:
  targetNamespace: storageclass-lab
  targetPVC: reports-pvc
  targetStorageClass: exam-standard
  storageClassInventory: kubectl get storageclass
  defaultClassCheck: kubectl get storageclass -o custom-columns=NAME:.metadata.name,DEFAULT:.metadata.annotations.storageclass\.kubernetes\.io/is-default-class
  pvcDescribe: kubectl describe pvc reports-pvc -n storageclass-lab
  workloadDescribe: kubectl describe pod reports-api -n storageclass-lab
  eventCheck: kubectl get events -n storageclass-lab --sort-by=.lastTimestamp
  recommendedManifestLine: 'storageClassName: exam-standard'
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/dynamic-provisioning-checklist.txt
StorageClass Inventory
- kubectl get storageclass
- kubectl get storageclass -o custom-columns=NAME:.metadata.name,DEFAULT:.metadata.annotations.storageclass\.kubernetes\.io/is-default-class

PVC Analysis
- kubectl describe pvc reports-pvc -n storageclass-lab
- kubectl describe pod reports-api -n storageclass-lab
- kubectl get events -n storageclass-lab --sort-by=.lastTimestamp

Safe Manifest Fix
- kubectl get pvc reports-pvc -n storageclass-lab -o yaml
- ensure the manifest contains storageClassName: exam-standard
EOF_CHECKLIST
kubectl get configmap dynamic-provisioning-brief -n storageclass-lab -o yaml > /tmp/exam/q1/dynamic-provisioning-brief.yaml
[ -s /tmp/exam/q1/dynamic-provisioning-brief.yaml ]
[ -s /tmp/exam/q1/dynamic-provisioning-checklist.txt ]
COMMAND
      ;;
    cka-027)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: disruption-planning-brief
  namespace: disruption-lab
data:
  targetNode: kind-cluster-worker
  pdbInventory: kubectl get pdb -A
  pdbDescribe: kubectl describe pdb api-pdb -n disruption-lab
  nodeWorkloadCheck: kubectl get pods -A -o wide --field-selector spec.nodeName=kind-cluster-worker
  cordonCommand: kubectl cordon kind-cluster-worker
  drainPreview: kubectl drain kind-cluster-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client
  uncordonCommand: kubectl uncordon kind-cluster-worker
  safeRemediationNote: review PodDisruptionBudget impact before any non-dry-run drain
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/disruption-planning-checklist.txt
PDB Inventory
- kubectl get pdb -A
- kubectl describe pdb api-pdb -n disruption-lab

Node Workload Audit
- kubectl get pods -A -o wide --field-selector spec.nodeName=kind-cluster-worker
- kubectl get deploy api -n disruption-lab

Safe Drain Sequence
- kubectl cordon kind-cluster-worker
- kubectl drain kind-cluster-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client
- review PodDisruptionBudget impact before any non-dry-run drain
- kubectl uncordon kind-cluster-worker
EOF_CHECKLIST
kubectl get configmap disruption-planning-brief -n disruption-lab -o yaml > /tmp/exam/q1/disruption-planning-brief.yaml
[ -s /tmp/exam/q1/disruption-planning-brief.yaml ]
[ -s /tmp/exam/q1/disruption-planning-checklist.txt ]
COMMAND
      ;;
    cka-028)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: stateful-identity-brief
  namespace: stateful-lab
data:
  targetStatefulSet: web
  headlessService: web-svc
  statefulSetInventory: kubectl get statefulset web -n stateful-lab -o wide
  serviceInspection: kubectl get svc web-svc -n stateful-lab -o yaml
  podInventory: kubectl get pods -n stateful-lab -l app=web -o wide
  ordinalDnsCheck: kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local
  pvcInventory: kubectl get pvc -n stateful-lab
  safeManifestNote: "confirm serviceName: web-svc and stable pod ordinals before changing manifests"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/stateful-identity-checklist.txt
StatefulSet Inventory
- kubectl get statefulset web -n stateful-lab -o wide
- kubectl get pods -n stateful-lab -l app=web -o wide

Stable Network Identity
- kubectl get svc web-svc -n stateful-lab -o yaml
- kubectl exec -n stateful-lab dns-debug -- nslookup web-0.web-svc.stateful-lab.svc.cluster.local

Safe Manifest Review
- kubectl get pvc -n stateful-lab
- confirm serviceName: web-svc and stable pod ordinals before changing manifests
EOF_CHECKLIST
kubectl get configmap stateful-identity-brief -n stateful-lab -o yaml > /tmp/exam/q1/stateful-identity-brief.yaml
[ -s /tmp/exam/q1/stateful-identity-brief.yaml ]
[ -s /tmp/exam/q1/stateful-identity-checklist.txt ]
COMMAND
      ;;
    cka-029)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: daemonset-rollout-brief
  namespace: daemonset-lab
data:
  targetDaemonSet: log-agent
  daemonSetInventory: kubectl get daemonset log-agent -n daemonset-lab -o wide
  rolloutStatusCheck: kubectl rollout status daemonset/log-agent -n daemonset-lab --timeout=180s
  nodeInventory: kubectl get nodes -o wide
  nodeCoverageCheck: kubectl get pods -n daemonset-lab -l app=log-agent -o wide
  updateStrategyCheck: kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.updateStrategy.type}'
  safeManifestNote: "confirm desiredNumberScheduled matches running pods before changing DaemonSet manifests"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/daemonset-rollout-checklist.txt
DaemonSet Inventory
- kubectl get daemonset log-agent -n daemonset-lab -o wide
- kubectl rollout status daemonset/log-agent -n daemonset-lab --timeout=180s

Node Coverage
- kubectl get nodes -o wide
- kubectl get pods -n daemonset-lab -l app=log-agent -o wide

Safe Rollout Review
- kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.updateStrategy.type}'
- confirm desiredNumberScheduled matches running pods before changing DaemonSet manifests
EOF_CHECKLIST
kubectl get configmap daemonset-rollout-brief -n daemonset-lab -o yaml > /tmp/exam/q1/daemonset-rollout-brief.yaml
[ -s /tmp/exam/q1/daemonset-rollout-brief.yaml ]
[ -s /tmp/exam/q1/daemonset-rollout-checklist.txt ]
COMMAND
      ;;
    cka-030)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cronjob-diagnostics-brief
  namespace: cronjob-lab
data:
  targetCronJob: log-pruner
  cronJobInventory: kubectl get cronjob log-pruner -n cronjob-lab -o wide
  scheduleCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.schedule}'
  suspendCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.suspend}'
  concurrencyPolicyCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.concurrencyPolicy}'
  historyLimitsCheck: kubectl get cronjob log-pruner -n cronjob-lab -o custom-columns=SUCCESS:.spec.successfulJobsHistoryLimit,FAILED:.spec.failedJobsHistoryLimit
  jobTemplateCheck: kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}'
  safeManifestNote: "confirm schedule, suspend=false, and history limits before changing the CronJob manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/cronjob-diagnostics-checklist.txt
CronJob Inventory
- kubectl get cronjob log-pruner -n cronjob-lab -o wide

Scheduling Checks
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.schedule}'
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.suspend}'
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.concurrencyPolicy}'
- kubectl get cronjob log-pruner -n cronjob-lab -o custom-columns=SUCCESS:.spec.successfulJobsHistoryLimit,FAILED:.spec.failedJobsHistoryLimit
- kubectl get cronjob log-pruner -n cronjob-lab -o jsonpath='{.spec.jobTemplate.spec.template.spec.restartPolicy}'

Safe Manifest Review
- confirm schedule, suspend=false, and history limits before changing the CronJob manifest
EOF_CHECKLIST
kubectl get configmap cronjob-diagnostics-brief -n cronjob-lab -o yaml > /tmp/exam/q1/cronjob-diagnostics-brief.yaml
[ -s /tmp/exam/q1/cronjob-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/cronjob-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-031)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: job-diagnostics-brief
  namespace: job-lab
data:
  targetJob: report-batch
  jobInventory: kubectl get job report-batch -n job-lab -o wide
  completionsCheck: kubectl get job report-batch -n job-lab -o jsonpath='{.spec.completions}'
  parallelismCheck: kubectl get job report-batch -n job-lab -o jsonpath='{.spec.parallelism}'
  backoffLimitCheck: kubectl get job report-batch -n job-lab -o jsonpath='{.spec.backoffLimit}'
  podEvidenceCheck: kubectl get pods -n job-lab -l job-name=report-batch -o wide
  jobDescribeCheck: kubectl describe job report-batch -n job-lab
  safeManifestNote: "confirm completions, parallelism, backoffLimit, and pod template command before changing the Job manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/job-diagnostics-checklist.txt
Job Inventory
- kubectl get job report-batch -n job-lab -o wide
- kubectl get job report-batch -n job-lab -o jsonpath='{.spec.completions}'
- kubectl get job report-batch -n job-lab -o jsonpath='{.spec.parallelism}'
- kubectl get job report-batch -n job-lab -o jsonpath='{.spec.backoffLimit}'

Pod Evidence
- kubectl get pods -n job-lab -l job-name=report-batch -o wide
- kubectl describe job report-batch -n job-lab

Safe Manifest Review
- confirm completions, parallelism, backoffLimit, and pod template command before changing the Job manifest
EOF_CHECKLIST
kubectl get configmap job-diagnostics-brief -n job-lab -o yaml > /tmp/exam/q1/job-diagnostics-brief.yaml
[ -s /tmp/exam/q1/job-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/job-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-032)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-diagnostics-brief
  namespace: probe-lab
data:
  targetDeployment: health-api
  deploymentInventory: kubectl get deployment health-api -n probe-lab -o wide
  startupProbeCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}'
  livenessProbeCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}'
  readinessProbeCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}'
  portCheck: kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'
  eventCheck: kubectl get events -n probe-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm startup, liveness, readiness probe paths and thresholds before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/probe-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment health-api -n probe-lab -o wide
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'

Probe Checks
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].startupProbe.httpGet.path}'
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.path}'
- kubectl get deployment health-api -n probe-lab -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}'
- kubectl get events -n probe-lab --sort-by=.lastTimestamp

Safe Manifest Review
- confirm startup, liveness, readiness probe paths and thresholds before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap probe-diagnostics-brief -n probe-lab -o yaml > /tmp/exam/q1/probe-diagnostics-brief.yaml
[ -s /tmp/exam/q1/probe-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/probe-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-033)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: init-diagnostics-brief
  namespace: init-lab
data:
  targetDeployment: report-api
  deploymentInventory: kubectl get deployment report-api -n init-lab -o wide
  initContainerInventory: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'
  initCommandCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'
  sharedVolumeCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'
  initMountCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'
  appMountCheck: kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n init-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm init container command, shared volume name, and mount paths before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/init-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment report-api -n init-lab -o wide
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'

Init Container Checks
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'
- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n init-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment report-api -n init-lab -o yaml
- confirm init container command, shared volume name, and mount paths before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap init-diagnostics-brief -n init-lab -o yaml > /tmp/exam/q1/init-diagnostics-brief.yaml
[ -s /tmp/exam/q1/init-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/init-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-034)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: placement-diagnostics-brief
  namespace: affinity-lab
data:
  targetDeployment: api-fleet
  deploymentInventory: kubectl get deployment api-fleet -n affinity-lab -o wide
  replicaCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'
  antiAffinityTopologyCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'
  antiAffinitySelectorCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'
  topologySpreadKeyCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'
  maxSkewCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'
  whenUnsatisfiableCheck: kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'
  eventCheck: kubectl get events -n affinity-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/placement-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment api-fleet -n affinity-lab -o wide
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'

Placement Checks
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'
- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'
- kubectl get events -n affinity-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment api-fleet -n affinity-lab -o yaml
- confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap placement-diagnostics-brief -n affinity-lab -o yaml > /tmp/exam/q1/placement-diagnostics-brief.yaml
[ -s /tmp/exam/q1/placement-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/placement-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-035)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: identity-diagnostics-brief
  namespace: identity-lab
data:
  targetDeployment: metrics-api
  deploymentInventory: kubectl get deployment metrics-api -n identity-lab -o wide
  serviceAccountCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'
  automountCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'
  projectedTokenPathCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'
  projectedAudienceCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'
  mountPathCheck: kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n identity-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/identity-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment metrics-api -n identity-lab -o wide
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'

Identity Checks
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'
- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n identity-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment metrics-api -n identity-lab -o yaml
- confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap identity-diagnostics-brief -n identity-lab -o yaml > /tmp/exam/q1/identity-diagnostics-brief.yaml
[ -s /tmp/exam/q1/identity-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/identity-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-036)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: securitycontext-diagnostics-brief
  namespace: securitycontext-lab
data:
  targetDeployment: secure-api
  deploymentInventory: kubectl get deployment secure-api -n securitycontext-lab -o wide
  runAsUserCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'
  fsGroupCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'
  seccompCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'
  allowPrivilegeEscalationCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'
  capabilitiesDropCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'
  mountPathCheck: kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/securitycontext-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment secure-api -n securitycontext-lab -o wide
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'

Security Context Checks
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'
- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment secure-api -n securitycontext-lab -o yaml
- confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap securitycontext-diagnostics-brief -n securitycontext-lab -o yaml > /tmp/exam/q1/securitycontext-diagnostics-brief.yaml
[ -s /tmp/exam/q1/securitycontext-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/securitycontext-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-037)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: priority-diagnostics-brief
  namespace: priority-lab
data:
  targetDeployment: batch-api
  targetPriorityClass: ops-critical
  priorityClassInventory: kubectl get priorityclass ops-critical -o yaml
  deploymentInventory: kubectl get deployment batch-api -n priority-lab -o wide
  priorityClassNameCheck: kubectl get deployment batch-api -n priority-lab -o jsonpath='{.spec.template.spec.priorityClassName}'
  priorityValueCheck: kubectl get priorityclass ops-critical -o jsonpath='{.value}'
  preemptionPolicyCheck: kubectl get priorityclass ops-critical -o jsonpath='{.preemptionPolicy}'
  globalDefaultCheck: kubectl get priorityclass ops-critical -o jsonpath='{.globalDefault}'
  schedulerCheck: kubectl get pods -n priority-lab -o wide
  eventCheck: kubectl get events -n priority-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm priorityClassName, priority value, preemption policy, and scheduler events before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/priority-diagnostics-checklist.txt
PriorityClass Inventory
- kubectl get priorityclass ops-critical -o yaml
- kubectl get priorityclass ops-critical -o jsonpath='{.value}'
- kubectl get priorityclass ops-critical -o jsonpath='{.preemptionPolicy}'
- kubectl get priorityclass ops-critical -o jsonpath='{.globalDefault}'

Workload Checks
- kubectl get deployment batch-api -n priority-lab -o wide
- kubectl get deployment batch-api -n priority-lab -o jsonpath='{.spec.template.spec.priorityClassName}'
- kubectl get pods -n priority-lab -o wide
- kubectl get events -n priority-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment batch-api -n priority-lab -o yaml
- confirm priorityClassName, priority value, preemption policy, and scheduler events before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap priority-diagnostics-brief -n priority-lab -o yaml > /tmp/exam/q1/priority-diagnostics-brief.yaml
[ -s /tmp/exam/q1/priority-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/priority-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-038)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: qos-diagnostics-brief
  namespace: qos-lab
data:
  targetDeployment: reporting-api
  deploymentInventory: kubectl get deployment reporting-api -n qos-lab -o wide
  requestsCpuCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}'
  requestsMemoryCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}'
  limitsCpuCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}'
  limitsMemoryCheck: kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}'
  qosClassCheck: kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}'
  eventCheck: kubectl get events -n qos-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm requests, limits, QoS class, and namespace events before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/qos-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment reporting-api -n qos-lab -o wide

Resource Checks
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}'
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}'
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}'
- kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}'
- kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}'
- kubectl get events -n qos-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment reporting-api -n qos-lab -o yaml
- confirm requests, limits, QoS class, and namespace events before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap qos-diagnostics-brief -n qos-lab -o yaml > /tmp/exam/q1/qos-diagnostics-brief.yaml
[ -s /tmp/exam/q1/qos-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/qos-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-039)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: pull-auth-diagnostics-brief
  namespace: registry-auth-lab
data:
  targetDeployment: private-api
  deploymentInventory: kubectl get deployment private-api -n registry-auth-lab -o wide
  serviceAccountCheck: kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'
  imagePullSecretsCheck: kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.imagePullSecrets[*].name}'
  imageReferenceCheck: kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  secretTypeCheck: kubectl get secret regcred -n registry-auth-lab -o jsonpath='{.type}'
  serviceAccountSecretCheck: kubectl get serviceaccount puller -n registry-auth-lab -o jsonpath='{.imagePullSecrets[*].name}'
  eventCheck: kubectl get events -n registry-auth-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm imagePullSecrets, ServiceAccount wiring, secret type, and image reference before changing the Deployment manifest"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/pull-auth-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment private-api -n registry-auth-lab -o wide

Pull Secret Checks
- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'
- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.imagePullSecrets[*].name}'
- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
- kubectl get secret regcred -n registry-auth-lab -o jsonpath='{.type}'
- kubectl get serviceaccount puller -n registry-auth-lab -o jsonpath='{.imagePullSecrets[*].name}'
- kubectl get events -n registry-auth-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment private-api -n registry-auth-lab -o yaml
- confirm imagePullSecrets, ServiceAccount wiring, secret type, and image reference before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap pull-auth-diagnostics-brief -n registry-auth-lab -o yaml > /tmp/exam/q1/pull-auth-diagnostics-brief.yaml
[ -s /tmp/exam/q1/pull-auth-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/pull-auth-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-040)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: reclaim-diagnostics-brief
  namespace: pv-reclaim-lab
data:
  targetPvc: reports-data
  pvcInventory: kubectl get pvc reports-data -n pv-reclaim-lab -o wide
  volumeNameCheck: kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.volumeName}'
  storageClassCheck: kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.storageClassName}'
  reclaimPolicyCheck: kubectl get pv reports-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
  claimRefCheck: kubectl get pv reports-pv -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}'
  mountPathCheck: kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n pv-reclaim-lab --sort-by=.lastTimestamp
  safeManifestNote: "confirm PVC binding, PV reclaim policy, claimRef, and workload mount path before changing storage manifests"
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/reclaim-diagnostics-checklist.txt
PVC Inventory
- kubectl get pvc reports-data -n pv-reclaim-lab -o wide
- kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.volumeName}'
- kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.storageClassName}'

PV Checks
- kubectl get pv reports-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'
- kubectl get pv reports-pv -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}'
- kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n pv-reclaim-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment reports-db -n pv-reclaim-lab -o yaml
- kubectl get pv reports-pv -o yaml
- confirm PVC binding, PV reclaim policy, claimRef, and workload mount path before changing storage manifests
EOF_CHECKLIST
kubectl get configmap reclaim-diagnostics-brief -n pv-reclaim-lab -o yaml > /tmp/exam/q1/reclaim-diagnostics-brief.yaml
[ -s /tmp/exam/q1/reclaim-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/reclaim-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-041)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: resize-diagnostics-brief
  namespace: pv-resize-lab
data:
  targetPvc: analytics-data
  pvcInventory: kubectl get pvc analytics-data -n pv-resize-lab -o wide
  requestedSizeCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.resources.requests.storage}'
  currentCapacityCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.capacity.storage}'
  storageClassCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.storageClassName}'
  allowExpansionCheck: kubectl get storageclass expandable-reports -o jsonpath='{.allowVolumeExpansion}'
  conditionCheck: kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.conditions[*].type}'
  mountPathCheck: kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  eventCheck: kubectl get events -n pv-resize-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm requested size, current capacity, resize support, PVC conditions, and mount path before changing storage manifests
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/resize-diagnostics-checklist.txt
PVC Inventory
- kubectl get pvc analytics-data -n pv-resize-lab -o wide
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.resources.requests.storage}'
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.capacity.storage}'
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.storageClassName}'

Resize Checks
- kubectl get storageclass expandable-reports -o jsonpath='{.allowVolumeExpansion}'
- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.conditions[*].type}'
- kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get events -n pv-resize-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment analytics-api -n pv-resize-lab -o yaml
- kubectl get pvc analytics-data -n pv-resize-lab -o yaml
- confirm requested size, current capacity, resize support, PVC conditions, and mount path before changing storage manifests
EOF_CHECKLIST
kubectl get configmap resize-diagnostics-brief -n pv-resize-lab -o yaml > /tmp/exam/q1/resize-diagnostics-brief.yaml
[ -s /tmp/exam/q1/resize-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/resize-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-042)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: debug-diagnostics-brief
  namespace: debug-lab
data:
  targetPod: orders-api
  podInventory: kubectl get pod orders-api -n debug-lab -o wide
  containerInventory: kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.containers[*].name}'
  logsCheck: kubectl logs orders-api -n debug-lab -c api --tail=50
  nodeCheck: kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.nodeName}'
  debugCommand: kubectl debug pod/orders-api -n debug-lab -it --image=busybox:1.36 --target=api
  ephemeralContainerCheck: kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[*].name}'
  eventCheck: kubectl get events -n debug-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm target pod, target container, debug image, and ephemeral container evidence before changing workload manifests
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/debug-diagnostics-checklist.txt
Pod Inventory
- kubectl get pod orders-api -n debug-lab -o wide
- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.containers[*].name}'
- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.nodeName}'

Debug Path
- kubectl logs orders-api -n debug-lab -c api --tail=50
- kubectl debug pod/orders-api -n debug-lab -it --image=busybox:1.36 --target=api
- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[*].name}'
- kubectl get events -n debug-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get pod orders-api -n debug-lab -o yaml
- confirm target pod, target container, debug image, and ephemeral container evidence before changing workload manifests
EOF_CHECKLIST
kubectl get configmap debug-diagnostics-brief -n debug-lab -o yaml > /tmp/exam/q1/debug-diagnostics-brief.yaml
[ -s /tmp/exam/q1/debug-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/debug-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-043)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: staticpod-diagnostics-brief
  namespace: staticpod-lab
data:
  targetMirrorPod: audit-agent-ckad9999
  mirrorPodInventory: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o wide
  staticPodPathCheck: sudo ls -l /etc/kubernetes/manifests/audit-agent.yaml
  manifestPreviewCheck: sudo sed -n '1,160p' /etc/kubernetes/manifests/audit-agent.yaml
  hostNetworkCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.hostNetwork}'
  containerCommandCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.containers[0].command}'
  nodeCheck: kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.nodeName}'
  eventCheck: kubectl get events -n staticpod-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm manifest path, mirror pod inventory, hostNetwork setting, and container command before changing static pod manifests
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/staticpod-diagnostics-checklist.txt
Mirror Pod Inventory
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o wide
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.nodeName}'

Static Pod Checks
- sudo ls -l /etc/kubernetes/manifests/audit-agent.yaml
- sudo sed -n '1,160p' /etc/kubernetes/manifests/audit-agent.yaml
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.hostNetwork}'
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.containers[0].command}'
- kubectl get events -n staticpod-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o yaml
- confirm manifest path, mirror pod inventory, hostNetwork setting, and container command before changing static pod manifests
EOF_CHECKLIST
kubectl get configmap staticpod-diagnostics-brief -n staticpod-lab -o yaml > /tmp/exam/q1/staticpod-diagnostics-brief.yaml
[ -s /tmp/exam/q1/staticpod-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/staticpod-diagnostics-checklist.txt ]
COMMAND
      ;;
    cka-044)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: projected-volume-brief
  namespace: projectedvolume-lab
data:
  targetDeployment: bundle-api
  deploymentInventory: kubectl get deployment bundle-api -n projectedvolume-lab -o wide
  configMapNameCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.name}'
  configMapItemPathCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.items[0].path}'
  secretNameCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.name}'
  secretItemPathCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.items[0].path}'
  mountPathCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
  readOnlyCheck: kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'
  eventCheck: kubectl get events -n projectedvolume-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/projected-volume-checklist.txt
Deployment Inventory
- kubectl get deployment bundle-api -n projectedvolume-lab -o wide
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.name}'

Projected Volume Checks
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.items[0].path}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.name}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.items[0].path}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'
- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'
- kubectl get events -n projectedvolume-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment bundle-api -n projectedvolume-lab -o yaml
- confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap projected-volume-brief -n projectedvolume-lab -o yaml > /tmp/exam/q1/projected-volume-brief.yaml
[ -s /tmp/exam/q1/projected-volume-brief.yaml ]
[ -s /tmp/exam/q1/projected-volume-checklist.txt ]
COMMAND
      ;;
    cka-045)
      cat <<'COMMAND'
cat <<'EOF_BRIEF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: envfrom-diagnostics-brief
  namespace: envfrom-lab
data:
  targetDeployment: env-bundle
  deploymentInventory: kubectl get deployment env-bundle -n envfrom-lab -o wide
  configMapEnvFromCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'
  secretEnvFromCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].secretRef.name}'
  prefixCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].prefix}'
  containerNameCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].name}'
  imageCheck: kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
  eventCheck: kubectl get events -n envfrom-lab --sort-by=.lastTimestamp
  safeManifestNote: confirm envFrom source order, secret prefix, and container name before changing the Deployment manifest
EOF_BRIEF
mkdir -p /tmp/exam/q1
cat <<'EOF_CHECKLIST' > /tmp/exam/q1/envfrom-diagnostics-checklist.txt
Deployment Inventory
- kubectl get deployment env-bundle -n envfrom-lab -o wide
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].name}'

EnvFrom Checks
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].secretRef.name}'
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].prefix}'
- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].image}'
- kubectl get events -n envfrom-lab --sort-by=.lastTimestamp

Safe Manifest Review
- kubectl get deployment env-bundle -n envfrom-lab -o yaml
- confirm envFrom source order, secret prefix, and container name before changing the Deployment manifest
EOF_CHECKLIST
kubectl get configmap envfrom-diagnostics-brief -n envfrom-lab -o yaml > /tmp/exam/q1/envfrom-diagnostics-brief.yaml
[ -s /tmp/exam/q1/envfrom-diagnostics-brief.yaml ]
[ -s /tmp/exam/q1/envfrom-diagnostics-checklist.txt ]
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
  local started_at elapsed exit_code timeout_script function_defs

  started_at="$(date +%s)"
  set +e
  if [ "$SUITE_TIMEOUT_SECONDS" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    function_defs="$(declare -f log require_command compose_cmd cleanup wait_for_http wait_for_health wait_for_exam_status wait_for_evaluated wait_for_no_current_exam wait_for_no_inner_clusters shared_exec post_solve_check run_suite)"
    printf -v timeout_script '%s\nCURRENT_EXAM=%q\nROOT_DIR=%q\nBASE_URL=%q\nHTTP_WAIT_ATTEMPTS=%q\nHEALTH_WAIT_ATTEMPTS=%q\nEXAM_STATUS_WAIT_ATTEMPTS=%q\nEVALUATED_WAIT_ATTEMPTS=%q\nCLEANUP_WAIT_ATTEMPTS=%q\ntrap cleanup EXIT\nrun_suite %q %q %q\n' \
      "$function_defs" \
      "" \
      "$ROOT_DIR" \
      "$BASE_URL" \
      "$HTTP_WAIT_ATTEMPTS" \
      "$HEALTH_WAIT_ATTEMPTS" \
      "$EXAM_STATUS_WAIT_ATTEMPTS" \
      "$EVALUATED_WAIT_ATTEMPTS" \
      "$CLEANUP_WAIT_ATTEMPTS" \
      "$suite" \
      "$expected_namespace" \
      "$solve_command"
    timeout --foreground "${SUITE_TIMEOUT_SECONDS}s" bash -lc "$timeout_script"
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
  printf '%s\n' cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013 cka-014 cka-015 cka-016 cka-017 cka-018 cka-019 cka-020 cka-021 cka-022 cka-023 cka-024 cka-025 cka-026 cka-027 cka-028 cka-029 cka-030 cka-031 cka-032 cka-033 cka-034 cka-035 cka-036 cka-037 cka-038 cka-039 cka-040 cka-041 cka-042 cka-043 cka-044 cka-045
  exit 0
fi

require_command curl
require_command jq
require_command sudo
require_command podman

SUITES=("$@")
if [ "${#SUITES[@]}" -eq 0 ]; then
  SUITES=(cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013 cka-014 cka-015 cka-016 cka-017 cka-018 cka-019 cka-020 cka-021 cka-022 cka-023 cka-024 cka-025 cka-026 cka-027 cka-028 cka-029 cka-030 cka-031 cka-032 cka-033 cka-034 cka-035 cka-036 cka-037 cka-038 cka-039 cka-040 cka-041 cka-042 cka-043 cka-044 cka-045)
fi

for suite in "${SUITES[@]}"; do
  namespace="$(resolve_suite_namespace "$suite")"
  solve_command="$(resolve_solve_command "$suite")"
  log "Running ${suite} single-domain smoke"
  run_suite_with_timeout "$suite" "$namespace" "$solve_command"
done

log "Selected CKA 2026 single-domain drill smokes completed"
