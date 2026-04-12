#!/bin/bash
set -euo pipefail

NAMESPACE="storage-lab"
PV_NAME="app-data-pv"
PVC_NAME="app-data"
DEPLOYMENT="reporting-app"

CLAIM_NS="$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.claimRef.namespace}')"
CLAIM_NAME="$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.claimRef.name}')"
RECLAIM_POLICY="$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')"
ACCESS_MODES="$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.accessModes[*]}')"
PVC_COUNT="$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | awk 'END { print NR + 0 }')"
DEPLOYMENT_CLAIM="$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.volumes[?(@.name=="app-data")].persistentVolumeClaim.claimName}')"

[ "$CLAIM_NS" = "$NAMESPACE" ] || {
  echo "PersistentVolume '$PV_NAME' is claimed by namespace '$CLAIM_NS', expected '$NAMESPACE'"
  exit 1
}

[ "$CLAIM_NAME" = "$PVC_NAME" ] || {
  echo "PersistentVolume '$PV_NAME' is claimed by '$CLAIM_NAME', expected '$PVC_NAME'"
  exit 1
}

[ "$RECLAIM_POLICY" = "Retain" ] || {
  echo "PersistentVolume '$PV_NAME' reclaim policy is '$RECLAIM_POLICY', expected 'Retain'"
  exit 1
}

echo "$ACCESS_MODES" | grep -wq ReadWriteOnce || {
  echo "PersistentVolume '$PV_NAME' does not keep ReadWriteOnce access"
  exit 1
}

[ "$PVC_COUNT" -eq 1 ] || {
  echo "Namespace '$NAMESPACE' should contain exactly one PVC, found '$PVC_COUNT'"
  exit 1
}

[ "$DEPLOYMENT_CLAIM" = "$PVC_NAME" ] || {
  echo "Deployment '$DEPLOYMENT' no longer references PVC '$PVC_NAME'"
  exit 1
}

echo "Storage fix preserves the intended PV/PVC relationship without orphaning resources"
