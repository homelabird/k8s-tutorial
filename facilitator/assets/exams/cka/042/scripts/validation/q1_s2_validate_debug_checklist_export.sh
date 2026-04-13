#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/debug-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Pod Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod orders-api -n debug-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.containers[*].name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.nodeName}'" "${CHECKLIST}" >/dev/null

grep -Fx "Debug Path" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl logs orders-api -n debug-lab -c api --tail=50" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl debug pod/orders-api -n debug-lab -it --image=busybox:1.36 --target=api" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod orders-api -n debug-lab -o jsonpath='{.spec.ephemeralContainers[*].name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n debug-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pod orders-api -n debug-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm target pod, target container, debug image, and ephemeral container evidence before changing workload manifests" "${CHECKLIST}" >/dev/null
