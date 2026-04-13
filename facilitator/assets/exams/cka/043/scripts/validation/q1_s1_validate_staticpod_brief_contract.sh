#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="staticpod-lab"
CONFIGMAP="staticpod-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetMirrorPod" "audit-agent-ckad9999"
expect_data "mirrorPodInventory" "kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o wide"
expect_data "staticPodPathCheck" "sudo ls -l /etc/kubernetes/manifests/audit-agent.yaml"
expect_data "manifestPreviewCheck" "sudo sed -n '1,160p' /etc/kubernetes/manifests/audit-agent.yaml"
expect_data "hostNetworkCheck" "kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.hostNetwork}'"
expect_data "containerCommandCheck" "kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.containers[0].command}'"
expect_data "nodeCheck" "kubectl get pod audit-agent-ckad9999 -n staticpod-lab -o jsonpath='{.spec.nodeName}'"
expect_data "eventCheck" "kubectl get events -n staticpod-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm manifest path, mirror pod inventory, hostNetwork setting, and container command before changing static pod manifests"
