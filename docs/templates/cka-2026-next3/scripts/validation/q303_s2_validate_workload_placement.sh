#!/bin/bash
set -euo pipefail

NAMESPACE="node-lab"
DEPLOYMENT="queue-consumer"
TARGET_NODE="$(kubectl get nodes -l maintenance-lab=target -o jsonpath='{.items[0].metadata.name}')"
[ -n "$TARGET_NODE" ] || {
  echo "No maintenance target node found"
  exit 1
}

AVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}' 2>/dev/null || true)"
[ "${AVAILABLE:-0}" -ge 1 ] || {
  echo "Deployment '$DEPLOYMENT' is not Available"
  exit 1
}

POD_NAME="$(kubectl get pods -n "$NAMESPACE" -l app=queue-consumer -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.metadata.name}{"\n"}{end}' | head -n1)"
[ -n "$POD_NAME" ] || {
  echo "No Running queue-consumer Pod found"
  exit 1
}

POD_NODE="$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.nodeName}')"
[ "$POD_NODE" = "$TARGET_NODE" ] || {
  echo "queue-consumer must run on the labeled maintenance target node"
  exit 1
}

echo "queue-consumer is Running on the labeled maintenance target node"
