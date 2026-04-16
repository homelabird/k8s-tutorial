#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="envfrom-lab"
CONFIGMAP="envfrom-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "env-bundle"
expect_data "deploymentInventory" "kubectl get deployment env-bundle -n envfrom-lab -o wide"
expect_data "configMapEnvFromCheck" "kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'"
expect_data "secretEnvFromCheck" "kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].secretRef.name}'"
expect_data "prefixCheck" "kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].prefix}'"
expect_data "containerNameCheck" "kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].name}'"
expect_data "imageCheck" "kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].image}'"
expect_data "eventCheck" "kubectl get events -n envfrom-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm envFrom source order, secret prefix, and container name before changing the Deployment manifest"
