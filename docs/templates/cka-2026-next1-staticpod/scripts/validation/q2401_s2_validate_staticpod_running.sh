#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="staticpod-lab"

for _ in $(seq 1 90); do
  POD_NAME="$(kubectl get pods -n "${NAMESPACE}" -l app=audit-agent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "${POD_NAME}" ]; then
    kubectl wait --for=condition=Ready "pod/${POD_NAME}" -n "${NAMESPACE}" --timeout=5s >/dev/null 2>&1 || true
    HOST_NETWORK="$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.hostNetwork}' 2>/dev/null || true)"
    PHASE="$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null || true)"
    if [ "${HOST_NETWORK}" = "true" ] && [ "${PHASE}" = "Running" ]; then
      echo "The mirror Pod for audit-agent is Running in staticpod-lab with host networking enabled"
      exit 0
    fi
  fi
  sleep 2
done

echo "audit-agent mirror Pod is not Running with hostNetwork=true"
exit 1
