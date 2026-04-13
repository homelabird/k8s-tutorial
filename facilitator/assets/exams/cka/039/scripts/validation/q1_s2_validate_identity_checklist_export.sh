#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1/pull-auth-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment private-api -n registry-auth-lab -o wide" "${CHECKLIST}" >/dev/null

grep -Fx "Pull Secret Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.imagePullSecrets[*].name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment private-api -n registry-auth-lab -o jsonpath='{.spec.template.spec.containers[0].image}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get secret regcred -n registry-auth-lab -o jsonpath='{.type}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get serviceaccount puller -n registry-auth-lab -o jsonpath='{.imagePullSecrets[*].name}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n registry-auth-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment private-api -n registry-auth-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm imagePullSecrets, ServiceAccount wiring, secret type, and image reference before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
