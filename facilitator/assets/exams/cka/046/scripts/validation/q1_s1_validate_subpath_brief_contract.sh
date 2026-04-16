#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="subpath-lab"
CONFIGMAP="subpath-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "subpath-api"
expect_data "deploymentInventory" "kubectl get deployment subpath-api -n subpath-lab -o wide"
expect_data "configMapNameCheck" "kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}'"
expect_data "itemPathCheck" "kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.items[0].path}'"
expect_data "mountPathCheck" "kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "subPathCheck" "kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}'"
expect_data "readOnlyCheck" "kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'"
expect_data "containerNameCheck" "kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].name}'"
expect_data "imageCheck" "kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].image}'"
expect_data "eventCheck" "kubectl get events -n subpath-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm ConfigMap item path, subPath, and target mount path before changing the Deployment manifest"
