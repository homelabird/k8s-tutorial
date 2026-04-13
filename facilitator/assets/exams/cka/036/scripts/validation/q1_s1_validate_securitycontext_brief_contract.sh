#!/bin/bash
set -euo pipefail

NAMESPACE="securitycontext-lab"
CONFIGMAP="securitycontext-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetDeployment)" = "secure-api" ] || { echo "targetDeployment is incorrect"; exit 1; }
[ "$(get_key deploymentInventory)" = "kubectl get deployment secure-api -n securitycontext-lab -o wide" ] || { echo "deploymentInventory is incorrect"; exit 1; }
[ "$(get_key runAsUserCheck)" = "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'" ] || { echo "runAsUserCheck is incorrect"; exit 1; }
[ "$(get_key fsGroupCheck)" = "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'" ] || { echo "fsGroupCheck is incorrect"; exit 1; }
[ "$(get_key seccompCheck)" = "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'" ] || { echo "seccompCheck is incorrect"; exit 1; }
[ "$(get_key allowPrivilegeEscalationCheck)" = "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'" ] || { echo "allowPrivilegeEscalationCheck is incorrect"; exit 1; }
[ "$(get_key capabilitiesDropCheck)" = "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'" ] || { echo "capabilitiesDropCheck is incorrect"; exit 1; }
[ "$(get_key mountPathCheck)" = "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" ] || { echo "mountPathCheck is incorrect"; exit 1; }
[ "$(get_key eventCheck)" = "kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp" ] || { echo "eventCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "securitycontext diagnostics brief contract is repaired"
