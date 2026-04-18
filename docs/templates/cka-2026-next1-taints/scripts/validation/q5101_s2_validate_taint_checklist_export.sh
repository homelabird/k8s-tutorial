#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/taint-diagnostics-checklist.txt"
[[ -f "$CHECKLIST" ]]

grep -Fx -- "Deployment Inventory" "$CHECKLIST" >/dev/null
grep -Fx -- "Toleration Checks" "$CHECKLIST" >/dev/null
grep -Fx -- "Safe Manifest Review" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment taint-api -n taints-lab -o wide" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].key}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].effect}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].operator}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.tolerations[0].tolerationSeconds}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment taint-api -n taints-lab -o jsonpath='{.spec.template.spec.nodeSelector.workload}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get events -n taints-lab --sort-by=.lastTimestamp" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment taint-api -n taints-lab -o yaml" "$CHECKLIST" >/dev/null
