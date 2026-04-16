#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/subpath-diagnostics-checklist.txt"

[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx "subPath Checks" "${CHECKLIST}" >/dev/null
grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null

grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.volumes[0].configMap.items[0].path}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].subPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].readOnly}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o jsonpath='{.spec.template.spec.containers[0].image}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n subpath-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment subpath-api -n subpath-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm ConfigMap item path, subPath, and target mount path before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
