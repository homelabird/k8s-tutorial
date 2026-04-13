#!/bin/bash
set -euo pipefail

NAMESPACE="init-lab"
CONFIGMAP="init-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetDeployment)" = "report-api" ] || { echo "targetDeployment is incorrect"; exit 1; }
[ "$(get_key deploymentInventory)" = "kubectl get deployment report-api -n init-lab -o wide" ] || { echo "deploymentInventory is incorrect"; exit 1; }
[ "$(get_key initContainerInventory)" = "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'" ] || { echo "initContainerInventory is incorrect"; exit 1; }
[ "$(get_key initCommandCheck)" = "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'" ] || { echo "initCommandCheck is incorrect"; exit 1; }
[ "$(get_key sharedVolumeCheck)" = "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'" ] || { echo "sharedVolumeCheck is incorrect"; exit 1; }
[ "$(get_key initMountCheck)" = "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'" ] || { echo "initMountCheck is incorrect"; exit 1; }
[ "$(get_key appMountCheck)" = "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" ] || { echo "appMountCheck is incorrect"; exit 1; }
[ "$(get_key eventCheck)" = "kubectl get events -n init-lab --sort-by=.lastTimestamp" ] || { echo "eventCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm init container command, shared volume name, and mount paths before changing the Deployment manifest" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "init diagnostics brief contract is repaired"
