#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="priority-lab"
CONFIGMAP="priority-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "batch-api"
expect_data "targetPriorityClass" "ops-critical"
expect_data "priorityClassInventory" "kubectl get priorityclass ops-critical -o yaml"
expect_data "deploymentInventory" "kubectl get deployment batch-api -n priority-lab -o wide"
expect_data "priorityClassNameCheck" "kubectl get deployment batch-api -n priority-lab -o jsonpath='{.spec.template.spec.priorityClassName}'"
expect_data "priorityValueCheck" "kubectl get priorityclass ops-critical -o jsonpath='{.value}'"
expect_data "preemptionPolicyCheck" "kubectl get priorityclass ops-critical -o jsonpath='{.preemptionPolicy}'"
expect_data "globalDefaultCheck" "kubectl get priorityclass ops-critical -o jsonpath='{.globalDefault}'"
expect_data "schedulerCheck" "kubectl get pods -n priority-lab -o wide"
expect_data "eventCheck" "kubectl get events -n priority-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm priorityClassName, priority value, preemption policy, and scheduler events before changing the Deployment manifest"
