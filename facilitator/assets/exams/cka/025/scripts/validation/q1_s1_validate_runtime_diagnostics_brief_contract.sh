#!/bin/bash
set -euo pipefail

NAMESPACE="runtime-lab"
CONFIGMAP="runtime-diagnostics-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key targetNode)" = "kind-cluster-control-plane" ] || { echo "targetNode must be kind-cluster-control-plane"; exit 1; }
[ "$(get_key kubeletConfigCheck)" = "sudo grep -n containerRuntimeEndpoint /var/lib/kubelet/config.yaml" ] || { echo "kubeletConfigCheck is incorrect"; exit 1; }
[ "$(get_key runtimeSocketCheck)" = "sudo test -S /run/containerd/containerd.sock" ] || { echo "runtimeSocketCheck is incorrect"; exit 1; }
[ "$(get_key crictlInfoCheck)" = "sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock info" ] || { echo "crictlInfoCheck is incorrect"; exit 1; }
[ "$(get_key crictlPodsCheck)" = "sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock pods" ] || { echo "crictlPodsCheck is incorrect"; exit 1; }
[ "$(get_key runtimeServiceCheck)" = "sudo systemctl status containerd" ] || { echo "runtimeServiceCheck is incorrect"; exit 1; }

echo "runtime diagnostics brief contract is repaired"
