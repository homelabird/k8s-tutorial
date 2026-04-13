#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1401/init-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment report-api -n init-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[*].name}'" "${CHECKLIST}" >/dev/null

grep -Fx "Init Container Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].command}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.volumes[0].name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.initContainers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment report-api -n init-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n init-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment report-api -n init-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm init container command, shared volume name, and mount paths before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
