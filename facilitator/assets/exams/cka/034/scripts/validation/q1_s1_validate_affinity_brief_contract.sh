#!/bin/bash
set -euo pipefail

NAMESPACE="affinity-lab"
CONFIGMAP="placement-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetDeployment)" = "api-fleet" ] || { echo "targetDeployment is incorrect"; exit 1; }
[ "$(get_key deploymentInventory)" = "kubectl get deployment api-fleet -n affinity-lab -o wide" ] || { echo "deploymentInventory is incorrect"; exit 1; }
[ "$(get_key replicaCheck)" = "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'" ] || { echo "replicaCheck is incorrect"; exit 1; }
[ "$(get_key antiAffinityTopologyCheck)" = "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'" ] || { echo "antiAffinityTopologyCheck is incorrect"; exit 1; }
[ "$(get_key antiAffinitySelectorCheck)" = "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'" ] || { echo "antiAffinitySelectorCheck is incorrect"; exit 1; }
[ "$(get_key topologySpreadKeyCheck)" = "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'" ] || { echo "topologySpreadKeyCheck is incorrect"; exit 1; }
[ "$(get_key maxSkewCheck)" = "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'" ] || { echo "maxSkewCheck is incorrect"; exit 1; }
[ "$(get_key whenUnsatisfiableCheck)" = "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'" ] || { echo "whenUnsatisfiableCheck is incorrect"; exit 1; }
[ "$(get_key eventCheck)" = "kubectl get events -n affinity-lab --sort-by=.lastTimestamp" ] || { echo "eventCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "affinity diagnostics brief contract is repaired"
