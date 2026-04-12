#!/bin/bash
set -euo pipefail

NAMESPACE="storageclass-lab"
CONFIGMAP="dynamic-provisioning-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetNamespace)" = "storageclass-lab" ] || { echo "targetNamespace must be storageclass-lab"; exit 1; }
[ "$(get_key targetPVC)" = "reports-pvc" ] || { echo "targetPVC must be reports-pvc"; exit 1; }
[ "$(get_key targetStorageClass)" = "exam-standard" ] || { echo "targetStorageClass must be exam-standard"; exit 1; }
[ "$(get_key storageClassInventory)" = "kubectl get storageclass" ] || { echo "storageClassInventory is incorrect"; exit 1; }
[ "$(get_key defaultClassCheck)" = "kubectl get storageclass -o custom-columns=NAME:.metadata.name,DEFAULT:.metadata.annotations.storageclass\\.kubernetes\\.io/is-default-class" ] || { echo "defaultClassCheck is incorrect"; exit 1; }
[ "$(get_key pvcDescribe)" = "kubectl describe pvc reports-pvc -n storageclass-lab" ] || { echo "pvcDescribe is incorrect"; exit 1; }
[ "$(get_key workloadDescribe)" = "kubectl describe pod reports-api -n storageclass-lab" ] || { echo "workloadDescribe is incorrect"; exit 1; }
[ "$(get_key eventCheck)" = "kubectl get events -n storageclass-lab --sort-by=.lastTimestamp" ] || { echo "eventCheck is incorrect"; exit 1; }
[ "$(get_key recommendedManifestLine)" = "storageClassName: exam-standard" ] || { echo "recommendedManifestLine is incorrect"; exit 1; }

echo "dynamic provisioning brief contract is repaired"
