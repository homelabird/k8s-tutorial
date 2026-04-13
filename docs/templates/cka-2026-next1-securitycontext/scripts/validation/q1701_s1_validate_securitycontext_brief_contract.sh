#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="securitycontext-lab"
CONFIGMAP="securitycontext-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "secure-api"
expect_data "deploymentInventory" "kubectl get deployment secure-api -n securitycontext-lab -o wide"
expect_data "runAsUserCheck" "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'"
expect_data "fsGroupCheck" "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'"
expect_data "seccompCheck" "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'"
expect_data "allowPrivilegeEscalationCheck" "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'"
expect_data "capabilitiesDropCheck" "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'"
expect_data "mountPathCheck" "kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "eventCheck" "kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest"
