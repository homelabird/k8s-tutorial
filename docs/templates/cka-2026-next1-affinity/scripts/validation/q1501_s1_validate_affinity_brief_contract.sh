#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="affinity-lab"
CONFIGMAP="placement-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetDeployment" "api-fleet"
expect_data "deploymentInventory" "kubectl get deployment api-fleet -n affinity-lab -o wide"
expect_data "replicaCheck" "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'"
expect_data "antiAffinityTopologyCheck" "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'"
expect_data "antiAffinitySelectorCheck" "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'"
expect_data "topologySpreadKeyCheck" "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'"
expect_data "maxSkewCheck" "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'"
expect_data "whenUnsatisfiableCheck" "kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'"
expect_data "eventCheck" "kubectl get events -n affinity-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest"
