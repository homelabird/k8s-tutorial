#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="service-debug-lab"

response="$(kubectl exec -n "${NAMESPACE}" net-debug -- wget -qO- http://echo-api:8080/healthz)"
[ "${response}" = "ok" ] || {
  echo "Service reachability must return ok"
  exit 1
}

echo "service reachability is repaired"
