#!/bin/bash
set -euo pipefail

NAMESPACE="netpol-lab"
IMAGE="curlimages/curl:8.7.1"

ensure_probe_pod() {
  local name="$1"
  local app_label="$2"

  if ! kubectl get pod "$name" -n "$NAMESPACE" >/dev/null 2>&1; then
    kubectl run "$name" -n "$NAMESPACE" --image="$IMAGE" --labels="app=${app_label}" --restart=Never --command -- sleep 3600 >/dev/null
  fi

  kubectl wait --for=condition=Ready pod/"$name" -n "$NAMESPACE" --timeout=180s >/dev/null
}

expect_denied() {
  local pod_name="$1"
  local target="$2"

  if kubectl exec -n "$NAMESPACE" "$pod_name" -- sh -lc "curl -fsS --max-time 5 http://${target}/ >/dev/null"; then
    echo "Traffic from '$pod_name' to '$target' should be denied"
    exit 1
  fi
}

ensure_probe_pod frontend-check frontend
ensure_probe_pod other-check other

expect_denied frontend-check db:5432
expect_denied other-check api:8080
expect_denied other-check db:5432

echo "Direct frontend->db traffic is denied"
