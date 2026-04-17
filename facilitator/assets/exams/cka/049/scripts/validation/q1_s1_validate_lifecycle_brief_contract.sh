#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="lifecycle-lab"
CONFIGMAP="lifecycle-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "$CONFIGMAP" -n "$NAMESPACE" -o "jsonpath={.data.${key}}")"
  [[ "$actual" == "$expected" ]]
}

expect_data "targetDeployment" "lifecycle-api"
expect_data "deploymentInventory" "kubectl get deployment lifecycle-api -n lifecycle-lab -o wide"
expect_data "terminationGraceCheck" "kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}'"
expect_data "preStopTypeCheck" "kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[0]}'"
expect_data "preStopCommandCheck" "kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]}'"
expect_data "containerCommandCheck" "kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].command[2]}'"
expect_data "imageCheck" "kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].image}'"
expect_data "eventCheck" "kubectl get events -n lifecycle-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm lifecycle preStop commands and termination grace period before changing workload manifests or forcing pod deletion"
