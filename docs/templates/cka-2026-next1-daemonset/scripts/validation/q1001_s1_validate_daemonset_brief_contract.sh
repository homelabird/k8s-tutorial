#!/bin/bash
set -euo pipefail

NAMESPACE="daemonset-lab"
CONFIGMAP="daemonset-rollout-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetDaemonSet)" = "log-agent" ] || { echo "targetDaemonSet must be log-agent"; exit 1; }
[ "$(get_key daemonSetInventory)" = "kubectl get daemonset log-agent -n daemonset-lab -o wide" ] || { echo "daemonSetInventory is incorrect"; exit 1; }
[ "$(get_key rolloutStatusCheck)" = "kubectl rollout status daemonset/log-agent -n daemonset-lab --timeout=180s" ] || { echo "rolloutStatusCheck is incorrect"; exit 1; }
[ "$(get_key nodeInventory)" = "kubectl get nodes -o wide" ] || { echo "nodeInventory is incorrect"; exit 1; }
[ "$(get_key nodeCoverageCheck)" = "kubectl get pods -n daemonset-lab -l app=log-agent -o wide" ] || { echo "nodeCoverageCheck is incorrect"; exit 1; }
[ "$(get_key updateStrategyCheck)" = "kubectl get daemonset log-agent -n daemonset-lab -o jsonpath='{.spec.updateStrategy.type}'" ] || { echo "updateStrategyCheck is incorrect"; exit 1; }
[ "$(get_key safeManifestNote)" = "confirm desiredNumberScheduled matches running pods before changing DaemonSet manifests" ] || { echo "safeManifestNote is incorrect"; exit 1; }

echo "daemonset brief contract is repaired"
