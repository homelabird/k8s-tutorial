#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="connectivity-lab"

kubectl wait --for=condition=Ready pod/echo-api-0 -n "${NAMESPACE}" --timeout=180s >/dev/null

pod_response="$(kubectl exec -n "${NAMESPACE}" net-debug -- wget -qO- http://echo-api-0.echo-api-headless.connectivity-lab.svc.cluster.local:8080/healthz)"
[ "${pod_response}" = "ok" ] || {
  echo "Headless ordinal DNS path must return ok"
  exit 1
}

echo "pod DNS connectivity is repaired"
