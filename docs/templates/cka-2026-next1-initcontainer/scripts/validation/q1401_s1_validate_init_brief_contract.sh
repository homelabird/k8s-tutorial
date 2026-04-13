#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="init-lab"
CONFIGMAP="init-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "report-api"
expect_data "deploymentInventory" "kubectl get deployment report-api -n init-lab -o wide"
expect_data "initContainerInventory" "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'"
expect_data "initCommandCheck" "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'"
expect_data "sharedVolumeCheck" "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'"
expect_data "initMountCheck" "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'"
expect_data "appMountCheck" "kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "eventCheck" "kubectl get events -n init-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm init container command, shared volume name, and mount paths before changing the Deployment manifest"
