#!/bin/bash
set -euo pipefail

NAMESPACE="node-health-lab"
CONFIGMAP="node-recovery-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetNode)" = "kind-cluster-worker" ] || { echo "targetNode must be kind-cluster-worker"; exit 1; }
[ "$(get_key nodeConditionCheck)" = "kubectl describe node kind-cluster-worker | grep -A3 Conditions" ] || { echo "nodeConditionCheck is incorrect"; exit 1; }
[ "$(get_key kubeletServiceCheck)" = "sudo systemctl status kubelet" ] || { echo "kubeletServiceCheck is incorrect"; exit 1; }
[ "$(get_key kubeletLogCheck)" = "sudo journalctl -u kubelet -n 50" ] || { echo "kubeletLogCheck is incorrect"; exit 1; }
[ "$(get_key configCheck)" = "sudo test -f /var/lib/kubelet/config.yaml" ] || { echo "configCheck is incorrect"; exit 1; }
[ "$(get_key runtimeCheck)" = "sudo crictl info" ] || { echo "runtimeCheck is incorrect"; exit 1; }

echo "node recovery brief contract is repaired"
