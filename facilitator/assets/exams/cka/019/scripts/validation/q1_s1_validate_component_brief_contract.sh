#!/bin/bash
set -euo pipefail

NAMESPACE="controlplane-lab"
CONFIGMAP="component-repair-brief"

kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" >/dev/null 2>&1 || {
  echo "ConfigMap $CONFIGMAP not found"
  exit 1
}

get_key() {
  kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o jsonpath="{.data.$1}"
}

[ "$(get_key schedulerManifest)" = "/etc/kubernetes/manifests/kube-scheduler.yaml" ] || { echo "schedulerManifest must be /etc/kubernetes/manifests/kube-scheduler.yaml"; exit 1; }
[ "$(get_key controllerManagerManifest)" = "/etc/kubernetes/manifests/kube-controller-manager.yaml" ] || { echo "controllerManagerManifest must be /etc/kubernetes/manifests/kube-controller-manager.yaml"; exit 1; }
[ "$(get_key schedulerHealthz)" = "https://127.0.0.1:10259/healthz" ] || { echo "schedulerHealthz must be https://127.0.0.1:10259/healthz"; exit 1; }
[ "$(get_key controllerManagerHealthz)" = "https://127.0.0.1:10257/healthz" ] || { echo "controllerManagerHealthz must be https://127.0.0.1:10257/healthz"; exit 1; }
[ "$(get_key schedulerKubeconfig)" = "/etc/kubernetes/scheduler.conf" ] || { echo "schedulerKubeconfig must be /etc/kubernetes/scheduler.conf"; exit 1; }
[ "$(get_key controllerManagerKubeconfig)" = "/etc/kubernetes/controller-manager.conf" ] || { echo "controllerManagerKubeconfig must be /etc/kubernetes/controller-manager.conf"; exit 1; }
[ "$(get_key schedulerLogHint)" = "journalctl -u kubelet | grep kube-scheduler" ] || { echo "schedulerLogHint does not match expected log guidance"; exit 1; }
[ "$(get_key controllerManagerLogHint)" = "journalctl -u kubelet | grep kube-controller-manager" ] || { echo "controllerManagerLogHint does not match expected log guidance"; exit 1; }

echo "control plane repair brief contract is repaired"
