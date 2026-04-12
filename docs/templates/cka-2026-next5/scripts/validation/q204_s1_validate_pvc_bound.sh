#!/bin/bash
set -euo pipefail

NAMESPACE="storage-lab"
PVC_NAME="app-data"
PV_NAME="app-data-pv"

kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "PersistentVolumeClaim '$PVC_NAME' not found in namespace '$NAMESPACE'"
  exit 1
}

PHASE="$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')"
BOUND_PV="$(kubectl get pvc "$PVC_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.volumeName}')"

[ "$PHASE" = "Bound" ] || {
  echo "PersistentVolumeClaim '$PVC_NAME' is not Bound. Current phase: '$PHASE'"
  exit 1
}

[ "$BOUND_PV" = "$PV_NAME" ] || {
  echo "PersistentVolumeClaim '$PVC_NAME' is bound to '$BOUND_PV', expected '$PV_NAME'"
  exit 1
}

echo "PersistentVolumeClaim app-data is Bound to app-data-pv"
