#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="registry-auth-lab"
CONFIGMAP="pull-auth-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "private-api"
expect_data "deploymentInventory" "kubectl get deployment private-api -n registry-auth-lab -o wide"
expect_data "serviceAccountCheck" "kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'"
expect_data "imagePullSecretsCheck" "kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.imagePullSecrets[*].name}'"
expect_data "imageReferenceCheck" "kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.containers[0].image}'"
expect_data "secretTypeCheck" "kubectl get secret regcred -n registry-auth-lab -o jsonpath='{.type}'"
expect_data "serviceAccountSecretCheck" "kubectl get serviceaccount puller -n registry-auth-lab -o jsonpath='{.imagePullSecrets[*].name}'"
expect_data "eventCheck" "kubectl get events -n registry-auth-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm imagePullSecrets, ServiceAccount wiring, secret type, and image reference before changing the Deployment manifest"
