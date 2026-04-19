#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="connectivity-lab"

kubectl rollout status statefulset/echo-api -n "${NAMESPACE}" --timeout=180s >/dev/null

kubectl exec -n "${NAMESPACE}" net-debug -- nslookup echo-api.connectivity-lab.svc.cluster.local >/dev/null

service_response="$(kubectl exec -n "${NAMESPACE}" net-debug -- wget -qO- http://echo-api:8080/healthz)"
[ "${service_response}" = "ok" ] || {
  echo "Service path must return ok"
  exit 1
}

echo "service path connectivity is repaired"
