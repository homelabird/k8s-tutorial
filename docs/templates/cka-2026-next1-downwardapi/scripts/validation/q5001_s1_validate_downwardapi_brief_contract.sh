#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="downwardapi-lab"
CONFIGMAP="meta-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o "jsonpath={.data.${key}}")"
  [[ "$actual" == "$expected" ]]
}

expect_data "targetDeployment" "meta-api"
expect_data "deploymentInventory" "kubectl get deployment meta-api -n downwardapi-lab -o wide"
expect_data "envNameCheck" "kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].name}'"
expect_data "fieldPathCheck" "kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.fieldRef.fieldPath}'"
expect_data "namespaceFieldCheck" "kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath}'"
expect_data "containerNameCheck" "kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].name}'"
expect_data "imageCheck" "kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].image}'"
expect_data "eventCheck" "kubectl get events -n downwardapi-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm downward API fieldRef paths and target env names before changing workload manifests or forcing pod recreation"
