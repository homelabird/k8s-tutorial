#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q2801/rwop-diagnostics-checklist.txt"

[[ -f "${CHECKLIST}" ]]

grep -Fx "Claim Inventory" "${CHECKLIST}" >/dev/null
grep -Fx "Access Mode Checks" "${CHECKLIST}" >/dev/null
grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null

grep -Fx -- "- kubectl get pvc data-claim -n rwop-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.accessModes[0]}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.storageClassName}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc data-claim -n rwop-lab -o jsonpath='{.spec.volumeName}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod rwop-reader -n rwop-lab -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod rwop-reader -n rwop-lab -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get storageclass rwop-hostpath -o jsonpath='{.allowVolumeExpansion}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n rwop-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc data-claim -n rwop-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm PVC access mode, claim consumer, and mount path before changing workload or storage manifests" "${CHECKLIST}" >/dev/null
