#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="rwop-lab"
CONFIGMAP="rwop-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetClaim" "data-claim"
expect_data "claimInventory" "kubectl get pvc data-claim -n rwop-lab -o wide"
expect_data "accessModeCheck" "kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.accessModes[0]}'"
expect_data "storageClassCheck" "kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.storageClassName}'"
expect_data "volumeNameCheck" "kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.volumeName}'"
expect_data "readerPodCheck" "kubectl get pod rwop-reader -n rwop-lab -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}'"
expect_data "mountPathCheck" "kubectl get pod rwop-reader -n rwop-lab -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "storageClassExpansionCheck" "kubectl get storageclass rwop-hostpath -o jsonpath='{.allowVolumeExpansion}'"
expect_data "eventCheck" "kubectl get events -n rwop-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm PVC access mode, claim consumer, and mount path before changing workload or storage manifests"
