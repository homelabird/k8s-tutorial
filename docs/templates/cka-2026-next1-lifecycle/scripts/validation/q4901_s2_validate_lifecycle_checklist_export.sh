#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/lifecycle-diagnostics-checklist.txt"
[[ -f "$CHECKLIST" ]]

grep -Fx -- "Deployment Inventory" "$CHECKLIST" >/dev/null
grep -Fx -- "Lifecycle Hook Checks" "$CHECKLIST" >/dev/null
grep -Fx -- "Safe Manifest Review" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment lifecycle-api -n lifecycle-lab -o wide" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[0]}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].lifecycle.preStop.exec.command[2]}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].command[2]}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment lifecycle-api -n lifecycle-lab -o jsonpath='{.spec.template.spec.containers[0].image}'" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get events -n lifecycle-lab --sort-by=.lastTimestamp" "$CHECKLIST" >/dev/null
grep -Fx -- "- kubectl get deployment lifecycle-api -n lifecycle-lab -o yaml" "$CHECKLIST" >/dev/null
