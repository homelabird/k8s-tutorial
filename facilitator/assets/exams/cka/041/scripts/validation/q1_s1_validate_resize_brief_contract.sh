#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="pv-resize-lab"
CONFIGMAP="resize-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetPvc" "analytics-data"
expect_data "pvcInventory" "kubectl get pvc analytics-data -n pv-resize-lab -o wide"
expect_data "requestedSizeCheck" "kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.resources.requests.storage}'"
expect_data "currentCapacityCheck" "kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.capacity.storage}'"
expect_data "storageClassCheck" "kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.storageClassName}'"
expect_data "allowExpansionCheck" "kubectl get storageclass expandable-reports -o jsonpath='{.allowVolumeExpansion}'"
expect_data "conditionCheck" "kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.conditions[*].type}'"
expect_data "mountPathCheck" "kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "eventCheck" "kubectl get events -n pv-resize-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm requested size, current capacity, resize support, PVC conditions, and mount path before changing storage manifests"
