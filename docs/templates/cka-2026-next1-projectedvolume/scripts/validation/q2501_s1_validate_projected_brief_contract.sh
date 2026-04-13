#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="projectedvolume-lab"
CONFIGMAP="projected-volume-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "bundle-api"
expect_data "deploymentInventory" "kubectl get deployment bundle-api -n projectedvolume-lab -o wide"
expect_data "configMapNameCheck" "kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.name}'"
expect_data "configMapItemPathCheck" "kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.items[0].path}'"
expect_data "secretNameCheck" "kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.name}'"
expect_data "secretItemPathCheck" "kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.items[0].path}'"
expect_data "mountPathCheck" "kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "readOnlyCheck" "kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'"
expect_data "eventCheck" "kubectl get events -n projectedvolume-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest"
