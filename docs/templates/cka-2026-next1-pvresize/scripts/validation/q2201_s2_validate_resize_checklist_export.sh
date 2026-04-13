#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q2201/resize-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "PVC Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc analytics-data -n pv-resize-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.resources.requests.storage}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.capacity.storage}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.spec.storageClassName}'" "${CHECKLIST}" >/dev/null

grep -Fx "Resize Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get storageclass expandable-reports -o jsonpath='{.allowVolumeExpansion}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc analytics-data -n pv-resize-lab -o jsonpath='{.status.conditions[*].type}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment analytics-api -n pv-resize-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n pv-resize-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment analytics-api -n pv-resize-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pvc analytics-data -n pv-resize-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm requested size, current capacity, resize support, PVC conditions, and mount path before changing storage manifests" "${CHECKLIST}" >/dev/null
