#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="identity-lab"
CONFIGMAP="identity-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "metrics-api"
expect_data "deploymentInventory" "kubectl get deployment metrics-api -n identity-lab -o wide"
expect_data "serviceAccountCheck" "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'"
expect_data "automountCheck" "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'"
expect_data "projectedTokenPathCheck" "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'"
expect_data "projectedAudienceCheck" "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'"
expect_data "mountPathCheck" "kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "eventCheck" "kubectl get events -n identity-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest"
