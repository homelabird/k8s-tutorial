#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="qos-lab"
CONFIGMAP="qos-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "reporting-api"
expect_data "deploymentInventory" "kubectl get deployment reporting-api -n qos-lab -o wide"
expect_data "requestsCpuCheck" "kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}'"
expect_data "requestsMemoryCheck" "kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}'"
expect_data "limitsCpuCheck" "kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}'"
expect_data "limitsMemoryCheck" "kubectl get deployment reporting-api -n qos-lab -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}'"
expect_data "qosClassCheck" "kubectl get pods -n qos-lab -l app=reporting-api -o jsonpath='{.items[0].status.qosClass}'"
expect_data "eventCheck" "kubectl get events -n qos-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm requests, limits, QoS class, and namespace events before changing the Deployment manifest"
