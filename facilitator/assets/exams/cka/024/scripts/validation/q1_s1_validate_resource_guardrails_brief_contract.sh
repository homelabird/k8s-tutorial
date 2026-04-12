#!/bin/bash
set -euo pipefail

NAMESPACE="quota-lab"
CONFIGMAP="resource-guardrails-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetNamespace)" = "quota-lab" ] || { echo "targetNamespace must be quota-lab"; exit 1; }
[ "$(get_key quotaInspection)" = "kubectl get resourcequota -n quota-lab" ] || { echo "quotaInspection is incorrect"; exit 1; }
[ "$(get_key quotaDescribe)" = "kubectl describe resourcequota compute-quota -n quota-lab" ] || { echo "quotaDescribe is incorrect"; exit 1; }
[ "$(get_key limitRangeInspection)" = "kubectl describe limitrange default-limits -n quota-lab" ] || { echo "limitRangeInspection is incorrect"; exit 1; }
[ "$(get_key workloadInspection)" = "kubectl describe deployment api -n quota-lab" ] || { echo "workloadInspection is incorrect"; exit 1; }
[ "$(get_key recommendedPatch)" = "kubectl set resources deployment/api -n quota-lab --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi" ] || { echo "recommendedPatch is incorrect"; exit 1; }

echo "resource guardrails brief contract is repaired"
