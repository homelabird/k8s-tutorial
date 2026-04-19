#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="service-debug-lab"

kubectl rollout status deployment/echo-api -n "${NAMESPACE}" --timeout=180s >/dev/null

replicas="$(kubectl get deployment echo-api -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}')"
[ "${replicas}" = "2" ] || { echo "Deployment echo-api must stay at replicas 2"; exit 1; }

for _ in $(seq 1 30); do
  addresses="$(kubectl get endpoints echo-api -n "${NAMESPACE}" -o jsonpath='{.subsets[*].addresses[*].ip}')"
  count="$(printf '%s\n' "${addresses}" | wc -w | tr -d ' ')"
  if [ "${count}" -eq 2 ]; then
    echo "service exposure endpoints are repaired"
    exit 0
  fi
  sleep 2
done

echo "Service echo-api must publish 2 ready endpoints"
exit 1
