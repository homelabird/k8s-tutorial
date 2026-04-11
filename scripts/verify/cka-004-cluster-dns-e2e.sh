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

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
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

require_command curl
require_command jq
require_command sudo
require_command podman

if [ "$(sudo systemctl is-active podman.socket || true)" != "active" ]; then
  log "Starting podman.socket"
  sudo systemctl start podman.socket
fi

log "Resetting stack"
compose_cmd down -v >/dev/null 2>&1 || true
compose_cmd up -d --build --force-recreate >/dev/null

log "Waiting for stack readiness"
wait_for_http
wait_for_health

log "Creating cka-004 exam"
CREATE_RESPONSE="$(curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams" \
  -H 'Content-Type: application/json' \
  -d '{"examId":"cka-004"}')"
CURRENT_EXAM="$(printf '%s' "$CREATE_RESPONSE" | jq -r '.id')"

wait_for_exam_status READY

log "Validating question routing metadata"
QUESTION_SUMMARY="$(curl -fsS "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/questions" \
  | jq -r '.questions[] | "Q\(.id):\(.machineHostname):\(.environmentId)"')"
printf '%s\n' "$QUESTION_SUMMARY" | grep -Fx 'Q1:ckad9999:shared' >/dev/null

log "Waiting for dns-check helper pod"
shared_exec "kubectl wait --for=condition=Ready pod/dns-check -n dns-lab --timeout=180s >/dev/null"

log "Confirming cluster-wide CoreDNS config is broken before the fix"
DNS_POLICY="$(shared_exec "kubectl get pod dns-check -n dns-lab -o jsonpath='{.spec.dnsPolicy}'")"
[ -z "$DNS_POLICY" ] || [ "$DNS_POLICY" = "ClusterFirst" ]

BROKEN_READY=0
for attempt in $(seq 1 60); do
  COREFILE="$(shared_exec "kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}'" 2>/dev/null || true)"
  if ! printf '%s' "$COREFILE" | grep -F 'kubernetes broken.local in-addr.arpa ip6.arpa' >/dev/null; then
    sleep 2
    continue
  fi
  BROKEN_READY=1
  break
done

if [ "$BROKEN_READY" -ne 1 ]; then
  echo "Expected cluster CoreDNS config to contain broken.local before fixing CoreDNS" >&2
  printf '%s\n' "$COREFILE" >&2
  exit 1
fi

log "Fixing kube-system CoreDNS and waiting for cluster DNS recovery"
shared_exec "kubectl get configmap coredns -n kube-system -o yaml \
  | sed 's/kubernetes broken.local in-addr.arpa ip6.arpa/kubernetes cluster.local in-addr.arpa ip6.arpa/' \
  | kubectl apply -f - >/dev/null
kubectl rollout restart deployment coredns -n kube-system >/dev/null
kubectl rollout status deployment coredns -n kube-system --timeout=180s >/dev/null
recovered=0
for attempt in \$(seq 1 90); do
  if kubectl exec -n dns-lab dns-check -- sh -lc 'nslookup web.dns-lab.svc.cluster.local && nslookup kubernetes.default.svc.cluster.local && wget -qO- http://web.dns-lab.svc.cluster.local >/dev/null'; then
    recovered=1
    break
  fi
  sleep 2
done
[ \"\$recovered\" -eq 1 ]"

log "Running evaluation and expecting a full pass"
curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/evaluate" \
  -H 'Content-Type: application/json' \
  -d '{}' >/dev/null
wait_for_evaluated
RESULT="$(curl -fsS "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/result")"

printf '%s' "$RESULT" | jq -e '
  (.data // .) as $result |
  $result.percentageScore == 100 and
  ([$result.evaluationResults[].verificationResults[].validAnswer] | all)
' >/dev/null || {
  printf '%s\n' "$RESULT" >&2
  exit 1
}

log "Terminating exam and verifying cleanup"
curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/terminate" >/dev/null
CURRENT_EXAM=""
wait_for_no_current_exam
wait_for_no_inner_clusters

log "cka-004 cluster DNS regression passed"
