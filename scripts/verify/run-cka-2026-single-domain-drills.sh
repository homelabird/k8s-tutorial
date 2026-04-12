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
  ./scripts/verify/run-cka-2026-single-domain-drills.sh cka-006 cka-013
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
    timeout --foreground "${SUITE_TIMEOUT_SECONDS}s" bash -lc "$(printf '%q ' declare -f log require_command compose_cmd cleanup wait_for_http wait_for_health wait_for_exam_status wait_for_evaluated wait_for_no_current_exam wait_for_no_inner_clusters shared_exec run_suite); CURRENT_EXAM=''; ROOT_DIR=$(printf '%q' "$ROOT_DIR"); BASE_URL=$(printf '%q' "$BASE_URL"); HTTP_WAIT_ATTEMPTS=$(printf '%q' "$HTTP_WAIT_ATTEMPTS"); HEALTH_WAIT_ATTEMPTS=$(printf '%q' "$HEALTH_WAIT_ATTEMPTS"); EXAM_STATUS_WAIT_ATTEMPTS=$(printf '%q' "$EXAM_STATUS_WAIT_ATTEMPTS"); EVALUATED_WAIT_ATTEMPTS=$(printf '%q' "$EVALUATED_WAIT_ATTEMPTS"); CLEANUP_WAIT_ATTEMPTS=$(printf '%q' "$CLEANUP_WAIT_ATTEMPTS"); trap cleanup EXIT; run_suite $(printf '%q' "$suite") $(printf '%q' "$expected_namespace") $(printf '%q' "$solve_command")"
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
  printf '%s\n' cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013
  exit 0
fi

require_command curl
require_command jq
require_command sudo
require_command podman

SUITES=("$@")
if [ "${#SUITES[@]}" -eq 0 ]; then
  SUITES=(cka-006 cka-007 cka-008 cka-009 cka-010 cka-011 cka-012 cka-013)
fi

for suite in "${SUITES[@]}"; do
  namespace="$(resolve_suite_namespace "$suite")"
  solve_command="$(resolve_solve_command "$suite")"
  log "Running ${suite} single-domain smoke"
  run_suite_with_timeout "$suite" "$namespace" "$solve_command"
done

log "Selected CKA 2026 single-domain drill smokes completed"
