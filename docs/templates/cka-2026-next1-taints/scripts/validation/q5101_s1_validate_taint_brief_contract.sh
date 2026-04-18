#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="taints-lab"
CONFIGMAP="taint-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o "jsonpath={.data.${key}}")"
  [[ "$actual" == "$expected" ]]
}

expect_data "targetDeployment" "taint-api"
expect_data "deploymentInventory" "kubectl get deployment taint-api -n taints-lab -o wide"
expect_data "tolerationKeyCheck" "kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].key}'"
expect_data "tolerationEffectCheck" "kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].effect}'"
expect_data "tolerationOperatorCheck" "kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].operator}'"
expect_data "tolerationSecondsCheck" "kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].tolerationSeconds}'"
expect_data "nodeSelectorCheck" "kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.nodeSelector.workload}'"
expect_data "eventCheck" "kubectl get events -n taints-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm taint effect, toleration seconds, and node selector before changing workload manifests or mutating node taints"
