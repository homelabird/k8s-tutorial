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

ensure_probe_pod frontend-check frontend
ensure_probe_pod api-check api

kubectl exec -n "$NAMESPACE" frontend-check -- sh -lc 'curl -fsS --max-time 5 http://api:8080/ >/dev/null' || {
  echo "frontend traffic to api:8080 should be allowed"
  exit 1
}

kubectl exec -n "$NAMESPACE" api-check -- sh -lc 'curl -fsS --max-time 5 http://db:5432/ >/dev/null' || {
  echo "api traffic to db:5432 should be allowed"
  exit 1
}

echo "Allowed paths frontend->api and api->db work on the required ports"
