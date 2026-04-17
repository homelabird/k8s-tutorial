#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/meta-diagnostics-checklist.txt"
[[ -f "$CHECKLIST" ]]

grep -Fx -- "Deployment Inventory" "$CHECKLIST" >/dev/null
grep -Fx -- "Downward API Checks" "$CHECKLIST" >/dev/null
grep -Fx -- "Safe Manifest Review" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment meta-api -n downwardapi-lab -o wide" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].name}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[0].valueFrom.fieldRef.fieldPath}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].env[1].valueFrom.fieldRef.fieldPath}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].name}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment meta-api -n downwardapi-lab -o jsonpath='{.spec.template.spec.containers[0].image}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get events -n downwardapi-lab --sort-by=.lastTimestamp" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment meta-api -n downwardapi-lab -o yaml" "$CHECKLIST" >/dev/null
