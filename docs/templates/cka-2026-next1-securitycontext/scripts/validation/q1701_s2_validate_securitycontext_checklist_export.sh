#!/usr/bin/env bash
set -euo pipefail

CHECKLIST="/tmp/exam/q1701/securitycontext-diagnostics-checklist.txt"
[[ -f "${CHECKLIST}" ]]

grep -Fx "Deployment Inventory" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o wide" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.runAsUser}'" "${CHECKLIST}" >/dev/null

grep -Fx "Security Context Checks" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.securityContext.fsGroup}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.seccompProfile.type}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop[0]}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}'" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get events -n securitycontext-lab --sort-by=.lastTimestamp" "${CHECKLIST}" >/dev/null

grep -Fx "Safe Manifest Review" "${CHECKLIST}" >/dev/null
grep -Fx -- "- kubectl get deployment secure-api -n securitycontext-lab -o yaml" "${CHECKLIST}" >/dev/null
grep -Fx -- "- confirm runAsUser, fsGroup, seccomp, capability drop, and mount path before changing the Deployment manifest" "${CHECKLIST}" >/dev/null
