#!/bin/bash
set -euo pipefail

NAMESPACE="storage-lab"
DEPLOYMENT="reporting-app"
PVC_NAME="app-data"

kubectl rollout status deployment "$DEPLOYMENT" -n "$NAMESPACE" --timeout=180s >/dev/null 2>&1 || {
  echo "Deployment '$DEPLOYMENT' did not become Available"
  exit 1
}

CLAIM_NAME="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.volumes[?(@.name=="app-data")].persistentVolumeClaim.claimName}')"
MOUNT_PATH="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[?(@.name=="app-data")].mountPath}')"
AVAILABLE="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.status.availableReplicas}')"
POD_NAME="$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}')"
PHASE="$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')"

[ "$CLAIM_NAME" = "$PVC_NAME" ] || {
  echo "Deployment volume points to '$CLAIM_NAME', expected '$PVC_NAME'"
  exit 1
}

[ "$MOUNT_PATH" = "/data" ] || {
  echo "Deployment mounts the PVC at '$MOUNT_PATH', expected '/data'"
  exit 1
}

[ "$AVAILABLE" = "1" ] || {
  echo "Deployment '$DEPLOYMENT' does not report 1 available replica"
  exit 1
}

[ "$PHASE" = "Running" ] || {
  echo "Pod '$POD_NAME' is not Running. Current phase: '$PHASE'"
  exit 1
}

kubectl exec -n "$NAMESPACE" "$POD_NAME" -- sh -c 'test -f /data/ready.txt' >/dev/null 2>&1 || {
  echo "Pod '$POD_NAME' does not expose the expected mounted file at /data/ready.txt"
  exit 1
}

echo "reporting-app is Available and mounts the claim at /data"
