#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q2501/projected-volume-checklist.txt"

[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx "Projected Volume Checks" "${CHECKLIST}" >/dev/null
grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null

grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].configMap.items[0].path}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[1].secret.items[0].path}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n projectedvolume-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment bundle-api -n projectedvolume-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm projected sources, item paths, and readOnly mount before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
