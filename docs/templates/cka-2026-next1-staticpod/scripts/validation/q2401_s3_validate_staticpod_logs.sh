#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="staticpod-lab"
POD_NAME="$(kubectl get pods -n "${NAMESPACE}" -l app=audit-agent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

[ -n "${POD_NAME}" ] || {
  echo "audit-agent mirror Pod not found"
  exit 1
}

kubectl logs "${POD_NAME}" -n "${NAMESPACE}" --tail=20 | grep -F 'static-pod-audit' >/dev/null || {
  echo "audit-agent logs do not contain static-pod-audit"
  exit 1
}

NODE_NAME="$(kubectl get pod "${POD_NAME}" -n "${NAMESPACE}" -o jsonpath='{.spec.nodeName}')"
[ -n "${NODE_NAME}" ] || {
  echo "audit-agent mirror Pod is missing node placement"
  exit 1
}

echo "The static pod emits the expected audit log line from the corrected command loop"
