#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1601/identity-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment metrics-api -n identity-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.serviceAccountName}'" "${CHECKLIST}" >/dev/null

grep -Fx "Identity Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.automountServiceAccountToken}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.path}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.volumes[0].projected.sources[0].serviceAccountToken.audience}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment metrics-api -n identity-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n identity-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment metrics-api -n identity-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm serviceAccountName, projected token audience, and mount path before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
