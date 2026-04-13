#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q2101/reclaim-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "PVC Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc reports-data -n pv-reclaim-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.volumeName}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc reports-data -n pv-reclaim-lab -o jsonpath='{.spec.storageClassName}'" "${CHECKLIST}" >/dev/null

grep -Fx "PV Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pv reports-pv -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pv reports-pv -o jsonpath='{.spec.claimRef.namespace}/{.spec.claimRef.name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reports-db -n pv-reclaim-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n pv-reclaim-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment reports-db -n pv-reclaim-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pv reports-pv -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm PVC binding, PV reclaim policy, claimRef, and workload mount path before changing storage manifests" "${CHECKLIST}" >/dev/null
