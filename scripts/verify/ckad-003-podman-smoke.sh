#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:30080}"
EXAM_TEMPLATE="${EXAM_TEMPLATE:-ckad-003}"
CURRENT_EXAM=""

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

assert_http_response() {
  local expected_status="$1"
  local body_file="$2"
  shift 2

  local actual_status
  actual_status="$(curl -sS -o "$body_file" -w '%{http_code}' "$@")"

  if [ "$actual_status" != "$expected_status" ]; then
    echo "Expected HTTP $expected_status but got $actual_status" >&2
    cat "$body_file" >&2
    exit 1
  fi
}

api_get() {
  curl -fsS "$@"
}

api_post() {
  curl -fsS -X POST "$@"
}

cleanup() {
  if [ -n "$CURRENT_EXAM" ]; then
    api_post "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/terminate" >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

wait_for_http() {
  until [ "$(curl -s -o /dev/null -w '%{http_code}' "$BASE_URL/")" = "200" ]; do
    sleep 2
  done
}

wait_for_health() {
  while sudo podman ps --format '{{.Names}} {{.Status}}' \
    | grep -E '^(kind-cluster|kind-cluster-dns|k8s-tutorial_remote-desktop_1|k8s-tutorial_webapp_1|k8s-tutorial_jumphost_1|k8s-tutorial_facilitator_1|k8s-tutorial_nginx_1) ' \
    | grep -vq '(healthy)'; do
    sleep 2
  done
}

wait_for_exam_status() {
  local exam_id="$1"
  local expected_status="$2"

  while [ "$(api_get "$BASE_URL/facilitator/api/v1/exams/$exam_id/status" | jq -r '.status')" != "$expected_status" ]; do
    sleep 2
  done
}

wait_for_no_current_exam() {
  while [ "$(curl -sS -o /tmp/ckx-current-exam.json -w '%{http_code}' "$BASE_URL/facilitator/api/v1/exams/current")" != "404" ]; do
    sleep 2
  done
}

wait_for_no_inner_clusters() {
  while sudo podman exec kind-cluster sh -lc "k3d cluster list | tail -n +2 | grep -q ." >/dev/null 2>&1; do
    sleep 2
  done
}

require_command curl
require_command jq
require_command sudo
require_command podman

log "Waiting for deployed stack"
wait_for_http
wait_for_health

log "Checking assessment catalog routes"
assert_http_response 200 /tmp/ckx-assessments-legacy.json \
  "$BASE_URL/facilitator/api/v1/assements/"
assert_http_response 200 /tmp/ckx-assessments-canonical.json \
  "$BASE_URL/facilitator/api/v1/assessments/"
cmp -s /tmp/ckx-assessments-legacy.json /tmp/ckx-assessments-canonical.json || {
  echo "Legacy and canonical assessment endpoints returned different payloads." >&2
  exit 1
}
cat /tmp/ckx-assessments-canonical.json | jq -e 'type == "array" and length > 0' >/dev/null

CURRENT_STATUS_CODE="$(curl -sS -o /tmp/ckx-current-exam.json -w '%{http_code}' "$BASE_URL/facilitator/api/v1/exams/current")"
if [ "$CURRENT_STATUS_CODE" = "200" ]; then
  echo "An exam is already active. Terminate it before running this smoke test." >&2
  exit 1
fi

log "Checking invalid request handling"
assert_http_response 400 /tmp/ckx-create-invalid.json \
  -X POST "$BASE_URL/facilitator/api/v1/exams/" \
  -H 'Content-Type: application/json' \
  -d '{}'
cat /tmp/ckx-create-invalid.json | jq -e '.error | contains("examId") or contains("assetPath")' >/dev/null

assert_http_response 400 /tmp/ckx-evaluate-invalid.json \
  -X POST "$BASE_URL/facilitator/api/v1/exams/test/evaluate" \
  -H 'Content-Type: application/json' \
  -d '[]'
cat /tmp/ckx-evaluate-invalid.json | jq -e '.error | contains("type object")' >/dev/null

assert_http_response 400 /tmp/ckx-json-invalid.json \
  -X POST "$BASE_URL/facilitator/api/v1/exams/test/evaluate" \
  -H 'Content-Type: application/json' \
  -d '"bad"'
cat /tmp/ckx-json-invalid.json | jq -e '.message == "Request body must be valid JSON"' >/dev/null

log "Creating ${EXAM_TEMPLATE} exam"
CREATE_RESPONSE="$(api_post "$BASE_URL/facilitator/api/v1/exams/" \
  -H 'Content-Type: application/json' \
  -d "{\"examId\":\"${EXAM_TEMPLATE}\"}")"
CURRENT_EXAM="$(printf '%s' "$CREATE_RESPONSE" | jq -r '.id')"

wait_for_exam_status "$CURRENT_EXAM" READY

log "Checking question metadata"
QUESTION_RESPONSE="$(api_get "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/questions")"
printf '%s' "$QUESTION_RESPONSE" | jq -e '.questions | length == 1' >/dev/null
printf '%s' "$QUESTION_RESPONSE" | jq -e '.questions[0].namespace == "app-team"' >/dev/null
printf '%s' "$QUESTION_RESPONSE" | jq -e '.questions[0].machineHostname == "ckad9999"' >/dev/null

log "Applying the expected solution through the facilitator SSH API"
SOLVE_COMMAND="$(cat <<'EOF'
export KUBECONFIG=/home/candidate/.kube/kubeconfig
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: app-team
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: app-team
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.27.0-alpine
YAML
kubectl rollout status deployment/web-frontend -n app-team --timeout=180s
EOF
)"

api_post "$BASE_URL/facilitator/api/v1/execute" \
  -H 'Content-Type: application/json' \
  -d "$(jq -cn --arg command "$SOLVE_COMMAND" '{command: $command}')" >/tmp/ckx-solve-response.json

cat /tmp/ckx-solve-response.json | jq -e '.exitCode == 0' >/dev/null

log "Starting evaluation"
api_post "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/evaluate" \
  -H 'Content-Type: application/json' \
  -d '{}' >/tmp/ckx-evaluate-response.json

wait_for_exam_status "$CURRENT_EXAM" EVALUATED

RESULT_RESPONSE="$(api_get "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/result")"
printf '%s' "$RESULT_RESPONSE" | jq -e '(.data.percentageScore // .percentageScore) == 100' >/dev/null
printf '%s' "$RESULT_RESPONSE" | jq -e '(.data.totalScore // .totalScore) == (.data.totalPossibleScore // .totalPossibleScore)' >/dev/null

log "Terminating exam and waiting for cleanup"
api_post "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/terminate" >/tmp/ckx-terminate-response.json
CURRENT_EXAM=""

wait_for_no_current_exam
wait_for_no_inner_clusters

RECENT_FACILITATOR_LOGS="$(sudo podman logs --tail 160 k8s-tutorial_facilitator_1 2>&1)"
printf '%s\n' "$RECENT_FACILITATOR_LOGS" | grep -F "Command : cleanup-exam-env, result" >/dev/null
printf '%s\n' "$RECENT_FACILITATOR_LOGS" | grep -F "Exam environment cleanup completed successfully" >/dev/null
if printf '%s\n' "$RECENT_FACILITATOR_LOGS" | grep -Fq "unknown shorthand flag: 'a' in -a"; then
  echo "Detected unsupported docker network prune flags in jumphost cleanup logs." >&2
  exit 1
fi

log "Podman CKAD smoke test passed"
