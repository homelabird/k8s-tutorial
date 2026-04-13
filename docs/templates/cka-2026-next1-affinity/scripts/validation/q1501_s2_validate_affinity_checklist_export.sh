#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1501/placement-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.replicas}'" "${CHECKLIST}" >/dev/null

grep -Fx "Placement Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].topologyKey}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution[0].labelSelector.matchLabels.app}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].topologyKey}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].maxSkew}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o jsonpath='{.spec.template.spec.topologySpreadConstraints[0].whenUnsatisfiable}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n affinity-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment api-fleet -n affinity-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm pod anti-affinity selectors and topology spread constraints before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
