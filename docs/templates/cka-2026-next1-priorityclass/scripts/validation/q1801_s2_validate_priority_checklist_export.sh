#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1801/priority-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "PriorityClass Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get priorityclass ops-critical -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get priorityclass ops-critical -o jsonpath='{.value}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get priorityclass ops-critical -o jsonpath='{.preemptionPolicy}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get priorityclass ops-critical -o jsonpath='{.globalDefault}'" "${CHECKLIST}" >/dev/null

grep -Fx "Workload Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment batch-api -n priority-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment batch-api -n priority-lab -o jsonpath='{.spec.template.spec.priorityClassName}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get pods -n priority-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n priority-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment batch-api -n priority-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm priorityClassName, priority value, preemption policy, and scheduler events before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
