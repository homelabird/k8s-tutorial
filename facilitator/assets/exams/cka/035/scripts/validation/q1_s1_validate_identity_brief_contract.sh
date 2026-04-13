#!/bin/bash
set -euo pipefail

NAMESPACE="identity-lab"
CONFIGMAP="identity-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetDeployment)" = "metrics-api" ] || { echo "targetDeployment is incorrect"; exit 1; }
[ "$(get_key deploymentInventory)" = "kubectl get deployment metrics-api -n identity-lab -o wide" ] || { echo "deploymentInventory is incorrect"; exit 1; }
[ "$(get_key serviceAccountCheck)" = "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'" ] || { echo "serviceAccountCheck is incorrect"; exit 1; }
[ "$(get_key automountCheck)" = "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'" ] || { echo "automountCheck is incorrect"; exit 1; }
[ "$(get_key projectedTokenPathCheck)" = "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'" ] || { echo "projectedTokenPathCheck is incorrect"; exit 1; }
[ "$(get_key projectedAudienceCheck)" = "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'" ] || { echo "projectedAudienceCheck is incorrect"; exit 1; }
[ "$(get_key mountPathCheck)" = "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" ] || { echo "mountPathCheck is incorrect"; exit 1; }
[ "$(get_key eventCheck)" = "kubectl get events -n identity-lab --sort-by=.lastTimestamp" ] || { echo "eventCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "identity diagnostics brief contract is repaired"
