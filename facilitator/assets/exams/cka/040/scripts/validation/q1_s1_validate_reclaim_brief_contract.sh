#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="pv-reclaim-lab"
CONFIGMAP="reclaim-diagnostics-brief"

expect_data() {
  local key="$1"
  local expected="$2"
  local actual
  actual="$(kubectl get configmap "${CONFIGMAP}" -n "${NAMESPACE}" -o "jsonpath={.data.${key}}")"
  [[ "${actual}" == "${expected}" ]]
}

expect_data "targetPvc" "reports-data"
expect_data "pvcInventory" "kubectl get pvc reports-data -n pv-reclaim-lab -o wide"
expect_data "volumeNameCheck" "kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.volumeName}'"
expect_data "storageClassCheck" "kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.storageClassName}'"
expect_data "reclaimPolicyCheck" "kubectl get pv reports-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'"
expect_data "claimRefCheck" "kubectl get pv reports-pv -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}'"
expect_data "mountPathCheck" "kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'"
expect_data "eventCheck" "kubectl get events -n pv-reclaim-lab --sort-by=.lastTimestamp"
expect_data "safeManifestNote" "confirm PVC binding, PV reclaim policy, claimRef, and workload mount path before changing storage manifests"
