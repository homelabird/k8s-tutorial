#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/envfrom-diagnostics-checklist.txt"

[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx "EnvFrom Checks" "${CHECKLIST}" >/dev/null
grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null

grep -Fx -- "- kubectl get deployment env-bundle -n envfrom-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].secretRef.name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].envFrom[1].prefix}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment env-bundle -n envfrom-lab -o jsonpath='{.spec.template.spec.containers[0].image}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n envfrom-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment env-bundle -n envfrom-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm envFrom source order, secret prefix, and container name before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
