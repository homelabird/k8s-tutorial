#!/bin/bash
set -euo pipefail

NAMESPACE="scheduling-lab"
DEPLOYMENT="metrics-agent"

kubectl rollout status deployment "$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s >/dev/null 2>&1 || {
  echo "Deployment '$DEPLOYMENT' did not become ready"
  exit 1
}

POD_NAME=""
NODE_NAME=""
while IFS='|' read -r CANDIDATE_NAME DELETION_TS PHASE CANDIDATE_NODE; do
  [ -n "$CANDIDATE_NAME" ] || continue
  [ -z "$DELETION_TS" ] || continue
  [ "$PHASE" = "Running" ] || continue
  POD_NAME="$CANDIDATE_NAME"
  NODE_NAME="$CANDIDATE_NODE"
  break
done <<EOF_PODS
$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath='{range .items[*]}{.metadata.name}{"|"}{.metadata.deletionTimestamp}{"|"}{.status.phase}{"|"}{.spec.nodeName}{"\n"}{end}')
EOF_PODS

[ -n "$POD_NAME" ] || {
  echo "No active Running Pod for '$DEPLOYMENT' was found"
  exit 1
}

NODE_LABEL="$(kubectl get node "$NODE_NAME" -o jsonpath='{.metadata.labels.workload}')"

[ "$NODE_LABEL" = "ops" ] || {
  echo "Pod '$POD_NAME' is running on node '$NODE_NAME' without workload=ops"
  exit 1
}

echo "metrics-agent Pod is Running on a node labeled workload=ops"
