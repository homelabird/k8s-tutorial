#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="debug-lab"
CONFIGMAP="debug-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetPod" "orders-api"
expect_data "podInventory" "kubectl get pod orders-api -n debug-lab -o wide"
expect_data "containerInventory" "kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.containers[*].name}'"
expect_data "logsCheck" "kubectl logs orders-api -n debug-lab -c api --tail=50"
expect_data "nodeCheck" "kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.nodeName}'"
expect_data "debugCommand" "kubectl debug pod/orders-api -n debug-lab -it --image=busybox:1.36 --target=api"
expect_data "ephemeralContainerCheck" "kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[*].name}'"
expect_data "eventCheck" "kubectl get events -n debug-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm target pod, target container, debug image, and ephemeral container evidence before changing workload manifests"
