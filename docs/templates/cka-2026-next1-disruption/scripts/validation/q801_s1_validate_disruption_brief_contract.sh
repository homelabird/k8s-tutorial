#!/bin/bash
set -euo pipefail

NAMESPACE="disruption-lab"
CONFIGMAP="disruption-planning-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetNode)" = "kind-cluster-worker" ] || { echo "targetNode must be kind-cluster-worker"; exit 1; }
[ "$(get_key pdbInventory)" = "kubectl get pdb -A" ] || { echo "pdbInventory is incorrect"; exit 1; }
[ "$(get_key pdbDescribe)" = "kubectl describe pdb api-pdb -n disruption-lab" ] || { echo "pdbDescribe is incorrect"; exit 1; }
[ "$(get_key nodeWorkloadCheck)" = "kubectl get pods -A -o wide --field-selector spec.nodeName=kind-cluster-worker" ] || { echo "nodeWorkloadCheck is incorrect"; exit 1; }
[ "$(get_key cordonCommand)" = "kubectl cordon kind-cluster-worker" ] || { echo "cordonCommand is incorrect"; exit 1; }
[ "$(get_key drainPreview)" = "kubectl drain kind-cluster-worker --ignore-daemonsets --delete-emptydir-data --dry-run=client" ] || { echo "drainPreview is incorrect"; exit 1; }
[ "$(get_key uncordonCommand)" = "kubectl uncordon kind-cluster-worker" ] || { echo "uncordonCommand is incorrect"; exit 1; }
[ "$(get_key safeRemediationNote)" = "review PodDisruptionBudget impact before any non-dry-run drain" ] || { echo "safeRemediationNote is incorrect"; exit 1; }

echo "disruption planning brief contract is repaired"
