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

log "Creating cka-003 exam"
CREATE_RESPONSE="$(curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams" \
  -H 'Content-Type: application/json' \
  -d '{"examId":"cka-003"}')"
CURRENT_EXAM="$(printf '%s' "$CREATE_RESPONSE" | jq -r '.id')"

wait_for_exam_status READY

log "Validating question routing metadata"
QUESTION_SUMMARY="$(curl -fsS "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/questions" \
  | jq -r '.questions[] | "Q\(.id):\(.machineHostname):\(.environmentId)"')"
printf '%s\n' "$QUESTION_SUMMARY" | grep -Fx 'Q1:ckad9999:shared' >/dev/null
printf '%s\n' "$QUESTION_SUMMARY" | grep -Fx 'Q2:ckad9999:shared' >/dev/null
printf '%s\n' "$QUESTION_SUMMARY" | grep -Fx 'Q3:ckad9999:shared' >/dev/null

log "Waiting for helper pods used by the regression checks"
shared_exec "kubectl wait --for=condition=Ready pod/ingress-check -n ingress-lab --timeout=180s >/dev/null"
shared_exec "kubectl wait --for=condition=Ready pod/dns-check -n dns-lab --timeout=180s >/dev/null"

log "Checking cluster DNS stays healthy outside the dedicated dns-lab drill"
SHARED_DNS="$(shared_exec "kubectl -n ingress-lab exec ingress-check -- nslookup kubernetes.default.svc.cluster.local")"
printf '%s\n' "$SHARED_DNS" | grep -F 'kubernetes.default.svc.cluster.local' >/dev/null

log "Checking dedicated dns-lab CoreDNS is the only broken DNS path"
DEDICATED_DNS_POLICY="$(shared_exec "kubectl get pod dns-check -n dns-lab -o jsonpath='{.spec.dnsPolicy}'")"
DEDICATED_DNS_IP="$(shared_exec "kubectl get service coredns -n dns-lab -o jsonpath='{.spec.clusterIP}'")"
DEDICATED_NAMESERVER="$(shared_exec "kubectl get pod dns-check -n dns-lab -o jsonpath='{.spec.dnsConfig.nameservers[0]}'")"

[ "$DEDICATED_DNS_POLICY" = "None" ]
[ "$DEDICATED_NAMESERVER" = "$DEDICATED_DNS_IP" ]

set +e
DEDICATED_DNS_OUTPUT="$(shared_exec "kubectl exec -n dns-lab dns-check -- nslookup web.dns-lab.svc.cluster.local" 2>&1)"
DEDICATED_DNS_EXIT=$?
set -e

if [ "$DEDICATED_DNS_EXIT" -eq 0 ]; then
  echo "Expected dedicated dns-lab CoreDNS lookup to fail before fixing the drill" >&2
  exit 1
fi

printf '%s\n' "$DEDICATED_DNS_OUTPUT" | grep -E 'NXDOMAIN|SERVFAIL|REFUSED|can.t resolve|server can.t find|no servers could be reached' >/dev/null

log "Solving PSA, dedicated CoreDNS, and ingress questions"
shared_exec "kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: secure-workloads
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
---
apiVersion: v1
kind: Pod
metadata:
  name: restricted-shell
  namespace: secure-workloads
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: busybox
    image: busybox:1.36
    command: [\"sh\", \"-c\", \"sleep 3600\"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: [\"ALL\"]
EOF
kubectl wait --for=condition=Ready pod/restricted-shell -n secure-workloads --timeout=180s >/dev/null
kubectl get configmap coredns -n dns-lab -o yaml \
  | sed 's/kubernetes broken.local in-addr.arpa ip6.arpa/kubernetes cluster.local in-addr.arpa ip6.arpa/' \
  | kubectl apply -f - >/dev/null
kubectl rollout restart deployment coredns -n dns-lab >/dev/null
kubectl rollout status deployment coredns -n dns-lab --timeout=180s >/dev/null
resolved=0
for attempt in \$(seq 1 60); do
  if kubectl exec -n dns-lab dns-check -- sh -lc 'nslookup web.dns-lab.svc.cluster.local && wget -qO- http://web.dns-lab.svc.cluster.local >/dev/null'; then
    resolved=1
    break
  fi
  sleep 2
done
[ \"\$resolved\" -eq 1 ]
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace --set controller.service.type=NodePort --set controller.service.nodePorts.http=30080 >/dev/null
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=300s >/dev/null
until kubectl get endpoints ingress-nginx-controller-admission -n ingress-nginx -o jsonpath='{.subsets[0].addresses[0].ip}' >/dev/null 2>&1; do
  sleep 2
done
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: ingress-lab
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
EOF
CONTROLLER_IP=\$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}')
routed=0
for attempt in \$(seq 1 60); do
  if kubectl exec -n ingress-lab ingress-check -- sh -lc \"curl -fsS -H 'Host: app.example.local' http://\${CONTROLLER_IP}/ | grep -qi 'Welcome to nginx'\"; then
    routed=1
    break
  fi
  sleep 2
done
[ \"\$routed\" -eq 1 ]"

log "Running evaluation and expecting a full pass"
curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/evaluate" \
  -H 'Content-Type: application/json' \
  -d '{}' >/dev/null
wait_for_evaluated
RESULT="$(curl -fsS "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/result")"

printf '%s' "$RESULT" | jq -e '
  .data.percentageScore == 100 and
  ([.data.evaluationResults[].verificationResults[].validAnswer] | all)
' >/dev/null || {
  printf '%s\n' "$RESULT" >&2
  exit 1
}

log "Terminating exam and verifying cleanup"
curl -fsS -X POST "$BASE_URL/facilitator/api/v1/exams/$CURRENT_EXAM/terminate" >/dev/null
CURRENT_EXAM=""
wait_for_no_current_exam
wait_for_no_inner_clusters

log "cka-003 dedicated DNS regression passed"
