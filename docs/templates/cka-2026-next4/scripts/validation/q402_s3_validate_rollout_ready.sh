#!/bin/bash
set -euo pipefail

NAMESPACE="triage-lab"
DEPLOYMENT="ops-api"

AVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
[ "${AVAILABLE:-0}" -ge 1 ] || {
  echo "Deployment '$DEPLOYMENT' is not Available"
  exit 1
}

POD_NAME="$(kubectl get pods -n "$NAMESPACE" -l app=ops-api -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"|"}{.status.phase}{"\n"}{end}' | awk -F'|' '$2=="" && $3=="Running" {print $1; exit}')"
[ -n "$POD_NAME" ] || {
  echo "No active Running Pod found for ops-api"
  exit 1
}

API_READY="$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[?(@.name=="api")].ready}')"
AGENT_READY="$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[?(@.name=="log-agent")].ready}')"
AGENT_RESTARTS="$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[?(@.name=="log-agent")].restartCount}')"

[ "$API_READY" = "true" ] || { echo "api container is not Ready"; exit 1; }
[ "$AGENT_READY" = "true" ] || { echo "log-agent container is not Ready"; exit 1; }
[ "${AGENT_RESTARTS:-0}" = "0" ] || { echo "Active log-agent container should not still be restarting"; exit 1; }

echo "The repaired multi-container workload is Available"
